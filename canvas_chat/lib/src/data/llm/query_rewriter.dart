import 'dart:convert';

import '../db/database.dart';
import 'llm_provider.dart';
import 'openai_compatible_provider.dart' show LlmException;

/// Rewrites a new, possibly content-free follow-up prompt into one or more
/// **standalone, coref-resolved** search queries using the last 1–2 turns
/// (DESIGN.md §10 step 1: "make that faster" → "optimize the k-NN query").
///
/// This is load-bearing because drift makes follow-ups content-free, so
/// raw-prompt retrieval fails exactly when it's needed; the "few query prompts"
/// idea lives here as multi-query expansion. Clones the [LlmProvider] stub-vs-
/// real pattern: v1 ships a fully-offline [StubQueryRewriter] and a real
/// [LlmQueryRewriter]; the retrieval layer is rewriter-agnostic.
abstract interface class QueryRewriter {
  /// Produces one or more standalone search queries for [prompt], given
  /// [recentTurns] (the last 1–2 turns, oldest→newest) for coreference
  /// resolution. The returned list is non-empty and de-duplicated; the first
  /// entry is always a usable query (the original prompt at minimum).
  Future<List<String>> rewrite(
    String prompt, {
    List<Turn> recentTurns = const [],
  });
}

/// The default, fully-offline rewriter: no network, no model. It augments the
/// raw [prompt] with salient terms pulled from the last turn (so a content-free
/// follow-up like "make that faster" still carries the topic words from what it
/// refers to), and emits the augmented query alongside the bare prompt as a
/// second query for recall. Deterministic by construction — the **same inputs
/// always yield the same queries** — so retrieval is reproducible offline.
/// Semantically weak (it's term carry-over, not real coref); swap in
/// [LlmQueryRewriter] for true rewriting.
class StubQueryRewriter implements QueryRewriter {
  const StubQueryRewriter({this.maxSalientTerms = 6});

  /// Cap on salient terms carried over from the last turn, keeping the
  /// augmented query focused.
  final int maxSalientTerms;

  @override
  Future<List<String>> rewrite(
    String prompt, {
    List<Turn> recentTurns = const [],
  }) async {
    final base = prompt.trim();
    final out = <String>[];
    final seen = <String>{};
    void add(String q) {
      final v = q.trim();
      if (v.isEmpty) return;
      if (seen.add(v.toLowerCase())) out.add(v);
    }

    // Salient terms from the most recent turn (its prompt + response), minus
    // anything already in the prompt — the coref carry-over.
    final last = recentTurns.isEmpty ? null : recentTurns.last;
    final salient = last == null
        ? const <String>[]
        : _salientTerms(
            '${last.promptMd} ${last.responseMd}',
            exclude: _tokens(base).toSet(),
          );

    if (salient.isEmpty) {
      add(base);
    } else {
      // Augmented query first (the better retrieval probe), then the bare
      // prompt second for recall (multi-query expansion).
      add('$base ${salient.join(' ')}');
      add(base);
    }
    // Never return empty: a blank prompt with no context still yields one query
    // (the raw prompt as-is, even if it's only whitespace) so callers can rely
    // on a non-empty list.
    if (out.isEmpty) return [prompt];
    return out;
  }

  /// First-seen, de-duplicated salient terms from [text]: lowercase word tokens
  /// of length ≥ 4 that aren't stopwords and aren't in [exclude], capped at
  /// [maxSalientTerms]. Stable for given inputs.
  List<String> _salientTerms(String text, {Set<String> exclude = const {}}) {
    final out = <String>[];
    final seen = <String>{};
    for (final token in _tokens(text)) {
      if (token.length < 4 || _stopwords.contains(token)) continue;
      if (exclude.contains(token)) continue;
      if (seen.add(token)) out.add(token);
      if (out.length >= maxSalientTerms) break;
    }
    return out;
  }

  Iterable<String> _tokens(String text) => text
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((t) => t.isNotEmpty);

