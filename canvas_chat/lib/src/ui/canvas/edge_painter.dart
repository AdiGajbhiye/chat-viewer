import 'package:flutter/material.dart';

import '../../domain/grid_layout.dart';
import 'canvas_metrics.dart';

/// Paints all edges in one painter below the node layer (DESIGN.md §6):
/// parent→child edges are vertical within a lane; sibling edges are
/// horizontal across a row between fork alternatives. Active-path edges
/// emphasized, others dimmed.
class EdgePainter extends CustomPainter {
  EdgePainter({
    required this.layout,
    required this.visibleRect,
    required this.activeColor,
    required this.dimColor,
  });

  final TurnGridLayout layout;

  /// Visible canvas rect — edges fully outside are culled.
  final Rect visibleRect;

  final Color activeColor;
  final Color dimColor;

  @override
  void paint(Canvas canvas, Size size) {
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final dimPaint = Paint()
      ..color = dimColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final cullRect = visibleRect.inflate(CanvasMetrics.rowGap);

    for (final edge in layout.edges) {
      final a = layout.byId[edge.from];
      final b = layout.byId[edge.to];
      if (a == null || b == null) continue;
      final paint = edge.active ? activePaint : dimPaint;
      if (edge.kind == GridEdgeKind.sibling) {
        // Horizontal connector between fork alternatives on the same row.
        final from = CanvasMetrics.cellRect(a).centerRight;
        final to = CanvasMetrics.cellRect(b).centerLeft;
        if (!cullRect.overlaps(Rect.fromPoints(from, to))) continue;
        canvas.drawLine(from, to, paint);
        continue;
      }
      final from = CanvasMetrics.cellRect(a).bottomCenter;
      final to = CanvasMetrics.cellRect(b).topCenter;
      if (!cullRect.overlaps(Rect.fromPoints(from, to))) continue;
      canvas.drawPath(_edgePath(from, to), paint);
    }
  }

  /// Straight vertical line within a lane; rounded elbow when the child sits
  /// in another lane.
  Path _edgePath(Offset from, Offset to) {
    final path = Path()..moveTo(from.dx, from.dy);
    if (from.dx == to.dx) {
      path.lineTo(to.dx, to.dy);
      return path;
    }
    final midY = (from.dy + to.dy) / 2;
    final dxSign = to.dx > from.dx ? 1.0 : -1.0;
    final r = [
      12.0,
      (to.dx - from.dx).abs() / 2,
      (to.dy - from.dy).abs() / 2,
    ].reduce((a, b) => a < b ? a : b);
    path
      ..lineTo(from.dx, midY - r)
      ..quadraticBezierTo(from.dx, midY, from.dx + dxSign * r, midY)
      ..lineTo(to.dx - dxSign * r, midY)
      ..quadraticBezierTo(to.dx, midY, to.dx, midY + r)
      ..lineTo(to.dx, to.dy);
    return path;
  }

  @override
  bool shouldRepaint(EdgePainter oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.visibleRect != visibleRect ||
      oldDelegate.activeColor != activeColor ||
      oldDelegate.dimColor != dimColor;
}
