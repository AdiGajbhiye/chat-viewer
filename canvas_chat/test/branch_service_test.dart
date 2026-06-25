import 'dart:async';

import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/data/llm/embedding_math.dart';
import 'package:canvas_chat/src/data/llm/embedding_provider.dart';
import 'package:canvas_chat/src/data/llm/llm_provider.dart';
import 'package:canvas_chat/src/state/branching.dart';
import 'package:canvas_chat/src/state/providers.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A deterministic provider that echoes a marker + the prompt, so a test can
/// assert the branch's response came from the seam (and saw the prompt).
class _EchoProvider implements LlmProvider {
  @override
  Stream<String> generate({
    required String prompt,
    required List<Turn> context,
    String? preamble,
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
    String? preamble,
  }) async* {
    await gate.future;
    yield 'done';
  }
}

/// Yields the given deltas in order — a multi-chunk stream, so a test can
/// assert the response is the *accumulation* of every delta and catch a
/// write-batching change that dropped or reordered chunks.
class _ChunkedProvider implements LlmProvider {
  _ChunkedProvider(this.deltas);

  final List<String> deltas;

  @override
  Stream<String> generate({
    required String prompt,
    required List<Turn> context,
    String? preamble,
  }) async* {
    for (final delta in deltas) {
      yield delta;
    }
  }
}

/// Yields one delta, then throws — exercising the failure seam in
/// [BranchService] (the partial response is replaced with an error and the
/// in-flight flag is cleared in `finally`).
class _ThrowingProvider implements LlmProvider {
  @override
  Stream<String> generate({
    required String prompt,
    required List<Turn> context,
    String? preamble,
  }) async* {
    yield 'half';
    throw Exception('boom');
  }
}

/// Captures the `context` + `preamble` the seam passed, so a test can assert
/// the swap to retrieval-assembled context (DESIGN.md §10) — not the full
/// ancestry.
class _CapturingProvider implements LlmProvider {
  List<Turn>? capturedContext;
  String? capturedPreamble;

  @override
  Stream<String> generate({
    required String prompt,
    required List<Turn> context,
    String? preamble,
  }) async* {
    capturedContext = context;
    capturedPreamble = preamble;
    yield 'ok';
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
  late SharedPreferences prefs;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    // turns.conversation_id is a FK; the branch's parent lives in a real
    // conversation, so seed one (foreign_keys is ON via the migration).
    await db
        .into(db.conversations)
        .insert(ConversationsCompanion.insert(id: 'c', source: 'test'));
    // The provider-backed BranchService now resolves contextAssemblerProvider
    // (DESIGN.md §10 retrieval), which reads the LLM/embedding config from
    // SharedPreferences — so the container tests must override it. With no
    // stored key the configs stay unconfigured → offline stub rewriter /
    // embedder, keeping these tests deterministic and offline.
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
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
      sharedPreferencesProvider.overrideWithValue(prefs),
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

  test('accumulates every streamed delta into the response', () async {
    // Guards a future write-batching/debounce optimization: however the deltas
    // are flushed, the persisted response is their full in-order concatenation.
    final parent = await _insertTurn(db, id: 'c:p');
    final service = BranchService(db, _ChunkedProvider(['Hel', 'lo, ', 'world']));

    final branch = await service.branchFrom(parent: parent, prompt: 'hi');
    await branch.done;

    final row =
        await (db.select(db.turns)..where((t) => t.id.equals(branch.id)))
            .getSingle();
    expect(row.responseMd, 'Hello, world');
  });

  test('a provider failure is written into the turn and clears generating',
      () async {
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      llmProviderProvider.overrideWithValue(_ThrowingProvider()),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(container.dispose);
    final parent = await _insertTurn(db, id: 'c:p');

    final branch = await container
        .read(branchServiceProvider)
        .branchFrom(parent: parent, prompt: 'go');
    await branch.done;

    final row =
        await (db.select(db.turns)..where((t) => t.id.equals(branch.id)))
            .getSingle();
    // The half-streamed text is replaced by the error, not left as a partial
    // answer masquerading as a complete one.
    expect(row.responseMd, contains('Generation failed'));
    expect(row.responseMd, isNot(contains('half')));
    // `finally` must clear the marker even on error, or the reader shows
    // "Generating…" forever.
    expect(container.read(generatingTurnsProvider), isNot(contains(branch.id)));
  });

  test(
      'sends retrieval-assembled context (not the full ancestry), offline & '
      'deterministic', () async {
    // A 3-deep linear chain. Under the OLD behavior all 3 ancestors would be
    // sent as context; under retrieval only the last 1–2 turns are kept
    // verbatim and the rest earns its place via retrieval (DESIGN.md §10).
    await _insertTurn(db, id: 'c:root', parent: null);
    await _insertTurn(db, id: 'c:mid', parent: 'c:root');
    final parent = await _insertTurn(db, id: 'c:leaf', parent: 'c:mid');

    // Index `c:root` with a proposition embedded (offline stub embedder) on the
    // exact text we'll prompt with, so retrieval surfaces it deterministically
    // even though it's outside the verbatim tail.
    const embedder = StubEmbeddingProvider();
    const probe = 'quantum entanglement nonlocal correlation';
    final vector = (await embedder.embed([probe])).single;
    await db.into(db.propositions).insert(
          PropositionsCompanion.insert(
            id: 'c:root#0',
            turnId: 'c:root',
            conversationId: 'c',
            projectId: 'default',
            propText: probe,
            embedding: Value(encodeEmbedding(vector)),
            embeddingModel: Value(embedder.modelId),
          ),
        );

    final captor = _CapturingProvider();
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      llmProviderProvider.overrideWithValue(captor),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(container.dispose);

    final branch = await container
        .read(branchServiceProvider)
        .branchFrom(parent: parent, prompt: probe);
    await branch.done;

    final ctxIds = captor.capturedContext!.map((t) => t.id).toList();
    // The verbatim context is the last 1–2 turns (mid, leaf) — NOT the full
    // root→mid→leaf ancestry the v1 behavior sent.
    expect(ctxIds, ['c:mid', 'c:leaf']);
    expect(ctxIds, isNot(contains('c:root')));
    // `c:root` earns its place by retrieval: it rides in the tagged preamble.
    expect(captor.capturedPreamble, isNotNull);
    expect(captor.capturedPreamble, contains('branch:c'));
  });
}
