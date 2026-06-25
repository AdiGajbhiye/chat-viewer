import 'package:drift/drift.dart';

import '../data/db/database.dart';
import '../data/llm/embedding_math.dart';
import '../data/llm/embedding_provider.dart';
import '../data/llm/query_rewriter.dart';
import '../domain/active_path.dart';

/// Retrieval & context assembly for continuing a session (DESIGN.md §10). This
/// replaces the full root→parent ancestry that `BranchService` used to send: a
/// new prompt is rewritten into standalone queries, hybrid-retrieved (dense
/// proposition embeddings + sparse FTS + boosted facts) over a project scope,
/// fork-aware scored, MMR-diversified, and assembled into an ordered context
/// (persona + last 1–2 turns verbatim + tagged retrieved items + the new
/// prompt).
///
/// Built as small, pure, injectable pieces so each is unit-testable with
/// controlled data (don't bury the logic in providers):
/// - [scoreCandidate] / [RetrievalWeights] — fork-aware scoring (step 3).
/// - [mmrSelect] — relevance-vs-redundancy diversification (step 4).
/// - [ContextAssembler] — the orchestrator (steps 1, 2, 5).

/// The breadth retrieval ranges over (DESIGN.md §10 "Scope filter = branch |
/// session | project | all"). The index is project-scoped, so [project] is the
/// sensible default; the full scope-toggle UI is a later step (M9.3).
enum RetrievalScope {
  /// Only turns on the active lineage of the current conversation (the branch
  /// the user is forking from), by `parent_turn_id` chain.
  branch,

  /// Only the current conversation (session).
  session,

  /// The whole project the conversation belongs to (the default — the index is
  /// project-scoped).
  project,

  /// Everything indexed, regardless of project.
  all,
}

/// A turn surfaced by retrieval, carried through scoring/MMR/assembly with the
/// tags the model needs (DESIGN.md §10 "tagged {branch, committed?}").
class RetrievedItem {
  const RetrievedItem({
    required this.turn,
    required this.similarity,
    required this.committed,
    required this.text,
    this.score = 0,
  });

  /// The full turn the matched proposition(s) expand to ("small-to-big").
  final Turn turn;

  /// Best retrieval similarity for this turn in `[0, 1]` (dense cosine, or a
  /// rank-derived proxy for an FTS-only / fact-only match).
  final double similarity;

  /// Whether this turn is a source of an active fact (or surfaced *as* a fact)
  /// — authoritative, "settled", not a tentative cross-branch claim.
  final bool committed;

  /// The text shown to the model for this item — the turn's prompt/response, or
  /// the fact statement when surfaced as a fact.
  final String text;

  /// The fork-aware score assigned by [scoreCandidate]; filled in by the
  /// assembler. Higher = more relevant.
  final double score;

  /// The branch the item belongs to — its conversation id, for the
  /// `{branch, committed?}` tag.
  String get branchId => turn.conversationId;

  RetrievedItem withScore(double score) => RetrievedItem(
        turn: turn,
        similarity: similarity,
        committed: committed,
        text: text,
        score: score,
      );
}

/// The assembled, ordered context that replaces the full-ancestry send
/// (DESIGN.md §10 step 4). [verbatim] is the last 1–2 turns kept whole (for
/// flow and as the rewriter's input); [retrieved] is the MMR-selected,
/// scored-best-first retrieved items; [preamble] is the synthesized system note
/// (the `{branch, committed?}` tags + a one-line reading instruction) handed to
/// `LlmProvider.generate(preamble:)`.
class AssembledContext {
  const AssembledContext({
    required this.verbatim,
    required this.retrieved,
    required this.preamble,
    required this.queries,
  });

  /// Last 1–2 turns, oldest→newest — passed as `generate(context:)`.
  final List<Turn> verbatim;

  /// MMR-selected retrieved items, best score first.
  final List<RetrievedItem> retrieved;

  /// System preamble carrying the tagged retrieved items; empty when nothing
  /// was retrieved (then the call is persona + verbatim + prompt only).
  final String preamble;

