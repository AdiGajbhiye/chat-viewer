import 'package:drift/drift.dart';

part 'database.g.dart';

/// `conversations` table (DESIGN.md §4).
class Conversations extends Table {
  /// Export conversation id.
  TextColumn get id => text()();
  TextColumn get title => text().withDefault(const Constant(''))();

  /// Milliseconds since epoch (export floats are converted on import).
  IntColumn get createTime => integer().nullable()();
  IntColumn get updateTime => integer().nullable()();

  /// Milliseconds since epoch of the conversation's most recent message
  /// (`MAX` of its turns' `create_time`). The export's `update_time` is bumped
  /// by server-side touches unrelated to messages — a bulk migration can stamp
  /// a years-old conversation as "today" — so it is unreliable for "when did
  /// this happen". This derived value drives sidebar ordering and the shown
  /// date instead; NULL when no turn carries a timestamp.
  IntColumn get lastMessageAt => integer().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  BoolColumn get isStarred => boolean().withDefault(const Constant(false))();
  TextColumn get defaultModelSlug => text().nullable()();

  /// Derived from the export's `current_node`.
  TextColumn get currentTurnId => text().nullable()();

  /// Importer plugin id, e.g. 'chatgpt_export'.
  TextColumn get source => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// `turns` table: one canvas node per row (DESIGN.md §4).
class Turns extends Table {
  /// `<conversation_id>:<node_id>` where `node_id` is the turn's starting
  /// message node. The conversation prefix is required because real exports
  /// contain server-side conversation copies that reuse node ids.
  TextColumn get id => text()();
  TextColumn get conversationId => text().references(Conversations, #id)();

  /// Tree edge; NULL = root turn.
  TextColumn get parentTurnId => text().nullable()();
  TextColumn get promptMd => text().withDefault(const Constant(''))();
  TextColumn get responseMd => text().withDefault(const Constant(''))();

  /// Collapsed reasoning, if any.
  TextColumn get thoughtsMd => text().nullable()();
  TextColumn get modelSlug => text().nullable()();

  /// Milliseconds since epoch.
  IntColumn get createTime => integer().nullable()();

  /// Original message nodes, for lossless re-derivation.
  TextColumn get rawJson => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// `turn_assets` table (DESIGN.md §4). A missing asset is recorded with an
/// empty `path` (placeholder record, not a failure).
class TurnAssets extends Table {
  TextColumn get turnId => text().references(Turns, #id)();

  /// 'prompt' | 'response'.
  TextColumn get kind => text()();

  /// Absolute path of the copied asset; '' when the asset was missing from
  /// the export.
  TextColumn get path => text()();
  TextColumn get originalName => text().nullable()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
}

/// `canvas_state` table (DESIGN.md §4): the only user-mutable canvas state.
class CanvasStates extends Table {
  @override
  String get tableName => 'canvas_state';

  TextColumn get conversationId => text()();
  TextColumn get viewportJson => text().nullable()();

  /// 'navigate' | 'read'.
  TextColumn get mode => text().withDefault(const Constant('navigate'))();
  TextColumn get focusedTurnId => text().nullable()();

  @override
  Set<Column> get primaryKey => {conversationId};
}

/// `imports` table: one row per import run (DESIGN.md §4).
class Imports extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get startedAt => integer()();
  IntColumn get finishedAt => integer().nullable()();
  TextColumn get sourcePath => text()();
  IntColumn get conversations => integer().withDefault(const Constant(0))();
  IntColumn get turns => integer().withDefault(const Constant(0))();
  TextColumn get warningsJson => text().withDefault(const Constant('[]'))();
}

@DriftDatabase(
  tables: [Conversations, Turns, TurnAssets, CanvasStates, Imports],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
            'CREATE INDEX idx_turns_conversation ON turns (conversation_id)',
          );
          await customStatement(
            'CREATE INDEX idx_turn_assets_turn ON turn_assets (turn_id)',
          );
          // FTS5 over prompts/responses, kept in sync by triggers so every
          // write path (import, future editing) is covered.
          await customStatement(
            'CREATE VIRTUAL TABLE turns_fts USING fts5('
            'prompt_md, response_md, content=turns, content_rowid=rowid)',
          );
          await customStatement(
            'CREATE TRIGGER turns_fts_ai AFTER INSERT ON turns BEGIN '
            'INSERT INTO turns_fts(rowid, prompt_md, response_md) '
            'VALUES (new.rowid, new.prompt_md, new.response_md); END',
          );
          await customStatement(
            'CREATE TRIGGER turns_fts_ad AFTER DELETE ON turns BEGIN '
            "INSERT INTO turns_fts(turns_fts, rowid, prompt_md, response_md) "
            "VALUES ('delete', old.rowid, old.prompt_md, old.response_md); "
            'END',
          );
          await customStatement(
            'CREATE TRIGGER turns_fts_au AFTER UPDATE ON turns BEGIN '
            "INSERT INTO turns_fts(turns_fts, rowid, prompt_md, response_md) "
            "VALUES ('delete', old.rowid, old.prompt_md, old.response_md); "
            'INSERT INTO turns_fts(rowid, prompt_md, response_md) '
            'VALUES (new.rowid, new.prompt_md, new.response_md); END',
          );
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v2 adds conversations.last_message_at. Backfill it from existing
            // turns so the corrected ordering/date applies without forcing a
            // re-import.
            await m.addColumn(conversations, conversations.lastMessageAt);
            await customStatement(
              'UPDATE conversations SET last_message_at = ('
              'SELECT MAX(t.create_time) FROM turns t '
              'WHERE t.conversation_id = conversations.id)',
            );
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Word-based FTS search over prompts/responses; returns matching turn ids,
  /// best match first. Each whitespace-separated term is quoted and prefix-
  /// matched, then ANDed (see [ftsMatchQuery]), so free-form user text is safe
  /// and partial words match. Scoped to one conversation when [conversationId]
  /// is given (in-canvas "find in conversation"), otherwise global. A blank
  /// query matches nothing.
  Future<List<String>> searchTurnIds(String query, {String? conversationId}) async {
    final match = ftsMatchQuery(query);
    if (match.isEmpty) return const [];
    final rows = await customSelect(
      'SELECT t.id AS id FROM turns_fts f '
      'JOIN turns t ON t.rowid = f.rowid '
      'WHERE turns_fts MATCH ?'
      '${conversationId == null ? '' : ' AND t.conversation_id = ?'} '
      'ORDER BY rank',
      variables: [
        Variable.withString(match),
        if (conversationId != null) Variable.withString(conversationId),
      ],
      readsFrom: {turns},
    ).get();
    return [for (final row in rows) row.read<String>('id')];
  }

  /// Builds a safe FTS5 MATCH expression from free-form user text: each
  /// whitespace-separated term becomes a quoted prefix query (`"term"*`),
  /// terms implicitly ANDed. Returns '' for blank input. Quoting disarms
  /// FTS5 query syntax (`AND`, `-`, `:` …) in user input.
  static String ftsMatchQuery(String raw) {
    final terms = raw.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    return [for (final t in terms) '"${t.replaceAll('"', '""')}"*'].join(' ');
  }

  /// Sidebar search (DESIGN.md §6 "FTS search over titles + content"):
  /// conversations whose title contains [query] (newest first), followed by
  /// FTS5 prompt/response matches (best rank first), deduplicated.
  Future<List<Conversation>> searchConversations(String query) async {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return const [];

    final results = <String, Conversation>{};
    final all = await (select(conversations)
          ..orderBy([
            (c) => OrderingTerm.desc(
                coalesce([c.lastMessageAt, c.updateTime, c.createTime])),
            (c) => OrderingTerm.desc(c.id),
          ]))
        .get();
    for (final conversation in all) {
      if (conversation.title.toLowerCase().contains(needle)) {
        results[conversation.id] = conversation;
      }
    }

    final byId = {for (final c in all) c.id: c};
    final rows = await customSelect(
      'SELECT t.conversation_id AS cid FROM turns_fts f '
      'JOIN turns t ON t.rowid = f.rowid '
      'WHERE turns_fts MATCH ? GROUP BY cid ORDER BY MIN(f.rank)',
      variables: [Variable.withString(ftsMatchQuery(query))],
      readsFrom: {turns, conversations},
    ).get();
    for (final row in rows) {
      final conversation = byId[row.read<String>('cid')];
      if (conversation != null) results[conversation.id] = conversation;
    }
    return results.values.toList();
  }

  /// The most recent import run, if any (import warnings UI).
  Future<Import?> latestImport() => (select(imports)
        ..orderBy([(i) => OrderingTerm.desc(i.id)])
        ..limit(1))
      .getSingleOrNull();
}
