import 'dart:io';

import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/data/import/chatgpt_importer.dart';
import 'package:canvas_chat/src/data/import/import_runner.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/synthetic_export.dart';

void main() {
  late Directory tempDir;
  late AppDatabase db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('canvas_chat_runner');
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  test('runs the import in a background isolate with streamed progress',
      () async {
    final exportDir = Directory('${tempDir.path}/export');
    await writeSyntheticExport(exportDir);
    final assetsDir = Directory('${tempDir.path}/assets')
      ..createSync(recursive: true);

    // A stream query open before the import must observe the inserts made
    // from the import isolate (shared connection).
    final emissions = <int>[];
    final subscription = db.conversations
        .count()
        .watchSingle()
        .listen(emissions.add);

    final progress = <ImportProgress>[];
    final result = await runImportInBackground(
      db: db,
      exportPath: exportDir.path,
      assetsDirPath: assetsDir.path,
      onProgress: progress.add,
    );

    expect(result.conversations, 3);
    expect(result.turns, greaterThan(3));
    expect(result.assetsCopied, 1);
    expect(result.assetsMissing, 1);

    expect(progress, hasLength(3));
    expect(progress.last.done, 3);
    expect(progress.last.total, 3);

    expect(await db.conversations.count().getSingle(), 3);

    // Stream query saw the imported data without a manual refresh.
    await pumpEventQueue();
    expect(emissions.last, 3);
    await subscription.cancel();
  });

  test('spawns even when onProgress captures unsendable UI objects', () async {
    // Regression: the app's onProgress closes over a Riverpod controller.
    // The Dart VM shares one closure context per scope, so an inline
    // computation closure in runImportInBackground used to drag onProgress
    // (and its unsendable captures) into the isolate spawn message:
    // "Illegal argument in isolate message: object is unsendable - _Future".
    final exportDir = Directory('${tempDir.path}/export_unsendable');
    await writeSyntheticExport(exportDir);
    final assetsDir = Directory('${tempDir.path}/assets_unsendable')
      ..createSync(recursive: true);

    final unsendable = Future<void>.value(); // like a controller's internals
    final seen = <int>[];
    final result = await runImportInBackground(
      db: db,
      exportPath: exportDir.path,
      assetsDirPath: assetsDir.path,
      onProgress: (p) {
        unsendable; // force capture into the caller's closure context
        seen.add(p.done);
      },
    );

    expect(result.conversations, 3);
    expect(seen, isNotEmpty);
  });

  test('surfaces failures from the isolate', () async {
    final bogus = Directory('${tempDir.path}/not_an_export')
      ..createSync(recursive: true);
    final assetsDir = Directory('${tempDir.path}/assets2')
      ..createSync(recursive: true);

    await expectLater(
      runImportInBackground(
        db: db,
        exportPath: bogus.path,
        assetsDirPath: assetsDir.path,
      ),
      throwsA(isA<Exception>()),
    );
  });
}
