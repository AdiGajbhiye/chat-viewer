import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import 'indexing.dart';
import 'providers.dart';
import 'soft_edges.dart';

/// Idle-time **index backfill** (DESIGN.md §10 "Cross-session retrieval only
/// sees already-opened sessions until an idle-time background backfill exists").
///
/// The lazy indexer (M7) only indexes a conversation when it is *opened*, so
/// `project`/`all`-scope retrieval would otherwise span just the sessions the
/// user happened to visit. This service closes that gap: when the app is idle
/// it walks the conversations whose `index_state != indexed` and runs the exact
/// same `ensureIndexed` (+ soft-edge precompute) chain the on-open trigger uses,
/// so the whole project eventually becomes retrievable.
///
/// It is deliberately **low-priority & polite**:
/// - One conversation at a time, yielding (a [pacing] delay) between each, so a
///   long backfill never monopolises the isolate or janks the UI.
/// - **Pausable** mid-run via [isPaused] (re-checked before each conversation),
///   and **cancellable** via [cancel] — the pause/cancel callbacks are read
///   live, so a flip takes effect at the next conversation boundary.
/// - **Yields to the foreground**: it never starts (or continues) a conversation
///   that a foreground open-session index is already processing
///   ([ConversationIndexer.isIndexing]) — the open-session index wins, and the
///   backfill picks the conversation up on a later pass if still needed.
/// - **Offline-safe & idempotent**: `ensureIndexed` no-ops on an
///   already-indexed conversation and swallows per-turn failures, and the
///   embedder/extractor resolve to the offline stubs until a backend is
///   configured — so under stubs this is deterministic and spends no tokens.
///   With a real embedding API it spends tokens, hence the prominent pause.
///
/// `crossSession` soft edges are intentionally **not** computed here: a true
/// cross-conversation k-NN over every indexed turn is O(n²) across the whole
/// project and order-dependent, and retrieval does not need it
/// (project-scope dense search already spans all indexed conversations). It is
/// left as future work; `recomputeForConversation` only ever (re)writes the
/// intra-conversation semantic/entity edges.
///
/// Constructed with explicit dependencies so it is unit-testable without
/// Riverpod; [indexBackfillerProvider] wires the app's providers into it.
class IndexBackfiller {
  IndexBackfiller({
    required AppDatabase db,
    required ConversationIndexer indexer,
    required SoftEdgeComputer softEdges,
    this.isPaused = _never,
    this.pacing = const Duration(milliseconds: 50),
  })  : _db = db, // ignore: prefer_initializing_formals
        _indexer = indexer, // ignore: prefer_initializing_formals
        _softEdges = softEdges; // ignore: prefer_initializing_formals

  final AppDatabase _db;
  final ConversationIndexer _indexer;
  final SoftEdgeComputer _softEdges;

  /// Read live before each conversation: when it returns `true` the backfill
  /// stops advancing (without cancelling — a later [runOnce] resumes where the
  /// remaining work is). Defaults to never-paused.
  final bool Function() isPaused;

  /// Delay yielded between conversations so the backfill stays in the
  /// background of the event loop. Small but non-zero so the UI thread always
  /// gets a turn even on a fast (stub) embedder.
  final Duration pacing;

  static bool _never() => false;

  /// True while a [runOnce] pass is live, so the trigger never starts a second
  /// overlapping backfill in this process.
  bool _running = false;
  bool get isRunning => _running;

  /// Set by [cancel] to abandon the current pass at the next boundary.
  bool _cancelled = false;

  /// Abandons the in-flight pass (if any) at the next conversation boundary.
  /// Idempotent and safe to call when nothing is running.
  void cancel() => _cancelled = true;

  /// Indexes (and soft-edge-precomputes) every not-yet-indexed conversation,
  /// one at a time, oldest-activity first, until none remain, the pass is
  /// [cancel]led, or [isPaused] flips on. A no-op when everything is already
  /// indexed. Best-effort: never throws — a conversation that fails to index is
  /// skipped (its persisted state is left for a later pass). Returns the number
  /// of conversations it carried to `indexed` this pass (for tests/telemetry).
  ///
  /// Re-entrant calls are rejected (returns 0) so two triggers can't run
  /// concurrent passes; the persisted `index_state` is the cross-pass source of
  /// truth, so a fresh pass resumes cleanly.
  Future<int> runOnce() async {
    if (_running) return 0;
    _running = true;
    _cancelled = false;
    var indexed = 0;
    try {
      while (!_cancelled && !isPaused()) {
        final next = await _nextPending();
        if (next == null) break; // nothing left to do
        // Re-check the live brakes after the (awaited) lookup — a cancel/pause
        // raised mid-pass takes effect at this conversation boundary, before
        // any new work is started.
        if (_cancelled || isPaused()) break;
        // Never fight a foreground open-session index for the same
        // conversation; skip it this pass and let the next one pick it up.
        if (ConversationIndexer.isIndexing(next.id)) {
          await _yield();
          continue;
        }
        try {
          await _indexer.ensureIndexed(next.id);
          // Mirror the on-open chain: precompute this conversation's soft edges
          // from the freshly persisted propositions + entities. Offline and
          // idempotent.
          await _softEdges.recomputeForConversation(next.id);
          indexed++;
        } catch (_) {
          // One conversation failing must not abort the whole backfill; skip it.
        }
        // Yield between conversations so the backfill stays polite. Re-check
        // pause/cancel happens at the top of the loop after this yield.
        await _yield();
      }
    } finally {
      _running = false;
    }
    return indexed;
  }

