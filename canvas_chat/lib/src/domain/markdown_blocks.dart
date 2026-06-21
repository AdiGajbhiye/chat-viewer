/// Strips ChatGPT web-export citation markers from [markdown]. The web export
/// wraps inline citations in Private Use Area anchors — U+E200 `cite` U+E202
/// `turn0search0` U+E201 — and sprinkles stray U+E204 / U+E206 group markers.
/// No font carries a glyph for these PUA code points (U+E200..U+E2FF), so they
/// render as tofu / `?`; only the ChatGPT web export emits them (the API never
/// does). The whole token — including the visible `cite` / `turnXsearchY` label
/// between the anchors — is removed, since stripping only the invisible anchors
/// would leave `citeturn0search0` behind as visible noise.
String stripChatMarkers(String markdown) {
  final open = String.fromCharCode(0xE200); // citation block open
  final close = String.fromCharCode(0xE201); // citation block close
  final sep = String.fromCharCode(0xE202); // ref separator
  return markdown
      // A citation token: open + `cite` + (sep + ref)* + close, where the label
      // and refs are ASCII alphanumeric. Bounding the inner run to [A-Za-z0-9] +
      // sep means an unpaired or differently-closed anchor (e.g. U+E203/E206)
      // can NEVER swallow real prose — spaces, punctuation or emoji break the
      // match, so content is left intact instead of being deleted.
      .replaceAll(RegExp('$open[A-Za-z0-9$sep]*$close'), '')
      // Then drop any leftover individual PUA anchors (U+E200..U+E2FF) — e.g. the
      // standalone U+E204/U+E206 group markers. Single-char removal never eats
      // surrounding text, so only the invisible marker itself is lost.
      .replaceAll(
        RegExp(
          '[${String.fromCharCode(0xE200)}-${String.fromCharCode(0xE2FF)}]',
        ),
        '',
      );
}

/// Splits assistant-response markdown into block-level "chunks" — one per
/// paragraph, heading, list, blockquote, table, or fenced code block — so the
/// reader can render each with its own per-passage toolbar (Ask AI / Explain /
/// Expand / Copy). Pure and deterministic; no rendering here.
///
/// Rules:
/// - One or more blank lines separate blocks.
/// - A fenced code block (` ``` ` or `~~~`, with any info string) is kept
///   intact even when it contains blank lines, so its toolbar acts on the whole
///   snippet and the fence is never split into invalid markdown.
/// - Consecutive non-blank lines (a paragraph, a tight list, a table) stay
///   together as one block.
///
/// Each returned block is itself valid standalone markdown.
List<String> splitMarkdownBlocks(String markdown) {
  final lines = markdown.replaceAll('\r\n', '\n').split('\n');
  final blocks = <String>[];
  final current = <String>[];
  String? fence; // the open fence token (``` / ~~~), or null when outside one.

  void flush() {
    while (current.isNotEmpty && current.last.trim().isEmpty) {
      current.removeLast();
    }
    if (current.isNotEmpty) blocks.add(current.join('\n'));
    current.clear();
  }

  for (final line in lines) {
    final token = _fenceToken(line);
    if (fence != null) {
      current.add(line);
      if (token == fence) {
        fence = null;
        flush(); // a code block is its own chunk
      }
      continue;
    }
    if (token != null) {
      flush(); // a fence opener starts a fresh block
      current.add(line);
      fence = token;
      continue;
    }
    if (line.trim().isEmpty) {
      flush();
    } else {
      current.add(line);
    }
  }
  flush();
  return blocks;
}

/// The fence marker (` ``` ` or `~~~`, ignoring any info string) if [line]
/// opens or closes a fenced code block, else null.
String? _fenceToken(String line) {
  final trimmed = line.trimLeft();
  if (trimmed.startsWith('```')) return '```';
  if (trimmed.startsWith('~~~')) return '~~~';
  return null;
}
