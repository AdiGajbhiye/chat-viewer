import '../db/database.dart';

/// A pluggable text-generation backend (DESIGN.md §9 "Live chat":
/// `sendTurn(List<Turn> path) → Stream<Delta>`). v1 ships only
/// [StubLlmProvider] and stays fully offline; a real provider
/// (Claude / OpenAI / Ollama …) drops in behind this interface without
/// touching the read-mode UI or the branch plumbing.
abstract interface class LlmProvider {
  /// Streams the assistant reply to [prompt] as incremental markdown deltas.
  /// [context] is the root→parent turn path, for providers that send the
  /// conversation so far. Concatenated in order, the deltas are the full
  /// response; a non-streaming provider simply yields once.
  Stream<String> generate({
    required String prompt,
    required List<Turn> context,
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
  }) async* {
    yield '*Offline stub — no model is connected.*\n\n'
        'This branch was created from your selection. Wire up a real '
        '`LlmProvider` (Claude, OpenAI, …) to generate a live answer here.';
  }
}