  /// The oldest-activity conversation still needing an index (`index_state` is
  /// not `indexed`), or null when none remain. Ordered so the backfill is
  /// deterministic and progresses front-to-back; `indexing`-state rows are
  /// included (a crashed/in-flight index re-runs idempotently).
  Future<Conversation?> _nextPending() async {
    return (_db.select(_db.conversations)
          ..where((c) => c.indexState.isNotValue(IndexState.indexed.value))
          ..orderBy([
            (c) => OrderingTerm.asc(
                  coalesce([c.lastMessageAt, c.updateTime, c.createTime]),
                ),
            (c) => OrderingTerm.asc(c.id),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> _yield() => Future<void>.delayed(pacing);
}

/// Whether the idle-time backfill is allowed to run at all (DESIGN.md §10).
/// **Defaults to `true`** so a launched app eventually indexes the whole
/// project; existing widget/integration tests don't override
/// `sharedPreferencesProvider` (the backfiller's indexer needs it), so the
/// trigger guards itself and no-ops on any error. A test (or a future settings
/// toggle) can override this to `false` to disable backfill outright. Distinct
/// from [backfillPausedProvider]: this is the hard on/off; pause is the live,
/// resumable brake.
final backfillEnabledProvider = Provider<bool>((ref) => true);

/// The live, resumable pause brake on the running backfill (DESIGN.md §10
/// "clearly pausable"). **Defaults to `false`** (not paused). Flipping it to
/// `true` halts the current pass at the next conversation boundary without
/// losing progress (the persisted `index_state` is the source of truth);
/// flipping back and re-triggering resumes. Surfaced so a UI control can offer
/// "pause background indexing" — important because with a real embedding API a
/// backfill spends tokens.
final backfillPausedProvider =
    NotifierProvider<BackfillPaused, bool>(BackfillPaused.new);

class BackfillPaused extends Notifier<bool> {
  @override
  bool build() => false;

  void pause() => state = true;
  void resume() => state = false;
  void toggle() => state = !state;
}

/// Builds an [IndexBackfiller] from the app's providers, reusing the same
/// [conversationIndexerProvider] / [softEdgeComputerProvider] the on-open
/// trigger uses (no duplicated indexing logic — the backfill only orchestrates).
/// The pause check reads [backfillPausedProvider] live. Reading this provider
/// touches the indexer's providers, which need `sharedPreferencesProvider` —
/// so [triggerBackfill] guards against that (mirrors [triggerIndexOnOpen]).
final indexBackfillerProvider = Provider<IndexBackfiller>((ref) {
  return IndexBackfiller(
    db: ref.watch(databaseProvider),
    indexer: ref.watch(conversationIndexerProvider),
    softEdges: ref.watch(softEdgeComputerProvider),
    isPaused: () => ref.read(backfillPausedProvider),
  );
});

/// Fire-and-forget kick of the idle-time index backfill (DESIGN.md §10). Never
/// blocks and never throws into the caller: if backfill is disabled, paused, or
/// building the backfiller fails (e.g. `sharedPreferencesProvider` isn't
/// overridden in a widget test), it silently no-ops — so launching/opening the
/// app stays cheap and existing tests stay green. Returns the running future
/// for tests that want to await it; UI callers ignore it.
Future<void> triggerBackfill(WidgetRef ref) async {
  if (!ref.read(backfillEnabledProvider)) return;
  if (ref.read(backfillPausedProvider)) return;
  IndexBackfiller backfiller;
  try {
    backfiller = ref.read(indexBackfillerProvider);
  } catch (_) {
    // Providers unavailable (e.g. prefs not overridden in a widget test):
    // backfill is best-effort, so just skip.
    return;
  }
  try {
    await backfiller.runOnce();
  } catch (_) {
    // The backfill is best-effort; a failure never surfaces to the UI.
  }
}
