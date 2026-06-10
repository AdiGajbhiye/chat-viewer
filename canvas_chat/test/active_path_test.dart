import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/domain/active_path.dart';
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

List<String> ids(List<Turn> path) => [for (final t in path) t.id];

void main() {
  test('empty tree yields empty path', () {
    expect(activePath(const [], null), isEmpty);
    expect(activePath(const [], 'x'), isEmpty);
  });

  test('linear chain returns all turns in order', () {
    final turns = [
      turn('c', parent: 'b', time: 3),
      turn('a', time: 1),
      turn('b', parent: 'a', time: 2),
    ];
    expect(ids(activePath(turns, 'c')), ['a', 'b', 'c']);
  });

  test('current turn picks its branch at a fork', () {
    final turns = [
      turn('root', time: 1),
      turn('left', parent: 'root', time: 2),
      turn('right', parent: 'root', time: 3),
      turn('left-child', parent: 'left', time: 4),
    ];
    expect(ids(activePath(turns, 'left-child')),
        ['root', 'left', 'left-child']);
    // The fork's other branch via its leaf:
    expect(ids(activePath(turns, 'right')), ['root', 'right']);
  });

  test('mid-path current turn extends down to a leaf, latest sibling first',
      () {
    final turns = [
      turn('root', time: 1),
      turn('old', parent: 'root', time: 2),
      turn('new', parent: 'root', time: 5),
      turn('new-child', parent: 'new', time: 6),
    ];
    // current = root (not a leaf): extend through the latest sibling.
    expect(ids(activePath(turns, 'root')), ['root', 'new', 'new-child']);
  });

  test('missing or unknown current turn falls back to latest branch', () {
    final turns = [
      turn('root', time: 1),
      turn('a', parent: 'root', time: 2),
      turn('b', parent: 'root', time: 3),
    ];
    expect(ids(activePath(turns, null)), ['root', 'b']);
    expect(ids(activePath(turns, 'nonexistent')), ['root', 'b']);
  });

  test('turn with dangling parent id is treated as a root', () {
    final turns = [
      turn('orphan', parent: 'gone', time: 1),
      turn('child', parent: 'orphan', time: 2),
    ];
    expect(ids(activePath(turns, null)), ['orphan', 'child']);
  });

  test('cycles in corrupt data terminate', () {
    final turns = [
      turn('a', parent: 'b', time: 1),
      turn('b', parent: 'a', time: 2),
    ];
    final path = activePath(turns, 'a');
    expect(path, isNotEmpty);
    expect(path.length, lessThanOrEqualTo(2));
  });
}
