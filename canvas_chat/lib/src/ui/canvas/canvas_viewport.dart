import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Navigate-mode viewport: `screen = canvas * scale + translation`.
///
/// Plain [ChangeNotifier] (not Riverpod) so pan/zoom updates stay a cheap
/// listenable rebuild at 60 fps (DESIGN.md §3). Programmatic control
/// (center-on-node, fit, minimap jumps) is why this is hand-rolled instead of
/// an `InteractiveViewer` (DESIGN.md §6 "Rendering approach").
class CanvasViewport extends ChangeNotifier {
  static const double minScale = 0.05;
  static const double maxScale = 2.5;

  Offset _translation = Offset.zero;
  double _scale = 1;

  Offset get translation => _translation;
  double get scale => _scale;

  Offset toScreen(Offset canvasPoint) => canvasPoint * _scale + _translation;

  Offset toCanvas(Offset screenPoint) => (screenPoint - _translation) / _scale;

  /// The canvas-coordinate rect currently visible in a view of [viewSize].
  Rect visibleRect(Size viewSize) => Rect.fromLTWH(
        -_translation.dx / _scale,
        -_translation.dy / _scale,
        viewSize.width / _scale,
        viewSize.height / _scale,
      );

  void panBy(Offset screenDelta) {
    _translation += screenDelta;
    notifyListeners();
  }

  /// Zooms by [factor] keeping the screen point [focal] fixed.
  void zoomAt(Offset focal, double factor) {
    final newScale = (_scale * factor).clamp(minScale, maxScale);
    if (newScale == _scale) return;
    _translation = focal - (focal - _translation) * (newScale / _scale);
    _scale = newScale;
    notifyListeners();
  }

  /// Centers [canvasPoint] in the view, optionally at a new [scale].
  void centerOn(Offset canvasPoint, Size viewSize, {double? scale}) {
    _set(
      scale: (scale ?? _scale).clamp(minScale, maxScale),
      around: canvasPoint,
      viewSize: viewSize,
    );
    notifyListeners();
  }

  /// The [translation] that would center [canvasPoint] in a view of [viewSize]
  /// at the current scale — the destination an animated recenter tweens toward
  /// (see [setTranslation]).
  Offset translationToCenter(Offset canvasPoint, Size viewSize) =>
      viewSize.center(Offset.zero) - canvasPoint * _scale;

  /// Sets [translation] directly, leaving [scale] untouched, and notifies. Used
  /// to drive an externally-animated pan (a per-frame [translationToCenter]
  /// glide); plain pans should prefer [panBy]/[centerOn].
  void setTranslation(Offset value) {
    if (_translation == value) return;
    _translation = value;
    notifyListeners();
  }

  /// Fits [contentSize] in the view (zoomed out at most to [minScale], in at
  /// most to 1:1), centered. Bound to double-tap and `f` (DESIGN.md §6).
  void fitContent(Size contentSize, Size viewSize) {
    final fitScale = math.min(
      viewSize.width / contentSize.width,
      viewSize.height / contentSize.height,
    );
    _set(
      scale: fitScale.clamp(minScale, 1.0),
      around: contentSize.center(Offset.zero),
      viewSize: viewSize,
    );
    notifyListeners();
  }

  /// Pans the minimum amount needed to bring [canvasRect] (plus [margin]
  /// screen pixels) fully into view. Used to keep the selection on screen
  /// during arrow-key navigation.
  void ensureVisible(Rect canvasRect, Size viewSize, {double margin = 24}) {
    final rect = Rect.fromPoints(
      toScreen(canvasRect.topLeft),
      toScreen(canvasRect.bottomRight),
    ).inflate(margin);
    var dx = 0.0;
    var dy = 0.0;
    if (rect.width <= viewSize.width) {
      if (rect.left < 0) dx = -rect.left;
      if (rect.right > viewSize.width) dx = viewSize.width - rect.right;
    }
    if (rect.height <= viewSize.height) {
      if (rect.top < 0) dy = -rect.top;
      if (rect.bottom > viewSize.height) dy = viewSize.height - rect.bottom;
    }
    if (dx != 0 || dy != 0) panBy(Offset(dx, dy));
  }

  /// Sets the viewport without notifying — for initialization during build.
  void reset({
    required double scale,
    required Offset centerOnCanvasPoint,
    required Size viewSize,
  }) {
    _set(
      scale: scale.clamp(minScale, maxScale),
      around: centerOnCanvasPoint,
      viewSize: viewSize,
    );
  }

  void _set({
    required double scale,
    required Offset around,
    required Size viewSize,
  }) {
    _scale = scale;
    _translation = viewSize.center(Offset.zero) - around * scale;
  }
}
