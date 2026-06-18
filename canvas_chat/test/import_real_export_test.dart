/// Golden tests against the real ChatGPT export fixture (read-only test
/// data; never modified, never committed — see PROGRESS.md).
///
/// Counts verified independently against the raw JSON with jq:
/// 1,594 conversations, 12,185 messages, 48 distinct referenced image
/// assets of which 3 are absent from the export.
@Timeout(Duration(minutes: 10))
library;

import 'dart:io';

import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/data/import/chatgpt_importer.dart';
import 'package:canvas_chat/src/data/import/export_source.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const fixturePath = '/Users/aditya/projects-running/chatgpt/chatgpt_data';

void main() {
  final fixture = Directory(fixturePath);
  late AppDatabase db;
  late Directory assetsDir;
  late ImportResult result;
  final progress = <ImportProgress>[];

  setUpAll(() async {
    expect(
      fixture.existsSync(),
      isTrue,
      reason: 'Real-export fixture expected at $fixturePath',
    );
    db = AppDatabase(NativeDatabase.memory());
    assetsDir = await Directory.systemTemp.createTemp('canvas_chat_assets');
    result = await ChatGptImporter(
      db: db,
      source: DirectoryExportSource(fixture),
      assetsDir: assetsDir,
      sourcePath: fixturePath,
      onProgress: progress.add,
    ).run();
  });

  tearDownAll(() async {
    await db.close();
    await assetsDir.delete(recursive: true);
  });

  test('imports every conversation and message', () async {
    expect(result.conversations, 1594);
    expect(result.messages, 12185);
    expect(
      await db.conversations.count().getSingle(),
      1594,
    );
    expect(await db.turns.count().getSingle(), result.turns);
    // Each user message starts a turn; regenerated-response branches fold the
    // shared prompt in (one full turn per branch — the prompt node dissolved,
    // and a prompt+response split by a transparent sibling merged back into
    // one cell). 79 fewer turns than the old prompt-then-responses shape; the
    // remaining one-sided cells are genuine orphans / trailing prompts.
    expect(result.turns, 5996);
  });

  test('progress was streamed once per conversation', () {
    expect(progress, hasLength(1594));
    expect(progress.last.done, progress.last.total);
  });

  test('all four content types are represented', () async {
    // `thoughts` (142 messages) + `reasoning_recap` (114) fold into turns.
    final thoughtTurns = await (db.selectOnly(db.turns)
          ..addColumns([db.turns.id])
          ..where(db.turns.thoughtsMd.isNotNull()))
        .get();
    expect(thoughtTurns, hasLength(113));

    // `multimodal_text` messages leave image markers in the turn text.
    final imageTurns = await db.customSelect(
      "SELECT COUNT(*) AS c FROM turns WHERE prompt_md LIKE '%](asset://%' "
      "OR response_md LIKE '%](asset://%'",
    ).getSingle();
    expect(imageTurns.read<int>('c'), 50);

    final plainText = await db.customSelect(
      "SELECT COUNT(*) AS c FROM turns WHERE prompt_md != '' "
      "AND response_md != ''",
    ).getSingle();
    expect(plainText.read<int>('c'), greaterThan(4000));
  });

  test('forks produce multiple sibling turns', () async {
    // Parents with >1 child: edited-prompt forks, plus regenerated-response
    // forks whose dissolved prompt had a (non-root) parent. Fewer than before
    // the fold (258) because regen-at-root branches become sibling roots and
    // single-response forks collapse into one cell.
    final forks = await db.customSelect(
      'SELECT parent_turn_id, COUNT(*) AS c FROM turns '
      'WHERE parent_turn_id IS NOT NULL '
      'GROUP BY parent_turn_id HAVING c > 1',
    ).get();
    expect(forks, hasLength(222));
  });

  test('assets are resolved, copied, and renamed', () async {
    // 48 distinct image pointers are referenced; 3 `.dat` files are absent
    // from the export (verified independently with jq).
    expect(result.assetsCopied, 45);
    expect(result.assetsMissing, 3);

    // 53 turn-asset rows: 49 `image_asset_pointer` occurrences plus prompt
    // images duplicated into regenerated-response branches by the fold.
    final rows = await db.select(db.turnAssets).get();
    expect(rows, hasLength(53));
    for (final row in rows.where((r) => r.path.isNotEmpty)) {
      expect(File(row.path).existsSync(), isTrue, reason: row.path);
      expect(p.extension(row.path), isNot('.dat'),
          reason: 'extension should be restored for ${row.path}');
    }
    // A specific known asset: sediment://file_00000000864071fabfc91ef650baaa1f
    final known = rows.where(
      (r) => r.path.endsWith('file_00000000864071fabfc91ef650baaa1f.png'),
    );
    expect(known, isNotEmpty);
  });

  test('re-import is idempotent and respects canvas_state policy', () async {
    final anyTurn = await (db.select(db.turns)..limit(1)).getSingle();
    await db.into(db.canvasStates).insert(
          CanvasStatesCompanion.insert(
            conversationId: anyTurn.conversationId,
            focusedTurnId: Value(anyTurn.id),
          ),
        );
    final otherConv = await (db.select(db.conversations)
          ..where((c) => c.id.isNotValue(anyTurn.conversationId))
          ..limit(1))
        .getSingle();
    await db.into(db.canvasStates).insert(
          CanvasStatesCompanion.insert(
            conversationId: otherConv.id,
            focusedTurnId: const Value('turn-id-that-never-existed'),
          ),
        );

    final second = await ChatGptImporter(
      db: db,
      source: DirectoryExportSource(fixture),
      assetsDir: assetsDir,
      sourcePath: fixturePath,
    ).run();

    expect(second.conversations, result.conversations);
    expect(second.turns, result.turns);
    expect(await db.conversations.count().getSingle(), 1594);
    expect(await db.turns.count().getSingle(), result.turns);

    final states = await db.select(db.canvasStates).get();
    expect(states, hasLength(1));
    expect(states.single.conversationId, anyTurn.conversationId);

    expect(await db.imports.count().getSingle(), 2);
    final lastImport = await (db.select(db.imports)
          ..orderBy([(i) => OrderingTerm.desc(i.id)])
          ..limit(1))
        .getSingle();
    expect(lastImport.finishedAt, isNotNull);
    expect(lastImport.conversations, 1594);
  });
}
