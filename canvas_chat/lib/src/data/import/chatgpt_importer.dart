import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../domain/paired_turn.dart';
import '../../domain/turn_pairing.dart';
import '../db/database.dart';
import 'export_models.dart';
import 'export_source.dart';

/// Progress callback payload: `done`/`total` conversations imported so far.
class ImportProgress {
  ImportProgress(this.done, this.total);

  final int done;
  final int total;
}

/// Summary of one import run.
class ImportResult {
  ImportResult({
    required this.conversations,
    required this.turns,
    required this.messages,
    required this.assetsCopied,
    required this.assetsMissing,
    required this.warnings,
  });

  final int conversations;
  final int turns;

  /// Message-bearing mapping nodes seen across all conversations.
  final int messages;

  /// Distinct asset files copied into the asset store.
  final int assetsCopied;

  /// Distinct referenced assets absent from the export (placeholder records).
  final int assetsMissing;

  final List<String> warnings;
}

/// Imports a ChatGPT data export (zip or extracted folder) into the app
/// database, per DESIGN.md §5.
///
/// Idempotent per conversation: matching `conversation.id`s are replaced.
/// `canvas_state` rows survive a re-import while their `focused_turn_id`
/// still exists.
class ChatGptImporter {
  ChatGptImporter({
    required this.db,
    required this.source,
    required this.assetsDir,
    this.sourcePath = '',
    this.onProgress,
  });

  static const importerSourceId = 'chatgpt_export';

  final AppDatabase db;
  final ExportSource source;

  /// Directory assets are copied into (`assets/<file_id>.<ext>` inside the
  /// app documents dir in production; injectable for tests).
  final Directory assetsDir;

  /// Recorded in the `imports` table.
  final String sourcePath;

  final void Function(ImportProgress progress)? onProgress;

  Future<ImportResult> run() async {
    final warnings = <String>[];
    final startedAt = DateTime.now().millisecondsSinceEpoch;

    final shardNames = await _discoverShards(warnings);
    final assetNames = await _readAssetNameMap(warnings);

    final importRowId = await db.into(db.imports).insert(
          ImportsCompanion.insert(
            startedAt: startedAt,
            sourcePath: sourcePath,
          ),
        );

    var conversationCount = 0;
    var turnCount = 0;
    var messageCount = 0;
    // pointerId -> copied path ('' when missing from the export).
    final copiedAssets = <String, String>{};
    // Progress total grows as shards are decoded (one shard at a time —
    // never all 16 decoded at once, per DESIGN.md §5).
    var totalConversations = 0;

    var done = 0;
    for (final shard in shardNames) {
      List<dynamic> conversations;
      try {
        final text = await source.readString(shard);
        final decoded = jsonDecode(text);
        if (decoded is! List) {
          warnings.add('$shard: expected a JSON array, got '
              '${decoded.runtimeType}; skipped');
          continue;
        }
        conversations = decoded;
      } on FormatException catch (e) {
        warnings.add('$shard: invalid JSON (${e.message}); skipped');
        continue;
      } on FileSystemException catch (e) {
        warnings.add('$shard: unreadable (${e.message}); skipped');
        continue;
      }
      totalConversations += conversations.length;

      for (final rawConv in conversations) {
        if (rawConv is! Map) {
          warnings.add('$shard: non-object conversation entry skipped');
          continue;
        }
        final conv =
            ExportConversation(rawConv.cast<String, dynamic>());
        if (conv.id.isEmpty) {
          warnings.add('$shard: conversation without id skipped');
          continue;
        }
        final paired = pairTurns(conv);
        warnings.addAll(paired.warnings);
        messageCount += paired.messageCount;

        await _replaceConversation(conv, paired);
        await _writeAssets(conv, paired, assetNames, copiedAssets, warnings);

        conversationCount++;
        turnCount += paired.turns.length;
        done++;
        onProgress?.call(ImportProgress(done, totalConversations));
      }
    }

    final assetsCopied =
        copiedAssets.values.where((path) => path.isNotEmpty).length;
    final assetsMissing =
        copiedAssets.values.where((path) => path.isEmpty).length;

    await (db.update(db.imports)..where((i) => i.id.equals(importRowId)))
        .write(
      ImportsCompanion(
        finishedAt: Value(DateTime.now().millisecondsSinceEpoch),
        conversations: Value(conversationCount),
        turns: Value(turnCount),
        warningsJson: Value(jsonEncode(warnings)),
      ),
    );

    return ImportResult(
      conversations: conversationCount,
      turns: turnCount,
      messages: messageCount,
      assetsCopied: assetsCopied,
      assetsMissing: assetsMissing,
      warnings: warnings,
    );
  }

