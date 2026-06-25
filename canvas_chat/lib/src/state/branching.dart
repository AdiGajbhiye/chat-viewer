import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../data/llm/embedding_provider.dart';
import '../data/llm/llm_provider.dart';
import '../data/llm/openai_compatible_embedding_provider.dart';
import '../data/llm/openai_compatible_provider.dart';
import '../data/llm/proposition_extractor.dart';
import '../data/llm/query_rewriter.dart';
import 'providers.dart';
import 'retrieval.dart';

/// Connection settings for the live provider, persisted in shared-prefs and
/// edited from the model-settings dialog. First-run defaults are seeded from
/// `--dart-define`s (`flutter run --dart-define=OPENAI_API_KEY=sk-…`) so a
/// backend can be wired up for a run without committing a key; once the user
/// saves, the stored values win. Until a usable key is present the app stays on
/// the offline [StubLlmProvider].
final llmConfigProvider =
    NotifierProvider<LlmConfigNotifier, LlmConfig>(LlmConfigNotifier.new);

class LlmConfigNotifier extends Notifier<LlmConfig> {
  static const _kBaseUrl = 'llm.baseUrl';
  static const _kApiKey = 'llm.apiKey';
  static const _kModel = 'llm.model';
  static const _kSystemPrompt = 'llm.systemPrompt';

  @override
  LlmConfig build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    // `--dart-define`s seed the first run; any saved value overrides them.
    const seed = LlmConfig(
      baseUrl: String.fromEnvironment(
        'OPENAI_BASE_URL',
        defaultValue: 'https://api.openai.com/v1',
      ),
      apiKey: String.fromEnvironment('OPENAI_API_KEY'),
      model: String.fromEnvironment('OPENAI_MODEL', defaultValue: 'gpt-4o-mini'),
    );
    return LlmConfig(
      baseUrl: prefs.getString(_kBaseUrl) ?? seed.baseUrl,
      apiKey: prefs.getString(_kApiKey) ?? seed.apiKey,
      model: prefs.getString(_kModel) ?? seed.model,
      systemPrompt: prefs.getString(_kSystemPrompt) ?? seed.systemPrompt,
    );
  }

  /// Trims, persists, and publishes [config]; `llmProviderProvider` rebuilds
  /// onto the new backend immediately. A blank system prompt is dropped.
  Future<void> set(LlmConfig config) async {
    final system = config.systemPrompt?.trim();
    final normalized = LlmConfig(
      baseUrl: config.baseUrl.trim(),
      apiKey: config.apiKey.trim(),
      model: config.model.trim(),
      systemPrompt: (system == null || system.isEmpty) ? null : system,
    );

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kBaseUrl, normalized.baseUrl);
    await prefs.setString(_kApiKey, normalized.apiKey);
    await prefs.setString(_kModel, normalized.model);
    if (normalized.systemPrompt == null) {
      await prefs.remove(_kSystemPrompt);
    } else {
      await prefs.setString(_kSystemPrompt, normalized.systemPrompt!);
    }

    state = normalized;
  }
}

/// The text-generation backend used when branching off a chunk. Resolves to a
/// live [OpenAiCompatibleProvider] once [llmConfigProvider] holds a usable key,
/// and otherwise to the fully-offline [StubLlmProvider]; the rest of the app is
/// provider-agnostic.
final llmProviderProvider = Provider<LlmProvider>((ref) {
  final config = ref.watch(llmConfigProvider);
  if (!config.isConfigured) return const StubLlmProvider();
  final provider = OpenAiCompatibleProvider(config);
  ref.onDispose(provider.close);
  return provider;
});

/// Embedding connection settings (DESIGN.md §10 proposition / fact index).
/// Reuses the chat config's host (`llm.baseUrl` / `llm.apiKey` — an
/// OpenAI-compatible host serves both chat and embeddings) and adds only the
/// embedding model name (`embedding.model`, seeded from `--dart-define`). Until
/// a usable host is present the app stays on the offline
/// [StubEmbeddingProvider].
final embeddingConfigProvider =
    NotifierProvider<EmbeddingConfigNotifier, EmbeddingConfig>(
  EmbeddingConfigNotifier.new,
);

class EmbeddingConfigNotifier extends Notifier<EmbeddingConfig> {
  // Host fields are shared with the chat config (same prefs keys).
  static const _kBaseUrl = 'llm.baseUrl';
  static const _kApiKey = 'llm.apiKey';
  static const _kModel = 'embedding.model';

