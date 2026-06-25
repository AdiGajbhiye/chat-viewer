import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../data/llm/embedding_provider.dart';
import '../data/llm/proposition_extractor.dart';
import '../domain/active_path.dart';
import 'branching.dart';
import 'providers.dart';

/// The lazy-index state machine values mirrored from `conversations.index_state`
/// (DESIGN.md §10): a conversation is indexed on session open, active-path-first.
enum IndexState {
  notIndexed(0),
  indexing(1),
  indexed(2),
  stale(3);

  const IndexState(this.value);

  /// The persisted int (`conversations.index_state`).
  final int value;

  static IndexState fromInt(int value) =>
      IndexState.values.firstWhere((s) => s.value == value,
          orElse: () => IndexState.notIndexed);
}

/// Per-conversation indexing progress, surfaced to the UI (the on-canvas
/// "Indexing N/M…" indicator). [done]/[total] count turns; [state] tracks the
/// machine so the indicator can show while `indexing` and hide once `indexed`.
class IndexingProgress {
  const IndexingProgress({
    required this.state,
    this.done = 0,
    this.total = 0,
  });

  final IndexState state;
  final int done;
  final int total;

  bool get isIndexing => state == IndexState.indexing;

  IndexingProgress copyWith({IndexState? state, int? done, int? total}) =>
      IndexingProgress(
        state: state ?? this.state,
        done: done ?? this.done,
        total: total ?? this.total,
      );

  @override
  bool operator ==(Object other) =>
      other is IndexingProgress &&
      other.state == state &&
      other.done == done &&
      other.total == total;

  @override
  int get hashCode => Object.hash(state, done, total);
}

/// Live indexing progress keyed by conversation id (mirrors
/// [generatingTurnsProvider]). The on-canvas indicator watches this; the
/// [ConversationIndexer] writes it. A conversation absent from the map has no
/// active or finished job this session (its persisted `index_state` is the
/// source of truth across launches).
final indexingProgressProvider =
    NotifierProvider<IndexingProgressNotifier, Map<String, IndexingProgress>>(
  IndexingProgressNotifier.new,
);

class IndexingProgressNotifier
    extends Notifier<Map<String, IndexingProgress>> {
  @override
  Map<String, IndexingProgress> build() => const {};

  /// Progress for [conversationId], or null when no job has touched it this
  /// session.
  IndexingProgress? of(String conversationId) => state[conversationId];

  void update(String conversationId, IndexingProgress progress) {
    if (state[conversationId] == progress) return;
    state = {...state, conversationId: progress};
  }
}

/// Orders [turns] **active-path-first** for indexing (DESIGN.md §10): the turns
/// on the conversation's active path (derived from [currentTurnId]) come first,
/// in root→leaf path order, so retrieval works before the whole session
/// finishes; the remaining off-path turns follow in a stable order
/// (create_time, then id). Pure and deterministic — tested directly.
List<Turn> indexOrder(List<Turn> turns, String? currentTurnId) {
  if (turns.isEmpty) return const [];
  final path = activePath(turns, currentTurnId);
  final onPath = {for (final t in path) t.id};
  final rest = [
    for (final t in turns)
      if (!onPath.contains(t.id)) t,
  ]..sort((a, b) {
      final ta = a.createTime, tb = b.createTime;
      if (ta != null && tb != null && ta != tb) return ta.compareTo(tb);
      if (ta == null && tb != null) return -1;
      if (ta != null && tb == null) return 1;
      return a.id.compareTo(b.id);
    });
  return [...path, ...rest];
}

/// Drives the lazy index for one conversation (DESIGN.md §10 "lazy indexing"):
/// loads its turns, orders them active-path-first, and for each turn extracts
/// ~5 propositions, embeds their texts in one batched call, and persists them —
/// yielding between turns so the UI thread stays responsive. The
/// `conversations.index_state` machine is driven start→finish and a re-entry of
/// a conversation left mid-flight (a prior crash) safely re-runs, because
/// [AppDatabase.persistTurnExtraction] is idempotent per turn.
///
/// Constructed with explicit dependencies so it is unit-testable without
/// Riverpod; [conversationIndexerProvider] wires the app's providers into it.
class ConversationIndexer {
  ConversationIndexer({
    required AppDatabase db,
    required PropositionExtractor extractor,
    required EmbeddingProvider embedder,
    this.onProgress,
  })  : _db = db, // ignore: prefer_initializing_formals
        _extractor = extractor, // ignore: prefer_initializing_formals
        _embedder = embedder; // ignore: prefer_initializing_formals

