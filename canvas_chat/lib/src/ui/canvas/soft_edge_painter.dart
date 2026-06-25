import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../data/db/database.dart';
import '../../domain/grid_layout.dart';
import 'canvas_metrics.dart';

/// Paints the **soft-edge** layer (DESIGN.md §10 "Soft edges"): the precomputed
/// associative relations between turns, drawn as faint curved/dashed arcs that
/// are deliberately distinct from the structural parent/child + sibling edges
/// ([EdgePainter]) so the two read as different things.
///
/// Each edge links two (often distant, non-adjacent) cells, so it bows out into
/// a quadratic curve — an arc, not a straight structural connector — and is
/// **dashed** so it never reads as a solid grid edge. The visual encoding:
///
/// - **kind → colour**: `semantic` (latent topical link) and `entity` (shared
///   entity) get their own hues, passed in so they track the theme.
/// - **weight → alpha + width**: a stronger relation draws slightly thicker and
///   more opaque; a weak one fades toward invisible. Capped low overall so the
///   layer stays a faint overlay that never obscures card text.
///
/// Like [EdgePainter] it culls edges fully outside the (inflated) visible rect
/// and lives behind a [RepaintBoundary], so it isn't repainted per pan/zoom
/// tick — only on a layout / data / cull / colour change ([shouldRepaint]).
class SoftEdgePainter extends CustomPainter {
  SoftEdgePainter({
    required this.layout,
    required this.edges,
    required this.visibleRect,
    required this.semanticColor,
    required this.entityColor,
  });

  final TurnGridLayout layout;

  /// The renderable intra-conversation soft edges (both endpoints on the grid);
  /// `crossSession` is already filtered out upstream.
  final List<SoftEdge> edges;

  /// Visible canvas rect — edges whose bounding box falls entirely outside it
  /// (inflated by the bow height) are culled.
  final Rect visibleRect;

  final Color semanticColor;
  final Color entityColor;

  /// Dash run / gap lengths (canvas units) for the associative look.
  static const double _dash = 9;
  static const double _gap = 6;

  @override
  void paint(Canvas canvas, Size size) {
    if (edges.isEmpty) return;
    // The arc bows out by a fraction of the endpoint distance; inflate the cull
    // rect generously so an edge whose midpoint bulges into view isn't dropped.
    final cullRect = visibleRect.inflate(
      CanvasMetrics.cardWidth + CanvasMetrics.cardHeight,
    );

    for (final edge in edges) {
      final a = layout.byId[edge.fromTurnId];
      final b = layout.byId[edge.toTurnId];
      if (a == null || b == null) continue;
      final from = CanvasMetrics.cellRect(a).center;
      final to = CanvasMetrics.cellRect(b).center;
      if (!cullRect.overlaps(Rect.fromPoints(from, to))) continue;

      final base = edge.kind == 'entity' ? entityColor : semanticColor;
      // weight ∈ (0, 1]; map to a faint, overlay-friendly band so even a
      // strong link stays translucent and never hides card text.
      final w = edge.weight.clamp(0.0, 1.0);
      final paint = Paint()
        ..color = base.withValues(alpha: 0.18 + 0.42 * w)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 + 1.8 * w
        ..strokeCap = StrokeCap.round;

      _drawDashed(canvas, _arc(from, to), paint);
    }
  }

  /// A bowed quadratic arc between two cell centres. The control point is the
  /// midpoint pushed perpendicular to the line so the edge reads as an
  /// associative link arcing across the grid, not a structural connector. The
  /// bow grows with span but is capped so long edges don't swing wildly.
  Path _arc(Offset from, Offset to) {
    final mid = (from + to) / 2;
    final delta = to - from;
    final dist = delta.distance;
    if (dist == 0) return Path()..moveTo(from.dx, from.dy);
    // Unit perpendicular to the chord.
    final perp = Offset(-delta.dy, delta.dx) / dist;
    final bow = (dist * 0.18).clamp(24.0, 140.0);
    final control = mid + perp * bow;
    return Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);
  }

  /// Strokes [path] as a dashed line by walking its [PathMetric]s and extracting
  /// alternating dash/gap segments — Flutter has no built-in dashed stroke.
  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    for (final PathMetric metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + _dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0.0, metric.length)),
          paint,
        );
        distance = next + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(SoftEdgePainter oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.edges != edges ||
      oldDelegate.visibleRect != visibleRect ||
      oldDelegate.semanticColor != semanticColor ||
      oldDelegate.entityColor != entityColor;
}
