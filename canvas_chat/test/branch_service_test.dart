import 'dart:async';

import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/data/llm/llm_provider.dart';
import 'package:canvas_chat/src/state/branching.dart';
import 'package:canvas_chat/src/state/providers.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A deterministic provider that echoes a marker + the prompt, so a test can
/// assert the branch's response came from the seam (and saw the prompt).
class _EchoProvider implements LlmProvider {
  @override
  Stream<String> generate({
    required String prompt,
    required List<Turn> context,
  }) async* {
    yield 'ECHO(${context.length}): ';
    yield prompt;
  }
}

/// A provider whose single delta is withheld until [gate] completes, so a test
/// can observe the in-flight (generating) state before letting it finish.
class _GatedProvider implements LlmProvider {
  _GatedProvider(this.gate);

  final Completer<void> gate;

  @override
  Stream<String> generate({
    required String prompt,
    required List<Turn> context,
  }) async* {
    await gate.future;
    yield 'done';
  }
}

Future<Turn> _insertTurn(
  AppDatabase db, {
  required String id,
  String? parent,
}) async {
  await db.into(db.turns).insert(
        TurnsCompanion.insert(
          id: id,
          conversationId: 'c',
          parentTurnId: Value(parent),
          promptMd: const Value('q'),
          responseMd: const Value('r'),
          rawJson: '[]',
        ),
      );
  return (db.select(db.turns)..where((t) => t.id.equals(id))).getSingle();
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    // turns.conversation_id is a FK; the branch's parent lives in a real
    // conversation, so seed one (foreign_keys is ON via the migration).
    await db
        .into(db.conversations)
        .insert(ConversationsCompanion.insert(id: 'c', source: 'test'));
  });
  tearDown(() => db.close());

  test('branchFrom inserts a child turn and streams the stub response',
      () async {
    final parent = await _insertTurn(db, id: 'c:p');
    final service = BranchService(db, const StubLlmProvider());

    final branch = await service.branchFrom(parent: parent, prompt: 'Explain X');

    // The id is namespaced and the row exists the instant branchFrom returns.
    expect(branch.id, startsWith('c:${BranchService.idPrefix}-'));
    final pending =
        await (db.select(db.turns)..where((t) => t.id.equals(branch.id)))
            .getSingle();
    expect(pending.parentTurnId, 'c:p');
    expect(pending.promptMd, 'Explain X');

    // After streaming completes, the stub response is written.
    await branch.done;
    final filled =
        await (db.select(db.turns)..where((t) => t.id.equals(branch.id)))
            .getSingle();
    expect(filled.responseMd, contains('Offline stub'));
  });

  test('passes the root→parent context path to the provider', () async {
    await _insertTurn(db, id: 'c:root');
    await _insertTurn(db, id: 'c:mid', parent: 'c:root');
    final parent = await _insertTurn(db, id: 'c:leaf', parent: 'c:mid');
    final service = BranchService(db, _EchoProvider());

    final branch = await service.branchFrom(parent: parent, prompt: 'go');
    await branch.done;

    final row =
        await (db.select(db.turns)..where((t) => t.id.equals(branch.id)))
            .getSingle();
    // root, mid, leaf → 3 ancestors.
    expect(row.responseMd, 'ECHO(3): go');
  });

  test('two branches off the same parent get distinct ids', () async {
    final parent = await _insertTurn(db, id: 'c:p');
    final service = BranchService(db, const StubLlmProvider());

    final a = await service.branchFrom(parent: parent, prompt: 'a');
    final b = await service.branchFrom(parent: parent, prompt: 'b');
    await a.done;
    await b.done;

    expect(a.id, isNot(b.id));
    final children = await (db.select(db.turns)
          ..where((t) => t.parentTurnId.equals('c:p')))
        .get();
    expect(children.map((t) => t.id), containsAll([a.id, b.id]));
  });

  test('generatingTurnsProvider holds the turn while its response streams',
      () async {
    final gate = Completer<void>();
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      llmProviderProvider.overrideWithValue(_GatedProvider(gate)),
    ]);
    addTearDown(container.dispose);
    final parent = await _insertTurn(db, id: 'c:p');

    final branch = await container
        .read(branchServiceProvider)
        .branchFrom(parent: parent, prompt: 'go');

    // The new turn is marked generating the moment streaming begins.
    expect(container.read(generatingTurnsProvider), contains(branch.id));

    // Once the stream completes, the id is cleared.
    gate.complete();
    await branch.done;
    expect(container.read(generatingTurnsProvider), isNot(contains(branch.id)));
  });
}