  final AppDatabase _db;
  final PropositionExtractor _extractor;
  final EmbeddingProvider _embedder;

  /// Called as the job advances (state changes and per-turn completion) so app
  /// state can mirror it into [indexingProgressProvider]. Optional — direct
  /// unit tests can omit it and read the DB.
  final void Function(String conversationId, IndexingProgress progress)?
      onProgress;

  /// Conversations with an index job in flight *this process*, so a second
  /// trigger (e.g. a rapid reselect) never starts a concurrent job for the same
  /// conversation. The persisted `indexing` state guards across launches; this
  /// guards within one.
  static final Set<String> _inFlight = <String>{};

  /// True while [conversationId] has a live index job in this process.
  static bool isIndexing(String conversationId) =>
      _inFlight.contains(conversationId);

  /// Indexes [conversationId] if it is not already `indexed` (or is `stale`).
  /// A no-op — returns immediately — when the conversation is already indexed
  /// for the current embedding model, when a job is already in flight, or when
  /// the conversation has no turns. Safe to call fire-and-forget; never throws
  /// out (per-turn extract/embed failures are swallowed so one bad turn doesn't
  /// abort the whole index, and the conversation still lands `indexed`).
  Future<void> ensureIndexed(String conversationId) async {
    // Claim the in-flight slot synchronously — before the first await — so two
    // overlapping calls (e.g. a rapid reselect) can't both pass the guard while
    // the conversation lookup is still pending.
    if (!_inFlight.add(conversationId)) return;
    try {
      final conversation = await (_db.select(_db.conversations)
            ..where((c) => c.id.equals(conversationId)))
          .getSingleOrNull();
      if (conversation == null) return;

      // Already indexed for the current model? Then nothing to do — unless the
      // embedding model has changed (staleness), which forces a re-index.
      final current = IndexState.fromInt(conversation.indexState);
      if (current == IndexState.indexed && !await _isStale(conversationId)) {
        return;
      }

      await _run(conversation);
    } finally {
      _inFlight.remove(conversationId);
    }
  }

