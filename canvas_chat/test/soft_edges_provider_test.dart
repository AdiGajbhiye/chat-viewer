import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/state/providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// M8.3 — the provider that feeds the soft-edge canvas layer. It must return
/// only the **renderable intra-conversation** edges: both endpoints turns in
/// the open conversation, and `crossSession` excluded (cross-canvas rendering
/// is later). Seeds `soft_edges` directly (the precompute is covered by
/// soft_edges_test) and asserts the filtering.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> seedConversation(String id) =>
      db.into(db.conversations).insert(
            ConversationsCompanion.insert(id: id, source: 'test'),
          );

  Future<void> seedTurn(String id, {required String conversationId}) =>
      db.into(db.turns).insert(
            TurnsCompanion.insert(
              id: id,
              conversationId: conversationId,
              rawJson: '[]',
            ),
          );

  Future<void> seedEdge(
    String from,
    String to, {
    String kind = 'semantic',
    double weight = 0.7,
  }) =>
      db.into(db.softEdges).insert(
            SoftEdgesCompanion.insert(
              fromTurnId: from,
              toTurnId: to,
              kind: kind,
              weight: weight,
              projectId: 'default',
            ),
          );

  Future<List<SoftEdge>> load(String conversationId) async {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    return container
        .read(softEdgesForConversationProvider(conversationId).future);
  }

  test('returns only edges with both endpoints in the conversation', () async {
    await seedConversation('c1');
    await seedConversation('c2');
    for (final id in ['c1:a', 'c1:b', 'c1:c']) {
      await seedTurn(id, conversationId: 'c1');
    }
    await seedTurn('c2:x', conversationId: 'c2');

    // Renderable: both endpoints in c1 (one semantic, one entity).
    await seedEdge('c1:a', 'c1:b');
    await seedEdge('c1:a', 'c1:c', kind: 'entity', weight: 0.5);
    // Endpoint in another conversation → dropped.
    await seedEdge('c1:a', 'c2:x');
    // Endpoint not a turn at all (dangling) → dropped.
    await seedEdge('c1:b', 'ghost');
    // crossSession is a later step → dropped even if both endpoints are in c1.
    await seedEdge('c1:b', 'c1:c', kind: 'crossSession');

    final edges = await load('c1');

    expect(edges, hasLength(2));
    expect(
      edges.map((e) => (e.fromTurnId, e.toTurnId, e.kind)).toSet(),
      {
        ('c1:a', 'c1:b', 'semantic'),
        ('c1:a', 'c1:c', 'entity'),
      },
    );
    // crossSession never surfaces.
    expect(edges.where((e) => e.kind == 'crossSession'), isEmpty);
  });

  test('an unindexed conversation (no edges) yields an empty list', () async {
    await seedConversation('c1');
    await seedTurn('c1:a', conversationId: 'c1');
    expect(await load('c1'), isEmpty);
  });

  test('a conversation with no turns yields an empty list', () async {
    await seedConversation('empty');
    expect(await load('empty'), isEmpty);
  });
}
