import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/data/llm/embedding_math.dart';
import 'package:canvas_chat/src/data/llm/embedding_provider.dart';
import 'package:canvas_chat/src/data/llm/proposition_extractor.dart';
import 'package:canvas_chat/src/state/indexing.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the order turns are handed to it, so the active-path-first ordering
/// is observable end-to-end (not only via the pure [indexOrder]). Delegates the
/// actual extraction to the deterministic stub.
class _RecordingExtractor implements PropositionExtractor {
  final List<String> seen = [];
  final _delegate = const StubPropositionExtractor();

  @override
  Future<TurnExtraction> extract(
    Turn turn, {
    List<Turn> parentContext = const [],
  }) async {
    seen.add(turn.id);
    return _delegate.extract(turn, parentContext: parentContext);
  }
}

/// A stub embedder with a swappable [modelId] so a model change (staleness) can
/// be simulated. Counts batch calls and records the batch sizes it was asked to
/// embed (to assert per-turn batching).
class _FakeEmbedder implements EmbeddingProvider {
  _FakeEmbedder(this._modelId);
  String _modelId;
  final List<int> batchSizes = [];

  set modelId(String value) => _modelId = value;

  @override
  String get modelId => _modelId;

  @override
  Future<List<List<double>>> embed(List<String> texts) async {
    batchSizes.add(texts.length);
    // A fixed small vector per input — content doesn't matter for these tests,
    // only that one vector comes back per text in order.
    return [for (var i = 0; i < texts.length; i++) List<double>.filled(4, 0.1)];
  }
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  Future<void> seedConversation(
    String id, {
    String? currentTurnId,
  }) async {
    await db.into(db.conversations).insert(
          ConversationsCompanion.insert(
            id: id,
            source: 'test',
            currentTurnId: Value(currentTurnId),
          ),
        );
  }

  Future<void> seedTurn(
    String id, {
    required String conversationId,
    String? parent,
    String prompt = '',
    String response = '',
    int? time,
  }) async {
    await db.into(db.turns).insert(
          TurnsCompanion.insert(
            id: id,
            conversationId: conversationId,
            parentTurnId: Value(parent),
            promptMd: Value(prompt),
            responseMd: Value(response),
            createTime: Value(time),
            rawJson: '[]',
          ),
        );
  }

  Future<Conversation> conv(String id) =>
      (db.select(db.conversations)..where((c) => c.id.equals(id))).getSingle();

  ConversationIndexer indexer({
    PropositionExtractor? extractor,
    EmbeddingProvider? embedder,
    void Function(String, IndexingProgress)? onProgress,
  }) =>
      ConversationIndexer(
        db: db,
        extractor: extractor ?? const StubPropositionExtractor(),
        embedder: embedder ?? _FakeEmbedder('stub-256'),
        onProgress: onProgress,
      );

  group('indexOrder', () {
    Turn t(String id, {String? parent, int? time}) => Turn(
          id: id,
          conversationId: 'c',
          parentTurnId: parent,
          promptMd: 'p',
          responseMd: 'r',
          rawJson: '[]',
          createTime: time,
        );

    test('puts active-path turns first, in path order, then off-path turns', () {
      // root → a (active) ; root → b (off path, forked). current = a-child.
      final turns = [
        t('root', time: 1),
        t('a', parent: 'root', time: 2),
        t('b', parent: 'root', time: 3),
        t('a-child', parent: 'a', time: 4),
      ];
      final order = [for (final x in indexOrder(turns, 'a-child')) x.id];
      // Active path root→a→a-child first; the off-path sibling 'b' last.
      expect(order, ['root', 'a', 'a-child', 'b']);
    });

    test('empty input yields empty order', () {
      expect(indexOrder(const [], null), isEmpty);
    });
  });

  group('happy path', () {
    test('every turn gets propositions + entities; state → indexed', () async {
      await seedConversation('c1', currentTurnId: 'c1:a');
      await seedTurn('c1:root',
          conversationId: 'c1', prompt: 'How do I use Postgres?', time: 1);
      await seedTurn('c1:a',
          conversationId: 'c1',
          parent: 'c1:root',
          response: 'Install Postgres. It is a database.',
          time: 2);

      final embedder = _FakeEmbedder('stub-256');
      await indexer(embedder: embedder).ensureIndexed('c1');

      // Both turns produced propositions.
      for (final turnId in ['c1:root', 'c1:a']) {
        final props = await (db.select(db.propositions)
              ..where((p) => p.turnId.equals(turnId)))
            .get();
        expect(props, isNotEmpty, reason: '$turnId should have propositions');
        // Embeddings persisted with the embedder's model id and decode back.
        for (final p in props) {
          expect(p.embeddingModel, 'stub-256');
          expect(p.embedding, isNotNull);
          expect(decodeEmbedding(p.embedding!), hasLength(4));
        }
      }

      // Entities were written (Postgres is a capitalized token).
      final entities = await db.select(db.entities).get();
      expect(entities, isNotEmpty);

      // State machine landed on indexed with a timestamp.
      final row = await conv('c1');
      expect(IndexState.fromInt(row.indexState), IndexState.indexed);
      expect(row.indexedAt, isNotNull);

      // The embed call was batched per turn (one call per turn that had texts),
      // not one call per proposition.
      expect(embedder.batchSizes.length, lessThanOrEqualTo(2));
    });
  });

