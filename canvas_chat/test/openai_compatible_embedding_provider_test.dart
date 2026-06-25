import 'dart:convert';

import 'package:canvas_chat/src/data/llm/openai_compatible_embedding_provider.dart';
import 'package:canvas_chat/src/data/llm/openai_compatible_provider.dart'
    show LlmException;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('posts the batch as `input` and returns one vector per text in order',
      () async {
    late Map<String, dynamic> sent;
    String? auth;
    final client = MockClient((request) async {
      auth = request.headers['authorization'];
      sent = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({
          'data': [
            // Deliberately out of order to exercise the index sort.
            {'index': 1, 'embedding': [0.3, 0.4]},
            {'index': 0, 'embedding': [0.1, 0.2]},
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final provider = OpenAiCompatibleEmbeddingProvider(
      const EmbeddingConfig(apiKey: 'sk-test', model: 'text-embedding-3-small'),
      client: client,
    );

    final out = await provider.embed(['first', 'second']);

    expect(auth, 'Bearer sk-test');
    expect(sent['model'], 'text-embedding-3-small');
    expect(sent['input'], ['first', 'second']);
    expect(out, [
      [0.1, 0.2],
      [0.3, 0.4],
    ]);
    expect(provider.modelId, 'text-embedding-3-small');
  });

  test('short-circuits empty input without hitting the network', () async {
    var called = false;
    final client = MockClient((request) async {
      called = true;
      return http.Response('{}', 200);
    });
    final provider = OpenAiCompatibleEmbeddingProvider(
      const EmbeddingConfig(apiKey: 'sk-test'),
      client: client,
    );

    expect(await provider.embed(const []), isEmpty);
    expect(called, isFalse);
  });

  test('throws LlmException carrying the endpoint error on a non-200', () async {
    final client = MockClient((request) async => http.Response(
          '{"error":{"message":"bad key"}}',
          401,
        ));
    final provider = OpenAiCompatibleEmbeddingProvider(
      const EmbeddingConfig(apiKey: 'sk-bad'),
      client: client,
    );

    expect(
      () => provider.embed(['x']),
      throwsA(isA<LlmException>()
          .having((e) => e.message, 'message', 'HTTP 401: bad key')),
    );
  });

  group('EmbeddingConfig.isConfigured', () {
    test('false for a blank key against a remote host', () {
      expect(const EmbeddingConfig().isConfigured, isFalse);
    });
    test('true once a key is supplied', () {
      expect(const EmbeddingConfig(apiKey: 'sk-x').isConfigured, isTrue);
    });
    test('true for a keyless localhost endpoint (Ollama)', () {
      expect(
        const EmbeddingConfig(
          baseUrl: 'http://localhost:11434/v1',
          model: 'nomic-embed-text',
        ).isConfigured,
        isTrue,
      );
    });
  });
}
