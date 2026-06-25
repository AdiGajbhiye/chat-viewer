import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/data/llm/embedding_math.dart';
import 'package:canvas_chat/src/data/llm/embedding_provider.dart';
import 'package:canvas_chat/src/data/llm/query_rewriter.dart';
import 'package:canvas_chat/src/state/retrieval.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// An embedder returning a controlled vector for each text — by exact match
/// against [vectors], else a zero vector — so retrieval similarity is exactly
/// what the test dictates (stub vectors aren't semantic). The query text is fed
/// through [queryVector].
class _ControlledEmbedder implements EmbeddingProvider {
  _ControlledEmbedder({required this.queryVector});

  final List<double> queryVector;

  @override
  String get modelId => 'controlled-4';

  @override
  Future<List<List<double>>> embed(List<String> texts) async =>
      [for (final _ in texts) queryVector];
}

/// A rewriter that returns the prompt unchanged (single query), so the test
/// controls retrieval purely through the embeddings.
class _PassthroughRewriter implements QueryRewriter {
  const _PassthroughRewriter();
  @override
  Future<List<String>> rewrite(String prompt,
          {List<Turn> recentTurns = const []}) async =>
      [prompt];
}

List<double> _vec(List<double> v) => v;

Future<void> _insertTurn(
  AppDatabase db, {
  required String id,
  String? parent,
  int? createTime,
  String prompt = 'p',
  String response = 'r',
}) async {
  await db.into(db.turns).insert(
        TurnsCompanion.insert(
          id: id,
          conversationId: 'c',
          parentTurnId: Value(parent),
          promptMd: Value(prompt),
          responseMd: Value(response),
          createTime: Value(createTime),
          rawJson: '[]',
        ),
      );
}

