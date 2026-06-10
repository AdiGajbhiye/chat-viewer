import 'package:flutter/material.dart';

import '../../domain/grid_layout.dart';
import 'canvas_metrics.dart';
import 'canvas_viewport.dart';

/// Bottom-right minimap (DESIGN.md §6): grid cells painted as tiny rects plus
/// the viewport rectangle. Tap to jump the viewport there.
class Minimap extends StatelessWidget {
  const Minimap({
    super.key,
    required this.layout,
    required this.viewport,
    required this.viewSize,
    required this.selectedId,
  });

  static const Size _size = Size(160, 120);

  final TurnGridLayout layout;
  final CanvasViewport viewport;

  /// Size of the canvas view the minimap mirrors.
  final Size viewSize;

  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final contentSize = CanvasMetrics.contentSize(layout);
    final miniScale = _miniScale(contentSize);
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) => viewport.centerOn(
          details.localPosition / miniScale,
          viewSize,
        ),
        child: CustomPaint(
          size: _size,
          painter: _MinimapPainter(
            layout: layout,
            viewportRect: viewport.visibleRect(viewSize),
            miniScale: miniScale,
            selectedId: selectedId,
            activeColor: scheme.primary,
            dimColor: scheme.outline,
            viewportColor: scheme.tertiary,
          ),
        ),
      ),
    );
  }

  double _miniScale(Size contentSize) {
    final sx = _size.width / contentSize.width;
    final sy = _size.height / contentSize.height;
    return sx < sy ? sx : sy;
  }
}

class _MinimapPainter extends CustomPainter {
  _MinimapPainter({
    required this.layout,
    required this.viewportRect,
    required this.miniScale,
    required this.selectedId,
    required this.activeColor,
    required this.dimColor,
    required this.viewportColor,
  });

  final TurnGridLayout layout;
  final Rect viewportRect;
  final double miniScale;
  final String? selectedId;
  final Color activeColor;
  final Color dimColor;
  final Color viewportColor;

  @override
  void paint(Canvas canvas, Size size) {
    final activePaint = Paint()..color = activeColor;
    final dimPaint = Paint()..color = dimColor.withValues(alpha: 0.55);
    final selectedPaint = Paint()..color = viewportColor;
    for (final cell in layout.cells) {
      final rect = _scaleRect(CanvasMetrics.cellRect(cell));
      final paint = cell.turn.id == selectedId
          ? selectedPaint
          : cell.onActivePath
              ? activePaint
              : dimPaint;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1)),
        paint,
      );
    }
    final viewRect = _scaleRect(viewportRect)
        .intersect((Offset.zero & size).inflate(1));
    if (!viewRect.isEmpty) {
      canvas.drawRect(
        viewRect,
        Paint()
          ..color = viewportColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  Rect _scaleRect(Rect rect) => Rect.fromLTWH(
        rect.left * miniScale,
        rect.top * miniScale,
        rect.width * miniScale,
        rect.height * miniScale,
      );

  @override
  bool shouldRepaint(_MinimapPainter oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.viewportRect != viewportRect ||
      oldDelegate.miniScale != miniScale ||
      oldDelegate.selectedId != selectedId;
}