  /// Shard list from `export_manifest.json`; falls back to
  /// `conversations.json` for unsharded exports.
  Future<List<String>> _discoverShards(List<String> warnings) async {
    if (source.exists('export_manifest.json')) {
      try {
        final manifest = jsonDecode(
          await source.readString('export_manifest.json'),
        );
        final logical = manifest is Map ? manifest['logical_files'] : null;
        final entry =
            logical is Map ? logical['conversations.json'] : null;
        final files = entry is Map ? entry['files'] : null;
        if (files is List) {
          return [for (final f in files) f.toString()];
        }
        warnings.add(
          'export_manifest.json has no conversations.json entry; '
          'falling back to conversations.json',
        );
      } on FormatException catch (e) {
        warnings.add('export_manifest.json unparsable (${e.message}); '
            'falling back to conversations.json');
      }
    }
    if (source.exists('conversations.json')) return ['conversations.json'];
    throw const FileSystemException(
      'Not a ChatGPT export: no export_manifest.json or conversations.json',
    );
  }

  /// `.dat` name → original filename (used to restore extensions).
  Future<Map<String, String>> _readAssetNameMap(List<String> warnings) async {
    if (!source.exists('conversation_asset_file_names.json')) {
      warnings.add('conversation_asset_file_names.json missing; '
          'asset extensions will not be restored');
      return const {};
    }
    try {
      final decoded = jsonDecode(
        await source.readString('conversation_asset_file_names.json'),
      );
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    } on FormatException catch (e) {
      warnings.add('conversation_asset_file_names.json unparsable '
          '(${e.message})');
    }
    return const {};
  }

  /// Database id for a turn: node ids are only unique *within* a
  /// conversation (server-side conversation copies reuse them), so rows are
  /// keyed by `<conversation_id>:<node_id>`.
  static String turnRowId(String conversationId, String nodeId) =>
      '$conversationId:$nodeId';

