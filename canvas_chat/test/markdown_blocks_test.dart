import 'package:canvas_chat/src/domain/markdown_blocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
