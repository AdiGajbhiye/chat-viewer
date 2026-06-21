import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/domain/grid_layout.dart';
import 'package:canvas_chat/src/ui/canvas/canvas_metrics.dart';
import 'package:canvas_chat/src/ui/canvas/edge_painter.dart';
import 'package:flutter/material.dart';
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

/// A [Canvas] that only counts the draw calls [EdgePainter] makes, so a test
/// can assert which edges survived culling without a real surface.
class _RecordingCanvas implements Canvas {
  int lines = 0;
  int paths = 0;

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) => lines++;

  @override
  void drawPath(Path path, Paint paint) => paths++;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  // A root with two children: the active child continues lane 0 (vertical
  // parent→child edges drawn as paths) and gets its own child; the fork sibling
  // lands in lane 1 (a horizontal sibling edge drawn as a line). So the layout
  // carries both edge kinds.
  final layout = computeGridLayout([
    turn('root', time: 1),
    turn('a', parent: 'root', time: 2),
    turn('c', parent: 'a', time: 4),
    turn('b', parent: 'root', time: 3),
  ], 'c');

  final verticals =
      layout.edges.where((e) => e.kind == GridEdgeKind.parentChild).length;
  final siblings =
      layout.edges.where((e) => e.kind == GridEdgeKind.sibling).length;

  EdgePainter painterFor(Rect visibleRect) => EdgePainter(
        layout: layout,
        visibleRect: visibleRect,
        activeColor: const Color(0xFF000000),
        dimColor: const Color(0x88000000),
      );

  group('culling', () {
    test('a viewport over the whole graph draws every edge', () {
      expect(verticals, 2); // root→a, a→c
      expect(siblings, 1); // a↔b

      final canvas = _RecordingCanvas();
      painterFor(const Rect.fromLTWH(-1000, -1000, 100000, 100000))
          .paint(canvas, const Size(100000, 100000));

      expect(canvas.paths, verticals);
      expect(canvas.lines, siblings);
    });

    test('a viewport far from the graph draws nothing', () {
      final canvas = _RecordingCanvas();
      painterFor(const Rect.fromLTWH(1000000, 1000000, 100, 100))
          .paint(canvas, const Size(100000, 100000));

      expect(canvas.paths, 0);
      expect(canvas.lines, 0);
    });

    test('a viewport over only the top edge keeps it and culls the rest', () {
      // Tightly box the root→a edge (top of lane 0). The deeper a→c edge and
      // the lane-1 sibling edge fall outside the inflated cull rect.
      final topEdge = Rect.fromPoints(
        CanvasMetrics.cellRect(layout.byId['root']!).center,
        CanvasMetrics.cellRect(layout.byId['a']!).center,
      );

      final canvas = _RecordingCanvas();
      painterFor(topEdge).paint(canvas, const Size(100000, 100000));

      expect(canvas.paths, 1);
      expect(canvas.lines, 0);
    });
  });

  group('shouldRepaint', () {
    const rect = Rect.fromLTWH(0, 0, 500, 500);
    const active = Color(0xFF111111);
    const dim = Color(0x88111111);
    final base = EdgePainter(
        layout: layout, visibleRect: rect, activeColor: active, dimColor: dim);

    test('no repaint when nothing changed', () {
      expect(
        base.shouldRepaint(EdgePainter(
            layout: layout,
            visibleRect: rect,
            activeColor: active,
            dimColor: dim)),
        isFalse,
      );
    });

    test('repaints when the layout changes', () {
      final other = computeGridLayout([turn('x', time: 1)], 'x');
      expect(
        base.shouldRepaint(EdgePainter(
            layout: other,
            visibleRect: rect,
            activeColor: active,
            dimColor: dim)),
        isTrue,
      );
    });

    test('repaints when the visible rect changes (scroll/zoom)', () {
      expect(
        base.shouldRepaint(EdgePainter(
            layout: layout,
            visibleRect: rect.shift(const Offset(1, 0)),
            activeColor: active,
            dimColor: dim)),
        isTrue,
      );
    });

    test('repaints when a theme color changes', () {
      expect(
        base.shouldRepaint(EdgePainter(
            layout: layout,
            visibleRect: rect,
            activeColor: const Color(0xFF222222),
            dimColor: dim)),
        isTrue,
      );
    });
  });
}