/// Inserts one embedded proposition for [turnId] with the given vector.
Future<void> _insertProp(
  AppDatabase db, {
  required String id,
  required String turnId,
  required List<double> vector,
  String text = 'prop',
  String project = 'default',
  String conversation = 'c',
}) async {
  await db.into(db.propositions).insert(
        PropositionsCompanion.insert(
          id: id,
          turnId: turnId,
          conversationId: conversation,
          projectId: project,
          propText: text,
          embedding: Value(encodeEmbedding(vector)),
          embeddingModel: const Value('controlled-4'),
        ),
      );
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.into(db.conversations).insert(
          ConversationsCompanion.insert(
            id: 'c',
            source: 'test',
            currentTurnId: const Value('c:leaf'),
          ),
        );
  });
  tearDown(() => db.close());

  ContextAssembler assembler({required List<double> queryVector}) =>
      ContextAssembler(
        db: db,
        embedder: _ControlledEmbedder(queryVector: queryVector),
        rewriter: const _PassthroughRewriter(),
      );

  Future<Conversation> conversation() =>
      (db.select(db.conversations)..where((c) => c.id.equals('c'))).getSingle();

  Future<Turn> turn(String id) =>
      (db.select(db.turns)..where((t) => t.id.equals(id))).getSingle();

  test('assembly keeps last 1–2 turns verbatim + the queries, no retrieval dup',
      () async {
    // Linear chain root → mid → leaf(parent). Retrieval will match `mid` (its
    // proposition equals the query vector), but `mid` is in the verbatim tail,
    // so it must NOT also appear as a retrieved item.
    await _insertTurn(db, id: 'c:root', createTime: 1, prompt: 'root q');
    await _insertTurn(db, id: 'c:mid', parent: 'c:root', createTime: 2, prompt: 'mid q');
    await _insertTurn(db, id: 'c:leaf', parent: 'c:mid', createTime: 3, prompt: 'leaf q');
    final query = _vec([1, 0, 0, 0]);
    await _insertProp(db, id: 'c:mid#0', turnId: 'c:mid', vector: query);

    final result = await assembler(queryVector: query).assemble(
      conversation: await conversation(),
      parent: await turn('c:leaf'),
      prompt: 'follow up',
    );

    // Verbatim tail = last 2 turns (mid, leaf), oldest→newest.
    expect(result.verbatim.map((t) => t.id), ['c:mid', 'c:leaf']);
    // `mid` is in the tail → never duplicated into retrieved.
    expect(result.retrieved.map((i) => i.turn.id), isNot(contains('c:mid')));
    expect(result.queries, ['follow up']);
  });

  test('retrieved items carry {branch, committed?} tags in the preamble',
      () async {
    await _insertTurn(db, id: 'c:root', createTime: 1, prompt: 'root');
    await _insertTurn(db, id: 'c:leaf', parent: 'c:root', createTime: 2, prompt: 'leaf');
    // An off-tail turn (a separate branch) whose prop matches the query.
    await _insertTurn(db, id: 'c:other', parent: 'c:root', createTime: 2, prompt: 'other');
    final query = _vec([1, 0, 0, 0]);
    await _insertProp(db, id: 'c:other#0', turnId: 'c:other', vector: query);

    final result = await assembler(queryVector: query).assemble(
      conversation: await conversation(),
      parent: await turn('c:leaf'),
      prompt: 'q',
    );

    expect(result.retrieved.map((i) => i.turn.id), contains('c:other'));
    final item = result.retrieved.firstWhere((i) => i.turn.id == 'c:other');
    expect(item.branchId, 'c'); // branch = conversation id
    expect(item.committed, isFalse);
    expect(result.preamble, contains('branch:c'));
    expect(result.preamble, contains('tentative'));
  });

  test('facts are surfaced as committed candidates with the fact text',
      () async {
    await _insertTurn(db, id: 'c:root', createTime: 1);
    await _insertTurn(db, id: 'c:leaf', parent: 'c:root', createTime: 2);
    await _insertTurn(db, id: 'c:src', parent: 'c:root', createTime: 2,
        prompt: 'source turn');
    final query = _vec([1, 0, 0, 0]);
    // A committed fact pinned to turn c:src.
    await db.into(db.facts).insert(
          FactsCompanion.insert(
            id: 'f1',
            projectId: 'default',
            factText: 'We chose SQLite over Postgres.',
            status: 'active',
            embedding: Value(encodeEmbedding(query)),
          ),
        );
    await db.into(db.factSources).insert(
          FactSourcesCompanion.insert(factId: 'f1', turnId: 'c:src'),
        );

    final result = await assembler(queryVector: query).assemble(
      conversation: await conversation(),
      parent: await turn('c:leaf'),
      prompt: 'q',
    );

    final item = result.retrieved.firstWhere((i) => i.turn.id == 'c:src');
    expect(item.committed, isTrue);
    expect(item.text, 'We chose SQLite over Postgres.');
    expect(result.preamble, contains('committed'));
  });

  test('dense + sparse + facts union dedups by turn', () async {
    await _insertTurn(db, id: 'c:root', createTime: 1);
    await _insertTurn(db, id: 'c:leaf', parent: 'c:root', createTime: 2);
    // One turn matched by BOTH dense (its prop == query) AND sparse (FTS on a
    // distinctive word in its prompt) — it must appear exactly once.
    await _insertTurn(db, id: 'c:both', parent: 'c:root', createTime: 2,
        prompt: 'quasiparticle discussion', response: 'details');
    final query = _vec([1, 0, 0, 0]);
    await _insertProp(db, id: 'c:both#0', turnId: 'c:both', vector: query);

    final result = await ContextAssembler(
      db: db,
      embedder: _ControlledEmbedder(queryVector: query),
      rewriter: const _PassthroughRewriter(),
    ).assemble(
      conversation: await conversation(),
      parent: await turn('c:leaf'),
      // The prompt also matches FTS on 'quasiparticle'.
      prompt: 'quasiparticle',
    );

    final occurrences =
        result.retrieved.where((i) => i.turn.id == 'c:both').length;
    expect(occurrences, 1);
  });

  test('scope=session limits candidates to the current conversation', () async {
    // A second conversation in the same project with a matching prop must be
    // visible under project scope but hidden under session scope.
    await db.into(db.conversations).insert(
          ConversationsCompanion.insert(id: 'c2', source: 'test'),
        );
    await _insertTurn(db, id: 'c:root', createTime: 1);
    await _insertTurn(db, id: 'c:leaf', parent: 'c:root', createTime: 2);
    await db.into(db.turns).insert(
          TurnsCompanion.insert(
            id: 'c2:t',
            conversationId: 'c2',
            promptMd: const Value('cross-session turn'),
            createTime: const Value(2),
            rawJson: '[]',
          ),
        );
    final query = _vec([1, 0, 0, 0]);
    await _insertProp(db, id: 'c2:t#0', turnId: 'c2:t', vector: query,
        conversation: 'c2');

    final base = ContextAssembler(
      db: db,
      embedder: _ControlledEmbedder(queryVector: query),
      rewriter: const _PassthroughRewriter(),
    );

    final project = await base.assemble(
      conversation: await conversation(),
      parent: await turn('c:leaf'),
      prompt: 'q',
      scope: RetrievalScope.project,
    );
    expect(project.retrieved.map((i) => i.turn.id), contains('c2:t'));

    final session = await base.assemble(
      conversation: await conversation(),
      parent: await turn('c:leaf'),
      prompt: 'q',
      scope: RetrievalScope.session,
    );
    expect(session.retrieved.map((i) => i.turn.id), isNot(contains('c2:t')));
  });

  test('fork-aware scoring ranks active-lineage above a diverged sibling',
      () async {
    // Tree:  root → a1 → a2 → leaf(parent, on active path)
    //                \→ sib (a diverged sibling subtree off a1)
    // a1 and sib both have a proposition matching the query equally; a1 is on
    // the parent's ancestry (active lineage) and sib is diverged, so a1 must
    // outrank sib. The verbatim tail is [a2, leaf], so a1/sib stay retrievable.
    await _insertTurn(db, id: 'c:root', createTime: 1);
    await _insertTurn(db, id: 'c:a1', parent: 'c:root', createTime: 2);
    await _insertTurn(db, id: 'c:a2', parent: 'c:a1', createTime: 4);
    await _insertTurn(db, id: 'c:leaf', parent: 'c:a2', createTime: 5);
    await _insertTurn(db, id: 'c:sib', parent: 'c:a1', createTime: 3);
    final query = _vec([1, 0, 0, 0]);
    await _insertProp(db, id: 'c:a1#0', turnId: 'c:a1', vector: query);
    await _insertProp(db, id: 'c:sib#0', turnId: 'c:sib', vector: query);

    final result = await assembler(queryVector: query).assemble(
      conversation: await conversation(),
      parent: await turn('c:leaf'),
      prompt: 'q',
    );

    final a1 = result.retrieved.firstWhere((i) => i.turn.id == 'c:a1');
    final sib = result.retrieved.firstWhere((i) => i.turn.id == 'c:sib');
    expect(a1.score, greaterThan(sib.score));
    // The diverged sibling is penalized, not excluded.
    expect(result.retrieved.map((i) => i.turn.id), contains('c:sib'));
  });

  test('committed candidate outranks an equally-similar uncommitted one',
      () async {
    await _insertTurn(db, id: 'c:root', createTime: 1);
    await _insertTurn(db, id: 'c:leaf', parent: 'c:root', createTime: 4);
    // Two diverged siblings, equal similarity; one is fact-backed.
    await _insertTurn(db, id: 'c:plain', parent: 'c:root', createTime: 2);
    await _insertTurn(db, id: 'c:fact', parent: 'c:root', createTime: 2);
    final query = _vec([1, 0, 0, 0]);
    await _insertProp(db, id: 'c:plain#0', turnId: 'c:plain', vector: query);
    await db.into(db.facts).insert(
          FactsCompanion.insert(
            id: 'f1',
            projectId: 'default',
            factText: 'fact body',
            status: 'active',
            embedding: Value(encodeEmbedding(query)),
          ),
        );
    await db.into(db.factSources).insert(
          FactSourcesCompanion.insert(factId: 'f1', turnId: 'c:fact'),
        );

    final result = await assembler(queryVector: query).assemble(
      conversation: await conversation(),
      parent: await turn('c:leaf'),
      prompt: 'q',
    );

    final plain = result.retrieved.firstWhere((i) => i.turn.id == 'c:plain');
    final fact = result.retrieved.firstWhere((i) => i.turn.id == 'c:fact');
    expect(fact.score, greaterThan(plain.score));
  });
}
