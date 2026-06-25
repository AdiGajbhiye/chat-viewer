import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart' show FocusNode;
import 'package:flutter/material.dart' show Brightness, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/db/database.dart';
import '../domain/grid_layout.dart';

/// The app database. Overridden in `main()` (and in tests) with a concrete
/// instance — there is no sensible default.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw StateError('databaseProvider must be overridden'),
);

/// Directory imported assets are copied into. Overridden in `main()`.
final assetsDirProvider = Provider<Directory>(
  (ref) => throw StateError('assetsDirProvider must be overridden'),
);

/// The app's key/value store for small settings (the LLM connection config).
/// Loaded once and overridden in `main()`; tests that touch settings override
/// it with a `SharedPreferences.getInstance()` after `setMockInitialValues`.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw StateError('sharedPreferencesProvider must be overridden'),
);

/// All conversations, most-recent activity first (DESIGN.md §6 sidebar).
/// Ordered by `last_message_at` (the real time of the latest message),
/// falling back to the export's `update_time`/`create_time` only when no turn
/// is timestamped — the header `update_time` alone is unreliable (server-side
/// touches re-stamp old conversations as recent). A drift stream query: it
/// re-emits as the importer inserts rows.
final conversationListProvider = StreamProvider<List<Conversation>>((ref) {
  final db = ref.watch(databaseProvider);
  final query = db.select(db.conversations)
    ..orderBy([
      (c) => OrderingTerm.desc(
            coalesce([c.lastMessageAt, c.updateTime, c.createTime]),
          ),
      (c) => OrderingTerm.desc(c.id),
    ]);
  return query.watch();
});

/// Current sidebar search text; '' = no filter (M5, DESIGN.md §6 sidebar).
final searchQueryProvider =
    NotifierProvider<SearchQuery, String>(SearchQuery.new);

class SearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;
}

/// FTS results for a non-empty sidebar search: title matches first (newest
/// first), then prompt/response FTS matches by rank. One-shot per query —
/// search results don't need to live-update during an import.
final searchResultsProvider =
    FutureProvider.autoDispose.family<List<Conversation>, String>((ref, query) {
  final db = ref.watch(databaseProvider);
  return db.searchConversations(query);
});

/// Focus node of the sidebar search field, exposed so the macOS Find menu
/// item / ⌘F shortcut can focus it from anywhere.
final searchFocusNodeProvider = Provider<FocusNode>((ref) {
  final node = FocusNode(debugLabel: 'conversation search');
  ref.onDispose(node.dispose);
  return node;
});

/// Word-based FTS over the open conversation's turns ("find in conversation"):
/// turn ids whose prompt/response match [query], best match first. One-shot
/// per (conversation, query) — a blank query yields no matches. The query
/// itself is owned by the canvas view, so it resets when the conversation
/// changes.
final canvasSearchResultsProvider = FutureProvider.autoDispose
    .family<List<String>, ({String conversationId, String query})>((ref, args) {
  if (args.query.trim().isEmpty) return Future.value(const []);
  final db = ref.watch(databaseProvider);
  return db.searchTurnIds(args.query, conversationId: args.conversationId);
});

/// Assets referenced by one turn (`turn_assets` rows), for resolving the
/// `asset://<pointerId>` markers in its markdown (M5).
final turnAssetsProvider =
    FutureProvider.autoDispose.family<List<TurnAsset>, String>((ref, turnId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.turnAssets)..where((a) => a.turnId.equals(turnId)))
      .get();
});

/// Light / dark / system theme selection. Defaults to following the OS;
/// the sidebar toggle flips it to an explicit light or dark mode.
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  /// Flip to the opposite of what's currently on screen. [platformBrightness]
  /// is the OS brightness, used to resolve [ThemeMode.system] before flipping.
  void toggle(Brightness platformBrightness) {
    final isDark = switch (state) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => platformBrightness == Brightness.dark,
    };
    state = isDark ? ThemeMode.light : ThemeMode.dark;
  }
}

/// Whether the canvas draws the soft-edge layer (DESIGN.md §10 "Soft edges").
/// **Default off** — associative links can clutter the map, so they're opt-in.
/// Ephemeral session state (not persisted): a fresh launch starts hidden. When
/// off, the soft-edge provider/painter do no work (the layer isn't built).
final showSoftEdgesProvider =
    NotifierProvider<ShowSoftEdges, bool>(ShowSoftEdges.new);

class ShowSoftEdges extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

/// Conversation selected in the sidebar; null = nothing selected.
final selectedConversationIdProvider =
    NotifierProvider<SelectedConversationId, String?>(
  SelectedConversationId.new,
);

class SelectedConversationId extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

/// Persisted canvas state for a conversation — mode / focused turn /
/// viewport (DESIGN.md §4 `canvas_state`). One-shot read used to *restore*
/// state when a canvas opens; deliberately not a stream so the canvas's own
/// writes never feed back into it.
final canvasStateProvider =
    FutureProvider.autoDispose.family<CanvasState?, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.canvasStates)
        ..where((s) => s.conversationId.equals(id)))
      .getSingleOrNull();
});

/// A conversation opened on the canvas: its row plus the grid layout of its
/// full turn tree (M3 navigate mode). Layout is a pure function of the tree,
/// recomputed whenever the turns change (DESIGN.md §6).
class ConversationGraph {
  ConversationGraph(this.conversation, this.layout);

  final Conversation conversation;
  final TurnGridLayout layout;
}

final conversationGraphProvider =
    StreamProvider.autoDispose.family<ConversationGraph, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  final turnsQuery = db.select(db.turns)
    ..where((t) => t.conversationId.equals(id));
  return turnsQuery.watch().asyncMap((turns) async {
    final conversation = await (db.select(db.conversations)
          ..where((c) => c.id.equals(id)))
        .getSingle();
    return ConversationGraph(
      conversation,
      computeGridLayout(turns, conversation.currentTurnId),
    );
  });
});

/// The **renderable** soft edges of an open conversation (DESIGN.md §10 "Soft
/// edges"): the precomputed `soft_edges` whose **both** endpoints are turns in
/// this conversation, so the canvas layer can map each to its two `GridCell`s.
///
/// `crossSession` edges (and any whose endpoints aren't both on this grid) are
/// dropped — cross-canvas rendering is a later step (M9.3). This is a one-shot
/// read (soft edges only change when the conversation is (re)indexed, which the
/// canvas isn't watching live), scoped per `conversationId`, so it resets when
/// the conversation changes. Returns `[]` for an unindexed conversation.
final softEdgesForConversationProvider = FutureProvider.autoDispose
    .family<List<SoftEdge>, String>((ref, conversationId) async {
  final db = ref.watch(databaseProvider);
  final turnIds = await (db.selectOnly(db.turns)
        ..addColumns([db.turns.id])
        ..where(db.turns.conversationId.equals(conversationId)))
      .map((row) => row.read(db.turns.id)!)
      .get();
  if (turnIds.isEmpty) return const [];
  final turnIdSet = turnIds.toSet();
  // Pull every non-crossSession edge touching one of this conversation's turns,
  // then keep only those whose *other* endpoint is also in-conversation. Both
  // endpoints must be on this grid for the painter to place the edge.
  final rows = await (db.select(db.softEdges)
        ..where((e) =>
            e.kind.isNotValue('crossSession') &
            (e.fromTurnId.isIn(turnIds) | e.toTurnId.isIn(turnIds))))
      .get();
  return [
    for (final e in rows)
      if (turnIdSet.contains(e.fromTurnId) && turnIdSet.contains(e.toTurnId)) e,
  ];
});
