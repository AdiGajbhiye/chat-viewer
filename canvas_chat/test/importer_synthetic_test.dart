import 'dart:io';

import 'package:archive/archive.dart';
import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/data/import/chatgpt_importer.dart';
import 'package:canvas_chat/src/data/import/export_source.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'helpers/synthetic_export.dart';

void main() {
  late Directory tempRoot;
  late Directory exportDir;

  setUpAll(() async {
    tempRoot = await Directory.systemTemp.createTemp('canvas_chat_test');
    exportDir = Directory(p.join(tempRoot.path, 'export'));
    await writeSyntheticExport(exportDir);
  });

  tearDownAll(() async {
    await tempRoot.delete(recursive: true);
  });

  Future<(AppDatabase, ImportResult)> import(ExportSource source,
      {Directory? assets, AppDatabase? db}) async {
    final database = db ?? AppDatabase(NativeDatabase.memory());
    final assetsDir = assets ?? await tempRoot.createTemp('assets');
    final result = await ChatGptImporter(
      db: database,
      source: source,
      assetsDir: assetsDir,
      sourcePath: exportDir.path,
    ).run();
    return (database, result);
  }

  group('folder import', () {
    late AppDatabase db;
    late ImportResult result;
    late Directory assetsDir;

    setUpAll(() async {
      assetsDir = Directory(p.join(tempRoot.path, 'assets_dir'));
      final (d, r) = await import(
        DirectoryExportSource(exportDir),
        assets: assetsDir,
      );
      db = d;
      result = r;
    });

    tearDownAll(() => db.close());

    test('imports all conversations and turns', () async {
      expect(result.conversations, 3);
      // Forked conv folds its regen prompt away: 3 (linear) + 5 (forked) + 1.
      expect(result.turns, 3 + 5 + 1);
      expect(result.messages, 8 + 6 + 3);
      final convRows = await db.select(db.conversations).get();
      expect(convRows, hasLength(3));
      final turnRows = await db.select(db.turns).get();
      expect(turnRows, hasLength(9));
    });

    test('conversation metadata lands in the row', () async {
      final conv = await (db.select(db.conversations)
            ..where((c) => c.id.equals('conv-linear')))
          .getSingle();
      expect(conv.title, 'Linear chat');
      expect(conv.createTime, 1700000000500);
      expect(conv.updateTime, 1700000400500);
      expect(conv.defaultModelSlug, 'gpt-4o');
      expect(conv.currentTurnId, 'conv-linear:u1');
      expect(conv.source, 'chatgpt_export');
    });

    test('present asset is copied with its original extension', () async {
      final copied = File(p.join(assetsDir.path, 'file_present.png'));
      expect(copied.existsSync(), isTrue);
      expect(copied.readAsBytesSync(), kTinyPngBytes);
      final rows = await (db.select(db.turnAssets)
            ..where((a) => a.path.equals(copied.path)))
          .get();
      expect(rows, hasLength(1));
      expect(rows.single.originalName, 'pic.png');
      expect(rows.single.kind, 'prompt');
      expect(result.assetsCopied, 1);
    });

    test('missing asset gets a placeholder record and a warning', () async {
      final rows = await (db.select(db.turnAssets)
            ..where((a) => a.path.equals('')))
          .get();
      expect(rows, hasLength(1));
      expect(rows.single.width, 7);
      expect(rows.single.height, 9);
      expect(result.assetsMissing, 1);
      expect(result.warnings, anyElement(contains('file_gone.dat')));
    });

    test('FTS finds turns by prompt and response text', () async {
      expect(await db.searchTurnIds('entanglement'), ['conv-linear:u1']);
      expect(await db.searchTurnIds('spooky'), ['conv-linear:u1']);
      expect(await db.searchTurnIds('xyzzy_not_there'), isEmpty);
    });

    test('re-import is idempotent and preserves valid canvas_state',
        () async {
      await db.into(db.canvasStates).insert(
            CanvasStatesCompanion.insert(
              conversationId: 'conv-linear',
              focusedTurnId: const Value('conv-linear:u2'),
            ),
          );
      await db.into(db.canvasStates).insert(
            CanvasStatesCompanion.insert(
              conversationId: 'conv-forked',
              focusedTurnId: const Value('no-such-turn'),
            ),
          );

      final (_, second) =
          await import(DirectoryExportSource(exportDir), db: db);
      expect(second.conversations, 3);
      expect(second.turns, 9);
      expect(await db.select(db.conversations).get(), hasLength(3));
      expect(await db.select(db.turns).get(), hasLength(9));
      // No duplicated asset rows either.
      expect(await db.select(db.turnAssets).get(), hasLength(2));
      // FTS stays in sync through the delete+reinsert cycle.
      expect(await db.searchTurnIds('entanglement'), ['conv-linear:u1']);

      final states = await db.select(db.canvasStates).get();
      expect(states, hasLength(1));
      expect(states.single.conversationId, 'conv-linear');

      expect(await db.select(db.imports).get(), hasLength(2));
    });
  });

  group('zip import', () {
    Future<File> zipExport({String prefix = ''}) async {
      final archive = Archive();
      for (final entity in exportDir.listSync()) {
        if (entity is! File) continue;
        final name = '$prefix${p.basename(entity.path)}';
        archive.addFile(ArchiveFile.bytes(name, entity.readAsBytesSync()));
      }
      final zipFile = File(
        p.join(tempRoot.path, prefix.isEmpty ? 'flat.zip' : 'nested.zip'),
      );
      zipFile.writeAsBytesSync(ZipEncoder().encode(archive));
      return zipFile;
    }

    test('zip import matches folder import', () async {
      final zip = await zipExport();
      final (db, result) = await import(await ExportSource.open(zip.path));
      addTearDown(db.close);
      expect(result.conversations, 3);
      expect(result.turns, 9);
      expect(result.assetsCopied, 1);
      expect(result.assetsMissing, 1);
    });

    test('zip with a single top-level folder also works', () async {
      final zip = await zipExport(prefix: 'my export/');
      final (db, result) = await import(await ZipExportSource.open(zip));
      addTearDown(db.close);
      expect(result.conversations, 3);
      expect(result.turns, 9);
      expect(result.assetsCopied, 1);
    });
  });

  test('ExportSource.open on a folder picks the directory source', () async {
    final source = await ExportSource.open(exportDir.path);
    expect(source, isA<DirectoryExportSource>());
    expect(source.exists('export_manifest.json'), isTrue);
  });

  test('conversation copies sharing node ids import side by side', () async {
    // Real exports contain server-side conversation copies that reuse node
    // ids; turn rows must not collide.
    final dir = Directory(p.join(tempRoot.path, 'copies'));
    await writeSyntheticExport(
      dir,
      conversations: [
        linearConversation(),
        linearConversation(id: 'conv-linear-copy'),
      ],
    );
    final (db, result) = await import(DirectoryExportSource(dir));
    addTearDown(db.close);
    expect(result.conversations, 2);
    expect(result.turns, 6);
    expect(await db.searchTurnIds('entanglement'),
        unorderedEquals(['conv-linear:u1', 'conv-linear-copy:u1']));
  });

  test('importer rejects a directory that is not an export', () async {
    final emptyDir =
        await Directory(p.join(tempRoot.path, 'not_export')).create();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(
      () => ChatGptImporter(
        db: db,
        source: DirectoryExportSource(emptyDir),
        assetsDir: tempRoot,
      ).run(),
      throwsA(isA<FileSystemException>()),
    );
  });
}
