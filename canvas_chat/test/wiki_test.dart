import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/data/llm/embedding_provider.dart';
import 'package:canvas_chat/src/state/facts.dart';
import 'package:canvas_chat/src/state/wiki.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// M9.2 — the generated, read-only project wiki data layer. Covers the
/// deterministic topic clustering (connected components over `soft_edges`,
/// crossing branches), entity mention counts, entity backlinks, and that the
/// facts list excludes superseded facts (reuses M9.1 active-only).
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.into(db.conversations).insert(
          ConversationsCompanion.insert(id: 'c', source: 'test'),
        );
  });
  tearDown(() => db.close());

  WikiService service() => WikiService(
        db: db,
        facts: FactsService(db: db, embedder: const StubEmbeddingProvider()),
      );

  Future<void> seedTurn(
    String id, {
    String conversation = 'c',
    String? parent,
  }) =>
      db.into(db.turns).insert(
            TurnsCompanion.insert(
              id: id,
              conversationId: conversation,
              parentTurnId: Value(parent),
              rawJson: '[]',
            ),
          );

  Future<void> seedEntity(
    String id, {
    required String name,
    String project = 'default',
  }) =>
      db.into(db.entities).insert(
            EntitiesCompanion.insert(
              id: id,
              projectId: project,
              name: name,
              normalized: name.toLowerCase(),
            ),
          );

  Future<void> link(String entityId, String turnId) =>
      db.into(db.turnEntities).insert(
            TurnEntitiesCompanion.insert(entityId: entityId, turnId: turnId),
          );

  Future<void> seedProposition(
    String id, {
    required String turnId,
    required String text,
    String conversation = 'c',
    String project = 'default',
  }) =>
      db.into(db.propositions).insert(
            PropositionsCompanion.insert(
              id: id,
              turnId: turnId,
              conversationId: conversation,
              projectId: project,
              propText: text,
            ),
          );

  Future<void> seedEdge(
    String from,
    String to, {
    String kind = 'semantic',
    double weight = 0.7,
    String project = 'default',
  }) =>
      db.into(db.softEdges).insert(
            SoftEdgesCompanion.insert(
              fromTurnId: from,
              toTurnId: to,
              kind: kind,
              weight: weight,
              projectId: project,
            ),
          );

  group('topic clustering (connected components over soft_edges)', () {
    test('groups edge-connected turns into one topic, isolates another',
        () async {
      for (final id in ['t1', 't2', 't3', 't4', 't5']) {
        await seedTurn(id);
      }
      // Component A: t1-t2-t3 (a chain). Component B: t4-t5.
      await seedEdge('t1', 't2');
      await seedEdge('t2', 't3', kind: 'entity', weight: 0.5);
      await seedEdge('t4', 't5');

      final topics = await service().topicsForProject('default');
      expect(topics, hasLength(2));
      // Larger component first (stable order: size desc, then least turn id).
      expect(topics[0].turnIds, ['t1', 't2', 't3']);
      expect(topics[1].turnIds, ['t4', 't5']);
    });

    test('a cross-branch (different-parent) edge still merges turns', () async {
      // Two sibling branches off the same parent — structurally divergent — but
      // an entity edge links them, which is exactly what clustering must catch.
      await seedTurn('root');
      await seedTurn('branchA', parent: 'root');
      await seedTurn('branchB', parent: 'root');
      await seedEdge('branchA', 'branchB', kind: 'entity', weight: 0.6);

      final topics = await service().topicsForProject('default');
      expect(topics, hasLength(1));
      expect(topics.single.turnIds, ['branchA', 'branchB']);
    });

    test('singletons / edge-less turns are not surfaced as topics', () async {
      await seedTurn('lonely');
      await seedTurn('a');
      await seedTurn('b');
      await seedEdge('a', 'b');

      final topics = await service().topicsForProject('default');
      expect(topics, hasLength(1));
      expect(topics.single.turnIds, ['a', 'b']);
    });

    test('clustering is deterministic regardless of edge insertion order',
        () async {
      for (final id in ['x', 'y', 'z']) {
        await seedTurn(id);
      }
      // Insert edges in a deliberately scrambled order.
      await seedEdge('z', 'y');
      await seedEdge('y', 'x', kind: 'entity', weight: 0.3);
      final first = await service().topicsForProject('default');

      // Wipe and reinsert in the opposite order.
      await db.delete(db.softEdges).go();
      await seedEdge('y', 'x', kind: 'entity', weight: 0.3);
      await seedEdge('z', 'y');
      final second = await service().topicsForProject('default');

      expect(first.map((t) => t.turnIds), second.map((t) => t.turnIds));
      expect(first.single.turnIds, ['x', 'y', 'z']);
    });

    test('a topic carries the entities and active facts on its turns',
        () async {
      await seedTurn('t1');
      await seedTurn('t2');
      await seedEdge('t1', 't2');
      await seedEntity('e1', name: 'SQLite');
      await link('e1', 't1');

      final committed = await FactsService(
        db: db,
        embedder: const StubEmbeddingProvider(),
      ).commitFact(
        text: 'We use SQLite.',
        sourceTurnIds: ['t2'],
        projectId: 'default',
        conversationId: 'c',
      );

      final topics = await service().topicsForProject('default');
      expect(topics, hasLength(1));
      final topic = topics.single;
      expect(topic.entities.map((e) => e.name), ['SQLite']);
      expect(topic.facts.map((f) => f.id), [committed.id]);
    });

    test('no edges → no topics', () async {
      await seedTurn('t1');
      expect(await service().topicsForProject('default'), isEmpty);
    });

    test('crossSession edges still cluster (topics span sessions)', () async {
      await db.into(db.conversations).insert(
            ConversationsCompanion.insert(id: 'c2', source: 'test'),
          );
      await seedTurn('c:t1');
      await seedTurn('c2:t1', conversation: 'c2');
      await seedEdge('c2:t1', 'c:t1', kind: 'crossSession', weight: 0.9);

      final topics = await service().topicsForProject('default');
      expect(topics, hasLength(1));
      expect(topics.single.turnIds, ['c2:t1', 'c:t1']);
    });
  });

  group('entity index + mention counts', () {
    test('mention counts reflect turn_entities, ordered most-mentioned first',
        () async {
      for (final id in ['t1', 't2', 't3']) {
        await seedTurn(id);
      }
      await seedEntity('e_a', name: 'Alpha');
      await seedEntity('e_b', name: 'Beta');
      // Alpha mentioned in 3 turns, Beta in 1.
      await link('e_a', 't1');
      await link('e_a', 't2');
      await link('e_a', 't3');
      await link('e_b', 't1');

      final entities = await service().entitiesForProject('default');
      expect(entities.map((e) => e.name), ['Alpha', 'Beta']);
      expect(entities.map((e) => e.mentionCount), [3, 1]);
    });

    test('an unmentioned entity has a zero count and sorts by name', () async {
      await seedEntity('e_z', name: 'Zeta');
      await seedEntity('e_a', name: 'Apple');
      final entities = await service().entitiesForProject('default');
      // Tie on count (0,0) → normalized name order.
      expect(entities.map((e) => e.name), ['Apple', 'Zeta']);
      expect(entities.every((e) => e.mentionCount == 0), isTrue);
    });

    test('entities are project-scoped', () async {
      await db.into(db.projects).insert(
            ProjectsCompanion.insert(id: 'other', name: const Value('Other')),
          );
      await seedEntity('e1', name: 'Here');
      await seedEntity('e2', name: 'There', project: 'other');
      final entities = await service().entitiesForProject('default');
      expect(entities.map((e) => e.name), ['Here']);
    });
  });

  group('entity backlinks (entity page)', () {
    test('returns the facts + propositions + turns mentioning the entity',
        () async {
      await seedTurn('t1');
      await seedTurn('t2');
      await seedTurn('t3'); // does NOT mention the entity
      await seedEntity('e1', name: 'Postgres');
      await link('e1', 't1');
      await link('e1', 't2');
      await seedProposition('p1', turnId: 't1', text: 'Postgres is fast.');
      await seedProposition('p2', turnId: 't2', text: 'Postgres has JSONB.');
      await seedProposition('p3', turnId: 't3', text: 'Unrelated.');

      final factsSvc =
          FactsService(db: db, embedder: const StubEmbeddingProvider());
      // A fact sourced from t1 (mentions the entity) and one from t3 (does not).
      final relevant = await factsSvc.commitFact(
        text: 'We picked Postgres.',
        sourceTurnIds: ['t1'],
        projectId: 'default',
        conversationId: 'c',
      );
      await factsSvc.commitFact(
        text: 'Irrelevant decision.',
        sourceTurnIds: ['t3'],
        projectId: 'default',
        conversationId: 'c',
      );

      final page = await service().entityPage('e1');
      expect(page, isNotNull);
      expect(page!.entity.name, 'Postgres');
      expect(page.mentionTurnIds.toSet(), {'t1', 't2'});
      // Propositions only from the mentioning turns, ordered by turn then id.
      expect(page.propositions.map((p) => p.id), ['p1', 'p2']);
      // Only the fact whose provenance includes a mentioning turn.
      expect(page.facts.map((b) => b.fact.id), [relevant.id]);
      expect(page.facts.single.sourceTurnIds, ['t1']);
    });

    test('a missing entity yields null', () async {
      expect(await service().entityPage('nope'), isNull);
    });
  });

  group('facts list (active-only, reuses M9.1)', () {
    test('the overview facts exclude superseded facts', () async {
      await seedTurn('t1');
      final factsSvc =
          FactsService(db: db, embedder: const StubEmbeddingProvider());
      final original = await factsSvc.commitFact(
        text: 'Old decision.',
        sourceTurnIds: ['t1'],
        projectId: 'default',
        conversationId: 'c',
      );
      final replacement = await factsSvc.commitFact(
        text: 'New decision.',
        sourceTurnIds: ['t1'],
        projectId: 'default',
        conversationId: 'c',
        supersedesId: original.id,
      );

      final overview = await service().overview('default');
      expect(overview.facts.map((f) => f.id), [replacement.id]);
      // Provenance pre-resolved for click-through.
      expect(overview.factSourceTurnIds[replacement.id], ['t1']);
    });
  });

  test('conversationOfTurn resolves the source turn\'s conversation', () async {
    await seedTurn('t1');
    expect(await service().conversationOfTurn('t1'), 'c');
    expect(await service().conversationOfTurn('ghost'), isNull);
  });
}