  static const _stopwords = {
    'this', 'that', 'them', 'they', 'with', 'from', 'into', 'your', 'have',
    'what', 'when', 'will', 'make', 'more', 'about', 'these', 'those', 'their',
    'there', 'which', 'would', 'could', 'should', 'than', 'then', 'also',
  };
}

/// A real [QueryRewriter] backed by an [LlmProvider]. It asks the model to
/// return STRICT JSON — a small array of standalone query strings, coref-
/// resolved against the recent turns — collects the full [LlmProvider.generate]
/// stream, and parses it robustly (tolerating ```json fences and surrounding
/// prose by slicing out the outermost JSON array, mirroring
/// [LlmPropositionExtractor]). On any parse failure it **falls back to the bare
/// prompt** rather than throwing, so a flaky rewrite never blocks a branch.
class LlmQueryRewriter implements QueryRewriter {
  const LlmQueryRewriter(this._llm, {this.targetCount = 3});

  final LlmProvider _llm;

  /// How many queries to request (small multi-query expansion).
  final int targetCount;

  @override
  Future<List<String>> rewrite(
    String prompt, {
    List<Turn> recentTurns = const [],
  }) async {
    final base = prompt.trim();
    try {
      final buffer = StringBuffer();
      await for (final delta
          in _llm.generate(prompt: _buildPrompt(base, recentTurns), context: const [])) {
        buffer.write(delta);
      }
      final queries = _parse(buffer.toString());
      if (queries.isNotEmpty) return queries;
    } on LlmException {
      // fall through to the bare-prompt fallback
    } catch (_) {
      // any other failure (network, decode) — fall through
    }
    return [if (base.isNotEmpty) base else prompt];
  }

  String _buildPrompt(String prompt, List<Turn> recentTurns) {
    final context = StringBuffer();
    for (final t in recentTurns) {
      if (t.promptMd.trim().isNotEmpty) {
        context.writeln('User: ${t.promptMd.trim()}');
      }
      if (t.responseMd.trim().isNotEmpty) {
        context.writeln('Assistant: ${t.responseMd.trim()}');
      }
    }
    return 'Rewrite the user\'s new message into up to $targetCount standalone '
        'search queries for retrieving relevant earlier discussion. Each query '
        'must:\n'
        '- be self-contained (resolve pronouns / "that" / "it" using the recent '
        'context — no dangling references);\n'
        '- be a short keyword-style search query, not a sentence.\n\n'
        'Return ONLY a JSON array of strings, no prose, no markdown fences. '
        'Example: ["optimize k-NN query latency", "vector index tuning"]\n\n'
        '${context.isEmpty ? '' : 'Recent context:\n$context\n'}'
        'New message: $prompt\n';
  }

  /// Parses the model output into a de-duplicated, non-empty list of query
  /// strings. Tolerates ```json fences / surrounding prose by slicing the
  /// outermost `[ … ]`. Returns an empty list on any failure (caller falls
  /// back to the bare prompt).
  List<String> _parse(String raw) {
    final json = _extractJsonArray(raw);
    if (json == null) return const [];
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } catch (_) {
      return const [];
    }
    if (decoded is! List) return const [];
    final out = <String>[];
    final seen = <String>{};
    for (final item in decoded) {
      if (item == null) continue;
      final s = item.toString().trim();
      if (s.isEmpty) continue;
      if (seen.add(s.toLowerCase())) out.add(s);
    }
    return out;
  }

  /// Slices out the outermost JSON array from [raw] (first `[` to its matching
  /// `]`), ignoring brackets inside double-quoted strings. Mirrors
  /// [LlmPropositionExtractor]'s robust extractor.
  String? _extractJsonArray(String raw) {
    final start = raw.indexOf('[');
    if (start < 0) return null;
    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var i = start; i < raw.length; i++) {
      final ch = raw[i];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (ch == r'\') {
          escaped = true;
        } else if (ch == '"') {
          inString = false;
        }
        continue;
      }
      if (ch == '"') {
        inString = true;
      } else if (ch == '[') {
        depth++;
      } else if (ch == ']') {
        depth--;
        if (depth == 0) return raw.substring(start, i + 1);
      }
    }
    return null;
  }
}
