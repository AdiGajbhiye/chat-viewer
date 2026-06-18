import '../data/db/database.dart';
import 'active_path.dart';

/// Grid layout for navigate mode (DESIGN.md §6).
///
/// Pure function of the turn tree — deterministic, recomputed on open, never
/// persisted. **Row = turn order** (depth in the turn tree), **column =
/// branch lane**, git-graph style:
///
/// - The active path (derived from `current_turn_id`) is laid out first and
///   occupies lane 0, one row per turn.
/// - At a fork, one child continues the parent's lane (the active-path child
///   if the fork is on the active path, otherwise the latest sibling — the
///   same "latest wins" rule [activePath] uses); each *additional* child
///   branch claims the nearest free lane to the right of the parent's lane,
///   starting at its fork row, and the whole branch continues downward in
///   that lane.
/// - A lane is "free" for a branch when no already-placed chain overlaps the
///   branch's row interval in that lane.
class TurnGridLayout {
  TurnGridLayout._({
    required this.cells,
    required this.edges,
    required this.rowCount,
    required this.laneCount,
    required this.activePathIds,
  }) : byId = {for (final c in cells) c.turn.id: c};

  /// All placed turns, in placement order (active path first).
  final List<GridCell> cells;

  final Map<String, GridCell> byId;

  /// Parent → child edges between placed turns.
  final List<GridEdge> edges;

  final int rowCount;
  final int laneCount;

  /// Ids on the active path, root → leaf.
  final List<String> activePathIds;

  bool get isEmpty => cells.isEmpty;
}

/// One turn placed on the grid.
class GridCell {
  GridCell({
    required this.turn,
    required this.row,
    required this.lane,
    required this.onActivePath,
    required this.childCount,
  });

  final Turn turn;
  final int row;
  final int lane;
  final bool onActivePath;

  /// Number of child turns (> 1 means this node is a fork parent).
  final int childCount;

  /// Grid neighbors for arrow navigation (DESIGN.md §6): above/below =
  /// parent/child following the edge, left/right = nearest cell by row in
  /// the adjacent lane. Filled in by [computeGridLayout].
  String? up, down, left, right;
}

/// Edge geometry kind (DESIGN.md §6): a [parentChild] edge runs vertically
/// down a lane into the branch's continuation; a [sibling] edge runs
/// horizontally across a row between fork alternatives.
enum GridEdgeKind { parentChild, sibling }

class GridEdge {
  GridEdge({
    required this.from,
    required this.to,
    required this.active,
    this.kind = GridEdgeKind.parentChild,
  });

  /// Source cell's turn id (the parent for [parentChild]; the left sibling
  /// for [sibling]).
  final String from;

  /// Target cell's turn id (the child for [parentChild]; the right sibling
  /// for [sibling]).
  final String to;

  /// True when both endpoints are on the active path (emphasized edge).
  final bool active;

  final GridEdgeKind kind;
}

