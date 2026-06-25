import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/data/llm/embedding_math.dart';
import 'package:canvas_chat/src/data/llm/embedding_provider.dart';
import 'package:canvas_chat/src/data/llm/llm_provider.dart';
import 'package:canvas_chat/src/data/llm/query_rewriter.dart';
import 'package:canvas_chat/src/state/branching.dart';
import 'package:canvas_chat/src/state/providers.dart';
import 'package:canvas_chat/src/state/retrieval.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Captures the `preamble` the seam passed, so a test can assert which
/// conversations' content the selected scope made eligible for retrieval.
class _CapturingProvider implements LlmProvider {
  String? capturedPreamble;

  @override
  Stream<String> generate({
    required String prompt,
    required List<Turn> context,
    String? preamble,
  }) async* {
    capturedPreamble = preamble;
    yield 'ok';
  }
}

/// An embedder returning a single controlled vector for every text, so a probe
/// proposition matches the query exactly and retrieval is deterministic.
class _ControlledEmbedder implements EmbeddingProvider {
  const _ControlledEmbedder(this.vector);
  final List<double> vector;

  @override
  String get modelId => 'controlled-4';

  @override
  Future<List<List<double>>> embed(List<String> texts) async =>
      [for (final _ in texts) vector];
}

class _PassthroughRewriter implements QueryRewriter {
  const _PassthroughRewriter();
  @override
  Future<List<String>> rewrite(String prompt,
          {List<Turn> recentTurns = const []}) async =>
      [prompt];
}

void main() {
  late AppDatabase db;
  const probeVector = [1.0, 0.0, 0.0, 0.0];

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    // Current conversation 'c' (project 'default') and a sibling 'c2' in the
    // same project; a third 'c3' in another project for the all-vs-project test.
    await db.into(db.conversations).insert(
          ConversationsCompanion.insert(
            id: 'c',
            source: 'test',
            currentTurnId: const Value('c:leaf'),
          ),
        );
    await db.into(db.conversations).insert(
          ConversationsCompanion.insert(id: 'c2', source: 'test'),
        );
    await db.into(db.conversations).insert(
          ConversationsCompanion.insert(
            id: 'c3',
            source: 'test',
            projectId: const Value('other'),
          ),
        );

    // Current conversation's linear chain root → leaf(parent).
    await db.into(db.turns).insert(TurnsCompanion.insert(
        id: 'c:root', conversationId: 'c', createTime: const Value(1),
        rawJson: '[]'));
    await db.into(db.turns).insert(TurnsCompanion.insert(
        id: 'c:leaf', conversationId: 'c', parentTurnId: const Value('c:root'),
        createTime: const Value(2), rawJson: '[]'));

    // A cross-session turn in the same project (visible under project/all).
    await db.into(db.turns).insert(TurnsCompanion.insert(
        id: 'c2:t', conversationId: 'c2', createTime: const Value(2),
        rawJson: '[]'));
    await db.into(db.propositions).insert(PropositionsCompanion.insert(
        id: 'c2:t#0', turnId: 'c2:t', conversationId: 'c2', projectId: 'default',
        propText: 'cross-session prop',
        embedding: Value(encodeEmbedding(probeVector)),
        embeddingModel: const Value('controlled-4')));

    // A turn in ANOTHER project (visible only under all).
    await db.into(db.turns).insert(TurnsCompanion.insert(
        id: 'c3:t', conversationId: 'c3', createTime: const Value(2),
        rawJson: '[]'));
    await db.into(db.propositions).insert(PropositionsCompanion.insert(
        id: 'c3:t#0', turnId: 'c3:t', conversationId: 'c3', projectId: 'other',
        propText: 'other-project prop',
        embedding: Value(encodeEmbedding(probeVector)),
        embeddingModel: const Value('controlled-4')));
  });
  tearDown(() => db.close());

  ContextAssembler buildAssembler() => ContextAssembler(
        db: db,
        embedder: const _ControlledEmbedder(probeVector),
        rewriter: const _PassthroughRewriter(),
      );

  Future<Turn> leaf() =>
      (db.select(db.turns)..where((t) => t.id.equals('c:leaf'))).getSingle();

  /// Runs a branch off c:leaf with the container's selected scope and returns
  /// the preamble the provider saw (carries the retrieved items' branch tags).
  Future<String?> branchAndCapture(ProviderContainer container) async {
    final captor = container.read(_captorProvider);
    final branch = await container
        .read(branchServiceProvider)
        .branchFrom(parent: await leaf(), prompt: 'recall');
    await branch.done;
    return captor.capturedPreamble;
  }

  test('BranchService routes the selected scope into assemble (session hides '
      'cross-session; project shows it)', () async {
    ProviderContainer makeContainer(RetrievalScope scope) {
      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        contextAssemblerProvider.overrideWithValue(buildAssembler()),
        _captorProvider.overrideWith((ref) => _CapturingProvider()),
        llmProviderProvider.overrideWith((ref) => ref.watch(_captorProvider)),
      ]);
      container.read(retrievalScopeProvider.notifier).set(scope);
      return container;
    }

    // session → only the current conversation; the cross-session prop is hidden.
    final sessionContainer = makeContainer(RetrievalScope.session);
    addTearDown(sessionContainer.dispose);
    final sessionPreamble = await branchAndCapture(sessionContainer);
    expect(sessionPreamble ?? '', isNot(contains('branch:c2')));

    // project → the whole project; the same-project cross-session prop surfaces.
    final projectContainer = makeContainer(RetrievalScope.project);
    addTearDown(projectContainer.dispose);
    final projectPreamble = await branchAndCapture(projectContainer);
    expect(projectPreamble, isNotNull);
    expect(projectPreamble, contains('branch:c2'));
  });

  test('all-scope widens past the project boundary; project does not',
      () async {
    ProviderContainer makeContainer(RetrievalScope scope) {
      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        contextAssemblerProvider.overrideWithValue(buildAssembler()),
        _captorProvider.overrideWith((ref) => _CapturingProvider()),
        llmProviderProvider.overrideWith((ref) => ref.watch(_captorProvider)),
      ]);
      container.read(retrievalScopeProvider.notifier).set(scope);
      return container;
    }

    // project → the other-project turn is NOT eligible.
    final projectContainer = makeContainer(RetrievalScope.project);
    addTearDown(projectContainer.dispose);
    final projectPreamble = await branchAndCapture(projectContainer);
    expect(projectPreamble ?? '', isNot(contains('branch:c3')));

    // all → it IS eligible (across every project).
    final allContainer = makeContainer(RetrievalScope.all);
    addTearDown(allContainer.dispose);
    final allPreamble = await branchAndCapture(allContainer);
    expect(allPreamble, isNotNull);
    expect(allPreamble, contains('branch:c3'));
  });
}

/// A test-local provider holding the capturing LLM, so the same instance can be
/// both read for assertions and supplied as `llmProviderProvider`.
final _captorProvider = Provider<_CapturingProvider>((ref) {
  throw StateError('overridden per test');
});