  /// The standalone queries the rewriter produced (first is primary). Surfaced
  /// for tests / debugging.
  final List<String> queries;
}

/// Named, documented weights for the fork-aware score
/// `α·similarity + β·recency + γ·branchProximity + ε·committedBoost −
/// δ·divergedSiblingPenalty` (DESIGN.md §10 step 3). Defaults lead with
/// semantic similarity, give recency and branch-proximity equal secondary
/// weight (in the no-fork linear case branchProximity ≈ recency, so they
/// reinforce), and treat the committed boost / diverged penalty as tie-breakers
/// that move a candidate a notch, not dominate.
class RetrievalWeights {
  const RetrievalWeights({
    this.alphaSimilarity = 1.0,
    this.betaRecency = 0.3,
    this.gammaBranchProximity = 0.3,
    this.epsilonCommitted = 0.25,
    this.deltaDivergedSibling = 0.4,
  });

  /// α — weight on semantic/lexical similarity (the dominant term).
  final double alphaSimilarity;

  /// β — weight on recency (newer-than-the-current-turn decay).
  final double betaRecency;

  /// γ — weight on branch proximity (closer on the active lineage = higher).
  final double gammaBranchProximity;

  /// ε — additive boost for a committed (fact-backed) candidate.
  final double epsilonCommitted;

  /// δ — penalty subtracted for a candidate in a sibling subtree the user
  /// forked away from (soft, never excludes).
  final double deltaDivergedSibling;
}

/// The precomputed per-candidate signals scoring needs, so [scoreCandidate]
/// stays a pure function (no DB, no tree walking) and is trivially testable with
/// hand-built values.
class ScoringSignals {
  const ScoringSignals({
    required this.similarity,
    required this.recency,
    required this.branchProximity,
    required this.committed,
    required this.divergedSibling,
  });

  /// `[0, 1]` retrieval similarity.
  final double similarity;

  /// `[0, 1]` recency: 1 = at/after the current turn, decaying to 0 for the
  /// oldest candidate (see [ContextAssembler] for the decay).
  final double recency;

  /// `[0, 1]` branch proximity: 1 = on the active lineage, decaying with graph
  /// distance from it.
  final double branchProximity;

  /// Whether the candidate is fact-backed (committed boost applies).
  final bool committed;

  /// Whether the candidate sits in a diverged sibling subtree (penalty applies).
  final bool divergedSibling;
}

/// The fork-aware score for one candidate (DESIGN.md §10 step 3). Pure: a linear
/// combination of [signals] under [weights]. Note: in the no-fork linear case
/// `branchProximity ≈ recency` (every ancestor is on the active lineage and
/// distance grows with age), so γ reinforces β; γ only adds independent signal
/// once forks exist.
double scoreCandidate(ScoringSignals signals, RetrievalWeights weights) {
  return weights.alphaSimilarity * signals.similarity +
      weights.betaRecency * signals.recency +
      weights.gammaBranchProximity * signals.branchProximity +
      (signals.committed ? weights.epsilonCommitted : 0.0) -
      (signals.divergedSibling ? weights.deltaDivergedSibling : 0.0);
}

