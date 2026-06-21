import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../db/database.dart';
import 'llm_provider.dart';

/// Connection settings for an OpenAI-compatible `/chat/completions` endpoint.
///
/// The same wire format is spoken by OpenAI, OpenRouter, Groq, Together, and a
/// local Ollama (`http://localhost:11434/v1`) — so one [LlmProvider] covers all
/// of them; only [baseUrl] / [apiKey] / [model] change.
class LlmConfig {
  const LlmConfig({
    this.baseUrl = 'https://api.openai.com/v1',
    this.apiKey = '',
    this.model = 'gpt-4o-mini',
    this.systemPrompt,
  });

  /// API root *without* a trailing slash, e.g. `https://api.openai.com/v1`.
  final String baseUrl;

  /// Bearer token. May be blank for a keyless local endpoint (see
  /// [isConfigured]).
  final String apiKey;

  /// Model id, e.g. `gpt-4o-mini`, `openai/gpt-4o`, `llama3.2`.
  final String model;

  /// Optional system message prepended to every request.
  final String? systemPrompt;

  /// Whether this config can actually reach a backend: a model plus either a
  /// key or a localhost endpoint (Ollama needs no key). A blank key against a
  /// remote host stays "unconfigured" so the app falls back to the offline
  /// stub instead of firing doomed 401s.
  bool get isConfigured {
    if (model.trim().isEmpty) return false;
    if (apiKey.trim().isNotEmpty) return true;
    final host = Uri.tryParse(baseUrl)?.host ?? '';
    return host == 'localhost' || host == '127.0.0.1';
  }

  LlmConfig copyWith({
    String? baseUrl,
    String? apiKey,
    String? model,
    String? systemPrompt,
  }) =>
      LlmConfig(
        baseUrl: baseUrl ?? this.baseUrl,
        apiKey: apiKey ?? this.apiKey,
        model: model ?? this.model,
        systemPrompt: systemPrompt ?? this.systemPrompt,
      );
}

/// Thrown when the endpoint returns a non-2xx status or streams an error frame.
/// Carries the provider's own message so the failure surfaces verbatim in the
/// branch ([BranchService] writes `_Generation failed: …_` into the turn).
class LlmException implements Exception {
  LlmException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A live [LlmProvider] talking to any OpenAI-compatible chat endpoint.
///
/// Streams the assistant reply as incremental markdown deltas via SSE
/// (`stream: true`). The root→parent [Turn] path becomes the message history;
/// each paired turn contributes a `user` message (its prompt) and an
/// `assistant` message (its response), with the new [generate] `prompt`
/// appended as the final `user` turn.
class OpenAiCompatibleProvider implements LlmProvider {
  OpenAiCompatibleProvider(this.config, {http.Client? client})
      : _client = client ?? http.Client();

  final LlmConfig config;
  final http.Client _client;

  /// Releases the underlying connection pool. Call when the provider is
  /// replaced (see `llmProviderProvider`).
  void close() => _client.close();

  @override
  Stream<String> generate({
    required String prompt,
    required List<Turn> context,
  }) async* {
    final request =
        http.Request('POST', Uri.parse('${config.baseUrl}/chat/completions'))
          ..headers['content-type'] = 'application/json'
          ..headers['accept'] = 'text/event-stream'
          ..body = jsonEncode({
            'model': config.model,
            'stream': true,
            'messages': _messages(prompt, context),
          });
    if (config.apiKey.trim().isNotEmpty) {
      request.headers['authorization'] = 'Bearer ${config.apiKey}';
    }

    final response = await _client.send(request);
    if (response.statusCode != 200) {
      throw LlmException(
        _describeError(response.statusCode, await response.stream.bytesToString()),
      );
    }

    // OpenAI streams one `data: {json}` line per token, terminated by
    // `data: [DONE]`; blank lines and `:`-comments (keep-alives) are skipped.
    await for (final line in response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (!line.startsWith('data:')) continue;
      final data = line.substring(5).trim();
      if (data == '[DONE]') break;
      if (data.isEmpty) continue;

      final Map<String, dynamic> frame;
      try {
        frame = jsonDecode(data) as Map<String, dynamic>;
      } catch (_) {
        continue; // partial / non-JSON frame — ignore
      }
      if (frame['error'] != null) {
        throw LlmException(_errorMessage(frame['error']) ?? frame['error'].toString());
      }

      final choices = frame['choices'] as List?;
      if (choices == null || choices.isEmpty) continue;
      final delta = (choices.first as Map)['delta'] as Map?;
      final content = delta?['content'];
      if (content is String && content.isNotEmpty) yield content;
    }
  }

  List<Map<String, String>> _messages(String prompt, List<Turn> context) {
    final messages = <Map<String, String>>[];
    final system = config.systemPrompt?.trim();
    if (system != null && system.isNotEmpty) {
      messages.add({'role': 'system', 'content': system});
    }
    for (final turn in context) {
      if (turn.promptMd.trim().isNotEmpty) {
        messages.add({'role': 'user', 'content': turn.promptMd});
      }
      if (turn.responseMd.trim().isNotEmpty) {
        messages.add({'role': 'assistant', 'content': turn.responseMd});
      }
    }
    messages.add({'role': 'user', 'content': prompt});
    return messages;
  }

  String _describeError(int status, String body) {
    final message = _errorMessage(_tryDecode(body)?['error']);
    if (message != null) return 'HTTP $status: $message';
    final snippet = body.length > 300 ? '${body.substring(0, 300)}…' : body;
    return 'HTTP $status: $snippet';
  }

  /// Pulls the human-readable string from OpenAI's `{"message": …}` (or a bare
  /// string) error shape.
  String? _errorMessage(Object? error) {
    if (error is String) return error;
    if (error is Map) {
      final message = error['message'];
      if (message is String) return message;
    }
    return null;
  }

  Map<String, dynamic>? _tryDecode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
