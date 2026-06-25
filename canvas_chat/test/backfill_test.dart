import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/data/llm/embedding_provider.dart';
import 'package:canvas_chat/src/data/llm/proposition_extractor.dart';
import 'package:canvas_chat/src/state/backfill.dart';
import 'package:canvas_chat/src/state/indexing.dart';
import 'package:canvas_chat/src/state/soft_edges.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records which conversations' turns the extractor was asked to process, so the
/// backfill's "one at a time, indexes each, doesn't double-index" behaviour is
/// observable. Delegates the actual extraction to the deterministic stub.
class _RecordingExtractor implements PropositionExtractor {
  final List<String> seenTurns = [];
  final _delegate = const StubPropositionExtractor();

  @override
  Future<TurnExtraction> extract(
    Turn turn, {
    List<Turn> parentContext = const [],
  }) async {
    seenTurns.add(turn.id);
    return _delegate.extract(turn, parentContext: parentContext);
  }
}

void main() {
  late AppDatabase db;
  late _RecordingExtractor extractor;
  late ConversationIndexer indexer;
  late SoftEdgeComputer softEdges;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    extractor = _RecordingExtractor();
    indexer = ConversationIndexer(
      db: db,
      extractor: extractor,
      embedder: const StubEmbeddingProvider(),
    );
    softEdges = SoftEdgeComputer(db);
  });
  tearDown(() => db.close());

  Future<void> seedConversation(
    String id, {
    int? lastMessageAt,
    int indexState = 0,
  }) async {
    await db.into(db.conversations).insert(
          ConversationsCompanion.insert(
            id: id,
            source: 'test',
            lastMessageAt: Value(lastMessageAt),
            indexState: Value(indexState),
          ),
        );
  }

  Future<void> seedTurn(
    String id, {
    required String conversationId,
    String? parent,
    String response = 'Postgres is a database.',
    int? time,
  }) async {
    await db.into(db.turns).insert(
          TurnsCompanion.insert(
            id: id,
            conversationId: conversationId,
            parentTurnId: Value(parent),
            responseMd: Value(response),
            createTime: Value(time),
            rawJson: '[]',
          ),
        );
  }

  Future<IndexState> stateOf(String id) async => IndexState.fromInt(
        (await (db.select(db.conversations)..where((c) => c.id.equals(id)))
                .getSingle())
            .indexState,
      );

  IndexBackfiller backfiller({bool Function()? isPaused}) => IndexBackfiller(
        db: db,
        indexer: indexer,
        softEdges: softEdges,
        isPaused: isPaused ?? () => false,
        // No real delay needed under the stub embedder; keep the test fast.
        pacing: Duration.zero,
      );

  test('indexes every not-yet-indexed conversation in one pass', () async {
    await seedConversation('a', lastMessageAt: 1);
    await seedTurn('a:t', conversationId: 'a', time: 1);
    await seedConversation('b', lastMessageAt: 2);
    await seedTurn('b:t', conversationId: 'b', time: 2);
    await seedConversation('c', lastMessageAt: 3);
    await seedTurn('c:t', conversationId: 'c', time: 3);

    final indexed = await backfiller().runOnce();

    expect(indexed, 3);
    expect(await stateOf('a'), IndexState.indexed);
    expect(await stateOf('b'), IndexState.indexed);
    expect(await stateOf('c'), IndexState.indexed);
    // Each conversation's single turn was extracted exactly once.
    expect(extractor.seenTurns..sort(), ['a:t', 'b:t', 'c:t']);
  });

  test('is a no-op when everything is already indexed', () async {
    await seedConversation('a', lastMessageAt: 1, indexState: 2); // indexed
    await seedTurn('a:t', conversationId: 'a', time: 1);

    final indexed = await backfiller().runOnce();

    expect(indexed, 0);
    expect(extractor.seenTurns, isEmpty);
  });

  test('a re-entrant runOnce does not start a second overlapping pass',
      () async {
    await seedConversation('a', lastMessageAt: 1);
    await seedTurn('a:t', conversationId: 'a', time: 1);
    await seedConversation('b', lastMessageAt: 2);
    await seedTurn('b:t', conversationId: 'b', time: 2);

    final bf = backfiller();
    final first = bf.runOnce();
    // A concurrent trigger while the first pass is live is rejected (returns 0).
    final second = await bf.runOnce();
    final firstCount = await first;

    expect(second, 0);
    expect(firstCount, 2);
    // No turn was double-extracted by the overlapping call.
    expect(extractor.seenTurns.where((id) => id == 'a:t').length, 1);
    expect(extractor.seenTurns.where((id) => id == 'b:t').length, 1);
  });

  test('respects pause: a paused backfill makes no progress', () async {
    await seedConversation('a', lastMessageAt: 1);
    await seedTurn('a:t', conversationId: 'a', time: 1);

    final indexed = await backfiller(isPaused: () => true).runOnce();

    expect(indexed, 0);
    expect(extractor.seenTurns, isEmpty);
    expect(await stateOf('a'), IndexState.notIndexed);
  });

  test('does not index a conversation a foreground index is processing',
      () async {
    await seedConversation('a', lastMessageAt: 1);
    await seedTurn('a:t', conversationId: 'a', time: 1);

    // Simulate a foreground open-session index in flight by starting (but not
    // awaiting) ensureIndexed; the backfill must yield it.
    final foreground = indexer.ensureIndexed('a');
    expect(ConversationIndexer.isIndexing('a'), isTrue);

    // With 'a' claimed by the foreground job and nothing else pending, the
    // backfill carries zero new conversations (it skips 'a' and finds no other
    // work, so it stops rather than spinning).
    final indexed = await backfiller().runOnce();
    expect(indexed, 0);

    await foreground; // let the foreground index complete
    expect(await stateOf('a'), IndexState.indexed);
  });

  test('precomputes soft edges as it indexes', () async {
    // Two turns sharing the capitalized entity "Postgres" (mid-sentence, so the
    // extractor doesn't drop it as a leading sentence-case capital) → an entity
    // soft edge is written for the conversation as the backfill indexes it.
    await seedConversation('a', lastMessageAt: 1);
    await seedTurn('a:root', conversationId: 'a', response: 'Using Postgres daily.',
        time: 1);
    await seedTurn('a:child', conversationId: 'a', parent: 'a:root',
        response: 'Loving Postgres lately.', time: 2);

    await backfiller().runOnce();

    final edges = await db.select(db.softEdges).get();
    expect(edges, isNotEmpty,
        reason: 'backfill should chain the soft-edge precompute');
    // No crossSession edges are produced (deferred to future work).
    expect(edges.where((e) => e.kind == 'crossSession'), isEmpty);
  });

  test('cancel halts the pass at the next conversation boundary', () async {
    await seedConversation('a', lastMessageAt: 1);
    await seedTurn('a:t', conversationId: 'a', time: 1);
    await seedConversation('b', lastMessageAt: 2);
    await seedTurn('b:t', conversationId: 'b', time: 2);

    // Cancel after the first conversation: the loop re-checks at the next
    // boundary and stops, so only 'a' (oldest-activity first) is indexed.
    late final IndexBackfiller bf;
    bf = IndexBackfiller(
      db: db,
      indexer: indexer,
      softEdges: softEdges,
      isPaused: () {
        if (extractor.seenTurns.isNotEmpty) bf.cancel();
        return false;
      },
      pacing: Duration.zero,
    );
    final indexed = await bf.runOnce();

    expect(indexed, 1);
    expect(await stateOf('a'), IndexState.indexed);
    expect(await stateOf('b'), IndexState.notIndexed);
  });
}