/// Maximal Marginal Relevance selection (DESIGN.md §10 step 4): greedily picks
/// up to [k] items that balance relevance (their [RetrievedItem.score]) against
/// redundancy with what's already chosen. [lambda] in `[0, 1]` is the trade-off:
/// 1 = pure relevance (ignore redundancy), 0 = pure diversity (spread out).
/// [similarityOf] gives the redundancy between two candidates' underlying texts
/// (e.g. cosine of their embeddings); when null, MMR degenerates to top-k by
/// score. [candidates] are assumed scored; the result is ordered by selection.
List<RetrievedItem> mmrSelect(
  List<RetrievedItem> candidates, {
  required int k,
  double lambda = 0.7,
  double Function(RetrievedItem a, RetrievedItem b)? similarityOf,
}) {
  if (candidates.isEmpty || k <= 0) return const [];
  // Stable order before selection: best score first, id tiebreak.
  final pool = [...candidates]..sort((a, b) {
      final c = b.score.compareTo(a.score);
      return c != 0 ? c : a.turn.id.compareTo(b.turn.id);
    });

  final selected = <RetrievedItem>[];
  final remaining = [...pool];
  // Normalize relevance to `[0, 1]` across the pool so it's commensurate with
  // the `[0, 1]` redundancy term regardless of the raw score range.
  final scores = pool.map((c) => c.score).toList();
  final minScore = scores.reduce((a, b) => a < b ? a : b);
  final maxScore = scores.reduce((a, b) => a > b ? a : b);
  final span = maxScore - minScore;
  double relevance(RetrievedItem c) =>
      span == 0 ? 1.0 : (c.score - minScore) / span;

  while (selected.length < k && remaining.isNotEmpty) {
    RetrievedItem? best;
    var bestValue = double.negativeInfinity;
    for (final c in remaining) {
      var maxRedundancy = 0.0;
      if (similarityOf != null) {
        for (final s in selected) {
          final r = similarityOf(c, s);
          if (r > maxRedundancy) maxRedundancy = r;
        }
      }
      final value = lambda * relevance(c) - (1 - lambda) * maxRedundancy;
      // `>` with a stable pre-sorted pool makes ties deterministic (earlier,
      // higher-scored candidate wins).
      if (value > bestValue) {
        bestValue = value;
        best = c;
      }
    }
    if (best == null) break;
    selected.add(best);
    remaining.remove(best);
  }
  return selected;
}

/// Orchestrates the four-step pipeline (DESIGN.md §10): rewrite → hybrid
/// retrieve → fork-aware score → MMR + assemble. Constructed with explicit
/// dependencies so it is unit-testable without Riverpod;
/// `contextAssemblerProvider` wires the app's providers in.
class ContextAssembler {
  ContextAssembler({
    required AppDatabase db,
    required EmbeddingProvider embedder,
    required QueryRewriter rewriter,
    this.weights = const RetrievalWeights(),
    this.maxRetrieved = 8,
    this.mmrLambda = 0.7,
    this.factBoost = 0.1,
    this.candidatePoolSize = 40,
  })  : _db = db, // ignore: prefer_initializing_formals
        _embedder = embedder, // ignore: prefer_initializing_formals
        _rewriter = rewriter; // ignore: prefer_initializing_formals

  final AppDatabase _db;
  final EmbeddingProvider _embedder;
  final QueryRewriter _rewriter;

  /// Scoring weights (DESIGN.md §10 step 3).
  final RetrievalWeights weights;

  /// How many retrieved items the assembled context carries (after MMR).
  final int maxRetrieved;

  /// MMR relevance-vs-diversity trade-off (DESIGN.md §10 step 4). Default 0.7
  /// leans toward relevance while still dropping near-duplicates.
  final double mmrLambda;

  /// Additive similarity bump for a fact hit over a proposition hit of the same
  /// raw cosine — facts are authoritative (DESIGN.md §10 "facts carry a boost").
  final double factBoost;

  /// Upper bound on candidates kept before scoring/MMR, so a huge project can't
  /// blow up the brute-force pass (lazy indexing keeps this small in practice).
  final int candidatePoolSize;

  /// How many trailing turns are kept verbatim (DESIGN.md §10 "last 1–2 turns").
  static const int verbatimTail = 2;

