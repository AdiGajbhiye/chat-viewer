import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/import/chatgpt_importer.dart';
import '../data/import/import_runner.dart';
import 'providers.dart';

/// UI-facing state of the (single) import pipeline.
sealed class ImportState {
  const ImportState();
}

class ImportIdle extends ImportState {
  const ImportIdle();
}

class ImportRunning extends ImportState {
  const ImportRunning(this.done, this.total);

  /// Conversations imported so far / discovered so far (the total grows as
  /// shards are decoded one at a time).
  final int done;
  final int total;
}

class ImportSucceeded extends ImportState {
  const ImportSucceeded(this.result);

  final ImportResult result;
}

class ImportFailed extends ImportState {
  const ImportFailed(this.message);

  final String message;
}

final importControllerProvider =
    NotifierProvider<ImportController, ImportState>(ImportController.new);

class ImportController extends Notifier<ImportState> {
  @override
  ImportState build() => const ImportIdle();

  /// Imports the export at [path] (zip file or extracted folder) in a
  /// background isolate, streaming progress into [state].
  Future<void> importFrom(String path) async {
    if (state is ImportRunning) return; // one import at a time
    state = const ImportRunning(0, 0);
    try {
      final result = await runImportInBackground(
        db: ref.read(databaseProvider),
        exportPath: path,
        assetsDirPath: ref.read(assetsDirProvider).path,
        onProgress: (p) => state = ImportRunning(p.done, p.total),
      );
      state = ImportSucceeded(result);
    } catch (e) {
      state = ImportFailed(e.toString());
    }
  }
}
