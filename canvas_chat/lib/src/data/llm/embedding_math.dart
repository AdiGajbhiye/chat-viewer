import 'dart:math' as math;
import 'dart:typed_data';

/// Vector (de)serialization + similarity for the proposition / fact index
/// (DESIGN.md §10). Embeddings are stored in `propositions.embedding` /
/// `facts.embedding` as a raw **float32 little-endian** BLOB — these helpers are
/// the single place that encoding is defined, so the indexer (writes) and
/// retrieval (reads + scores) can't drift apart.

/// Packs [vector] into a float32 little-endian byte buffer for a `BlobColumn`.
/// Round-trips with [decodeEmbedding] (within float32 precision).
Uint8List encodeEmbedding(List<double> vector) {
  final data = ByteData(vector.length * 4);
  for (var i = 0; i < vector.length; i++) {
    data.setFloat32(i * 4, vector[i], Endian.little);
  }
  return data.buffer.asUint8List();
}

/// Reads a float32 little-endian BLOB (as written by [encodeEmbedding]) back
/// into a vector. The byte length must be a multiple of 4.
List<double> decodeEmbedding(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  final count = bytes.lengthInBytes ~/ 4;
  return List<double>.generate(
    count,
    (i) => data.getFloat32(i * 4, Endian.little),
  );
}

/// Cosine similarity of [a] and [b] in `[-1, 1]`; `1` = identical direction,
/// `0` = orthogonal. Returns `0` when either vector is zero-norm (or the
/// lengths differ) so a degenerate embedding can never produce a NaN score.
double cosineSimilarity(List<double> a, List<double> b) {
  if (a.length != b.length) return 0;
  var dot = 0.0;
  var normA = 0.0;
  var normB = 0.0;
  for (var i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  if (normA == 0 || normB == 0) return 0;
  return dot / (math.sqrt(normA) * math.sqrt(normB));
}