  /// Builds the retrieval-assembled context for a new [prompt] forked off
  /// [parent] in [conversation]. [scope] defaults to [RetrievalScope.project].
  ///
  /// Offline-safe & deterministic under the stub embedding provider + the
  /// deterministic FTS, so a branch can be created with no network.
  Future<AssembledContext> assemble({
    required Conversation conversation,
    required Turn parent,
    required String prompt,
    RetrievalScope scope = RetrievalScope.project,
  }) async {
    // --- step 0: the verbatim tail (last 1–2 turns up to and including parent).
    final convTurns = await (_db.select(_db.turns)
          ..where((t) => t.conversationId.equals(conversation.id)))
        .get();
    final byId = {for (final t in convTurns) t.id: t};
    final ancestry = _ancestry(parent, byId); // root→parent inclusive
    final verbatim = ancestry.length <= verbatimTail
        ? ancestry
        : ancestry.sublist(ancestry.length - verbatimTail);

    // --- step 1: rewrite into standalone queries (coref-resolved).
    final queries = await _rewriter.rewrite(prompt, recentTurns: verbatim);

    // --- step 2: hybrid retrieval over scope.
    final candidates = await _retrieve(
      queries: queries,
      conversation: conversation,
      parent: parent,
      scope: scope,
      verbatim: verbatim,
    );

    // --- step 3: fork-aware scoring.
    final scored = _score(
      candidates,
      conversation: conversation,
      parent: parent,
      convTurns: convTurns,
      byId: byId,
    );

    // --- step 4: MMR diversify, then assemble.
    final selected = mmrSelect(
      scored,
      k: maxRetrieved,
      lambda: mmrLambda,
      similarityOf: _embeddingRedundancy,
    );

    return AssembledContext(
      verbatim: verbatim,
      retrieved: selected,
      preamble: _buildPreamble(selected),
      queries: queries,
    );
  }

  // ---- step 2: hybrid retrieval --------------------------------------------