  @override
  EmbeddingConfig build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    const seed = EmbeddingConfig(
      baseUrl: String.fromEnvironment(
        'OPENAI_BASE_URL',
        defaultValue: 'https://api.openai.com/v1',
      ),
      apiKey: String.fromEnvironment('OPENAI_API_KEY'),
      model: String.fromEnvironment(
        'OPENAI_EMBEDDING_MODEL',
        defaultValue: 'text-embedding-3-small',
      ),
    );
    return EmbeddingConfig(
      baseUrl: prefs.getString(_kBaseUrl) ?? seed.baseUrl,
      apiKey: prefs.getString(_kApiKey) ?? seed.apiKey,
      model: prefs.getString(_kModel) ?? seed.model,
    );
  }

  /// Trims, persists, and publishes [config]; `embeddingProviderProvider`
  /// rebuilds onto the new backend immediately. The host fields share the chat
  /// config's prefs keys, so writing here keeps the two in sync.
  Future<void> set(EmbeddingConfig config) async {
    final normalized = EmbeddingConfig(
      baseUrl: config.baseUrl.trim(),
      apiKey: config.apiKey.trim(),
      model: config.model.trim(),
    );

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kBaseUrl, normalized.baseUrl);
    await prefs.setString(_kApiKey, normalized.apiKey);
    await prefs.setString(_kModel, normalized.model);

    state = normalized;
  }
}

/// The embedding backend used by the index / retrieval layer. Resolves to a
/// live [OpenAiCompatibleEmbeddingProvider] once [embeddingConfigProvider] holds
/// a usable host, and otherwise to the fully-offline [StubEmbeddingProvider];
/// the rest of the app is provider-agnostic. Nothing calls this yet (M6.2 is
/// strictly additive).
final embeddingProviderProvider = Provider<EmbeddingProvider>((ref) {
  final config = ref.watch(embeddingConfigProvider);
  if (!config.isConfigured) return const StubEmbeddingProvider();
  final provider = OpenAiCompatibleEmbeddingProvider(config);
  ref.onDispose(provider.close);
  return provider;
});

/// The query rewriter used by retrieval (DESIGN.md §10 step 1). Mirrors
/// [propositionExtractorProvider]: once a usable LLM key is present it resolves
/// to the model-backed [LlmQueryRewriter], and otherwise to the fully-offline
/// [StubQueryRewriter] — so context assembly stays deterministic offline.
final queryRewriterProvider = Provider<QueryRewriter>((ref) {
  final config = ref.watch(llmConfigProvider);
  if (!config.isConfigured) return const StubQueryRewriter();
  return LlmQueryRewriter(ref.watch(llmProviderProvider));
});

/// Builds a [ContextAssembler] from the app's providers (DESIGN.md §10). The
/// embedder / rewriter resolve to the offline stubs until a backend is
/// configured, so context assembly is fully offline and deterministic by
/// default. Reading this needs `sharedPreferencesProvider` (via the configs),
/// so any caller on a no-prefs path must guard — but [BranchService] only
/// resolves it when a branch is actually created.
final contextAssemblerProvider = Provider<ContextAssembler>((ref) {
  return ContextAssembler(
    db: ref.watch(databaseProvider),
    embedder: ref.watch(embeddingProviderProvider),
    rewriter: ref.watch(queryRewriterProvider),
  );
});

/// The proposition + entity extractor used by the index (DESIGN.md §10). Reuses
/// [llmProviderProvider]: once a usable LLM key is present it resolves to the
/// model-backed [LlmPropositionExtractor], and otherwise to the fully-offline
/// [StubPropositionExtractor]. Nothing calls this yet (M6.3 is strictly additive
/// — the indexer step wires it).
final propositionExtractorProvider = Provider<PropositionExtractor>((ref) {
  final config = ref.watch(llmConfigProvider);
  if (!config.isConfigured) return const StubPropositionExtractor();
  return LlmPropositionExtractor(ref.watch(llmProviderProvider));
});

/// Turn ids whose response is currently streaming in (DESIGN.md §9 "pending"
/// state). The reader shows a "Generating…" indicator for these; the set is
/// driven by [BranchService] — an id is added when its stream starts and
/// removed when it finishes or fails.
final generatingTurnsProvider =
    NotifierProvider<GeneratingTurns, Set<String>>(GeneratingTurns.new);

class GeneratingTurns extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void add(String id) {
    if (state.contains(id)) return;
    state = {...state, id};
  }

  void remove(String id) {
    if (!state.contains(id)) return;
    state = {...state}..remove(id);
  }
}

final branchServiceProvider = Provider<BranchService>(
  (ref) => BranchService(
    ref.watch(databaseProvider),
    ref.watch(llmProviderProvider),
    assembler: ref.watch(contextAssemblerProvider),
    // Read (not watch) the live scope at branch time so flipping the on-canvas
    // scope control affects the next branch without rebuilding the service
    // (DESIGN.md §10 "Scope filter = branch | session | project | all").
    scope: () => ref.read(retrievalScopeProvider),
    onGenerating: (turnId, generating) {
      final turns = ref.read(generatingTurnsProvider.notifier);
      generating ? turns.add(turnId) : turns.remove(turnId);
    },
  ),
);

/// Creates new "authored" turns that branch off an existing one — the
/// read-mode chunk toolbar's Ask-AI / Explain / Expand actions (DESIGN.md §9
/// forking: "start a new child turn from any node and send its root-path as
/// context"). The new turn is a *child* of the source turn, so the grid layout
/// lays it out in a fresh lane to the right — a horizontal branch — whenever
/// the source already has a continuation below it.
class BranchService {
  BranchService(
    this._db,
    this._llm, {
    this.assembler,
    this.onGenerating,
    this.scope,
  });

  final AppDatabase _db;
  final LlmProvider _llm;

