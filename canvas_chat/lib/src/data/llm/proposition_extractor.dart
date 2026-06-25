import 'dart:convert';

import '../db/database.dart';
import 'llm_provider.dart';
import 'openai_compatible_provider.dart' show LlmException;

/// One atomic, standalone, coref-resolved statement distilled from a turn
/// (DESIGN.md §10 "Proposition index"). Entities are kept as the model's / the
/// heuristic's **raw** surface strings here; normalization (lowercase/trim and
/// de-duplication by `(projectId, normalized)`) happens at persistence, so the
/// extractor stays purely about *what was said*, not *how it's stored*.
class ExtractedProposition {
  const ExtractedProposition({
    required this.text,
    this.aspect,
    this.entities = const [],
  });

  /// The proposition statement (the future `propositions.text` column).
  final String text;

  /// Open-vocab aspect tag (not a fixed bucket) — e.g. `definition`,
  /// `instruction`, `claim`. May be null when none was assigned.
  final String? aspect;

  /// Raw entity surface strings mentioned by this proposition.
  final List<String> entities;
}

/// The whole-turn extraction result: the handful (~5) of propositions a turn
/// distills into. Plain data; the indexer embeds the proposition texts and the
/// repository persists them.
class TurnExtraction {
  const TurnExtraction({this.propositions = const []});

  final List<ExtractedProposition> propositions;
}

/// A pluggable proposition + entity extractor for the index (DESIGN.md §10).
/// Clones the [LlmProvider] / [EmbeddingProvider] stub-vs-real pattern: v1 ships
/// a fully-offline [StubPropositionExtractor] and a real
/// [LlmPropositionExtractor] that wraps an [LlmProvider]; the indexer is
/// extractor-agnostic.
abstract interface class PropositionExtractor {
  /// Distills [turn] into ~5 standalone propositions. [parentContext] is the
  /// root→parent turn path (same shape an `LlmProvider` receives), given so an
  /// isolated turn's propositions can be coref-resolved against what came
  /// before instead of summarizing to noise.
  Future<TurnExtraction> extract(
    Turn turn, {
    List<Turn> parentContext = const [],
  });
}

/// The default, fully-offline extractor: no network, no model. It segments the
/// turn's prompt + response into sentences/lines, caps at [maxPropositions],
/// and pulls naive entities (capitalized tokens, `code` identifiers, "quoted"
/// terms). Deterministic by construction — the **same turn always yields the
/// same extraction**, in every run and process (stable arithmetic over code
/// units; no `hashCode`, no randomness) — so a re-index produces identical rows.
/// Semantically weak (it's heuristics, not a model); swap in
/// [LlmPropositionExtractor] for real propositions.
class StubPropositionExtractor implements PropositionExtractor {
  const StubPropositionExtractor({this.maxPropositions = 5});

  /// Upper bound on propositions per turn (~5, DESIGN.md §10).
  final int maxPropositions;

  @override
  Future<TurnExtraction> extract(
    Turn turn, {
    List<Turn> parentContext = const [],
  }) async {
    // Prefer the response (the substance) then fall back to the prompt, so a
    // turn with an empty response still yields something.
    final source = turn.responseMd.trim().isNotEmpty
        ? turn.responseMd
        : turn.promptMd;
    final segments = _segment(source);

    final propositions = <ExtractedProposition>[];
    for (final segment in segments) {
      if (propositions.length >= maxPropositions) break;
      propositions.add(
        ExtractedProposition(
          text: segment,
          aspect: _aspect(segment),
          entities: _entities(segment),
        ),
      );
    }
    return TurnExtraction(propositions: propositions);
  }

  /// Splits text into trimmed, non-empty segments: first by line, then each
  /// line by sentence terminators (`.`, `!`, `?`). Markdown bullet / heading
  /// markers and surrounding whitespace are stripped so a segment reads as a
  /// statement, not a list item. Order is preserved (deterministic).
  List<String> _segment(String text) {
    final out = <String>[];
    for (final line in text.split('\n')) {
      for (final raw in line.split(RegExp(r'(?<=[.!?])\s+'))) {
        final cleaned = raw
            .replaceFirst(RegExp(r'^\s*(?:[-*+>#]+|\d+[.)])\s*'), '')
            .trim();
        if (cleaned.isNotEmpty) out.add(cleaned);
      }
    }
    return out;
  }

  /// A simple, deterministic open-vocab aspect tag derived from the segment's
  /// shape — enough to be sensible and stable, not smart. A question is a
  /// `question`; a fenced/inline-code or imperative-looking line is
  /// `instruction`; an "X is/are …" line is a `definition`; everything else is
  /// a `statement`.
  String _aspect(String segment) {
    final lower = segment.toLowerCase();
    if (segment.contains('?')) return 'question';
    if (segment.contains('`') ||
        segment.contains('```') ||
        _startsWithImperative(lower)) {
      return 'instruction';
    }
    if (RegExp(r'\b(is|are|was|were|means|refers to)\b').hasMatch(lower)) {
      return 'definition';
    }
    return 'statement';
  }

  static const _imperatives = {
    'run', 'use', 'add', 'set', 'create', 'install', 'open', 'call', 'make',
    'write', 'remove', 'delete', 'import', 'export', 'click', 'enter', 'select',
  };

  bool _startsWithImperative(String lower) {
    final first = RegExp(r'^[a-z]+').firstMatch(lower)?.group(0);
    return first != null && _imperatives.contains(first);
  }

