import 'dart:io';
import 'dart:isolate';

import '../db/database.dart';
import 'chatgpt_importer.dart';
import 'export_source.dart';

/// Runs a full import in a background isolate (DESIGN.md §3/§5: parsing and
/// pairing never run on the UI thread).
///
/// The isolate shares [db]'s underlying connection via drift's
/// `computeWithDatabase`, so stream queries on the UI side update live as
/// conversations are inserted. Progress events are forwarded through a port
/// back to [onProgress] on the calling isolate.
Future<ImportResult> runImportInBackground({
  required AppDatabase db,
  required String exportPath,
  required String assetsDirPath,
  void Function(ImportProgress progress)? onProgress,
}) async {
  final progressPort = ReceivePort();
  progressPort.listen((message) {
    if (message is List && message.length == 2) {
      onProgress?.call(ImportProgress(message[0] as int, message[1] as int));
    }
  });
  final progressSend = progressPort.sendPort;

  try {
    return await db.computeWithDatabase(
      connect: AppDatabase.new,
      computation: _importComputation(exportPath, assetsDirPath, progressSend),
    );
  } finally {
    progressPort.close();
  }
}

/// Builds the isolate-side computation in a scope whose captures are only
/// sendable values (two strings and a [SendPort]).
///
/// Must not be inlined into [runImportInBackground]: the Dart VM gives all
/// captured variables of a scope one shared closure context, so an inline
/// closure drags the caller's `onProgress` (which captures UI objects, e.g.
/// the Riverpod controller) into the isolate spawn message and the spawn
/// fails with "Illegal argument in isolate message: object is unsendable".
Future<ImportResult> Function(AppDatabase) _importComputation(
  String exportPath,
  String assetsDirPath,
  SendPort progress,
) {
  return (db) async {
    final source = await ExportSource.open(exportPath);
    try {
      return await ChatGptImporter(
        db: db,
        source: source,
        assetsDir: Directory(assetsDirPath),
        sourcePath: exportPath,
        onProgress: (p) => progress.send([p.done, p.total]),
      ).run();
    } finally {
      await source.close();
    }
  };
}
