import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart' show FocusNode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// All conversations, newest `update_time` first (DESIGN.md §6 sidebar).
/// A drift stream query: re-emits as the importer inserts rows.
final conversationListProvider = StreamProvider<List<Conversation>>((ref) {
  final db = ref.watch(databaseProvider);
  final query = db.select(db.conversations)
    ..orderBy([
      (c) => OrderingTerm(
            expression: c.updateTime,
            mode: OrderingMode.desc,
          ),
      (c) => OrderingTerm.desc(c.createTime),
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
