import 'dart:io';

import 'package:canvas_chat/src/data/db/database.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' show sqlite3;

/// Guards the v2 → v3 migration (DESIGN.md §10): the Project tier and the
/// retrieval/facts layer must land additively on an existing, populated v2 DB —
/// no data loss, the three new conversation columns present, a single 'default'
/// project seeded, and every pre-existing conversation backfilled to it.
///
/// There is no drift schema-dump setup in this project, so the v2 state is built
/// by hand (the exact v2 `CREATE TABLE`s + `user_version = 2`) on a real file,
/// then reopened as [AppDatabase] so its [MigrationStrategy] runs the upgrade.
void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('canvas_chat_migration');
    dbFile = File('${tempDir.path}/app_v2.sqlite');
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  /// Writes a minimal but representative schema-v2 database to [dbFile] with one
  /// conversation and one turn, then closes it. Mirrors the v2 column set:
  /// conversations *without* project_id / index_state / indexed_at, and none of
  /// the v3 tables.
  void seedV2Database() {
    final raw = sqlite3.open(dbFile.path);
    raw.execute('''
      CREATE TABLE conversations (
        id TEXT NOT NULL PRIMARY KEY,
        title TEXT NOT NULL DEFAULT '',
        create_time INTEGER,
        update_time INTEGER,
        last_message_at INTEGER,
        is_archived INTEGER NOT NULL DEFAULT 0,
        is_starred INTEGER NOT NULL DEFAULT 0,
        default_model_slug TEXT,
        current_turn_id TEXT,
        source TEXT NOT NULL
      );
    ''');
    raw.execute('''
      CREATE TABLE turns (
        id TEXT NOT NULL PRIMARY KEY,
        conversation_id TEXT NOT NULL REFERENCES conversations (id),
        parent_turn_id TEXT,
        prompt_md TEXT NOT NULL DEFAULT '',
        response_md TEXT NOT NULL DEFAULT '',
        thoughts_md TEXT,
        model_slug TEXT,
        create_time INTEGER,
        raw_json TEXT NOT NULL
      );
    ''');
    raw.execute('''
      CREATE TABLE turn_assets (
        turn_id TEXT NOT NULL REFERENCES turns (id),
        kind TEXT NOT NULL,
        path TEXT NOT NULL,
        original_name TEXT,
        width INTEGER,
        height INTEGER
      );
    ''');
    raw.execute('''
      CREATE TABLE canvas_state (
        conversation_id TEXT NOT NULL PRIMARY KEY,
        viewport_json TEXT,
        mode TEXT NOT NULL DEFAULT 'navigate',
        focused_turn_id TEXT
      );
    ''');
    raw.execute('''
      CREATE TABLE imports (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        started_at INTEGER NOT NULL,
        finished_at INTEGER,
        source_path TEXT NOT NULL,
        conversations INTEGER NOT NULL DEFAULT 0,
        turns INTEGER NOT NULL DEFAULT 0,
        warnings_json TEXT NOT NULL DEFAULT '[]'
      );
    ''');

    raw.execute(
      "INSERT INTO conversations (id, title, source) "
      "VALUES ('c1', 'Existing chat', 'chatgpt_export')",
    );
    raw.execute(
      "INSERT INTO turns (id, conversation_id, raw_json) "
      "VALUES ('c1:t1', 'c1', '{}')",
    );

    // Drift keys its migration off sqlite's user_version pragma.
    raw.execute('PRAGMA user_version = 2');
    raw.close();
  }

  Future<List<String>> columnNames(AppDatabase db, String table) async {
    final rows =
        await db.customSelect('PRAGMA table_info($table)').get();
    return [for (final r in rows) r.read<String>('name')];
  }

  Future<bool> tableExists(AppDatabase db, String table) async {
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
          variables: [Variable.withString(table)],
        )
        .get();
    return rows.isNotEmpty;
  }

  test('upgrades a populated v2 DB to v3 without losing data', () async {
    seedV2Database();

    final db = AppDatabase(NativeDatabase(dbFile));
    addTearDown(db.close);

    // Opening at schemaVersion 3 runs onUpgrade(2 -> 3). Force the connection
    // open / migration to complete by issuing a read.
    final convCols = await columnNames(db, 'conversations');

    // 1. The three new conversation columns exist.
    expect(convCols, containsAll(['project_id', 'index_state', 'indexed_at']));

    // 2. The new v3 tables all exist.
    for (final table in [
      'projects',
      'propositions',
      'entities',
      'turn_entities',
      'soft_edges',
      'facts',
      'fact_sources',
    ]) {
      expect(await tableExists(db, table), isTrue, reason: 'missing $table');
    }

    // 3. The single 'default' project row was seeded.
    final projects = await db.select(db.projects).get();
    expect(projects.map((p) => p.id), ['default']);
    expect(projects.single.name, 'Default');

    // 4. The pre-existing conversation survived and was backfilled.
    final conv =
        await (db.select(db.conversations)..where((c) => c.id.equals('c1')))
            .getSingle();
    expect(conv.title, 'Existing chat');
    expect(conv.projectId, 'default');
    expect(conv.indexState, 0);
    expect(conv.indexedAt, isNull);

    // 5. Existing turn data survived the migration.
    final turns = await db.select(db.turns).get();
    expect(turns.map((t) => t.id), ['c1:t1']);
  });

  test('fresh v3 DB seeds the default project and new tables', () async {
    // A brand-new DB takes the onCreate path; it must reach the same shape as a
    // migrated one (default project + new tables present).
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final projects = await db.select(db.projects).get();
    expect(projects.map((p) => p.id), ['default']);
    expect(await tableExists(db, 'propositions'), isTrue);
    expect(await tableExists(db, 'facts'), isTrue);
  });
}
