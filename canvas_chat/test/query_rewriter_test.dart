import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/data/llm/llm_provider.dart';
import 'package:canvas_chat/src/data/llm/query_rewriter.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fake [LlmProvider] yielding a fixed payload, so [LlmQueryRewriter]'s
/// collect + parse is testable without a model.
class _FixedProvider implements LlmProvider {
  _FixedProvider(this.payload);
  final String payload;

  @override
  Stream<String> generate({
    required String prompt,
    required List<Turn> context,
    String? preamble,
  }) async* {
    yield payload;
  }
}

Turn _turn({String prompt = '', String response = ''}) => Turn(
      id: 't',
      conversationId: 'c',
      promptMd: prompt,
      responseMd: response,
      rawJson: '[]',
    );

void main() {
  group('StubQueryRewriter', () {
    test('is deterministic for the same inputs', () async {
      const rewriter = StubQueryRewriter();
      final last = _turn(prompt: 'How do I tune the kNN query latency?');
      final a = await rewriter.rewrite('make that faster', recentTurns: [last]);
      final b = await rewriter.rewrite('make that faster', recentTurns: [last]);
      expect(a, b);
    });

    test('carries salient terms from the last turn into the query', () async {
      const rewriter = StubQueryRewriter();
      final last = _turn(
        prompt: 'We are discussing Postgres indexing strategies.',
        response: 'A BRIN index suits append-only tables.',
      );
      final queries =
          await rewriter.rewrite('make that faster', recentTurns: [last]);

      // Augmented query first (multi-query: augmented + bare), and it carries
      // topic words the bare follow-up lacks.
      expect(queries.length, greaterThanOrEqualTo(2));
      expect(queries.first, contains('make that faster'));
      expect(queries.first.toLowerCase(), contains('postgres'));
      expect(queries.last, 'make that faster');
    });

    test('with no context yields just the bare prompt', () async {
      const rewriter = StubQueryRewriter();
      final queries = await rewriter.rewrite('explain entanglement');
      expect(queries, ['explain entanglement']);
    });

    test('never returns empty even for a blank prompt', () async {
      const rewriter = StubQueryRewriter();
      final queries = await rewriter.rewrite('   ');
      expect(queries, isNotEmpty);
    });
  });

  group('LlmQueryRewriter', () {
    test('parses a JSON array of queries (tolerates fences/prose)', () async {
      final rewriter = LlmQueryRewriter(
        _FixedProvider(
          'Sure:\n```json\n["optimize kNN query latency", '
          '"vector index tuning", "optimize kNN query latency"]\n```',
        ),
      );
      final queries = await rewriter.rewrite('make that faster');
      // De-duplicated, order preserved.
      expect(queries, ['optimize kNN query latency', 'vector index tuning']);
    });

    test('falls back to the bare prompt on unparseable output', () async {
      final rewriter = LlmQueryRewriter(_FixedProvider('not json at all'));
      final queries = await rewriter.rewrite('the original prompt');
      expect(queries, ['the original prompt']);
    });
  });
}
