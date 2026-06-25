import 'dart:math' as math;

/// A pluggable text-embedding backend for the proposition / fact index
/// (DESIGN.md §10: "clones the `LlmProvider` pattern for an `EmbeddingProvider`").
/// Vectors feed the dense half of hybrid retrieval; the producing model is
/// stamped into `propositions.embedding_model` so a model change can invalidate
/// and trigger a re-embed. Like `LlmProvider` this stays fully offline by
/// default ([StubEmbeddingProvider]); a real provider
/// (`OpenAiCompatibleEmbeddingProvider`) drops in behind this interface.
abstract interface class EmbeddingProvider {
  /// Embeds [texts] in a single batch, returning one vector per input in the
  /// **same order**. All vectors share a fixed dimension. An empty input
  /// yields an empty list.
  Future<List<List<double>>> embed(List<String> texts);

  /// Identifier of the model producing these vectors, stamped into
  /// `propositions.embedding_model` for re-embed invalidation.
  String get modelId;
}

/// The default, fully-offline embedding backend: no network, no API key. It
/// hashes each text into a fixed-dimension vector and L2-normalizes it, so the
/// index / retrieval / soft-edge plumbing is exercised end-to-end without a
/// model. Deterministic by construction — the **same text always maps to the
/// same vector**, in every run and process — so a stored embedding stays
/// comparable across app launches. Semantically weak (it's a hashing trick, not
/// a learned model); swap in `OpenAiCompatibleEmbeddingProvider` for real
/// similarity.
class StubEmbeddingProvider implements EmbeddingProvider {
  const StubEmbeddingProvider({this.dimension = 256});

  /// Output vector dimension. Kept small — this is a placeholder, not a model.
  final int dimension;

  @override
  String get modelId => 'stub-$dimension';

  @override
  Future<List<List<double>>> embed(List<String> texts) async =>
      [for (final text in texts) _embedOne(text)];

  /// Bag-of-tokens hashing: each lowercased word lands in a bucket (via a
  /// stable FNV-1a hash) and bumps it by a sign drawn from a second salted
  /// hash, then the vector is L2-normalized. Pure arithmetic over code units —
  /// no `hashCode` (not stable across processes) and no randomness.
  List<double> _embedOne(String text) {
    final vector = List<double>.filled(dimension, 0);
    for (final token in _tokenize(text)) {
      final bucket = _fnv1a(token) % dimension;
      // A salted second hash picks the sign so distinct tokens don't all push
      // the same direction (and near-collisions in `bucket` can still cancel).
      final sign = (_fnv1a('sign:$token') & 1) == 0 ? 1.0 : -1.0;
      vector[bucket] += sign;
    }
    return _l2Normalize(vector);
  }

  Iterable<String> _tokenize(String text) => text
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((t) => t.isNotEmpty);

  /// 32-bit FNV-1a over UTF-16 code units. Masked to stay in the JS-safe int
  /// range and identical on every platform.
  int _fnv1a(String s) {
    var hash = 0x811c9dc5;
    for (var i = 0; i < s.length; i++) {
      hash ^= s.codeUnitAt(i);
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }

  List<double> _l2Normalize(List<double> v) {
    var sum = 0.0;
    for (final x in v) {
      sum += x * x;
    }
    if (sum == 0) return v; // all-empty / no tokens → zero vector, left as-is
    final norm = math.sqrt(sum);
    for (var i = 0; i < v.length; i++) {
      v[i] /= norm;
    }
    return v;
  }
}
