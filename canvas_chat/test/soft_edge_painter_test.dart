import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/domain/grid_layout.dart';
import 'package:canvas_chat/src/ui/canvas/canvas_metrics.dart';
import 'package:canvas_chat/src/ui/canvas/soft_edge_painter.dart';
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

SoftEdge edge(String from, String to, {String kind = 'semantic', double w = 0.7}) =>
    SoftEdge(
      fromTurnId: from,
      toTurnId: to,
      kind: kind,
      weight: w,
      projectId: 'default',
    );

/// A [Canvas] that only counts the dashed sub-path draws [SoftEdgePainter]
/// makes, so a test can assert which edges survived culling without a surface.
class _RecordingCanvas implements Canvas {
  int paths = 0;

  @override
  void drawPath(Path path, Paint paint) => paths++;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  // A deep linear chain so the two soft-edge endpoints are far apart on the
  // grid (the layer connects distant cells, not just neighbours).
  final layout = computeGridLayout([
    turn('t0', time: 1),
    turn('t1', parent: 't0', time: 2),
    turn('t2', parent: 't1', time: 3),
    turn('t3', parent: 't2', time: 4),
  ], 't3');

  SoftEdgePainter painterFor(Rect visibleRect, List<SoftEdge> edges) =>
      SoftEdgePainter(
        layout: layout,
        edges: edges,
        visibleRect: visibleRect,
        semanticColor: const Color(0xFF00AA00),
        entityColor: const Color(0xFF0000AA),
      );

  group('culling', () {
    test('a viewport over the whole graph draws the (distant) soft edge', () {
      final canvas = _RecordingCanvas();
      painterFor(
        const Rect.fromLTWH(-1000, -1000, 100000, 100000),
        [edge('t0', 't3')],
      ).paint(canvas, const Size(100000, 100000));
      // The dashed arc is stroked as many short sub-paths; just assert it drew.
      expect(canvas.paths, greaterThan(0));
    });

    test('a viewport far from the graph draws nothing', () {
      final canvas = _RecordingCanvas();
      painterFor(
        const Rect.fromLTWH(2000000, 2000000, 100, 100),
        [edge('t0', 't3')],
      ).paint(canvas, const Size(100000, 100000));
      expect(canvas.paths, 0);
    });

    test('no edges → nothing painted', () {
      final canvas = _RecordingCanvas();
      painterFor(const Rect.fromLTWH(-1000, -1000, 100000, 100000), const [])
          .paint(canvas, const Size(100000, 100000));
      expect(canvas.paths, 0);
    });

    test('an edge with a missing endpoint is skipped, not crashed', () {
      final canvas = _RecordingCanvas();
      painterFor(
        const Rect.fromLTWH(-1000, -1000, 100000, 100000),
        [edge('t0', 'ghost')],
      ).paint(canvas, const Size(100000, 100000));
      expect(canvas.paths, 0);
    });
  });

  group('shouldRepaint', () {
    const rect = Rect.fromLTWH(0, 0, 500, 500);
    const sem = Color(0xFF00AA00);
    const ent = Color(0xFF0000AA);
    final edges = [edge('t0', 't3')];
    final base = SoftEdgePainter(
        layout: layout,
        edges: edges,
        visibleRect: rect,
        semanticColor: sem,
        entityColor: ent);

    test('no repaint when nothing changed', () {
      expect(
        base.shouldRepaint(SoftEdgePainter(
            layout: layout,
            edges: edges,
            visibleRect: rect,
            semanticColor: sem,
            entityColor: ent)),
        isFalse,
      );
    });

    test('repaints when the edge set changes', () {
      expect(
        base.shouldRepaint(SoftEdgePainter(
            layout: layout,
            edges: [edge('t1', 't2')],
            visibleRect: rect,
            semanticColor: sem,
            entityColor: ent)),
        isTrue,
      );
    });

    test('repaints when the visible rect changes (scroll/zoom)', () {
      expect(
        base.shouldRepaint(SoftEdgePainter(
            layout: layout,
            edges: edges,
            visibleRect: rect.shift(const Offset(1, 0)),
            semanticColor: sem,
            entityColor: ent)),
        isTrue,
      );
    });

    test('repaints when a kind color changes (theme)', () {
      expect(
        base.shouldRepaint(SoftEdgePainter(
            layout: layout,
            edges: edges,
            visibleRect: rect,
            semanticColor: const Color(0xFF112233),
            entityColor: ent)),
        isTrue,
      );
    });
  });

  test('cell geometry is used for endpoints (distant cells are linked)', () {
    // Sanity: the two endpoints really are far apart, so this exercises the
    // "between distant cells" arc, not an adjacent connector.
    final a = CanvasMetrics.cellRect(layout.byId['t0']!).center;
    final b = CanvasMetrics.cellRect(layout.byId['t3']!).center;
    expect((b - a).distance, greaterThan(CanvasMetrics.cardHeight));
  });
}