  Future<void> _run(Conversation conversation) async {
    final id = conversation.id;
    final projectId = conversation.projectId;

    final turns = await (_db.select(_db.turns)
          ..where((t) => t.conversationId.equals(id)))
        .get();

    // Zero-turn conversation: complete cleanly to indexed (nothing to extract).
    final ordered = indexOrder(turns, conversation.currentTurnId);
    var progress = IndexingProgress(
      state: IndexState.indexing,
      done: 0,
      total: ordered.length,
    );
    await _setState(id, IndexState.indexing);
    onProgress?.call(id, progress);

    final byId = {for (final t in turns) t.id: t};
    final modelId = _embedder.modelId;

    for (final turn in ordered) {
      try {
        final extraction = await _extractor.extract(
          turn,
          parentContext: _ancestors(turn, byId),
        );
        final texts = [for (final p in extraction.propositions) p.text];
        final embeddings =
            texts.isEmpty ? const <List<double>>[] : await _embedder.embed(texts);
        await _db.persistTurnExtraction(
          turnId: turn.id,
          conversationId: id,
          projectId: projectId,
          extraction: extraction,
          embeddings: embeddings,
          embeddingModel: modelId,
        );
      } catch (_) {
        // One turn failing (e.g. a model parse error) must not abort the whole
        // index; skip it — a later re-index can pick it up.
      }
      progress = progress.copyWith(done: progress.done + 1);
      onProgress?.call(id, progress);
      // Yield to the event loop between turns so a long conversation doesn't
      // jank the UI thread (the work is await-driven, so this stays on the main
      // isolate — DESIGN.md §10).
      await Future<void>.delayed(Duration.zero);
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    await _setState(id, IndexState.indexed, indexedAt: now);
    onProgress?.call(id, progress.copyWith(state: IndexState.indexed));
  }

  /// Root→[turn] ancestor path (exclusive of [turn]) for coref-resolving its
  /// propositions against earlier context (the shape `PropositionExtractor`
  /// expects). Walks `parent_turn_id` with a cycle guard.
  List<Turn> _ancestors(Turn turn, Map<String, Turn> byId) {
    final path = <Turn>[];
    final seen = <String>{turn.id};
    var cursor = turn.parentTurnId == null ? null : byId[turn.parentTurnId];
    while (cursor != null && seen.add(cursor.id)) {
      path.add(cursor);
      final parentId = cursor.parentTurnId;
      cursor = parentId == null ? null : byId[parentId];
    }
    return path.reversed.toList();
  }

  Future<void> _setState(String id, IndexState state, {int? indexedAt}) =>
      (_db.update(_db.conversations)..where((c) => c.id.equals(id))).write(
        ConversationsCompanion(
          indexState: Value(state.value),
          indexedAt:
              indexedAt == null ? const Value.absent() : Value(indexedAt),
        ),
      );

  /// True when [conversationId] is indexed but its stored propositions were
  /// embedded by a different model than the current provider's — so the dense
  /// vectors are no longer comparable and a re-index is required (DESIGN.md §10
  /// "re-embed only when the embedding model changes"). A conversation with no
  /// embedded propositions is not stale (nothing to invalidate).
  Future<bool> _isStale(String conversationId) async {
    final modelId = _embedder.modelId;
    final mismatched = await (_db.select(_db.propositions)
          ..where((p) =>
              p.conversationId.equals(conversationId) &
              p.embeddingModel.isNotNull() &
              p.embeddingModel.equals(modelId).not())
          ..limit(1))
        .getSingleOrNull();
    return mismatched != null;
  }

  /// If [conversationId] is `indexed` but its embeddings are from a different
  /// model (see [_isStale]), flip its persisted state to `stale` so the trigger
  /// re-indexes it. Returns whether it was marked stale. A full background
  /// re-embed of every session is a later step (M9.3); this handles the
  /// currently-opened conversation.
  Future<bool> markStaleIfModelChanged(String conversationId) async {
    final conversation = await (_db.select(_db.conversations)
          ..where((c) => c.id.equals(conversationId)))
        .getSingleOrNull();
    if (conversation == null) return false;
    if (IndexState.fromInt(conversation.indexState) != IndexState.indexed) {
      return false;
    }
    if (!await _isStale(conversationId)) return false;
    await _setState(conversationId, IndexState.stale);
    return true;
  }
}

/// Builds a [ConversationIndexer] from the app's providers, wiring per-turn
/// progress into [indexingProgressProvider]. The extractor / embedder resolve
/// to the offline stubs until a backend is configured, so indexing is fully
/// offline by default. Reading this provider touches
/// [propositionExtractorProvider] / [embeddingProviderProvider], which need
/// `sharedPreferencesProvider` — so the on-open trigger guards against that
/// (see [indexingEnabledProvider]).
final conversationIndexerProvider = Provider<ConversationIndexer>((ref) {
  return ConversationIndexer(
    db: ref.watch(databaseProvider),
    extractor: ref.watch(propositionExtractorProvider),
    embedder: ref.watch(embeddingProviderProvider),
    onProgress: (conversationId, progress) {
      ref
          .read(indexingProgressProvider.notifier)
          .update(conversationId, progress);
    },
  );
});

/// Whether the on-open indexing trigger is allowed to fire. Defaults to `true`
/// so the real app indexes on session open. Existing widget/integration tests
/// don't override `sharedPreferencesProvider` (the indexer's providers need
/// it), so the trigger guards itself and no-ops on any error — but a test can
/// also override this to `false` to disable it outright, or to `true` (with
/// prefs overridden) to exercise the on-open path.
final indexingEnabledProvider = Provider<bool>((ref) => true);

/// Fire-and-forget kick of the lazy index for [conversationId] when the
/// conversation is opened (DESIGN.md §10 "index on session open"). Never blocks
/// first paint and never throws into the caller: if indexing is disabled, or
/// building the indexer fails (e.g. `sharedPreferencesProvider` isn't overridden
/// in a widget test), it silently no-ops, so opening a conversation stays cheap
/// and existing tests stay green. Returns the running future for tests that want
/// to await it; UI callers ignore it.
Future<void> triggerIndexOnOpen(WidgetRef ref, String conversationId) async {
  if (!ref.read(indexingEnabledProvider)) return;
  ConversationIndexer indexer;
  try {
    indexer = ref.read(conversationIndexerProvider);
  } catch (_) {
    // Providers unavailable (e.g. prefs not overridden in a widget test):
    // opening a conversation must not depend on the index, so just skip.
    return;
  }
  try {
    // Re-embed on model change for the opened conversation before deciding
    // whether to (re)index.
    await indexer.markStaleIfModelChanged(conversationId);
    await indexer.ensureIndexed(conversationId);
  } catch (_) {
    // Indexing is best-effort; a failure never surfaces to the canvas.
  }
}
