import 'package:canvas_chat/src/data/llm/embedding_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('encodeEmbedding / decodeEmbedding', () {
    test('round-trips within float32 tolerance', () {
      final v = [0.0, 1.0, -1.5, 3.14159, -0.000123, 1234.5];
      final decoded = decodeEmbedding(encodeEmbedding(v));
      expect(decoded.length, v.length);
      for (var i = 0; i < v.length; i++) {
        expect(decoded[i], closeTo(v[i], 1e-4));
      }
    });

    test('encodes 4 little-endian bytes per element', () {
      final bytes = encodeEmbedding([1.0]); // 1.0f = 0x3F800000 LE
      expect(bytes, [0x00, 0x00, 0x80, 0x3F]);
    });

    test('empty vector → empty bytes → empty vector', () {
      expect(encodeEmbedding(const []), isEmpty);
      expect(decodeEmbedding(encodeEmbedding(const [])), isEmpty);
    });
  });

  group('cosineSimilarity', () {
    test('identical vectors → 1.0', () {
      final v = [1.0, 2.0, 3.0];
      expect(cosineSimilarity(v, v), closeTo(1.0, 1e-12));
    });

    test('orthogonal vectors → 0.0', () {
      expect(cosineSimilarity([1.0, 0.0], [0.0, 1.0]), closeTo(0.0, 1e-12));
    });

    test('opposite vectors → -1.0', () {
      expect(cosineSimilarity([1.0, 1.0], [-1.0, -1.0]), closeTo(-1.0, 1e-12));
    });

    test('zero vector is handled without NaN', () {
      final s = cosineSimilarity([0.0, 0.0], [1.0, 2.0]);
      expect(s.isNaN, isFalse);
      expect(s, 0.0);
    });

    test('mismatched lengths → 0.0 (no throw)', () {
      expect(cosineSimilarity([1.0], [1.0, 2.0]), 0.0);
    });
  });
}