  /// Replaces one conversation's rows (content is export-owned; the only
  /// thing preserved is `canvas_state`, when still valid).
  Future<void> _replaceConversation(
    ExportConversation conv,
    PairedConversation paired,
  ) async {
    await db.transaction(() async {
      final oldTurnIds = await (db.selectOnly(db.turns)
            ..addColumns([db.turns.id])
            ..where(db.turns.conversationId.equals(conv.id)))
          .map((row) => row.read(db.turns.id)!)
          .get();
      if (oldTurnIds.isNotEmpty) {
        await (db.delete(db.turnAssets)
              ..where((a) => a.turnId.isIn(oldTurnIds)))
            .go();
        await (db.delete(db.turns)
              ..where((t) => t.conversationId.equals(conv.id)))
            .go();
      }

      // Real time of the conversation's latest message, used for ordering and
      // the displayed date in place of the unreliable header `update_time`.
      int? lastMessageAt;
      for (final turn in paired.turns) {
        final millis = _millis(turn.createTime);
        if (millis != null &&
            (lastMessageAt == null || millis > lastMessageAt)) {
          lastMessageAt = millis;
        }
      }

      await db.into(db.conversations).insertOnConflictUpdate(
            ConversationsCompanion.insert(
              id: conv.id,
              title: Value(conv.title),
              createTime: Value(_millis(conv.createTime)),
              updateTime: Value(_millis(conv.updateTime)),
              lastMessageAt: Value(lastMessageAt),
              isArchived: Value(conv.isArchived),
              isStarred: Value(conv.isStarred),
              defaultModelSlug: Value(conv.defaultModelSlug),
              currentTurnId: Value(paired.currentTurnId == null
                  ? null
                  : turnRowId(conv.id, paired.currentTurnId!)),
              source: importerSourceId,
            ),
          );

      await db.batch((batch) {
        batch.insertAll(db.turns, [
          for (final turn in paired.turns)
            TurnsCompanion.insert(
              id: turnRowId(conv.id, turn.id),
              conversationId: conv.id,
              parentTurnId: Value(turn.parentTurnId == null
                  ? null
                  : turnRowId(conv.id, turn.parentTurnId!)),
              promptMd: Value(turn.promptMd),
              responseMd: Value(turn.responseMd),
              thoughtsMd: Value(turn.thoughtsMd),
              modelSlug: Value(turn.modelSlug),
              createTime: Value(_millis(turn.createTime)),
              rawJson: jsonEncode(turn.rawNodes),
            ),
        ]);
      });

      // canvas_state survives only while its focused turn still exists.
      final state = await (db.select(db.canvasStates)
            ..where((s) => s.conversationId.equals(conv.id)))
          .getSingleOrNull();
      if (state != null && state.focusedTurnId != null) {
        final stillExists = paired.turns
            .any((t) => turnRowId(conv.id, t.id) == state.focusedTurnId);
        if (!stillExists) {
          await (db.delete(db.canvasStates)
                ..where((s) => s.conversationId.equals(conv.id)))
              .go();
        }
      }
    });
  }

  Future<void> _writeAssets(
    ExportConversation conv,
    PairedConversation paired,
    Map<String, String> assetNames,
    Map<String, String> copiedAssets,
    List<String> warnings,
  ) async {
    final rows = <TurnAssetsCompanion>[];
    for (final turn in paired.turns) {
      for (final asset in turn.assets) {
        final originalName = assetNames['${asset.pointerId}.dat'];
        final path = await _copyAsset(
          conv.id,
          asset,
          originalName,
          copiedAssets,
          warnings,
        );
        rows.add(
          TurnAssetsCompanion.insert(
            turnId: turnRowId(conv.id, turn.id),
            kind: asset.kind,
            path: path,
            originalName: Value(originalName),
            width: Value(asset.width),
            height: Value(asset.height),
          ),
        );
      }
    }
    if (rows.isNotEmpty) {
      await db.batch((batch) => batch.insertAll(db.turnAssets, rows));
    }
  }

  /// Copies the `.dat` file for [asset] into the asset store with its
  /// original extension restored. Returns the destination path, or '' when
  /// the asset is missing from the export (placeholder record).
  Future<String> _copyAsset(
    String conversationId,
    TurnAssetRef asset,
    String? originalName,
    Map<String, String> copiedAssets,
    List<String> warnings,
  ) async {
    final cached = copiedAssets[asset.pointerId];
    if (cached != null) return cached;

    final datName = '${asset.pointerId}.dat';
    if (!source.exists(datName)) {
      warnings.add('$conversationId: asset $datName missing from export');
      copiedAssets[asset.pointerId] = '';
      return '';
    }

    var extension = originalName == null ? '' : p.extension(originalName);
    if (extension.isEmpty) extension = '.dat';
    final destPath = p.join(assetsDir.path, '${asset.pointerId}$extension');
    await source.copyTo(datName, destPath);
    copiedAssets[asset.pointerId] = destPath;
    return destPath;
  }

  static int? _millis(double? seconds) =>
      seconds == null ? null : (seconds * 1000).round();
}
