import '../data/db/database.dart';

/// Computes the **active path** (root → leaf) through a conversation's turn
/// tree: the branch ChatGPT displayed last, derived from
/// `conversations.current_turn_id` (DESIGN.md §2).
///
/// Rules:
/// - The path is the chain of ancestors of the current turn, extended down
///   to a leaf if the current turn has children.
/// - Wherever a choice between sibling branches has to be made without
///   guidance from `current_turn_id` (missing/unresolvable id, or extension
///   below the current turn), the most recently created sibling wins —
///   matching ChatGPT's behavior of displaying the latest edit/regeneration.
/// - Sibling order is deterministic: `create_time`, then id (same rule the
///   turn-pairing uses).
List<Turn> activePath(List<Turn> turns, String? currentTurnId) {
  if (turns.isEmpty) return const [];

  final byId = {for (final t in turns) t.id: t};
  final roots = <Turn>[];
  final childrenOf = <String, List<Turn>>{};
  for (final t in turns) {
    final parent = t.parentTurnId;
    if (parent == null || !byId.containsKey(parent)) {
      roots.add(t);
    } else {
      (childrenOf[parent] ??= []).add(t);
    }
  }
  int order(Turn a, Turn b) {
    final ta = a.createTime;
    final tb = b.createTime;
    if (ta != null && tb != null && ta != tb) return ta.compareTo(tb);
    if (ta == null && tb != null) return -1;
    if (ta != null && tb == null) return 1;
    return a.id.compareTo(b.id);
  }

  roots.sort(order);
  for (final children in childrenOf.values) {
    children.sort(order);
  }

  // Walk up from the current turn to its root (guarding against cycles in
  // corrupt data).
  final path = <Turn>[];
  final seen = <String>{};
  var cursor = currentTurnId == null ? null : byId[currentTurnId];
  while (cursor != null && seen.add(cursor.id)) {
    path.add(cursor);
    final parent = cursor.parentTurnId;
    cursor = parent == null ? null : byId[parent];
  }
  final upward = path.reversed.toList();

  // Extend down to a leaf, picking the latest sibling at each fork. When the
  // current turn was unresolvable this walks the whole path from the latest
  // root.
  if (upward.isEmpty) {
    // Corrupt data can have no roots at all (every parent pointer part of a
    // cycle); fall back to the oldest turn so we still show something.
    final root =
        roots.isNotEmpty ? roots.last : (turns.toList()..sort(order)).first;
    seen.add(root.id);
    upward.add(root);
  }
  var tail = upward.last;
  while (true) {
    final children = childrenOf[tail.id];
    if (children == null || children.isEmpty) break;
    tail = children.last;
    if (!seen.add(tail.id)) break;
    upward.add(tail);
  }
  return upward;
}
