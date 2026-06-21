import 'dart:convert';

import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/data/llm/openai_compatible_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';

/// A paired turn carrying a user prompt and an assistant response.
Turn _turn(String id, {String prompt = '', String response = ''}) => Turn(
      id: id,
      conversationId: 'c',
      parentTurnId: null,
      promptMd: prompt,
      responseMd: response,
      rawJson: '[]',
      createTime: null,
    );

/// One OpenAI streaming frame carrying a content delta.
String _chunk(String content) => jsonEncode({
      'choices': [
        {'delta': content.isEmpty ? <String, dynamic>{} : {'content': content}}
      ]
    });

/// A `\n`-terminated SSE byte stream from raw lines (the provider splits on
/// newlines, so this mirrors the wire format closely enough).
Stream<List<int>> _sse(List<String> lines) =>
    Stream.fromIterable(lines.map((l) => utf8.encode('$l\n')));

void main() {
  test('streams content deltas in order, ignoring comments/blanks, stops at [DONE]',
      () async {
    final client = MockClient.streaming((request, _) async {
      return http.StreamedResponse(
        _sse([
          ': keep-alive', // SSE comment
          'data: ${_chunk('Hello')}',
          '', // blank separator
          'data: ${_chunk(' ')}',
          'data: ${_chunk('world')}',
          'data: [DONE]',
          'data: ${_chunk('AFTER-DONE')}', // never read
        ]),
        200,
        request: request,
      );
    });
    final provider = OpenAiCompatibleProvider(
      const LlmConfig(apiKey: 'sk-test'),
      client: client,
    );

    final deltas =
        await provider.generate(prompt: 'hi', context: const []).toList();

    expect(deltas, ['Hello', ' ', 'world']);
    expect(deltas.join(), 'Hello world');
  });

  test('builds the messages array from the context path plus the new prompt',
      () async {
    late Map<String, dynamic> sent;
    String? auth;
    final client = MockClient.streaming((request, bodyStream) async {
      auth = request.headers['authorization'];
      sent = jsonDecode(await bodyStream.bytesToString()) as Map<String, dynamic>;
      return http.StreamedResponse(_sse(['data: [DONE]']), 200, request: request);
    });
    final provider = OpenAiCompatibleProvider(
      const LlmConfig(apiKey: 'sk-test', model: 'gpt-4o-mini'),
      client: client,
    );

    await provider.generate(
      prompt: 'q2',
      context: [_turn('a', prompt: 'q1', response: 'r1')],
    ).toList();

    expect(auth, 'Bearer sk-test');
    expect(sent['model'], 'gpt-4o-mini');
    expect(sent['stream'], true);
    expect(sent['messages'], [
      {'role': 'user', 'content': 'q1'},
      {'role': 'assistant', 'content': 'r1'},
      {'role': 'user', 'content': 'q2'},
    ]);
  });

  test('prepends a system prompt and drops empty prompt/response sides',
      () async {
    late Map<String, dynamic> sent;
    final client = MockClient.streaming((request, bodyStream) async {
      sent = jsonDecode(await bodyStream.bytesToString()) as Map<String, dynamic>;
      return http.StreamedResponse(_sse(['data: [DONE]']), 200, request: request);
    });
    final provider = OpenAiCompatibleProvider(
      const LlmConfig(apiKey: 'sk-test', systemPrompt: 'Be terse.'),
      client: client,
    );

    await provider.generate(
      prompt: 'q',
      context: [
        _turn('root', response: 'r0'), // assistant-only (no prompt)
        _turn('mid', prompt: 'p1'), // user-only (no response)
      ],
    ).toList();

    expect(sent['messages'], [
      {'role': 'system', 'content': 'Be terse.'},
      {'role': 'assistant', 'content': 'r0'},
      {'role': 'user', 'content': 'p1'},
      {'role': 'user', 'content': 'q'},
    ]);
  });

  test('throws LlmException carrying the endpoint error on a non-200', () async {
    final client = MockClient.streaming((request, _) async {
      return http.StreamedResponse(
        Stream.value(utf8.encode('{"error":{"message":"bad key"}}')),
        401,
        request: request,
      );
    });
    final provider = OpenAiCompatibleProvider(
      const LlmConfig(apiKey: 'sk-bad'),
      client: client,
    );

    expect(
      () => provider.generate(prompt: 'x', context: const []).toList(),
      throwsA(isA<LlmException>()
          .having((e) => e.message, 'message', 'HTTP 401: bad key')),
    );
  });

  group('LlmConfig.isConfigured', () {
    test('false for a blank key against a remote host', () {
      expect(const LlmConfig().isConfigured, isFalse);
    });
    test('true once a key is supplied', () {
      expect(const LlmConfig(apiKey: 'sk-x').isConfigured, isTrue);
    });
    test('true for a keyless localhost endpoint (Ollama)', () {
      expect(
        const LlmConfig(baseUrl: 'http://localhost:11434/v1', model: 'llama3.2')
            .isConfigured,
        isTrue,
      );
    });
  });
}
