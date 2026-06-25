import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/data/llm/embedding_math.dart';
import 'package:canvas_chat/src/data/llm/embedding_provider.dart';
import 'package:canvas_chat/src/data/llm/query_rewriter.dart';
import 'package:canvas_chat/src/state/facts.dart';
import 'package:canvas_chat/src/state/retrieval.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// An embedder returning a controlled vector for every text, so a committed
/// fact's embedding matches the retrieval query exactly (stub vectors aren't
/// semantic) — the retrieval-integration test can then assert the fact surfaces.
class _ControlledEmbedder implements EmbeddingProvider {
  _ControlledEmbedder(this.vector);
  final List<double> vector;
  @override
  String get modelId => 'controlled-4';
  @override
  Future<List<List<double>>> embed(List<String> texts) async =>
      [for (final _ in texts) vector];
}

/// Rewriter that returns the prompt unchanged, so retrieval is driven purely by
/// the controlled embeddings.
class _PassthroughRewriter implements QueryRewriter {
  const _PassthroughRewriter();
  @override
  Future<List<String>> rewrite(String prompt,
          {List<Turn> recentTurns = const []}) async =>
      [prompt];
}

Future<Turn> _insertTurn(
  AppDatabase db, {
  required String id,
  String conversation = 'c',
  String? parent,
  int? createTime,
}) async {
  await db.into(db.turns).insert(
        TurnsCompanion.insert(
          id: id,
          conversationId: conversation,
          parentTurnId: Value(parent),
          promptMd: const Value('q'),
          responseMd: const Value('r'),
          createTime: Value(createTime),
          rawJson: '[]',
        ),
      );
  return (db.select(db.turns)..where((t) => t.id.equals(id))).getSingle();
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    // turns/facts.conversation_id reference a real conversation (foreign_keys
    // is ON via the migration), so seed one in the default project.
    await db.into(db.conversations).insert(
          ConversationsCompanion.insert(id: 'c', source: 'test'),
        );
  });
  tearDown(() => db.close());

  FactsService service([EmbeddingProvider? embedder]) => FactsService(
        db: db,
        embedder: embedder ?? const StubEmbeddingProvider(),
      );

  test('commitFact inserts an active, embedded fact with provenance', () async {
    final turn = await _insertTurn(db, id: 'c:t1');

    final fact = await service().commitFact(
      text: 'We use SQLite, not Postgres.',
      sourceTurnIds: [turn.id],
      projectId: 'default',
      conversationId: 'c',
    );

    expect(fact.id, startsWith('${FactsService.idPrefix}-'));
    expect(fact.status, 'active');
    expect(fact.factText, 'We use SQLite, not Postgres.');
    expect(fact.projectId, 'default');
    // conversationId is set (session-pinned) when the caller passes it.
    expect(fact.conversationId, 'c');
    expect(fact.supersedesId, isNull);
    expect(fact.createdAt, isNotNull);

    // The embedding decodes back to what the embedder produced (within float32
    // precision — the BLOB is float32 little-endian).
    final expected =
        (await const StubEmbeddingProvider().embed(['We use SQLite, not Postgres.']))
            .single;
    final decoded = decodeEmbedding(fact.embedding!);
    expect(decoded, hasLength(expected.length));
    for (var i = 0; i < expected.length; i++) {
      expect(decoded[i], moreOrLessEquals(expected[i], epsilon: 1e-6));
    }

    // A provenance row links the fact back to its source turn.
    expect(await service().factSources(fact.id), ['c:t1']);
  });

  test('commitFact allows a project-wide (null conversation) fact', () async {
    final turn = await _insertTurn(db, id: 'c:t1');

    final fact = await service().commitFact(
      text: 'Project-wide decision.',
      sourceTurnIds: [turn.id],
      projectId: 'default',
    );

    expect(fact.conversationId, isNull);
    // Project-wide facts surface for any conversation in the project.
    final visible = await service().activeFactsForConversation('c');
    expect(visible.map((f) => f.id), contains(fact.id));
  });

  test('commitFact records a provenance row per source turn', () async {
    await _insertTurn(db, id: 'c:a');
    await _insertTurn(db, id: 'c:b');

    final fact = await service().commitFact(
      text: 'Backed by two turns.',
      sourceTurnIds: ['c:a', 'c:b'],
      projectId: 'default',
      conversationId: 'c',
    );

    expect(await service().factSources(fact.id), containsAll(['c:a', 'c:b']));
  });

  test('supersession flips the prior fact and chains the new one', () async {
    final turn = await _insertTurn(db, id: 'c:t1');

    final original = await service().commitFact(
      text: 'We use Postgres.',
      sourceTurnIds: [turn.id],
      projectId: 'default',
      conversationId: 'c',
    );
    final replacement = await service().commitFact(
      text: 'We switched to SQLite.',
      sourceTurnIds: [turn.id],
      projectId: 'default',
      conversationId: 'c',
      supersedesId: original.id,
    );

    // The prior fact is now superseded; the new one chains back to it.
    final prior =
        await (db.select(db.facts)..where((f) => f.id.equals(original.id)))
            .getSingle();
    expect(prior.status, 'superseded');
    expect(replacement.status, 'active');
    expect(replacement.supersedesId, original.id);

    // The active-facts helpers exclude the superseded fact.
    final byProject = await service().activeFactsForProject('default');
    expect(byProject.map((f) => f.id), [replacement.id]);
    final byConversation = await service().activeFactsForConversation('c');
    expect(byConversation.map((f) => f.id), [replacement.id]);
  });

  test('activeFactsForConversation includes session-pinned + project-wide only',
      () async {
    // Another conversation in the same project, plus one in a different project.
    await db.into(db.projects).insert(
          ProjectsCompanion.insert(id: 'other', name: const Value('Other')),
        );
    await db.into(db.conversations).insert(
          ConversationsCompanion.insert(
            id: 'c2',
            source: 'test',
            projectId: const Value('other'),
          ),
        );
    await _insertTurn(db, id: 'c:t1');
    await _insertTurn(db, id: 'c2:t1', conversation: 'c2');

    final svc = service();
    final pinned = await svc.commitFact(
      text: 'Pinned to c.',
      sourceTurnIds: ['c:t1'],
      projectId: 'default',
      conversationId: 'c',
    );
    final wide = await svc.commitFact(
      text: 'Project-wide in default.',
      sourceTurnIds: ['c:t1'],
      projectId: 'default',
    );
    // Pinned to a different conversation / a different project — must NOT show.
    final otherPinned = await svc.commitFact(
      text: 'Pinned to c2.',
      sourceTurnIds: ['c2:t1'],
      projectId: 'other',
      conversationId: 'c2',
    );

    final visible = await svc.activeFactsForConversation('c');
    final ids = visible.map((f) => f.id).toSet();
    expect(ids, containsAll([pinned.id, wide.id]));
    expect(ids, isNot(contains(otherPinned.id)));
  });

  test('a committed active fact is picked up by retrieval; superseded is not',
      () async {
    // The query and the fact share the controlled embedding, so the fact's
    // cosine is maximal and it lands in the assembled context (tagged committed).
    final query = [1.0, 0.0, 0.0, 0.0];
    // c:t1 (the fact's source) sits two turns up from the parent, so it is
    // OUTSIDE the verbatim tail (mid, leaf) and must earn its place by
    // retrieval — proving the committed boost, not the ancestry pass.
    final turn = await _insertTurn(db, id: 'c:t1', createTime: 1);
    await _insertTurn(db, id: 'c:mid', parent: 'c:t1', createTime: 2);
    final parent = await _insertTurn(db, id: 'c:leaf', parent: 'c:mid', createTime: 3);

    final fact = await service(_ControlledEmbedder(query)).commitFact(
      text: 'Committed: SQLite is the database.',
      sourceTurnIds: [turn.id],
      projectId: 'default',
      conversationId: 'c',
    );

    final assembler = ContextAssembler(
      db: db,
      embedder: _ControlledEmbedder(query),
      rewriter: const _PassthroughRewriter(),
    );
    final conversation =
        await (db.select(db.conversations)..where((c) => c.id.equals('c')))
            .getSingle();

    final active = await assembler.assemble(
      conversation: conversation,
      parent: parent,
      prompt: 'which database',
    );
    // The fact's source turn rides in as a retrieved, committed item carrying
    // the fact text.
    final committed = active.retrieved.where((i) => i.committed).toList();
    expect(committed.map((i) => i.turn.id), contains('c:t1'));
    expect(active.preamble, contains('committed'));
    expect(active.preamble, contains('SQLite is the database'));

    // Supersede the fact, re-assemble: it must no longer surface (retrieval only
    // boosts status='active').
    await service(_ControlledEmbedder(query)).commitFact(
      text: 'Committed: actually DuckDB now.',
      sourceTurnIds: [turn.id],
      projectId: 'default',
      conversationId: 'c',
      supersedesId: fact.id,
    );
    final after = await assembler.assemble(
      conversation: conversation,
      parent: parent,
      prompt: 'which database',
    );
    expect(after.preamble, isNot(contains('SQLite is the database')));
    // The replacement fact (still active) is what surfaces now.
    expect(after.preamble, contains('DuckDB'));
  });
}
