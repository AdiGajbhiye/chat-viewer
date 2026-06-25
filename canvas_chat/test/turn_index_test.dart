import 'package:canvas_chat/src/data/db/database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// The reader's "Generated index" data layer ([AppDatabase.turnIndex],
/// DESIGN.md §10): a turn's propositions (text + aspect) plus the names of the
/// entities it mentions, both in a stable order, deduped — and the empty result
/// for a turn that hasn't been indexed.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.into(db.conversations).insert(
          ConversationsCompanion.insert(id: 'c', source: 'test'),
        );
  });
  tearDown(() => db.close());

  Future<void> seedTurn(String id) => db.into(db.turns).insert(
        TurnsCompanion.insert(
          id: id,
          conversationId: 'c',
          rawJson: '[]',
        ),
      );

  Future<void> seedProposition(
    String id, {
    required String turnId,
    required String text,
    String? aspect,
  }) =>
      db.into(db.propositions).insert(
            PropositionsCompanion.insert(
              id: id,
              turnId: turnId,
              conversationId: 'c',
              projectId: 'default',
              propText: text,
              aspect: Value(aspect),
            ),
          );

  Future<void> seedEntity(String id, {required String name}) =>
      db.into(db.entities).insert(
            EntitiesCompanion.insert(
              id: id,
              projectId: 'default',
              name: name,
              normalized: name.toLowerCase(),
            ),
          );

  Future<void> link(String entityId, String turnId) =>
      db.into(db.turnEntities).insert(
            TurnEntitiesCompanion.insert(entityId: entityId, turnId: turnId),
          );

  test('returns a turn\'s propositions (with aspects) and entities, in a '
      'stable order', () async {
    await seedTurn('t1');
    await seedTurn('t2'); // a different turn — must not leak in.
    // Inserted out of id order to prove the query sorts.
    await seedProposition('t1#2', turnId: 't1', text: 'C is true.');
    await seedProposition('t1#0', turnId: 't1', text: 'A is true.', aspect: 'perf');
    await seedProposition('t1#1',
        turnId: 't1', text: 'B is asked?', aspect: 'question');
    await seedProposition('t2#0', turnId: 't2', text: 'Other turn.');

    await seedEntity('e_z', name: 'Zeta');
    await seedEntity('e_a', name: 'alpha');
    await link('e_z', 't1');
    await link('e_a', 't1');
    await link('e_z', 't2'); // also on t2 — t1's read is unaffected.

    final index = await db.turnIndex('t1');

    // Propositions ordered by id, aspect preserved (null where absent).
    expect(
      index.propositions.map((p) => p.text),
      ['A is true.', 'B is asked?', 'C is true.'],
    );
    expect(
      index.propositions.map((p) => p.aspect),
      ['perf', 'question', null],
    );
    // Entities ordered case-insensitively (normalized), only this turn's.
    expect(index.entities, ['alpha', 'Zeta']);
    expect(index.isEmpty, isFalse);
  });

  test('dedupes an entity linked to the turn more than once', () async {
    await seedTurn('t1');
    await seedEntity('e_a', name: 'Drift');
    await link('e_a', 't1');
    await link('e_a', 't1'); // defensive double-link.

    final index = await db.turnIndex('t1');
    expect(index.entities, ['Drift']);
  });

  test('a not-yet-indexed turn returns an empty index', () async {
    await seedTurn('t1');
    final index = await db.turnIndex('t1');
    expect(index.propositions, isEmpty);
    expect(index.entities, isEmpty);
    expect(index.isEmpty, isTrue);
  });
}
