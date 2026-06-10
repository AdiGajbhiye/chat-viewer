import 'dart:io';

import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/data/import/chatgpt_importer.dart';
import 'package:canvas_chat/src/data/import/export_source.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'helpers/synthetic_export.dart';

/// M5 sidebar search: conversation-level FTS over prompts/responses plus
/// title matching (DESIGN.md §6 "FTS search over titles + content").
void main() {
  group('ftsMatchQuery', () {
    test('quotes terms and adds prefix matching', () {
      expect(AppDatabase.ftsMatchQuery('hello world'), '"hello"* "world"*');
    });

    test('escapes embedded quotes and FTS operators', () {
      expect(AppDatabase.ftsMatchQuery('sa"y'), '"sa""y"*');
      expect(AppDatabase.ftsMatchQuery('AND NOT col:x'),
          '"AND"* "NOT"* "col:x"*');
    });

    test('blank input yields an empty match expression', () {
      expect(AppDatabase.ftsMatchQuery('   '), '');
    });
  });

  group('searchConversations', () {
    late Directory tempRoot;
    late AppDatabase db;

    setUpAll(() async {
      tempRoot = await Directory.systemTemp.createTemp('canvas_chat_search');
      final exportDir = Directory(p.join(tempRoot.path, 'export'));
      await writeSyntheticExport(exportDir);
      db = AppDatabase(NativeDatabase.memory());
      await ChatGptImporter(
        db: db,
        source: DirectoryExportSource(exportDir),
        assetsDir: await tempRoot.createTemp('assets'),
      ).run();
    });

    tearDownAll(() async {
      await db.close();
      await tempRoot.delete(recursive: true);
    });

    Future<List<String>> search(String query) async =>
        [for (final c in await db.searchConversations(query)) c.id];

    test('finds conversations by prompt and response content', () async {
      expect(await search('entanglement'), ['conv-linear']);
      expect(await search('spooky action'), ['conv-linear']);
      expect(await search('regenerate'), ['conv-forked']);
    });

    test('matches term prefixes', () async {
      expect(await search('entangle'), ['conv-linear']);
    });

    test('matches titles too, newest first, before content-only matches',
        () async {
      // Both titles contain "chat"; neither's content does. Forked chat has
      // the later update_time.
      expect(await search('chat'), ['conv-forked', 'conv-linear']);
      // "first" hits the "Assistant first" title and conv-forked's
      // "first answer" response; the title match ranks first.
      expect(await search('first'), ['conv-aroot', 'conv-forked']);
    });

    test('deduplicates title + content matches', () async {
      // "Linear" is in the title and "linear" nowhere in content; "hello"
      // is in content only — combined query must not duplicate conv-linear.
      expect(await search('Linear chat'), ['conv-linear']);
    });

    test('is robust against FTS5 query syntax in user input', () async {
      expect(await search('"unbalanced (AND -x:'), isEmpty);
      expect(await search('NEAR("a" "b")'), isEmpty);
    });

    test('blank query returns nothing', () async {
      expect(await search('   '), isEmpty);
    });
  });
}