  Future<List<_Candidate>> _retrieve({
    required List<String> queries,
    required Conversation conversation,
    required Turn parent,
    required RetrievalScope scope,
    required List<Turn> verbatim,
  }) async {
    // Embed every query once; the dense pass scores each proposition against
    // the best (max) cosine over the query vectors (multi-query union).
    final queryVectors = await _embedder.embed(queries);

    // Turns already kept verbatim must never be re-surfaced as retrieved items
    // (no duplicate of a turn already in the tail).
    final excludeTurnIds = {for (final t in verbatim) t.id, parent.id};

    final inScopeConversationIds = await _scopeConversationIds(
      scope: scope,
      conversation: conversation,
      parent: parent,
    );

    // Best similarity + committed flag per turn, merged across dense/sparse/fact.
    final byTurn = <String, _Candidate>{};
    void offer(Turn turn, double similarity, {bool committed = false, String? text}) {
      if (excludeTurnIds.contains(turn.id)) return;
      final existing = byTurn[turn.id];
      if (existing == null) {
        byTurn[turn.id] = _Candidate(
          turn: turn,
          similarity: similarity,
          committed: committed,
          text: text ?? _turnText(turn),
        );
      } else {
        byTurn[turn.id] = _Candidate(
          turn: turn,
          similarity: similarity > existing.similarity ? similarity : existing.similarity,
          committed: existing.committed || committed,
          text: existing.text,
        );
      }
    }

    // ---- dense: cosine vs proposition embeddings within scope.
    final props = await _propositionsInScope(
      scope: scope,
      conversation: conversation,
      inScopeConversationIds: inScopeConversationIds,
    );
    final bestPropSimByTurn = <String, double>{};
    final propEmbeddingByTurn = <String, List<double>>{};
    for (final p in props) {
      final blob = p.embedding;
      if (blob == null) continue;
      final vector = decodeEmbedding(blob);
      var best = 0.0;
      for (final q in queryVectors) {
        final s = cosineSimilarity(q, vector);
        if (s > best) best = s;
      }
      final prior = bestPropSimByTurn[p.turnId];
      if (prior == null || best > prior) {
        bestPropSimByTurn[p.turnId] = best;
        propEmbeddingByTurn[p.turnId] = vector;
      }
    }
    final turnCache = <String, Turn?>{};
    Future<Turn?> loadTurn(String id) async {
      if (turnCache.containsKey(id)) return turnCache[id];
      final t = await (_db.select(_db.turns)..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      turnCache[id] = t;
      return t;
    }

    for (final entry in bestPropSimByTurn.entries) {
      final turn = await loadTurn(entry.key);
      if (turn == null) continue;
      offer(turn, entry.value);
      // Remember the proposition embedding so MMR can measure redundancy.
      _redundancyVectors[turn.id] = propEmbeddingByTurn[entry.key]!;
    }

    // ---- sparse: FTS over the queries → turns. Rank-derived similarity so a
    // top FTS hit is comparable to a strong dense match without crowding it out.
    for (final query in queries) {
      final hits = await _db.searchTurnIds(query);
      for (var rank = 0; rank < hits.length; rank++) {
        final id = hits[rank];
        if (inScopeConversationIds != null) {
          final turn = await loadTurn(id);
          if (turn == null || !inScopeConversationIds.contains(turn.conversationId)) {
            continue;
          }
          offer(turn, _rankSimilarity(rank));
        } else {
          final turn = await loadTurn(id);
          if (turn == null) continue;
          offer(turn, _rankSimilarity(rank));
        }
      }
    }

    // ---- facts: cosine vs active fact embeddings (boosted, authoritative).
    final facts = await _activeFactsInScope(
      scope: scope,
      conversation: conversation,
      inScopeConversationIds: inScopeConversationIds,
    );
    for (final fact in facts) {
      final blob = fact.embedding;
      if (blob == null) continue;
      final vector = decodeEmbedding(blob);
      var best = 0.0;
      for (final q in queryVectors) {
        final s = cosineSimilarity(q, vector);
        if (s > best) best = s;
      }
      // A fact's provenance turns become committed candidates carrying the
      // fact's (boosted) similarity and the fact's text.
      final sources = await (_db.select(_db.factSources)
            ..where((fs) => fs.factId.equals(fact.id)))
          .get();
      final boosted = (best + factBoost).clamp(0.0, 1.0);
      for (final src in sources) {
        final turn = await loadTurn(src.turnId);
        if (turn == null) continue;
        offer(turn, boosted, committed: true, text: fact.factText);
      }
    }

    final out = byTurn.values.toList()
      ..sort((a, b) {
        final c = b.similarity.compareTo(a.similarity);
        return c != 0 ? c : a.turn.id.compareTo(b.turn.id);
      });
    return out.length <= candidatePoolSize
        ? out
        : out.sublist(0, candidatePoolSize);
  }

  /// Conversation ids the scope admits, or null for "no conversation filter"
  /// (project relies on the project-id filter on rows; all = unfiltered).
  Future<Set<String>?> _scopeConversationIds({
    required RetrievalScope scope,
    required Conversation conversation,
    required Turn parent,
  }) async {
    switch (scope) {
      case RetrievalScope.branch:
      case RetrievalScope.session:
        return {conversation.id};
      case RetrievalScope.project:
      case RetrievalScope.all:
        return null;
    }
  }

  Future<List<Proposition>> _propositionsInScope({
    required RetrievalScope scope,
    required Conversation conversation,
    required Set<String>? inScopeConversationIds,
  }) {
    final query = _db.select(_db.propositions)
      ..where((p) => p.embedding.isNotNull());
    switch (scope) {
      case RetrievalScope.branch:
      case RetrievalScope.session:
        query.where((p) => p.conversationId.equals(conversation.id));
      case RetrievalScope.project:
        query.where((p) => p.projectId.equals(conversation.projectId));
      case RetrievalScope.all:
        break;
    }
    return query.get();
  }

  Future<List<Fact>> _activeFactsInScope({
    required RetrievalScope scope,
    required Conversation conversation,
    required Set<String>? inScopeConversationIds,
  }) {
    final query = _db.select(_db.facts)
      ..where((f) => f.status.equals('active') & f.embedding.isNotNull());
    switch (scope) {
      case RetrievalScope.branch:
      case RetrievalScope.session:
        // Session-pinned facts (conversation_id set) plus project-wide ones.
        query.where(
          (f) =>
              f.conversationId.equals(conversation.id) |
              f.conversationId.isNull(),
        );
      case RetrievalScope.project:
        query.where((f) => f.projectId.equals(conversation.projectId));
      case RetrievalScope.all:
        break;
    }
    return query.get();
  }

  // ---- step 3: fork-aware scoring -------------------------------------------

  List<RetrievedItem> _score(
    List<_Candidate> candidates, {
    required Conversation conversation,
    required Turn parent,
    required List<Turn> convTurns,
    required Map<String, Turn> byId,
  }) {
    if (candidates.isEmpty) return const [];

    // Branch-proximity inputs: the active lineage of the current conversation,
    // and the parent's own ancestor chain (both derived from parent pointers +
    // current_turn_id — same inputs as the grid, no new storage).
    final active = activePath(convTurns, conversation.currentTurnId);
    final onActive = {for (final t in active) t.id};
    final parentAncestry = {for (final t in _ancestry(parent, byId)) t.id};

    // Recency baseline: the current turn's time, and the oldest candidate time,
    // so recency decays linearly from the current turn back to the oldest hit.
    final currentTime = parent.createTime ?? _maxTime(convTurns) ?? 0;
    var oldest = currentTime;
    for (final c in candidates) {
      final t = c.turn.createTime;
      if (t != null && t < oldest) oldest = t;
    }
    final timeSpan = (currentTime - oldest).toDouble();

    final out = <RetrievedItem>[];
    for (final c in candidates) {
      final recency = _recency(c.turn.createTime, currentTime, timeSpan);
      final proximity = _branchProximity(
        c.turn,
        conversation: conversation,
        onActive: onActive,
        parentAncestry: parentAncestry,
        byId: byId,
      );
      final diverged = _isDivergedSibling(
        c.turn,
        conversation: conversation,
        onActive: onActive,
        parentAncestry: parentAncestry,
      );
      final score = scoreCandidate(
        ScoringSignals(
          similarity: c.similarity,
          recency: recency,
          branchProximity: proximity,
          committed: c.committed,
          divergedSibling: diverged,
        ),
        weights,
      );
      out.add(
        RetrievedItem(
          turn: c.turn,
          similarity: c.similarity,
          committed: c.committed,
          text: c.text,
          score: score,
        ),
      );
    }
    out.sort((a, b) {
      final cmp = b.score.compareTo(a.score);
      return cmp != 0 ? cmp : a.turn.id.compareTo(b.turn.id);
    });
    return out;
  }

  /// `[0, 1]` recency: 1 at/after the current turn, decaying linearly to 0 at
  /// the oldest candidate. A candidate with no timestamp gets a neutral 0.5.
  double _recency(int? createTime, int currentTime, double timeSpan) {
    if (createTime == null) return 0.5;
    if (timeSpan <= 0) return 1.0;
    final age = (currentTime - createTime).toDouble();
    final r = 1.0 - (age / timeSpan);
    return r.clamp(0.0, 1.0);
  }

  /// `[0, 1]` branch proximity. A candidate in another conversation gets 0
  /// (cross-session is topical, not lineage-based). Within the conversation: 1
  /// on the active lineage, 1 on the parent's own ancestor chain (the branch
  /// being continued), and a decay by graph distance to the nearest of those
  /// for everything else. In the no-fork linear case every ancestor is on the
  /// active lineage, so this ≈ recency.
  double _branchProximity(
    Turn turn, {
    required Conversation conversation,
    required Set<String> onActive,
    required Set<String> parentAncestry,
    required Map<String, Turn> byId,
  }) {
    if (turn.conversationId != conversation.id) return 0.0;
    if (onActive.contains(turn.id) || parentAncestry.contains(turn.id)) {
      return 1.0;
    }
    // Distance: hops up the parent chain until we hit the active lineage or the
    // parent's ancestry, capped so far-off siblings still get a small value.
    var hops = 0;
    var cursor = turn.parentTurnId == null ? null : byId[turn.parentTurnId];
    final seen = <String>{turn.id};
    while (cursor != null && seen.add(cursor.id)) {
      hops++;
      if (onActive.contains(cursor.id) || parentAncestry.contains(cursor.id)) {
        return (1.0 / (1 + hops)).clamp(0.0, 1.0);
      }
      cursor = cursor.parentTurnId == null ? null : byId[cursor.parentTurnId!];
    }
    return 0.0;
  }

  /// Whether [turn] sits in a sibling subtree the user forked away from: in the
  /// current conversation, not on the active lineage and not on the parent's
  /// ancestry, but sharing a fork point with the parent's lineage (its chain
  /// rejoins the parent's ancestry above it). Soft — only flags the penalty.
  bool _isDivergedSibling(
    Turn turn, {
    required Conversation conversation,
    required Set<String> onActive,
    required Set<String> parentAncestry,
  }) {
    if (turn.conversationId != conversation.id) return false;
    if (onActive.contains(turn.id) || parentAncestry.contains(turn.id)) {
      return false;
    }
    // Off both the active lineage and the parent's ancestry → a diverged branch.
    return true;
  }

  // ---- step 5: assembly preamble --------------------------------------------

  /// Synthesizes the system preamble: a one-line note on how to read the tags,
  /// then each retrieved item tagged `{branch, committed?}` with its text
  /// (DESIGN.md §10 "tagged {branch, committed?}").
  String _buildPreamble(List<RetrievedItem> items) {
    if (items.isEmpty) return '';
    final buffer = StringBuffer()
      ..writeln(
        'Relevant earlier context retrieved from this project. Each item is '
        'tagged with its source branch and whether it is a committed '
        '(settled) fact; treat uncommitted items from different branches as '
        'tentative and possibly contradictory, not as agreed facts.',
      )
      ..writeln();
    for (final item in items) {
      final tag = item.committed
          ? '[branch:${item.branchId} · committed]'
          : '[branch:${item.branchId} · tentative]';
      buffer.writeln('$tag ${item.text.trim()}');
    }
    return buffer.toString().trim();
  }

  // ---- helpers --------------------------------------------------------------

  /// Redundancy between two retrieved items for MMR: cosine of their proposition
  /// embeddings when both are known, else 0 (treated as non-redundant).
  double _embeddingRedundancy(RetrievedItem a, RetrievedItem b) {
    final va = _redundancyVectors[a.turn.id];
    final vb = _redundancyVectors[b.turn.id];
    if (va == null || vb == null) return 0.0;
    return cosineSimilarity(va, vb).clamp(0.0, 1.0);
  }

  /// Per-turn proposition embedding kept from the dense pass, so MMR can measure
  /// inter-candidate redundancy without re-embedding. Scoped to one [assemble].
  final Map<String, List<double>> _redundancyVectors = {};

  /// Root→[turn] path (inclusive) within one conversation, cycle-guarded.
  List<Turn> _ancestry(Turn turn, Map<String, Turn> byId) {
    final path = <Turn>[];
    final seen = <String>{};
    Turn? cursor = turn;
    while (cursor != null && seen.add(cursor.id)) {
      path.add(cursor);
      final parentId = cursor.parentTurnId;
      cursor = parentId == null ? null : byId[parentId];
    }
    return path.reversed.toList();
  }

  /// A rank-derived similarity in `(0, 1]` for a sparse FTS hit at [rank]: the
  /// first hit ~0.9, decaying so a deep FTS-only hit can't outrank a strong
  /// dense match. Keeps sparse and dense on one comparable scale.
  double _rankSimilarity(int rank) => 0.9 / (1 + rank * 0.5);

  String _turnText(Turn turn) {
    final prompt = turn.promptMd.trim();
    final response = turn.responseMd.trim();
    if (prompt.isNotEmpty && response.isNotEmpty) return '$prompt\n\n$response';
    return prompt.isNotEmpty ? prompt : response;
  }

  int? _maxTime(List<Turn> turns) {
    int? max;
    for (final t in turns) {
      final time = t.createTime;
      if (time != null && (max == null || time > max)) max = time;
    }
    return max;
  }
}

/// Internal merge bucket: best similarity + committed flag + display text per
/// turn before scoring.
class _Candidate {
  const _Candidate({
    required this.turn,
    required this.similarity,
    required this.committed,
    required this.text,
  });

  final Turn turn;
  final double similarity;
  final bool committed;
  final String text;
}
