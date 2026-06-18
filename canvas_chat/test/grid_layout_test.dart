import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/domain/grid_layout.dart';
import 'package:flutter_test/flutter_test.dart';

Turn turn(String id, {String? parent, int? time}) => Turn(
      id: id,
      conversationId: 'c',
      parentTurnId: parent,
      promptMd: 'prompt $id',
      responseMd: 'response $id',
      rawJson: '[]',
      createTime: time,
    );

(int, int) cellOf(TurnGridLayout layout, String id) {
  final cell = layout.byId[id]!;
  return (cell.row, cell.lane);
}

void main() {
  test('empty input yields empty layout', () {
    final layout = computeGridLayout(const [], null);
    expect(layout.isEmpty, isTrue);
    expect(layout.rowCount, 0);
    expect(layout.laneCount, 0);
  });

  test('linear chain occupies lane 0, one row per turn', () {
    final layout = computeGridLayout([
      turn('a', time: 1),
      turn('b', parent: 'a', time: 2),
      turn('c', parent: 'b', time: 3),
    ], 'c');
    expect(cellOf(layout, 'a'), (0, 0));
    expect(cellOf(layout, 'b'), (1, 0));
    expect(cellOf(layout, 'c'), (2, 0));
    expect(layout.rowCount, 3);
    expect(layout.laneCount, 1);
    expect(layout.activePathIds, ['a', 'b', 'c']);
    expect(layout.edges, hasLength(2));
    expect(layout.edges.every((e) => e.active), isTrue);
  });

  test('active path takes lane 0; fork branch claims lane 1 at its fork row',
      () {
    // root forks: old (inactive) and new -> new-child (active, current).
    final layout = computeGridLayout([
      turn('root', time: 1),
      turn('old', parent: 'root', time: 2),
      turn('old-child', parent: 'old', time: 3),
      turn('new', parent: 'root', time: 5),
      turn('new-child', parent: 'new', time: 6),
    ], 'new-child');
    expect(cellOf(layout, 'root'), (0, 0));
    expect(cellOf(layout, 'new'), (1, 0));
    expect(cellOf(layout, 'new-child'), (2, 0));
    // Inactive branch: starts at the fork row (1), in lane 1, continues down.
    expect(cellOf(layout, 'old'), (1, 1));
    expect(cellOf(layout, 'old-child'), (2, 1));
    expect(layout.laneCount, 2);

    // root continues into the active branch (new) with a vertical edge.
    final edgeRootNew = layout.edges.singleWhere((e) =>
        e.from == 'root' &&
        e.to == 'new' &&
        e.kind == GridEdgeKind.parentChild);
    expect(edgeRootNew.active, isTrue);
    // The other branch (old) is reached by a horizontal sibling edge, not a
    // parent→child edge from root.
    expect(layout.edges.any((e) => e.from == 'root' && e.to == 'old'), isFalse);
    final sibling =
        layout.edges.singleWhere((e) => e.kind == GridEdgeKind.sibling);
    expect((sibling.from, sibling.to), ('new', 'old'));
    expect(sibling.active, isFalse);
  });

  test('non-overlapping branches reuse lane 1; overlapping ones move right',
      () {
    // Active spine a-b-c-d with a fork at a (overlapping branch x-x2) and a
    // fork at c (branch y). x occupies lane 1 rows 1-2, so y (row 3) fits
    // back into lane 1.
    final layout = computeGridLayout([
      turn('a', time: 1),
      turn('b', parent: 'a', time: 4),
      turn('c', parent: 'b', time: 5),
      turn('d', parent: 'c', time: 6),
      turn('x', parent: 'a', time: 2),
      turn('x2', parent: 'x', time: 3),
      turn('y', parent: 'c', time: 2),
    ], 'd');
    expect(cellOf(layout, 'x'), (1, 1));
    expect(cellOf(layout, 'x2'), (2, 1));
    expect(cellOf(layout, 'y'), (3, 1));
    expect(layout.laneCount, 2);

    // Now make the first branch long enough to overlap row 3: y must move to
    // lane 2.
    final layout2 = computeGridLayout([
      turn('a', time: 1),
      turn('b', parent: 'a', time: 4),
      turn('c', parent: 'b', time: 5),
      turn('d', parent: 'c', time: 6),
      turn('x', parent: 'a', time: 2),
      turn('x2', parent: 'x', time: 3),
      turn('x3', parent: 'x2', time: 3),
      turn('y', parent: 'c', time: 2),
    ], 'd');
    expect(cellOf(layout2, 'x3'), (3, 1));
    expect(cellOf(layout2, 'y'), (3, 2));
    expect(layout2.laneCount, 3);
  });

  test('sub-branches fork off branches into further lanes', () {
    // Inactive branch x forks again at x into x2 (continues lane) and z.
    final layout = computeGridLayout([
      turn('a', time: 1),
      turn('b', parent: 'a', time: 9),
      turn('x', parent: 'a', time: 2),
      turn('x2', parent: 'x', time: 4),
      turn('z', parent: 'x', time: 3),
    ], 'b');
    expect(cellOf(layout, 'x'), (1, 1));
    // Latest sibling (x2) continues the branch lane, z claims the next lane.
    expect(cellOf(layout, 'x2'), (2, 1));
    expect(cellOf(layout, 'z'), (2, 2));
  });

  test('a fork sibling stays in the adjacent lane despite a deeper branch', () {
    // Two root siblings (e.g. regenerated responses): r-active (current) and
    // r-sib, which continues down to row 1. The active branch also has a
    // sub-fork (act-fork) at row 1. Topmost-first placement must give r-sib
    // lane 1 (adjacent to r-active) and push act-fork to lane 2 — otherwise
    // the sibling edge would have to jump a lane.
    final layout = computeGridLayout([
      turn('r-active', time: 2),
      turn('act-cont', parent: 'r-active', time: 5),
      turn('act-fork', parent: 'r-active', time: 4),
      turn('r-sib', time: 1),
      turn('sib-cont', parent: 'r-sib', time: 3),
    ], 'act-cont');
    expect(cellOf(layout, 'r-active'), (0, 0));
    expect(cellOf(layout, 'r-sib'), (0, 1)); // adjacent, not pushed right
    expect(cellOf(layout, 'sib-cont'), (1, 1));
    expect(cellOf(layout, 'act-fork'), (1, 2));

    // The two roots are siblings, joined by a horizontal edge on row 0.
    expect(
      layout.edges.any((e) =>
          e.kind == GridEdgeKind.sibling &&
          e.from == 'r-active' &&
          e.to == 'r-sib'),
      isTrue,
    );
  });

  test('neighbors follow grid semantics', () {
    final layout = computeGridLayout([
      turn('root', time: 1),
      turn('old', parent: 'root', time: 2),
      turn('old-child', parent: 'old', time: 3),
      turn('new', parent: 'root', time: 5),
      turn('new-child', parent: 'new', time: 6),
    ], 'new-child');

    final root = layout.byId['root']!;
    expect(root.up, isNull);
    expect(root.down, 'new'); // same-lane child preferred
    expect(root.left, isNull);
    expect(root.right, 'old'); // nearest in lane 1 to row 0 is row 1

    final newCell = layout.byId['new']!;
    expect(newCell.up, 'root');
    expect(newCell.down, 'new-child');
    expect(newCell.right, 'old'); // same row, lane 1

    final old = layout.byId['old']!;
    expect(old.up, 'root'); // follows the edge across lanes
    expect(old.down, 'old-child');
    expect(old.left, 'new'); // nearest in lane 0 at same row
    expect(old.right, isNull);

    // Fork parent child-count is exposed for the ⑂ badge.
    expect(root.childCount, 2);
    expect(newCell.childCount, 1);
  });

  test('multiple roots: extra root parks in a free lane at row 0', () {
    final layout = computeGridLayout([
      turn('a', time: 1),
      turn('a2', parent: 'a', time: 2),
      turn('b', time: 3),
    ], 'a2');
    expect(cellOf(layout, 'a'), (0, 0));
    expect(cellOf(layout, 'a2'), (1, 0));
    expect(cellOf(layout, 'b'), (0, 1));
  });

  test('cycles in corrupt data still place every turn', () {
    final layout = computeGridLayout([
      turn('a', time: 1),
      turn('loop1', parent: 'loop2', time: 2),
      turn('loop2', parent: 'loop1', time: 3),
    ], 'a');
    expect(layout.byId.length, 3);
    expect(layout.byId.keys, containsAll(['a', 'loop1', 'loop2']));
  });
}
