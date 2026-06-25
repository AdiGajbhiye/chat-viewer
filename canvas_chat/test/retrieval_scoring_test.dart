import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/state/retrieval.dart';
import 'package:flutter_test/flutter_test.dart';

Turn _turn(String id) => Turn(
      id: id,
      conversationId: 'c',
      promptMd: id,
      responseMd: '',
      rawJson: '[]',
    );

RetrievedItem _item(String id, double similarity) => RetrievedItem(
      turn: _turn(id),
      similarity: similarity,
      committed: false,
      text: id,
      score: similarity,
    );

void main() {
  group('scoreCandidate', () {
    const weights = RetrievalWeights();

    ScoringSignals signals({
      double similarity = 0.5,
      double recency = 0.5,
      double branchProximity = 0.5,
      bool committed = false,
      bool divergedSibling = false,
    }) =>
        ScoringSignals(
          similarity: similarity,
          recency: recency,
          branchProximity: branchProximity,
          committed: committed,
          divergedSibling: divergedSibling,
        );

    test('higher similarity scores higher (α term)', () {
      expect(
        scoreCandidate(signals(similarity: 0.9), weights),
        greaterThan(scoreCandidate(signals(similarity: 0.1), weights)),
      );
    });

    test('more recent scores higher (β term)', () {
      expect(
        scoreCandidate(signals(recency: 1.0), weights),
        greaterThan(scoreCandidate(signals(recency: 0.0), weights)),
      );
    });

    test('on the active lineage scores higher (γ branchProximity)', () {
      expect(
        scoreCandidate(signals(branchProximity: 1.0), weights),
        greaterThan(scoreCandidate(signals(branchProximity: 0.0), weights)),
      );
    });

    test('committed gets a boost (ε term)', () {
      expect(
        scoreCandidate(signals(committed: true), weights),
        greaterThan(scoreCandidate(signals(committed: false), weights)),
      );
      expect(
        scoreCandidate(signals(committed: true), weights) -
            scoreCandidate(signals(committed: false), weights),
        closeTo(weights.epsilonCommitted, 1e-9),
      );
    });

    test('diverged sibling is penalized (δ term), but not excluded', () {
      final penalized = scoreCandidate(signals(divergedSibling: true), weights);
      final clean = scoreCandidate(signals(divergedSibling: false), weights);
      expect(penalized, lessThan(clean));
      expect(clean - penalized, closeTo(weights.deltaDivergedSibling, 1e-9));
    });

    test('weights tune each term deterministically', () {
      // Zero out recency's weight → recency no longer changes the score.
      const noRecency = RetrievalWeights(betaRecency: 0);
      expect(
        scoreCandidate(signals(recency: 1.0), noRecency),
        closeTo(scoreCandidate(signals(recency: 0.0), noRecency), 1e-9),
      );
    });
  });

  group('mmrSelect', () {
    test('redundant near-duplicates get diversified out', () {
      // a and b are near-identical (high mutual similarity); c is distinct.
      // With low-ish lambda, MMR should pick a then c (not a then b).
      final items = [_item('a', 0.9), _item('b', 0.89), _item('c', 0.6)];
      double sim(RetrievedItem x, RetrievedItem y) {
        final pair = {x.turn.id, y.turn.id};
        if (pair.containsAll({'a', 'b'})) return 0.99; // a~b redundant
        return 0.0;
      }

      final picked = mmrSelect(items, k: 2, lambda: 0.5, similarityOf: sim);
      expect(picked.map((i) => i.turn.id), ['a', 'c']);
    });

    test('lambda=1 is pure relevance (top-k by score)', () {
      final items = [_item('a', 0.9), _item('b', 0.89), _item('c', 0.6)];
      double sim(RetrievedItem x, RetrievedItem y) => 0.99; // all redundant
      // Pure relevance ignores redundancy → highest two scores: a, b.
      final picked = mmrSelect(items, k: 2, lambda: 1.0, similarityOf: sim);
      expect(picked.map((i) => i.turn.id), ['a', 'b']);
    });

    test('lambda=0 is pure diversity (avoids the redundant one)', () {
      final items = [_item('a', 0.9), _item('b', 0.89), _item('c', 0.6)];
      double sim(RetrievedItem x, RetrievedItem y) {
        final pair = {x.turn.id, y.turn.id};
        if (pair.containsAll({'a', 'b'})) return 0.99;
        return 0.0;
      }

      // First pick is the top-scored (a); the second pick under pure diversity
      // is whichever is least redundant with a → c, never b.
      final picked = mmrSelect(items, k: 2, lambda: 0.0, similarityOf: sim);
      expect(picked.first.turn.id, 'a');
      expect(picked[1].turn.id, 'c');
    });

    test('with no similarity function degenerates to top-k by score', () {
      final items = [_item('a', 0.3), _item('b', 0.9), _item('c', 0.6)];
      final picked = mmrSelect(items, k: 2);
      expect(picked.map((i) => i.turn.id), ['b', 'c']);
    });
  });
}
