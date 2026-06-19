import 'package:canvas_chat/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('clampReadableTextScale', () {
    test('stays finite when scaling a zero-size font', () {
      // GptMarkdown emits `fontSize: 0` spans (e.g. the spacer after an H1).
      // If the clamp ceiling were infinite, scale(0) would be infinity * 0 ==
      // NaN, tripping clampDouble's `min <= max` assert and blanking read mode
      // on the real engine. The ceiling must be finite so this stays 0.
      final scaler = clampReadableTextScale(TextScaler.noScaling);
      expect(scaler.scale(0).isFinite, isTrue,
          reason: 'a non-finite scale crashes layout for zero-size spans');
      expect(scaler.scale(0), 0);
    });

    test('still enforces the 1.2x readability floor', () {
      final scaler = clampReadableTextScale(TextScaler.noScaling);
      expect(scaler.scale(10), closeTo(12, 0.0001));
    });

    test('honors a larger system scale, up to the finite ceiling', () {
      expect(clampReadableTextScale(const TextScaler.linear(2)).scale(10), 20);
      // Past 4x is capped; crucially, scaling zero stays finite there too.
      final huge = clampReadableTextScale(const TextScaler.linear(10));
      expect(huge.scale(10), 40);
      expect(huge.scale(0).isFinite, isTrue);
    });
  });
}