TurnGridLayout computeGridLayout(List<Turn> turns, String? currentTurnId) {
  if (turns.isEmpty) {
    return TurnGridLayout._(
      cells: const [],
      edges: const [],
      rowCount: 0,
      laneCount: 0,
      activePathIds: const [],
    );
  }

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
  // Same deterministic sibling order as activePath: create_time, then id.
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

  final active = activePath(turns, currentTurnId);
  final activeIds = {for (final t in active) t.id};

  final cells = <GridCell>[];
  final cellById = <String, GridCell>{};
  // Per lane: occupied row intervals (inclusive), in placement order.
  final laneIntervals = <List<(int, int)>>[];

  bool isFree(int lane, int start, int end) {
    if (lane >= laneIntervals.length) return true;
    for (final (s, e) in laneIntervals[lane]) {
      if (start <= e && s <= end) return false;
    }
    return true;
  }

  void occupy(int lane, int start, int end) {
    while (laneIntervals.length <= lane) {
      laneIntervals.add([]);
    }
    laneIntervals[lane].add((start, end));
  }

  void placeChain(List<Turn> chain, int lane, int startRow) {
    occupy(lane, startRow, startRow + chain.length - 1);
    for (var i = 0; i < chain.length; i++) {
      final turn = chain[i];
      final cell = GridCell(
        turn: turn,
        row: startRow + i,
        lane: lane,
        onActivePath: activeIds.contains(turn.id),
        childCount: childrenOf[turn.id]?.length ?? 0,
      );
      cells.add(cell);
      cellById[turn.id] = cell;
    }
  }

  /// Follows the chain from [start]: at each fork the active-path child wins,
  /// otherwise the latest sibling (consistent with [activePath]).
  List<Turn> chainFrom(Turn start) {
    final chain = [start];
    final seen = {start.id};
    var cursor = start;
    while (true) {
      final children = childrenOf[cursor.id];
      if (children == null || children.isEmpty) break;
      cursor = children.firstWhere(
        (c) => activeIds.contains(c.id),
        orElse: () => children.last,
      );
      if (!seen.add(cursor.id)) break; // cycle guard for corrupt data
      chain.add(cursor);
    }
    return chain;
  }

  // Pending branches: (start turn, start row, first lane to try). Processed
  // smallest-startRow first so forks near the top claim the near lanes —
  // which keeps a fork's siblings (e.g. regenerated responses at the root)
  // in adjacent lanes even when a deeper branch was discovered first.
  final pending = <(Turn, int, int)>[];

  void enqueueBranches(List<Turn> chain, int startRow, int lane) {
    final inChain = {for (final t in chain) t.id};
    for (var i = 0; i < chain.length; i++) {
      final children = childrenOf[chain[i].id] ?? const <Turn>[];
      for (final child in children) {
        if (inChain.contains(child.id) || cellById.containsKey(child.id)) {
          continue;
        }
        pending.add((child, startRow + i + 1, lane + 1));
      }
    }
  }

  // 1. Active path → lane 0. activePath() is non-empty for non-empty input.
  placeChain(active, 0, 0);
  enqueueBranches(active, 0, 0);

  // 2. Remaining roots (rare: multiple roots) start at row 0, lanes ≥ 1.
  for (final root in roots) {
    if (!cellById.containsKey(root.id)) {
      pending.add((root, 0, 1));
    }
  }

  // 3. Place pending branches, topmost (smallest startRow) first so a fork's
  // branches settle into adjacent lanes before deeper branches grab them.
  while (pending.isNotEmpty) {
    var pick = 0;
    for (var i = 1; i < pending.length; i++) {
      if (pending[i].$2 < pending[pick].$2) pick = i;
    }
    final (start, startRow, fromLane) = pending.removeAt(pick);
    if (cellById.containsKey(start.id)) continue;
    final chain = chainFrom(start);
    var lane = fromLane;
    while (!isFree(lane, startRow, startRow + chain.length - 1)) {
      lane++;
    }
    placeChain(chain, lane, startRow);
    enqueueBranches(chain, startRow, lane);
  }

  // 4. Unreachable turns (cycles in corrupt data): park each in a fresh lane
  //    so every turn is at least visible.
  for (final turn in turns.toList()..sort(order)) {
    if (!cellById.containsKey(turn.id)) {
      placeChain([turn], laneIntervals.length, 0);
    }
  }

  // Edges (DESIGN.md §6): a vertical parent→child edge into the in-lane
  // continuation; horizontal sibling edges chaining a fork's alternatives
  // across their shared row. Fork branches are connected to each other (and
  // to the continuation) by sibling edges, not by a parent→child elbow.
  final edges = <GridEdge>[];
  // Group placed cells by parent (key null groups roots — themselves
  // alternative starts, hence siblings).
  final siblingGroups = <String?, List<GridCell>>{};
  for (final cell in cells) {
    (siblingGroups[cell.turn.parentTurnId] ??= []).add(cell);

    // Vertical edge only for the child continuing the parent's lane.
    final parentId = cell.turn.parentTurnId;
    final parent = parentId == null ? null : cellById[parentId];
    if (parent != null && cell.lane == parent.lane) {
      edges.add(GridEdge(
        from: parent.turn.id,
        to: cell.turn.id,
        active: parent.onActivePath && cell.onActivePath,
      ));
    }
  }
  // Horizontal edges between adjacent (by lane) siblings on the same row.
  for (final group in siblingGroups.values) {
    if (group.length < 2) continue;
    group.sort((a, b) => a.lane.compareTo(b.lane));
    for (var i = 0; i + 1 < group.length; i++) {
      final a = group[i];
      final b = group[i + 1];
      edges.add(GridEdge(
        from: a.turn.id,
        to: b.turn.id,
        active: a.onActivePath && b.onActivePath,
        kind: GridEdgeKind.sibling,
      ));
    }
  }

  // Neighbors. Lanes are contiguous (a lane is only ever claimed after the
  // ones left of it hold cells), so lane ± 1 always has candidates.
  final lanes = <int, List<GridCell>>{};
  for (final cell in cells) {
    (lanes[cell.lane] ??= []).add(cell);
  }
  GridCell? nearestInLane(int lane, int row) {
    final candidates = lanes[lane];
    if (candidates == null || candidates.isEmpty) return null;
    GridCell? best;
    var bestDistance = 0;
    for (final c in candidates) {
      final d = (c.row - row).abs();
      if (best == null || d < bestDistance) {
        best = c;
        bestDistance = d;
      }
    }
    return best;
  }

  var rowCount = 0;
  for (final cell in cells) {
    if (cell.row + 1 > rowCount) rowCount = cell.row + 1;
    final parentId = cell.turn.parentTurnId;
    cell.up = parentId != null && cellById.containsKey(parentId)
        ? parentId
        : null;
    // Down: the child continuing this lane if there is one, else the first
    // placed child.
    final children = (childrenOf[cell.turn.id] ?? const <Turn>[])
        .map((t) => cellById[t.id])
        .whereType<GridCell>()
        .toList();
    if (children.isNotEmpty) {
      cell.down = children
          .firstWhere((c) => c.lane == cell.lane, orElse: () => children.first)
          .turn
          .id;
    }
    cell.left = nearestInLane(cell.lane - 1, cell.row)?.turn.id;
    cell.right = nearestInLane(cell.lane + 1, cell.row)?.turn.id;
  }

  return TurnGridLayout._(
    cells: cells,
    edges: edges,
    rowCount: rowCount,
    laneCount: lanes.length,
    activePathIds: [for (final t in active) t.id],
  );
}
