import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'embedding_provider.dart';
import 'openai_compatible_provider.dart' show LlmException;

/// Connection settings for an OpenAI-compatible `/embeddings` endpoint.
///
/// Reuses the chat plumbing's [baseUrl] / [apiKey] (an OpenAI-compatible host
/// typically serves both chat and embeddings) and adds only the embedding
/// [model] — e.g. `text-embedding-3-small`, or a local Ollama embedding model
/// against `http://localhost:11434/v1`.
class EmbeddingConfig {
  const EmbeddingConfig({
    this.baseUrl = 'https://api.openai.com/v1',
    this.apiKey = '',
    this.model = 'text-embedding-3-small',
  });

  /// API root *without* a trailing slash, e.g. `https://api.openai.com/v1`.
  final String baseUrl;

  /// Bearer token. May be blank for a keyless local endpoint (see
  /// [isConfigured]).
  final String apiKey;

  /// Embedding model id, e.g. `text-embedding-3-small`, `nomic-embed-text`.
  final String model;

  /// Whether this config can reach a backend: a model plus either a key or a
  /// localhost endpoint (Ollama needs no key). A blank key against a remote host
  /// stays "unconfigured" so the app falls back to the offline stub instead of
  /// firing doomed 401s. Mirrors [LlmConfig.isConfigured].
  bool get isConfigured {
    if (model.trim().isEmpty) return false;
    if (apiKey.trim().isNotEmpty) return true;
    final host = Uri.tryParse(baseUrl)?.host ?? '';
    return host == 'localhost' || host == '127.0.0.1';
  }

  EmbeddingConfig copyWith({
    String? baseUrl,
    String? apiKey,
    String? model,
  }) =>
      EmbeddingConfig(
        baseUrl: baseUrl ?? this.baseUrl,
        apiKey: apiKey ?? this.apiKey,
        model: model ?? this.model,
      );
}

/// A live [EmbeddingProvider] talking to any OpenAI-compatible `/embeddings`
/// endpoint. POSTs the whole batch as `input` and returns one vector per input
/// in request order (the endpoint echoes an `index` per row, which we sort by
/// to be safe). Reuses [LlmException] so failures surface identically to chat.
class OpenAiCompatibleEmbeddingProvider implements EmbeddingProvider {
  OpenAiCompatibleEmbeddingProvider(this.config, {http.Client? client})
      : _client = client ?? http.Client();

  final EmbeddingConfig config;
  final http.Client _client;

  /// Releases the underlying connection pool. Call when the provider is
  /// replaced (see `embeddingProviderProvider`).
  void close() => _client.close();

  @override
  String get modelId => config.model;

  @override
  Future<List<List<double>>> embed(List<String> texts) async {
    if (texts.isEmpty) return const [];

    final headers = {'content-type': 'application/json'};
    if (config.apiKey.trim().isNotEmpty) {
      headers['authorization'] = 'Bearer ${config.apiKey}';
    }
    final response = await _client.post(
      Uri.parse('${config.baseUrl}/embeddings'),
      headers: headers,
      body: jsonEncode({'model': config.model, 'input': texts}),
    );
    if (response.statusCode != 200) {
      throw LlmException(_describeError(response.statusCode, response.body));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List?;
    if (data == null) {
      throw LlmException('Malformed embeddings response: missing "data"');
    }
    // Order by the endpoint's `index` so the result lines up with `texts` even
    // if rows come back out of order.
    final rows = data.cast<Map<String, dynamic>>().toList()
      ..sort((a, b) => (a['index'] as int? ?? 0).compareTo(b['index'] as int? ?? 0));
    return [
      for (final row in rows)
        [for (final v in row['embedding'] as List) (v as num).toDouble()],
    ];
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