  /// Builds the retrieval-assembled context that replaces the full root→parent
  /// ancestry (DESIGN.md §10). Optional: when null (e.g. a focused unit test
  /// that constructs the service directly), the service falls back to sending
  /// the full ancestry — the v1 behavior — so it never needs the index.
  final ContextAssembler? assembler;

  /// Notified when a turn's streaming starts (`true`) and ends (`false`), so
  /// app state can track which turns are mid-generation. Optional — tests that
  /// don't care about the pending state omit it.
  final void Function(String turnId, bool generating)? onGenerating;

  /// Reads the user-selected retrieval breadth (DESIGN.md §10 "Scope filter")
  /// at assemble time, so flipping the on-canvas scope control takes effect on
  /// the next branch without rebuilding the service. A callback (not a value)
  /// because the provider's value can change between branches; when null the
  /// assembler's default scope (`project`) is used.
  final RetrievalScope Function()? scope;

  /// Authored turns get a distinct id namespace so they never collide with
  /// imported `<conversation>:<node>` ids.
  static const idPrefix = 'authored';
  static int _seq = 0;

  /// Branches off [parent] with a child turn whose prompt is [prompt], then
  /// streams the provider's response into it. Returns the new turn's id
  /// (already inserted, so the caller can focus it immediately) plus a [done]
  /// future that completes once the response has finished streaming in — the
  /// UI ignores it; tests await it.
  Future<({String id, Future<void> done})> branchFrom({
    required Turn parent,
    required String prompt,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = '${parent.conversationId}:$idPrefix-'
        '${DateTime.now().microsecondsSinceEpoch}-${_seq++}';
    await _db.into(_db.turns).insert(
          TurnsCompanion.insert(
            id: id,
            conversationId: parent.conversationId,
            parentTurnId: Value(parent.id),
            promptMd: Value(prompt),
            createTime: Value(now),
            rawJson: '{"authored":true}',
          ),
        );
    // An authored turn is the conversation's newest message: keep the sidebar
    // ordering/date key honest so the branch surfaces at the top.
    await (_db.update(_db.conversations)
          ..where((c) => c.id.equals(parent.conversationId)))
        .write(ConversationsCompanion(lastMessageAt: Value(now)));
    // Kick off streaming now; hand the caller its future without awaiting so
    // the branch appears (and can be focused) before the answer arrives.
    return (id: id, done: _stream(id, parent, prompt));
  }

  Future<void> _stream(String id, Turn parent, String prompt) async {
    onGenerating?.call(id, true);
    try {
      // DESIGN.md §10: continuing a session RETRIEVES context instead of
      // sending the full root→parent ancestry. With an assembler wired, the
      // context is the last 1–2 turns verbatim + MMR-selected retrieved items
      // (tagged {branch, committed?} in the preamble); without one, fall back
      // to the v1 full-ancestry send.
      List<Turn> context;
      String? preamble;
      final assembler = this.assembler;
      if (assembler != null) {
        final assembled = await _assembleContext(assembler, parent, prompt);
        context = assembled.verbatim;
        preamble = assembled.preamble.isEmpty ? null : assembled.preamble;
      } else {
        context = await _ancestors(parent);
      }

      final buffer = StringBuffer();
      await for (final delta in _llm.generate(
        prompt: prompt,
        context: context,
        preamble: preamble,
      )) {
        buffer.write(delta);
        await _writeResponse(id, buffer.toString());
      }
    } catch (e) {
      await _writeResponse(id, '_Generation failed: ${e}_');
    } finally {
      onGenerating?.call(id, false);
    }
  }

  /// Loads [parent]'s conversation row and runs the assembler over the
  /// user-selected scope (DESIGN.md §10). Kept separate so `_stream` stays
  /// readable; when no [scope] getter is wired the assembler's default
  /// (`project`) applies.
  Future<AssembledContext> _assembleContext(
    ContextAssembler assembler,
    Turn parent,
    String prompt,
  ) async {
    final conversation = await (_db.select(_db.conversations)
          ..where((c) => c.id.equals(parent.conversationId)))
        .getSingle();
    return assembler.assemble(
      conversation: conversation,
      parent: parent,
      prompt: prompt,
      scope: scope?.call() ?? RetrievalScope.project,
    );
  }

  Future<void> _writeResponse(String id, String md) =>
      (_db.update(_db.turns)..where((t) => t.id.equals(id)))
          .write(TurnsCompanion(responseMd: Value(md)));

  /// Root→[turn] path (inclusive), for providers that send conversation
  /// history. Walks `parent_turn_id` with a cycle guard over corrupt data.
  Future<List<Turn>> _ancestors(Turn turn) async {
    final all = await (_db.select(_db.turns)
          ..where((t) => t.conversationId.equals(turn.conversationId)))
        .get();
    final byId = {for (final t in all) t.id: t};
    final path = <Turn>[];
    final seen = <String>{};
    Turn? cursor = turn;
    while (cursor != null && seen.add(cursor.id)) {
      path.add(cursor);
      final parentId = cursor.parentTurnId;
      cursor = parentId == null ? null : byId[parentId];
    }
    return path.reversed.toList();
  }
}
