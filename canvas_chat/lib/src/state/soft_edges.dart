import 'package:drift/drift.dart';

import '../data/db/database.dart';
import '../data/llm/embedding_math.dart';

/// Precomputes and persists the **intra-conversation soft edges** that the
/// canvas layer renders (DESIGN.md §10 "Soft edges"): symmetric, weighted
/// relations between the turns of one conversation, computed once at index time
/// and stored in `soft_edges`.
///
/// Two kinds are produced here (crossSession is M9.3, computed elsewhere):
///
/// - **semantic** — a turn-to-turn k-NN over the turns' proposition embeddings.
///   A turn's propositions are decoded to vectors and the **turn-to-turn
///   similarity is the maximum cosine over the cross-product** of the two turns'
///   proposition vectors — i.e. "are these turns related *at all*", which is
///   robust to a turn covering several topics (a single shared topic links
///   them) where a centroid would dilute the signal. For each turn we keep its
///   **top-[semanticK]** neighbours whose similarity is **≥ [semanticThreshold]**
///   (both directed nominations are unioned, so a pair survives if *either*
///   endpoint ranks the other in its top-k); the stored `weight` is the
///   symmetric max-cosine similarity.
///
/// - **entity** — turns that share ≥1 entity (joined through `turn_entities`).
///   The `weight` is the **Jaccard similarity** of the two turns' entity sets
///   (`|A ∩ B| / |A ∪ B|`) in `(0, 1]`, an interpretable, size-normalized
///   overlap measure (two turns each mentioning only "Postgres" score 1.0; one
///   shared entity out of many scores low).
///
/// Edges are symmetric, so each pair is stored **once canonicalized** with
/// `fromTurnId < toTurnId` (string compare), and never as a self-edge. A pair
/// that qualifies as both semantic and entity yields **two rows** (distinct
/// `kind`).
///
/// Recompute is **idempotent**: [recomputeForConversation] first deletes the
/// existing semantic/entity edges incident to this conversation's turns, then
/// reinserts — all in one transaction — so re-running yields the same edge set
/// with no duplicates. `crossSession` rows are never touched.
///
/// Constructed with an explicit [AppDatabase] so it is unit-testable without
/// Riverpod; [recomputeForConversation] is chained off indexing completion in
/// `indexing.dart`.
class SoftEdgeComputer {
  SoftEdgeComputer(this._db);

  final AppDatabase _db;

  /// Default count of nearest semantic neighbours kept per turn.
  static const int defaultSemanticK = 5;

  /// Default minimum max-cosine similarity for a semantic edge to be emitted.
  static const double defaultSemanticThreshold = 0.5;

  /// Recomputes the semantic + entity soft edges for [conversationId] and
  /// persists them, replacing any previously computed ones for this
  /// conversation's turns. Best-effort: never throws on an empty / un-indexed
  /// conversation (it simply clears and writes nothing). [semanticK] and
  /// [semanticThreshold] tune the k-NN (see class doc).
  Future<void> recomputeForConversation(
    String conversationId, {
    int semanticK = defaultSemanticK,
    double semanticThreshold = defaultSemanticThreshold,
  }) async {
    final conversation = await (_db.select(_db.conversations)
          ..where((c) => c.id.equals(conversationId)))
        .getSingleOrNull();
    if (conversation == null) return;
    final projectId = conversation.projectId;

    final turns = await (_db.select(_db.turns)
          ..where((t) => t.conversationId.equals(conversationId)))
        .get();
    final turnIds = [for (final t in turns) t.id];

    final semantic = await _semanticEdges(
      conversationId,
      semanticK: semanticK,
      semanticThreshold: semanticThreshold,
    );
    final entity = await _entityEdges(turnIds);

    await _db.transaction(() async {
      // Idempotent recompute: drop the semantic/entity edges incident to any of
      // this conversation's turns before reinserting. crossSession rows are left
      // untouched. An empty conversation deletes nothing and inserts nothing.
      if (turnIds.isNotEmpty) {
        await (_db.delete(_db.softEdges)
              ..where((e) =>
                  (e.kind.equals('semantic') | e.kind.equals('entity')) &
                  (e.fromTurnId.isIn(turnIds) | e.toTurnId.isIn(turnIds))))
            .go();
      }

      final rows = <SoftEdgesCompanion>[
        for (final e in semantic)
          SoftEdgesCompanion.insert(
            fromTurnId: e.from,
            toTurnId: e.to,
            kind: 'semantic',
            weight: e.weight,
            projectId: projectId,
          ),
        for (final e in entity)
          SoftEdgesCompanion.insert(
            fromTurnId: e.from,
            toTurnId: e.to,
            kind: 'entity',
            weight: e.weight,
            projectId: projectId,
          ),
      ];
      if (rows.isNotEmpty) {
        await _db.batch((b) => b.insertAll(_db.softEdges, rows));
      }
    });
  }