  group('active-path-first ordering (end to end)', () {
    test('on-path turns are extracted before off-path turns', () async {
      await seedConversation('c2', currentTurnId: 'c2:a-child');
      await seedTurn('c2:root', conversationId: 'c2', prompt: 'root', time: 1);
      await seedTurn('c2:a',
          conversationId: 'c2', parent: 'c2:root', prompt: 'a', time: 2);
      await seedTurn('c2:b',
          conversationId: 'c2', parent: 'c2:root', prompt: 'b', time: 3);
      await seedTurn('c2:a-child',
          conversationId: 'c2', parent: 'c2:a', prompt: 'a-child', time: 4);

      final recorder = _RecordingExtractor();
      await indexer(extractor: recorder).ensureIndexed('c2');

      // Active path (root→a→a-child) recorded before the off-path sibling 'b'.
      expect(recorder.seen, ['c2:root', 'c2:a', 'c2:a-child', 'c2:b']);
    });
  });

  group('state machine + double-start guard', () {
    test('a second concurrent call does not double-process', () async {
      await seedConversation('c3', currentTurnId: 'c3:a');
      await seedTurn('c3:a',
          conversationId: 'c3', response: 'one. two. three.', time: 1);

      final recorder = _RecordingExtractor();
      final ix = indexer(extractor: recorder);
      // Fire two overlapping jobs for the same conversation.
      await Future.wait([ix.ensureIndexed('c3'), ix.ensureIndexed('c3')]);

      // The turn was extracted exactly once (the in-flight guard rejected the
      // concurrent second job).
      expect(recorder.seen.where((id) => id == 'c3:a').length, 1);
      expect(IndexState.fromInt((await conv('c3')).indexState),
          IndexState.indexed);
    });

    test('zero-turn conversation completes cleanly to indexed', () async {
      await seedConversation('c4');
      await indexer().ensureIndexed('c4');
      final row = await conv('c4');
      expect(IndexState.fromInt(row.indexState), IndexState.indexed);
      expect(row.indexedAt, isNotNull);
    });

    test('an already-indexed conversation is not re-extracted', () async {
      await seedConversation('c5', currentTurnId: 'c5:a');
      await seedTurn('c5:a', conversationId: 'c5', response: 'hello.', time: 1);

      final recorder = _RecordingExtractor();
      await indexer(extractor: recorder).ensureIndexed('c5'); // indexes
      final firstCount = recorder.seen.length;
      await indexer(extractor: recorder).ensureIndexed('c5'); // no-op
      expect(recorder.seen.length, firstCount);
    });
  });

  group('staleness (embedding model change)', () {
    test('indexed conversation with a different stored model is re-indexed',
        () async {
      await seedConversation('c6', currentTurnId: 'c6:a');
      await seedTurn('c6:a',
          conversationId: 'c6', response: 'Postgres is a database.', time: 1);

      // Index with model A.
      await indexer(embedder: _FakeEmbedder('model-A')).ensureIndexed('c6');
      var props = await db.select(db.propositions).get();
      expect(props, isNotEmpty);
      expect(props.every((p) => p.embeddingModel == 'model-A'), isTrue);

      // The embedding model changes to B → the conversation is stale and gets
      // re-indexed, restamping every proposition with the new model.
      final newModel = _FakeEmbedder('model-B');
      final ix = indexer(embedder: newModel);
      expect(await ix.markStaleIfModelChanged('c6'), isTrue);
      expect(IndexState.fromInt((await conv('c6')).indexState),
          IndexState.stale);
      await ix.ensureIndexed('c6');

      props = await db.select(db.propositions).get();
      expect(props, isNotEmpty);
      expect(props.every((p) => p.embeddingModel == 'model-B'), isTrue,
          reason: 're-index should restamp with the current model');
      expect(IndexState.fromInt((await conv('c6')).indexState),
          IndexState.indexed);
    });

    test('same model is not stale', () async {
      await seedConversation('c7', currentTurnId: 'c7:a');
      await seedTurn('c7:a', conversationId: 'c7', response: 'hello.', time: 1);
      await indexer(embedder: _FakeEmbedder('m1')).ensureIndexed('c7');
      final ix = indexer(embedder: _FakeEmbedder('m1'));
      expect(await ix.markStaleIfModelChanged('c7'), isFalse);
    });
  });

  group('progress', () {
    test('onProgress reports indexing then indexed, with done→total', () async {
      await seedConversation('c8', currentTurnId: 'c8:a');
      await seedTurn('c8:root', conversationId: 'c8', prompt: 'q', time: 1);
      await seedTurn('c8:a',
          conversationId: 'c8', parent: 'c8:root', response: 'a.', time: 2);

      final updates = <IndexingProgress>[];
      await indexer(onProgress: (id, p) {
        expect(id, 'c8');
        updates.add(p);
      }).ensureIndexed('c8');

      // First update announces indexing with the full total.
      expect(updates.first.state, IndexState.indexing);
      expect(updates.first.total, 2);
      expect(updates.first.done, 0);
      // Last update is indexed with done == total.
      expect(updates.last.state, IndexState.indexed);
      expect(updates.last.done, 2);
      expect(updates.last.total, 2);
      // done advances monotonically.
      final doneSeq = updates.map((u) => u.done).toList();
      for (var i = 1; i < doneSeq.length; i++) {
        expect(doneSeq[i], greaterThanOrEqualTo(doneSeq[i - 1]));
      }
    });
  });
}
