import 'package:canvas_chat/src/domain/markdown_blocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stripChatMarkers removes ChatGPT web-export citation/PUA markers', () {
    final e200 = String.fromCharCode(0xE200);
    final e201 = String.fromCharCode(0xE201);
    final e202 = String.fromCharCode(0xE202);
    final e204 = String.fromCharCode(0xE204);
    final e206 = String.fromCharCode(0xE206);

    // A full citation token is removed wholesale (anchors + cite/turn label),
    // not just the invisible anchors — otherwise "citeturn0search0" remains.
    expect(
      stripChatMarkers('See this.${e200}cite${e202}turn0search0$e201 Next.'),
      'See this. Next.',
    );
    // Multiple refs inside a single token.
    expect(
      stripChatMarkers(
          'A${e200}cite${e202}turn0search0${e202}turn0search1${e201}B'),
      'AB',
    );
    // Stray group anchors that wrap no label.
    expect(stripChatMarkers('Done.$e204$e206\nmore'), 'Done.\nmore');
    // Ordinary text (incl. non-PUA Unicode) is untouched.
    expect(stripChatMarkers('plain ascii only'), 'plain ascii only');

    // Regression: an anchor NOT followed by a marker-shaped token must never
    // swallow the prose (and emoji) up to the next anchor — only the stray
    // anchors themselves go.
    final brain = String.fromCharCode(0x1F9E0); // 🧠
    expect(
      stripChatMarkers('$e200 keep $brain this prose $e201'),
      ' keep $brain this prose ',
    );
    // A real citation is still removed cleanly while later emoji prose stays.
    expect(
      stripChatMarkers('${e200}cite${e202}turn0search0$e201 then $brain ok'),
      ' then $brain ok',
    );
  });

  test('splits paragraphs on blank lines', () {
    expect(
      splitMarkdownBlocks('first para\n\nsecond para\n\n\nthird'),
      ['first para', 'second para', 'third'],
    );
  });

  test('keeps a tight list as one block', () {
    const md = 'Intro:\n\n- one\n- two\n- three\n\nOutro.';
    expect(splitMarkdownBlocks(md), [
      'Intro:',
      '- one\n- two\n- three',
      'Outro.',
    ]);
  });

  test('keeps a fenced code block intact, blank lines and all', () {
    const md = 'before\n\n```dart\nvoid main() {\n\n  print(1);\n}\n```\n\nafter';
    expect(splitMarkdownBlocks(md), [
      'before',
      '```dart\nvoid main() {\n\n  print(1);\n}\n```',
      'after',
    ]);
  });

  test('a fence with no surrounding blank lines still splits off', () {
    const md = 'text\n```\ncode\n```\nmore';
    expect(splitMarkdownBlocks(md), ['text', '```\ncode\n```', 'more']);
  });

  test('blank and whitespace-only input yields no blocks', () {
    expect(splitMarkdownBlocks(''), isEmpty);
    expect(splitMarkdownBlocks('   \n\n  \n'), isEmpty);
  });

  test('a single paragraph is one block, trimmed of trailing blanks', () {
    expect(splitMarkdownBlocks('just one thing\n\n'), ['just one thing']);
  });
}