  /// Builds the semantic edges for [conversationId]'s turns from their
  /// proposition embeddings (see class doc for the aggregation).
  Future<List<_Edge>> _semanticEdges(
    String conversationId, {
    required int semanticK,
    required double semanticThreshold,
  }) async {
    if (semanticK <= 0) return const [];

    // Proposition vectors grouped by turn. Only embedded propositions count;
    // an un-embedded turn simply can't form a semantic edge.
    final props = await (_db.select(_db.propositions)
          ..where((p) =>
              p.conversationId.equals(conversationId) &
              p.embedding.isNotNull()))
        .get();

    final vectorsByTurn = <String, List<List<double>>>{};
    for (final p in props) {
      final blob = p.embedding;
      if (blob == null) continue;
      (vectorsByTurn[p.turnId] ??= <List<double>>[])
          .add(decodeEmbedding(blob));
    }

    final turnIds = vectorsByTurn.keys.toList()..sort();
    if (turnIds.length < 2) return const [];

    // Pairwise turn-to-turn similarity = max cosine over the cross-product of
    // their proposition vectors. O(turns²) within one conversation (~8 turns).
    final simByPair = <String, double>{}; // 'from|to' (from<to) -> weight
    final neighbours = <String, List<_Neighbour>>{
      for (final id in turnIds) id: <_Neighbour>[],
    };
    for (var i = 0; i < turnIds.length; i++) {
      for (var j = i + 1; j < turnIds.length; j++) {
        final a = turnIds[i];
        final b = turnIds[j];
        final sim = _maxCosine(vectorsByTurn[a]!, vectorsByTurn[b]!);
        if (sim < semanticThreshold) continue;
        neighbours[a]!.add(_Neighbour(b, sim));
        neighbours[b]!.add(_Neighbour(a, sim));
        simByPair['$a|$b'] = sim; // a<b since turnIds is sorted and i<j
      }
    }

    // Keep each turn's top-k neighbours (highest similarity, id tiebreak for
    // determinism), then union both directed nominations into a symmetric set.
    final kept = <String>{}; // canonical 'from|to' keys
    for (final id in turnIds) {
      final list = neighbours[id]!
        ..sort((x, y) {
          final c = y.sim.compareTo(x.sim);
          return c != 0 ? c : x.turnId.compareTo(y.turnId);
        });
      for (final n in list.take(semanticK)) {
        final from = id.compareTo(n.turnId) < 0 ? id : n.turnId;
        final to = id.compareTo(n.turnId) < 0 ? n.turnId : id;
        kept.add('$from|$to');
      }
    }

    return [
      for (final key in kept)
        () {
          final parts = key.split('|');
          return _Edge(parts[0], parts[1], simByPair[key]!);
        }(),
    ];
  }

  /// Max cosine similarity over the cross-product of two turns' proposition
  /// vectors — the turn-to-turn relatedness signal (see class doc).
  double _maxCosine(List<List<double>> a, List<List<double>> b) {
    var best = -1.0;
    for (final va in a) {
      for (final vb in b) {
        final s = cosineSimilarity(va, vb);
        if (s > best) best = s;
      }
    }
    return best;
  }

  /// Builds the entity edges for [turnIds] from `turn_entities`: turns sharing
  /// ≥1 entity, weighted by Jaccard over their entity sets (see class doc).
  Future<List<_Edge>> _entityEdges(List<String> turnIds) async {
    if (turnIds.length < 2) return const [];

    final links = await (_db.select(_db.turnEntities)
          ..where((te) => te.turnId.isIn(turnIds)))
        .get();

    final entitiesByTurn = <String, Set<String>>{};
    for (final link in links) {
      (entitiesByTurn[link.turnId] ??= <String>{}).add(link.entityId);
    }

    final ids = entitiesByTurn.keys.toList()..sort();
    final edges = <_Edge>[];
    for (var i = 0; i < ids.length; i++) {
      for (var j = i + 1; j < ids.length; j++) {
        final a = entitiesByTurn[ids[i]]!;
        final b = entitiesByTurn[ids[j]]!;
        final intersection = a.intersection(b).length;
        if (intersection == 0) continue;
        final union = a.length + b.length - intersection;
        // ids is sorted, so ids[i] < ids[j] is already canonical.
        edges.add(_Edge(ids[i], ids[j], intersection / union));
      }
    }
    return edges;
  }
}

/// A canonicalized (`from < to`) weighted soft edge, pre-`SoftEdgesCompanion`.
class _Edge {
  const _Edge(this.from, this.to, this.weight);
  final String from;
  final String to;
  final double weight;
}

/// A directed top-k candidate during semantic k-NN selection.
class _Neighbour {
  const _Neighbour(this.turnId, this.sim);
  final String turnId;
  final double sim;
}
