import 'package:canvas_chat/src/data/llm/embedding_provider.dart';
import 'package:flutter_test/flutter_test.dart';

double _norm(List<double> v) {
  var sum = 0.0;
  for (final x in v) {
    sum += x * x;
  }
  return sum;
}

void main() {
  group('StubEmbeddingProvider', () {
    const provider = StubEmbeddingProvider();

    test('is deterministic: same text → identical vector across calls',
        () async {
      final a = (await provider.embed(['the quick brown fox'])).single;
      final b = (await provider.embed(['the quick brown fox'])).single;
      expect(a, b);
    });

    test('different inputs → different vectors', () async {
      final out = await provider.embed(['postgres is fast', 'sqlite is small']);
      expect(out[0], isNot(out[1]));
    });

    test('fixed output dimension', () async {
      final out = await provider.embed(['one', 'two words here']);
      expect(out[0].length, 256);
      expect(out[1].length, 256);
    });

    test('vectors are L2-normalized (≈1.0)', () async {
      final v = (await provider.embed(['retrieval augmented generation'])).single;
      expect(_norm(v), closeTo(1.0, 1e-9));
    });

    test('order-preserving and one vector per input', () async {
      final out = await provider.embed(['a', 'b', 'c']);
      expect(out.length, 3);
      final solo = await provider.embed(['b']);
      expect(out[1], solo.single); // 'b' lands the same vector in any batch
    });

    test('empty input yields an empty list', () async {
      expect(await provider.embed(const []), isEmpty);
    });

    test('tokenless text → zero vector (no NaN from normalization)', () async {
      final v = (await provider.embed(['   !!!  '])).single;
      expect(v.every((x) => x == 0), isTrue);
    });

    test('modelId reflects the dimension', () {
      expect(provider.modelId, 'stub-256');
      expect(const StubEmbeddingProvider(dimension: 64).modelId, 'stub-64');
    });

    test('honors a custom dimension', () async {
      const small = StubEmbeddingProvider(dimension: 16);
      final v = (await small.embed(['hello world'])).single;
      expect(v.length, 16);
    });
  });
}
