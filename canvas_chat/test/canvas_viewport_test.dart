import 'package:canvas_chat/src/ui/canvas/canvas_viewport.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A viewport plus a counter of how many times it notified its listeners, so
/// tests can assert both the math and that a mutation actually fired a rebuild.
({CanvasViewport vp, int Function() notifications}) tracked() {
  var count = 0;
  final vp = CanvasViewport()..addListener(() => count++);
  return (vp: vp, notifications: () => count);
}

void main() {
  group('toScreen / toCanvas', () {
    test('applies screen = canvas * scale + translation', () {
      final vp = CanvasViewport()
        ..centerOn(Offset.zero, const Size(0, 0), scale: 2)
        ..panBy(const Offset(30, 40));
      // scale 2, translation (30, 40).
      expect(vp.toScreen(const Offset(5, 5)), const Offset(40, 50));
    });

    test('are inverses of each other at an arbitrary viewport', () {
      final vp = CanvasViewport()
        ..centerOn(const Offset(120, 80), const Size(400, 300), scale: 1.7);
      const point = Offset(42, 99);
      expect(
        vp.toCanvas(vp.toScreen(point)),
        offsetMoreOrLessEquals(point, epsilon: 1e-9),
      );
    });
  });

  group('panBy', () {
    test('accumulates the screen-space translation', () {
      final t = tracked();
      t.vp.panBy(const Offset(10, -5));
      t.vp.panBy(const Offset(3, 8));
      expect(t.vp.translation, const Offset(13, 3));
      expect(t.notifications(), 2);
    });

    test('shifts the projection without touching scale', () {
      final vp = CanvasViewport()..panBy(const Offset(100, 0));
      expect(vp.scale, 1);
      expect(vp.toScreen(Offset.zero), const Offset(100, 0));
    });
  });

  group('zoomAt', () {
    test('keeps the canvas point under the focal point fixed', () {
      final vp = CanvasViewport();
      const focal = Offset(100, 100);
      final anchored = vp.toCanvas(focal);
      vp.zoomAt(focal, 2);
      expect(vp.scale, 2);
      // The canvas point that was under the cursor stays under the cursor.
      expect(vp.toScreen(anchored), offsetMoreOrLessEquals(focal));
    });

    test('stays anchored across a non-trivial starting viewport', () {
      final vp = CanvasViewport()
        ..centerOn(const Offset(50, 50), const Size(400, 400), scale: 0.8);
      const focal = Offset(310, 90);
      final anchored = vp.toCanvas(focal);
      vp.zoomAt(focal, 1.5);
      expect(vp.scale, moreOrLessEquals(1.2));
      expect(vp.toScreen(anchored), offsetMoreOrLessEquals(focal));
    });

    test('clamps zoom-in at maxScale and zoom-out at minScale', () {
      final vp = CanvasViewport();
      vp.zoomAt(Offset.zero, 1000);
      expect(vp.scale, CanvasViewport.maxScale);

      vp.zoomAt(Offset.zero, 0.00001);
      expect(vp.scale, CanvasViewport.minScale);
    });

    test('is a no-op (no notification) when already clamped at the limit', () {
      final t = tracked();
      t.vp.zoomAt(Offset.zero, 1000); // -> maxScale, 1 notification.
      expect(t.vp.scale, CanvasViewport.maxScale);
      t.vp.zoomAt(Offset.zero, 2); // already at max: returns early.
      expect(t.notifications(), 1);
    });

    test('stays anchored even when the requested factor is clamped', () {
      final vp = CanvasViewport();
      const focal = Offset(70, 130);
      final anchored = vp.toCanvas(focal);
      vp.zoomAt(focal, 1000); // clamped to maxScale.
      expect(vp.scale, CanvasViewport.maxScale);
      expect(vp.toScreen(anchored), offsetMoreOrLessEquals(focal));
    });
  });

  group('centerOn', () {
    test('places the canvas point at the centre of the view', () {
      final t = tracked();
      t.vp.centerOn(const Offset(300, 300), const Size(400, 400), scale: 1.5);
      expect(t.vp.scale, 1.5);
      expect(
        t.vp.toScreen(const Offset(300, 300)),
        offsetMoreOrLessEquals(const Offset(200, 200)),
      );
      expect(t.notifications(), 1);
    });

    test('keeps the current scale when none is given', () {
      final vp = CanvasViewport()
        ..centerOn(Offset.zero, const Size(400, 400), scale: 1.8)
        ..centerOn(const Offset(10, 10), const Size(400, 400));
      expect(vp.scale, 1.8);
    });

    test('clamps the requested scale into range', () {
      final vp = CanvasViewport()
        ..centerOn(Offset.zero, const Size(400, 400), scale: 99);
      expect(vp.scale, CanvasViewport.maxScale);
    });
  });

  group('fitContent', () {
    test('fits a wide content exactly and centres it', () {
      final vp = CanvasViewport()
        ..fitContent(const Size(1000, 500), const Size(500, 500));
      // Width is the binding dimension: 500 / 1000 = 0.5.
      expect(vp.scale, moreOrLessEquals(0.5));
      // Content centre lands at the view centre.
      expect(
        vp.toScreen(const Offset(500, 250)),
        offsetMoreOrLessEquals(const Offset(250, 250)),
      );
      // The full content width maps onto the full view width.
      expect(vp.toScreen(Offset.zero).dx, moreOrLessEquals(0));
      expect(vp.toScreen(const Offset(1000, 0)).dx, moreOrLessEquals(500));
    });

    test('never zooms in past 1:1 for content smaller than the view', () {
      final vp = CanvasViewport()
        ..fitContent(const Size(100, 100), const Size(500, 500));
      expect(vp.scale, 1.0);
    });

    test('never zooms out past minScale for enormous content', () {
      final vp = CanvasViewport()
        ..fitContent(const Size(1000000, 1000000), const Size(500, 500));
      expect(vp.scale, CanvasViewport.minScale);
    });
  });

  group('visibleRect', () {
    test('shrinks and offsets with zoom and pan', () {
      final vp = CanvasViewport()
        ..centerOn(const Offset(150, 150), const Size(400, 400), scale: 2);
      final rect = vp.visibleRect(const Size(400, 400));
      // At 2x a 400px view shows 200 canvas units, centred on (150, 150).
      expect(rect.width, moreOrLessEquals(200));
      expect(rect.height, moreOrLessEquals(200));
      expect(rect.center, offsetMoreOrLessEquals(const Offset(150, 150)));
    });
  });

  group('ensureVisible', () {
    test('pans the minimum to bring an off-screen rect into view', () {
      final t = tracked();
      // scale 1, translation 0; rect is off the right edge.
      t.vp.ensureVisible(
        const Rect.fromLTWH(600, 100, 50, 50),
        const Size(500, 500),
      );
      // Right edge (650) + margin (24) = 674; pan left by 674 - 500 = 174.
      expect(t.vp.translation, const Offset(-174, 0));
      expect(t.notifications(), 1);
      // The rect plus its margin now sits flush against the right edge.
      expect(t.vp.toScreen(const Offset(650, 0)).dx, moreOrLessEquals(476));
    });

    test('does nothing when the rect is already comfortably in view', () {
      final t = tracked();
      t.vp.ensureVisible(
        const Rect.fromLTWH(100, 100, 50, 50),
        const Size(500, 500),
      );
      expect(t.vp.translation, Offset.zero);
      expect(t.notifications(), 0);
    });

    test('leaves an axis alone when the rect is larger than the view there',
        () {
      final t = tracked();
      // 900px-wide rect cannot fit horizontally in a 500px view: no x pan.
      // It does fit vertically and sits above the view: pan down.
      t.vp.ensureVisible(
        const Rect.fromLTWH(-200, -300, 900, 50),
        const Size(500, 500),
      );
      expect(t.vp.translation.dx, 0);
      expect(t.vp.translation.dy, greaterThan(0));
    });
  });

  group('reset', () {
    test('centres and scales like centerOn but without notifying', () {
      final t = tracked();
      t.vp.reset(
        scale: 2,
        centerOnCanvasPoint: const Offset(100, 100),
        viewSize: const Size(400, 400),
      );
      expect(t.vp.scale, 2);
      expect(
        t.vp.toScreen(const Offset(100, 100)),
        offsetMoreOrLessEquals(const Offset(200, 200)),
      );
      expect(t.notifications(), 0);
    });

    test('clamps the scale into range', () {
      final vp = CanvasViewport()
        ..reset(
          scale: 100,
          centerOnCanvasPoint: Offset.zero,
          viewSize: const Size(400, 400),
        );
      expect(vp.scale, CanvasViewport.maxScale);
    });
  });
}