  /// Naive entity surfaces, in first-seen order and de-duplicated:
  /// `code`/```fenced``` identifiers, "quoted" terms, and Capitalized /
  /// CamelCase tokens (skipping a leading capital that's just sentence case).
  /// Stable for a given segment.
  List<String> _entities(String segment) {
    final seen = <String>{};
    final out = <String>[];
    void take(String? value) {
      final v = value?.trim();
      if (v == null || v.isEmpty) return;
      if (seen.add(v.toLowerCase())) out.add(v);
    }

    // Backtick code spans / fenced identifiers.
    for (final m in RegExp(r'`+([^`]+)`+').allMatches(segment)) {
      take(m.group(1));
    }
    // Double- or single-quoted terms.
    for (final m in RegExp(r'''["']([^"']+)["']''').allMatches(segment)) {
      take(m.group(1));
    }
    // Capitalized / CamelCase words. Skip a capitalized word that merely starts
    // the segment (sentence case), unless it's CamelCase (an internal capital).
    final words = RegExp(r'[A-Za-z][A-Za-z0-9]*').allMatches(segment).toList();
    for (var i = 0; i < words.length; i++) {
      final word = words[i].group(0)!;
      final isCapitalized = RegExp(r'^[A-Z]').hasMatch(word);
      final isCamel = RegExp(r'^[A-Z][a-z0-9]*[A-Z]').hasMatch(word) ||
          RegExp(r'[a-z][A-Z]').hasMatch(word);
      if (!isCapitalized) continue;
      if (i == 0 && !isCamel) continue; // leading sentence-case capital
      take(word);
    }
    return out;
  }
}

/// A real [PropositionExtractor] backed by an [LlmProvider]. It asks the model
/// to return STRICT JSON — an array of `{ "text", "aspect", "entities" }`,
/// ~[targetCount] items, each proposition standalone and coref-resolved against
/// [parentContext] — collects the full [LlmProvider.generate] stream, and parses
/// it robustly (tolerating ```json fences and leading/trailing prose by
/// extracting the outermost JSON array). A parse failure throws [LlmException]
/// so it surfaces identically to a chat/embedding failure; the indexer decides
/// whether to skip or retry.
class LlmPropositionExtractor implements PropositionExtractor {
  const LlmPropositionExtractor(this._llm, {this.targetCount = 5});

  final LlmProvider _llm;

  /// How many propositions to request (~5, DESIGN.md §10).
  final int targetCount;

  @override
  Future<TurnExtraction> extract(
    Turn turn, {
    List<Turn> parentContext = const [],
  }) async {
    final prompt = _buildPrompt(turn, parentContext);
    final buffer = StringBuffer();
    await for (final delta in _llm.generate(prompt: prompt, context: const [])) {
      buffer.write(delta);
    }
    return _parse(buffer.toString());
  }

  String _buildPrompt(Turn turn, List<Turn> parentContext) {
    final context = StringBuffer();
    for (final t in parentContext) {
      if (t.promptMd.trim().isNotEmpty) {
        context.writeln('User: ${t.promptMd.trim()}');
      }
      if (t.responseMd.trim().isNotEmpty) {
        context.writeln('Assistant: ${t.responseMd.trim()}');
      }
    }

    return 'Extract about $targetCount atomic, standalone propositions from the '
        'conversation turn below. Each proposition must:\n'
        '- be a single self-contained statement (no pronouns left dangling — '
        'resolve coreferences using the earlier context);\n'
        '- carry an open-vocabulary "aspect" tag (a short label, e.g. '
        '"definition", "instruction", "claim");\n'
        '- list the named entities ("entities") it mentions as raw strings.\n\n'
        'Return ONLY a JSON array, no prose, no markdown fences. Shape:\n'
        '[{"text": "...", "aspect": "...", "entities": ["..."]}]\n\n'
        '${context.isEmpty ? '' : 'Earlier context:\n$context\n'}'
        'Turn:\n'
        'User: ${turn.promptMd.trim()}\n'
        'Assistant: ${turn.responseMd.trim()}\n';
  }

  /// Parses the model output into a [TurnExtraction]. Tolerates ```json fences
  /// and leading/trailing prose by slicing out the outermost `[ … ]`. Skips
  /// array elements that aren't objects or lack a non-empty `text`. Throws
  /// [LlmException] when no JSON array is present or it doesn't decode.
  TurnExtraction _parse(String raw) {
    final json = _extractJsonArray(raw);
    if (json == null) {
      throw LlmException('Extractor returned no JSON array: ${_snippet(raw)}');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } catch (e) {
      throw LlmException('Extractor returned invalid JSON: $e');
    }
    if (decoded is! List) {
      throw LlmException('Extractor JSON was not an array');
    }

    final propositions = <ExtractedProposition>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final text = (item['text'] as Object?)?.toString().trim() ?? '';
      if (text.isEmpty) continue;
      final aspectRaw = (item['aspect'] as Object?)?.toString().trim();
      final entitiesRaw = item['entities'];
      final entities = <String>[
        if (entitiesRaw is List)
          for (final e in entitiesRaw)
            if (e != null && e.toString().trim().isNotEmpty) e.toString().trim(),
      ];
      propositions.add(
        ExtractedProposition(
          text: text,
          aspect: (aspectRaw == null || aspectRaw.isEmpty) ? null : aspectRaw,
          entities: entities,
        ),
      );
    }
    return TurnExtraction(propositions: propositions);
  }

  /// Slices out the outermost JSON array from [raw] — the first `[` to its
  /// matching `]` — so ```json fences and surrounding prose are tolerated.
  /// Brackets inside double-quoted strings (with `\"` escapes) don't count.
  /// Returns null when no balanced array is found.
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

  String _snippet(String raw) {
    final trimmed = raw.trim();
    return trimmed.length > 120 ? '${trimmed.substring(0, 120)}…' : trimmed;
  }
}
