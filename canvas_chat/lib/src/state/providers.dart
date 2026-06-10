import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../domain/active_path.dart';

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

/// A conversation opened for reading: its row plus the active path through
/// its turn tree (M2's bare read mode walks this path with ↑/↓).
class ConversationPath {
  ConversationPath(this.conversation, this.path);

  final Conversation conversation;

  /// Active path, root → leaf. Empty for conversations without turns.
  final List<Turn> path;
}

final conversationPathProvider =
    StreamProvider.autoDispose.family<ConversationPath, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  final turnsQuery = db.select(db.turns)
    ..where((t) => t.conversationId.equals(id));
  return turnsQuery.watch().asyncMap((turns) async {
    final conversation = await (db.select(db.conversations)
          ..where((c) => c.id.equals(id)))
        .getSingle();
    return ConversationPath(
      conversation,
      activePath(turns, conversation.currentTurnId),
    );
  });
});
