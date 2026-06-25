import '../db/database.dart';

/// A pluggable text-generation backend (DESIGN.md §9 "Live chat":
/// `sendTurn(List<Turn> path) → Stream<Delta>`). v1 ships only
/// [StubLlmProvider] and stays fully offline; a real provider
/// (Claude / OpenAI / Ollama …) drops in behind this interface without
/// touching the read-mode UI or the branch plumbing.
abstract interface class LlmProvider {
  /// Streams the assistant reply to [prompt] as incremental markdown deltas.
  /// [context] is the turn history the provider should send before [prompt]:
  /// the root→parent path in the v1 stub, the retrieval-assembled tail in
  /// Phase 2 (DESIGN.md §10). Concatenated in order, the deltas are the full
  /// response; a non-streaming provider simply yields once.
  ///
  /// [preamble] is optional out-of-band system guidance assembled alongside
  /// [context] — in Phase 2 it carries the tagged retrieved propositions plus a
  /// one-line note on how to read the `{branch, committed?}` tags (DESIGN.md
  /// §10 "tagged {branch, committed?}"). It is surfaced as an extra system
  /// message; a provider that has no notion of a system role may fold it into
  /// the prompt. Defaults to null so every existing call site (and
  /// [StubLlmProvider]) is unaffected.
  Stream<String> generate({
    required String prompt,
    required List<Turn> context,
    String? preamble,
  });
}

/// The default, fully-offline provider: no network, no API key. It emits a
/// short placeholder so the branch / compose / stream plumbing is exercised
/// end-to-end; swap in a real [LlmProvider] (see DESIGN.md §9) to get live
/// answers in the new branch.
class StubLlmProvider implements LlmProvider {
  const StubLlmProvider();

  @override
  Stream<String> generate({
    required String prompt,
    required List<Turn> context,
    String? preamble,
  }) async* {
    yield '*Offline stub — no model is connected.*\n\n'
        'This branch was created from your selection. Wire up a real '
        '`LlmProvider` (Claude, OpenAI, …) to generate a live answer here.';
  }
}
