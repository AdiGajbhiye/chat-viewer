import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/data/llm/embedding_math.dart';
import 'package:canvas_chat/src/data/llm/embedding_provider.dart';
import 'package:canvas_chat/src/data/llm/proposition_extractor.dart';
import 'package:canvas_chat/src/state/indexing.dart';
import 'package:canvas_chat/src/state/soft_edges.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// M8.1 soft-edge precompute. Stub embeddings are hash-based (not semantically
/// meaningful), so every semantic test seeds **hand-crafted** embedding vectors
/// via [encodeEmbedding] and asserts the math/top-k/threshold/canonicalization
/// deterministically; nothing here assumes the stub embedder produces "similar"
/// vectors.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  Future<void> seedConversation(String id, {String projectId = 'default'}) =>
      db.into(db.conversations).insert(
            ConversationsCompanion.insert(
              id: id,
              source: 'test',
              projectId: Value(projectId),
            ),
          );

  Future<void> seedTurn(String id, {required String conversationId}) =>
      db.into(db.turns).insert(
            TurnsCompanion.insert(
              id: id,
              conversationId: conversationId,
              rawJson: '[]',
            ),
          );

  /// Writes one proposition with a controlled embedding [vector] for [turnId].
  Future<void> seedProp(
    String id, {
    required String turnId,
    required String conversationId,
    required List<double> vector,
    String projectId = 'default',
  }) =>
      db.into(db.propositions).insert(
            PropositionsCompanion.insert(
              id: id,
              turnId: turnId,
              conversationId: conversationId,
              projectId: projectId,
              propText: 'p:$id',
              embedding: Value(encodeEmbedding(vector)),
              embeddingModel: const Value('test-model'),
            ),
          );

  /// Links [turnId] to each entity name (creating the entity row on demand).
  Future<void> seedEntities(
    String turnId,
    List<String> names, {
    String projectId = 'default',
  }) async {
    for (final name in names) {
      final entId = 'ent:$projectId:$name';
      await db.into(db.entities).insertOnConflictUpdate(
            EntitiesCompanion.insert(
              id: entId,
              projectId: projectId,
              name: name,
              normalized: name,
            ),
          );
      await db.into(db.turnEntities).insert(
            TurnEntitiesCompanion.insert(entityId: entId, turnId: turnId),
          );
    }
  }

  Future<List<SoftEdge>> edgesOfKind(String kind) =>
      (db.select(db.softEdges)..where((e) => e.kind.equals(kind))).get();

  SoftEdgeComputer computer() => SoftEdgeComputer(db);

  group('semantic edges', () {
    test('edges form on similarity, weight == max cosine, canonical from<to',
        () async {
      await seedConversation('c');
      for (final id in ['t-b', 't-a', 't-c']) {
        await seedTurn(id, conversationId: 'c');
      }
      // t-a and t-b nearly parallel (high cosine); t-c orthogonal to both.
      await seedProp('p1', turnId: 't-a', conversationId: 'c', vector: [1, 0]);
      await seedProp('p2', turnId: 't-b', conversationId: 'c', vector: [1, 0]);
      await seedProp('p3', turnId: 't-c', conversationId: 'c', vector: [0, 1]);

      await computer().recomputeForConversation('c');

      final edges = await edgesOfKind('semantic');
      // Only the t-a/t-b pair clears the 0.5 default threshold; t-c is orthogonal.
      expect(edges, hasLength(1));
      final e = edges.single;
      // Canonicalized: 't-a' < 't-b' (string compare).
      expect(e.fromTurnId, 't-a');
      expect(e.toTurnId, 't-b');
      expect(e.weight, closeTo(1.0, 1e-6));
      expect(e.kind, 'semantic');
      expect(e.projectId, 'default');
      // No self-edges.
      expect(edges.where((x) => x.fromTurnId == x.toTurnId), isEmpty);
    });

    test('max-cosine aggregation: a single shared topic links two turns',
        () async {
      await seedConversation('c');
      for (final id in ['t1', 't2']) {
        await seedTurn(id, conversationId: 'c');
      }
      // t1 covers two topics; t2 covers one that matches t1's second topic.
      // A centroid would dilute this; max-cosine keeps it.
      await seedProp('a1', turnId: 't1', conversationId: 'c', vector: [1, 0]);
      await seedProp('a2', turnId: 't1', conversationId: 'c', vector: [0, 1]);
      await seedProp('b1', turnId: 't2', conversationId: 'c', vector: [0, 1]);

      await computer().recomputeForConversation('c');

      final edges = await edgesOfKind('semantic');
      expect(edges, hasLength(1));
      expect(edges.single.weight, closeTo(1.0, 1e-6));
    });

    test('threshold excludes weakly-similar pairs', () async {
      await seedConversation('c');
      for (final id in ['t1', 't2']) {
        await seedTurn(id, conversationId: 'c');
      }
      // cos(45°) ≈ 0.707 with default 0.5 → kept; raise threshold above it → dropped.
      await seedProp('a', turnId: 't1', conversationId: 'c', vector: [1, 0]);
      await seedProp('b', turnId: 't2', conversationId: 'c', vector: [1, 1]);

      await computer().recomputeForConversation('c', semanticThreshold: 0.8);
      expect(await edgesOfKind('semantic'), isEmpty);

      await computer().recomputeForConversation('c', semanticThreshold: 0.5);
      expect(await edgesOfKind('semantic'), hasLength(1));
    });

    test('top-k truncates a hub turn to its k strongest neighbours', () async {
      await seedConversation('c');
      // A "hub" turn is similar (above threshold) to three "spoke" turns. The
      // spokes are FAR apart from each other (orthogonal-ish), so each spoke's
      // only candidate is the hub. To make top-k actually bite on the hub side
      // we give each spoke a SECOND, even-stronger neighbour (its own partner),
      // so the hub does NOT appear in any spoke's top-1 — leaving the hub's
      // top-k as the sole gate on how many hub edges survive.
      for (final id in ['hub', 's1', 's1p', 's2', 's2p', 's3', 's3p']) {
        await seedTurn(id, conversationId: 'c');
      }
      await seedProp('h', turnId: 'hub', conversationId: 'c', vector: [1, 1, 1]);
      // Each spoke is similar to the hub but PARALLEL to its own partner (cos 1),
      // so the partner — not the hub — is each spoke's top-1.
      await seedProp('a1', turnId: 's1', conversationId: 'c', vector: [1, 0, 0]);
      await seedProp('a2', turnId: 's1p', conversationId: 'c', vector: [1, 0, 0]);
      await seedProp('b1', turnId: 's2', conversationId: 'c', vector: [0, 1, 0]);
      await seedProp('b2', turnId: 's2p', conversationId: 'c', vector: [0, 1, 0]);
      await seedProp('d1', turnId: 's3', conversationId: 'c', vector: [0, 0, 1]);
      await seedProp('d2', turnId: 's3p', conversationId: 'c', vector: [0, 0, 1]);

      // cos(hub, spoke) = 1/sqrt(3) ≈ 0.577 > 0.5; cos(spoke, partner) = 1.
      await computer().recomputeForConversation('c', semanticK: 1);
      final edges = await edgesOfKind('semantic');
      final hubEdges = edges.where(
          (e) => e.fromTurnId == 'hub' || e.toTurnId == 'hub');
      // With k=1 the hub keeps exactly ONE spoke (its top-1); the other spokes
      // each spent their single slot on their parallel partner, not the hub.
      expect(hubEdges, hasLength(1));
      // Each spoke↔partner pair survives (their mutual top-1), 3 of them.
      expect(edges.length, 4);
    });

    test('symmetric pair stored once; no self-edge for a turn vs itself',
        () async {
      await seedConversation('c');
      for (final id in ['x', 'y']) {
        await seedTurn(id, conversationId: 'c');
      }
      await seedProp('x1', turnId: 'x', conversationId: 'c', vector: [1, 0]);
      await seedProp('y1', turnId: 'y', conversationId: 'c', vector: [1, 0]);

      await computer().recomputeForConversation('c');
      final edges = await edgesOfKind('semantic');
      // Exactly one row for the x/y pair, none for x/x or y/y.
      expect(edges, hasLength(1));
      expect(edges.single.fromTurnId, 'x');
      expect(edges.single.toTurnId, 'y');
    });
  });

  group('entity edges', () {
    test('turns sharing an entity get a Jaccard-weighted edge; no self-edge',
        () async {
      await seedConversation('c');
      for (final id in ['t1', 't2', 't3']) {
        await seedTurn(id, conversationId: 'c');
      }
      // t1 ∩ t2 = {Postgres}; union = {Postgres, Redis, MySQL} → 1/3.
      await seedEntities('t1', ['Postgres', 'Redis']);
      await seedEntities('t2', ['Postgres', 'MySQL']);
      // t3 shares nothing.
      await seedEntities('t3', ['Mongo']);

      await computer().recomputeForConversation('c');
      final edges = await edgesOfKind('entity');
      expect(edges, hasLength(1));
      final e = edges.single;
      expect(e.fromTurnId, 't1');
      expect(e.toTurnId, 't2');
      expect(e.weight, closeTo(1 / 3, 1e-6));
      expect(edges.where((x) => x.fromTurnId == x.toTurnId), isEmpty);
    });

    test('identical entity sets score Jaccard 1.0', () async {
      await seedConversation('c');
      for (final id in ['t1', 't2']) {
        await seedTurn(id, conversationId: 'c');
      }
      await seedEntities('t1', ['Postgres']);
      await seedEntities('t2', ['Postgres']);

      await computer().recomputeForConversation('c');
      final edges = await edgesOfKind('entity');
      expect(edges, hasLength(1));
      expect(edges.single.weight, closeTo(1.0, 1e-6));
    });

    test('non-sharing turns produce no entity edge', () async {
      await seedConversation('c');
      for (final id in ['t1', 't2']) {
        await seedTurn(id, conversationId: 'c');
      }
      await seedEntities('t1', ['A']);
      await seedEntities('t2', ['B']);

      await computer().recomputeForConversation('c');
      expect(await edgesOfKind('entity'), isEmpty);
    });
  });

  group('both kinds + canonicalization', () {
    test('a pair that is both semantic and entity stores two distinct rows',
        () async {
      await seedConversation('c');
      for (final id in ['t1', 't2']) {
        await seedTurn(id, conversationId: 'c');
      }
      await seedProp('p1', turnId: 't1', conversationId: 'c', vector: [1, 0]);
      await seedProp('p2', turnId: 't2', conversationId: 'c', vector: [1, 0]);
      await seedEntities('t1', ['Shared']);
      await seedEntities('t2', ['Shared']);

      await computer().recomputeForConversation('c');
      final all = await db.select(db.softEdges).get();
      expect(all, hasLength(2));
      expect(all.map((e) => e.kind).toSet(), {'semantic', 'entity'});
      // Both canonicalized identically.
      for (final e in all) {
        expect(e.fromTurnId, 't1');
        expect(e.toTurnId, 't2');
      }
    });
  });

  group('idempotent recompute', () {
    test('running twice yields the same edge set (no duplicates)', () async {
      await seedConversation('c');
      for (final id in ['t1', 't2']) {
        await seedTurn(id, conversationId: 'c');
      }
      await seedProp('p1', turnId: 't1', conversationId: 'c', vector: [1, 0]);
      await seedProp('p2', turnId: 't2', conversationId: 'c', vector: [1, 0]);
      await seedEntities('t1', ['Shared']);
      await seedEntities('t2', ['Shared']);

      await computer().recomputeForConversation('c');
      final first = await db.select(db.softEdges).get();
      await computer().recomputeForConversation('c');
      final second = await db.select(db.softEdges).get();

      expect(second, hasLength(first.length));
      expect(second.length, 2);
    });

    test('recompute does not touch crossSession rows', () async {
      await seedConversation('c');
      for (final id in ['t1', 't2']) {
        await seedTurn(id, conversationId: 'c');
      }
      await seedProp('p1', turnId: 't1', conversationId: 'c', vector: [1, 0]);
      await seedProp('p2', turnId: 't2', conversationId: 'c', vector: [1, 0]);
      // A pre-existing crossSession edge incident to one of this conv's turns.
      await db.into(db.softEdges).insert(
            SoftEdgesCompanion.insert(
              fromTurnId: 't1',
              toTurnId: 'other:z',
              kind: 'crossSession',
              weight: 0.9,
              projectId: 'default',
            ),
          );

      await computer().recomputeForConversation('c');
      final cross = await edgesOfKind('crossSession');
      expect(cross, hasLength(1));
      expect(cross.single.toTurnId, 'other:z');
    });
  });

  group('integration: chained after indexing', () {
    test('ensureIndexed → recompute populates entity edges (offline)', () async {
      // Two turns mentioning the SAME capitalized entity ("Postgres") so the
      // offline stub extractor links them and an entity edge is guaranteed
      // (entity edges don't depend on embedding semantics). The stub skips a
      // capitalized word that merely *starts* a sentence, so "Postgres" appears
      // mid-sentence in both turns to be picked up as an entity.
      await seedConversation('c');
      await db.into(db.turns).insert(
            TurnsCompanion.insert(
              id: 'c:root',
              conversationId: 'c',
              promptMd: const Value('Tell me about Postgres.'),
              createTime: const Value(1),
              rawJson: '[]',
            ),
          );
      await db.into(db.turns).insert(
            TurnsCompanion.insert(
              id: 'c:a',
              conversationId: 'c',
              parentTurnId: const Value('c:root'),
              responseMd: const Value(
                  'A relational engine like Postgres is widely used.'),
              createTime: const Value(2),
              rawJson: '[]',
            ),
          );

      final indexer = ConversationIndexer(
        db: db,
        extractor: const StubPropositionExtractor(),
        embedder: const StubEmbeddingProvider(),
      );
      await indexer.ensureIndexed('c');
      expect(
        IndexState.fromInt(
            (await (db.select(db.conversations)..where((x) => x.id.equals('c')))
                    .getSingle())
                .indexState),
        IndexState.indexed,
      );

      await SoftEdgeComputer(db).recomputeForConversation('c');

      // Both turns mention "Postgres" → an entity edge exists between them.
      final entity = await edgesOfKind('entity');
      expect(entity, isNotEmpty,
          reason: 'shared "Postgres" entity should link the two turns');
      expect(entity.single.fromTurnId, 'c:a'); // 'c:a' < 'c:root'
      expect(entity.single.toTurnId, 'c:root');
    });
  });
}
