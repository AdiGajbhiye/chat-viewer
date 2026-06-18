import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/domain/grid_layout.dart';
import 'package:canvas_chat/src/ui/canvas/canvas_metrics.dart';
import 'package:flutter/widgets.dart';
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

GridCell cellAt(int row, int lane) => GridCell(
      turn: turn('t'),
      row: row,
      lane: lane,
      onActivePath: false,
      childCount: 0,
    );

void main() {
  // Mirror the constants so a silent change to geometry is caught here.
  const w = 480.0, h = 282.0, laneGap = 56.0, rowGap = 44.0, pad = 48.0;

  group('cellOrigin', () {
    test('first cell sits at the padding corner', () {
      expect(CanvasMetrics.cellOrigin(0, 0), const Offset(pad, pad));
    });

    test('rows step by cardHeight + rowGap, lanes by cardWidth + laneGap', () {
      expect(CanvasMetrics.cellOrigin(1, 0), const Offset(pad, pad + h + rowGap));
      expect(CanvasMetrics.cellOrigin(0, 1), const Offset(pad + w + laneGap, pad));
      expect(
        CanvasMetrics.cellOrigin(2, 3),
        const Offset(pad + 3 * (w + laneGap), pad + 2 * (h + rowGap)),
      );
    });
  });

  group('cellRect', () {
    test('is the origin sized to one card', () {
      final rect = CanvasMetrics.cellRect(cellAt(2, 1));
      expect(rect.topLeft, CanvasMetrics.cellOrigin(2, 1));
      expect(rect.size, const Size(w, h));
    });
  });

  group('contentSize', () {
    test('empty layout is just the surrounding padding, never negative', () {
      // The general gap formula would underflow to 2*pad - gap here; the
      // empty case must short-circuit to a 2*pad square instead.
      final size = CanvasMetrics.contentSize(computeGridLayout(const [], null));
      expect(size, const Size(2 * pad, 2 * pad));
    });

    test('a linear chain spans one lane and one row per turn', () {
      final layout = computeGridLayout([
        turn('a', time: 1),
        turn('b', parent: 'a', time: 2),
        turn('c', parent: 'b', time: 3),
      ], 'c');
      expect(layout.laneCount, 1);
      expect(layout.rowCount, 3);
      // One lane: no inter-lane gap. Three rows: two inter-row gaps.
      expect(
        CanvasMetrics.contentSize(layout),
        const Size(2 * pad + w, 2 * pad + 3 * h + 2 * rowGap),
      );
    });

    test('counts the inter-lane gap once a fork claims a second lane', () {
      final layout = computeGridLayout([
        turn('root', time: 1),
        turn('old', parent: 'root', time: 2),
        turn('new', parent: 'root', time: 5),
        turn('new-child', parent: 'new', time: 6),
      ], 'new-child');
      expect(layout.laneCount, 2);
      expect(layout.rowCount, 3);
      expect(
        CanvasMetrics.contentSize(layout),
        const Size(2 * pad + 2 * w + laneGap, 2 * pad + 3 * h + 2 * rowGap),
      );
    });

    test('equals the far cell rect inflated by one padding (gap invariant)', () {
      // Ties cellRect and contentSize together: the content box is exactly the
      // bottom-right cell plus a padding margin. Catches an off-by-one in the
      // (n-1)*gap term regardless of the specific dimensions.
      final layout = computeGridLayout([
        turn('a', time: 1),
        turn('b', parent: 'a', time: 4),
        turn('c', parent: 'b', time: 5),
        turn('x', parent: 'a', time: 2),
        turn('x2', parent: 'x', time: 3),
      ], 'c');
      final farCell = CanvasMetrics.cellOrigin(
        layout.rowCount - 1,
        layout.laneCount - 1,
      ) &
          const Size(w, h);
      final size = CanvasMetrics.contentSize(layout);
      expect(size.width, farCell.right + pad);
      expect(size.height, farCell.bottom + pad);
    });
  });
}
