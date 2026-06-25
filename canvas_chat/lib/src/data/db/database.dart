import 'package:drift/drift.dart';

import '../llm/embedding_math.dart';
import '../llm/proposition_extractor.dart';

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

  /// Project tier (DESIGN.md §10). Conceptual FK to `projects.id`; defaults to
  /// the single 'default' project created by migration v3.
  TextColumn get projectId =>
      text().withDefault(const Constant('default'))();

  /// Lazy-index state machine (DESIGN.md §10):
  /// 0=notIndexed 1=indexing 2=indexed 3=stale.
  IntColumn get indexState => integer().withDefault(const Constant(0))();

  /// Milliseconds since epoch the conversation was last indexed; NULL until
  /// indexed.
  IntColumn get indexedAt => integer().nullable()();

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

/// `projects` table: the Project tier above Conversation (DESIGN.md §10). Every
/// Phase-2 row carries a `project_id` so retrieval can range across a project.
class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withDefault(const Constant(''))();

  /// Milliseconds since epoch.
  IntColumn get createdAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// `propositions` table (DESIGN.md §10): ~5 atomic, standalone, coref-resolved
/// statements per indexed turn, each separately retrievable. `conversation_id`
/// and `project_id` are denormalized so retrieval can scope-filter without a
/// join. `embedding` is a raw float32 little-endian BLOB; `embedding_model`
/// records which model produced it so re-embedding can be invalidated.
class Propositions extends Table {
  TextColumn get id => text()();
  TextColumn get turnId => text().references(Turns, #id)();
  TextColumn get conversationId => text()();
  TextColumn get projectId => text()();

  /// The proposition statement. DB column is `text` (DESIGN.md §10); the getter
  /// is renamed because drift reserves a bare `text` getter for its column
  /// builder.
  TextColumn get propText => text().named('text')();

  /// Open-vocab aspect tag (not fixed buckets).
  TextColumn get aspect => text().nullable()();

  /// float32[] little-endian.
  BlobColumn get embedding => blob().nullable()();
  TextColumn get embeddingModel => text().nullable()();

  /// Milliseconds since epoch.
  IntColumn get createdAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// `entities` table (DESIGN.md §10): named things mentioned across turns; the
/// wiki's backbone. `normalized` is the lookup key for de-duplication.
class Entities extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get name => text()();
  TextColumn get normalized => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// `turn_entities` table (DESIGN.md §10): the m:n edge between turns and the
/// entities they mention — entity soft-edges and wiki backlinks.
class TurnEntities extends Table {
  TextColumn get entityId => text().references(Entities, #id)();
  TextColumn get turnId => text().references(Turns, #id)();
}

/// `soft_edges` table (DESIGN.md §10): precomputed inter-turn relations rendered
/// as a canvas layer. Symmetric, stored once canonicalized so `from_turn_id <
/// to_turn_id`. `kind` ∈ semantic | entity | crossSession.
class SoftEdges extends Table {
  TextColumn get fromTurnId => text()();
  TextColumn get toTurnId => text()();
  TextColumn get kind => text()();
  RealColumn get weight => real()();
  TextColumn get projectId => text()();
}

/// `facts` table (DESIGN.md §10, Layer 2): canonical statements a user commits
/// from a turn. `conversation_id` NULL = project-wide; set = pinned to a
/// session. `status` ∈ active | superseded; `supersedes_id` links the
/// superseded fact. `embedding` is a raw float32 little-endian BLOB.
class Facts extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get conversationId => text().nullable()();

  /// The committed statement. DB column is `text` (DESIGN.md §10); the getter is
  /// renamed because drift reserves a bare `text` getter for its column builder.
  TextColumn get factText => text().named('text')();
  TextColumn get status => text()();
  TextColumn get supersedesId => text().nullable()();

  /// float32[] little-endian.
  BlobColumn get embedding => blob().nullable()();

  /// Milliseconds since epoch.
  IntColumn get createdAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// `fact_sources` table (DESIGN.md §10): a fact's provenance back to its source
/// turn(s) — the wiki's click-through.
class FactSources extends Table {
  TextColumn get factId => text().references(Facts, #id)();
  TextColumn get turnId => text().references(Turns, #id)();
}

@DriftDatabase(
  tables: [
    Conversations,
    Turns,
    TurnAssets,
    CanvasStates,
    Imports,
    Projects,
    Propositions,
    Entities,
    TurnEntities,
    SoftEdges,
    Facts,
    FactSources,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

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
          // Phase-2 retrieval indexes (DESIGN.md §10). A fresh DB seeds the
          // single 'default' project so conversations.project_id is valid.
          await _createPhase2Indexes();
          await _seedDefaultProject();
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
          if (from < 3) {
            // v3 (DESIGN.md §10): the Project tier + the retrieval/facts layer.
            // Additive only — existing canvas_state/turns/turn_assets rows are
            // untouched. Create the new tables, add the three conversation
            // columns, seed the single 'default' project, and backfill every
            // existing conversation to it (index_state defaults to notIndexed).
            await m.createTable(projects);
            await m.createTable(propositions);
            await m.createTable(entities);
            await m.createTable(turnEntities);
            await m.createTable(softEdges);
            await m.createTable(facts);
            await m.createTable(factSources);
            await m.addColumn(conversations, conversations.projectId);
            await m.addColumn(conversations, conversations.indexState);
            await m.addColumn(conversations, conversations.indexedAt);
            await _createPhase2Indexes();
            await _seedDefaultProject();
            // Defaults already stamp project_id='default'/index_state=0 on
            // existing rows, but set them explicitly so the backfill is obvious
            // and independent of column-default behavior.
            await customStatement(
              "UPDATE conversations SET project_id = 'default', index_state = 0",
            );
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Phase-2 retrieval indexes (DESIGN.md §10), shared by `onCreate` and the
  /// v2→v3 upgrade so a fresh and a migrated DB end up identical.
  Future<void> _createPhase2Indexes() async {
    await customStatement(
      'CREATE INDEX idx_propositions_project ON propositions (project_id)',
    );
    await customStatement(
      'CREATE INDEX idx_propositions_turn ON propositions (turn_id)',
    );
    await customStatement(
      'CREATE INDEX idx_turn_entities_turn ON turn_entities (turn_id)',
    );
    await customStatement(
      'CREATE INDEX idx_turn_entities_entity ON turn_entities (entity_id)',
    );
    await customStatement(
      'CREATE INDEX idx_soft_edges_project ON soft_edges (project_id)',
    );
    await customStatement(
      'CREATE INDEX idx_fact_sources_fact ON fact_sources (fact_id)',
    );
  }

  /// Inserts the single 'default' project (DESIGN.md §10) if absent.
  /// `INSERT OR IGNORE` keeps it idempotent across create/upgrade paths.
  Future<void> _seedDefaultProject() async {
    await customStatement(
      "INSERT OR IGNORE INTO projects (id, name, created_at) "
      "VALUES ('default', 'Default', NULL)",
    );
  }

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

  /// Persists a turn's [extraction] (DESIGN.md §10 proposition / entity index):
  /// writes one `propositions` row per [ExtractedProposition], upserts the
  /// referenced `entities` (deduped by `(projectId, normalized)`, reusing
  /// existing rows), and links them via `turn_entities`. All in one transaction.
  ///
  /// **Idempotent for re-index**: every existing `propositions` and
  /// `turn_entities` row for [turnId] is cleared first, so re-running never
  /// duplicates. Entities are never deleted — they're shared across turns — only
  /// new ones are inserted.
  ///
  /// When [embeddings] is supplied it must be the **same length and order** as
  /// `extraction.propositions`; each vector is encoded ([encodeEmbedding]) into
  /// the matching row with [embeddingModel]. Omit it (the default) to leave the
  /// `embedding` column null for the indexer to backfill.
  Future<void> persistTurnExtraction({
    required String turnId,
    required String conversationId,
    required String projectId,
    required TurnExtraction extraction,
    List<List<double>>? embeddings,
    String? embeddingModel,
  }) async {
    final propositions = extraction.propositions;
    if (embeddings != null && embeddings.length != propositions.length) {
      throw ArgumentError(
        'embeddings (${embeddings.length}) must match propositions '
        '(${propositions.length})',
      );
    }
    final now = DateTime.now().millisecondsSinceEpoch;

    await transaction(() async {
      // Idempotent re-index: drop this turn's prior propositions + entity links
      // before re-inserting. Entities themselves are shared and left in place.
      await (delete(this.propositions)..where((p) => p.turnId.equals(turnId)))
          .go();
      await (delete(turnEntities)..where((te) => te.turnId.equals(turnId)))
          .go();

      // Propositions. Deterministic ids ('<turnId>#<index>') keep a re-index
      // stable and make the rows easy to trace back to a turn.
      final propRows = <PropositionsCompanion>[];
      for (var i = 0; i < propositions.length; i++) {
        final prop = propositions[i];
        final vector = embeddings?[i];
        propRows.add(
          PropositionsCompanion.insert(
            id: '$turnId#$i',
            turnId: turnId,
            conversationId: conversationId,
            projectId: projectId,
            propText: prop.text,
            aspect: Value(prop.aspect),
            embedding:
                Value(vector == null ? null : encodeEmbedding(vector)),
            embeddingModel:
                Value(vector == null ? null : embeddingModel),
            createdAt: Value(now),
          ),
        );
      }
      if (propRows.isNotEmpty) {
        await batch((b) => b.insertAll(this.propositions, propRows));
      }

      // Entities, deduped by (projectId, normalized). Reuse an existing row if
      // one already exists for this project; otherwise create it. The map keys
      // off `normalized` so two surfaces of the same entity within this turn
      // collapse to one row / one link.
      final wantedByNormalized = <String, String>{}; // normalized -> surface
      for (final prop in propositions) {
        for (final surface in prop.entities) {
          final normalized = surface.trim().toLowerCase();
          if (normalized.isEmpty) continue;
          wantedByNormalized.putIfAbsent(normalized, () => surface.trim());
        }
      }

      final entityIdByNormalized = <String, String>{};
      if (wantedByNormalized.isNotEmpty) {
        final existing = await (select(entities)
              ..where((e) =>
                  e.projectId.equals(projectId) &
                  e.normalized.isIn(wantedByNormalized.keys.toList())))
            .get();
        for (final row in existing) {
          entityIdByNormalized[row.normalized] = row.id;
        }

        final newEntityRows = <EntitiesCompanion>[];
        for (final entry in wantedByNormalized.entries) {
          if (entityIdByNormalized.containsKey(entry.key)) continue;
          final id = 'ent:$projectId:${entry.key}';
          entityIdByNormalized[entry.key] = id;
          newEntityRows.add(
            EntitiesCompanion.insert(
              id: id,
              projectId: projectId,
              name: entry.value,
              normalized: entry.key,
            ),
          );
        }
        if (newEntityRows.isNotEmpty) {
          await batch((b) => b.insertAll(entities, newEntityRows));
        }
      }

      // turn_entities links, deduped by entity id (the turn mentions each entity
      // once for the wiki backlink, regardless of how many propositions cite it).
      if (entityIdByNormalized.isNotEmpty) {
        final linkRows = [
          for (final entityId in entityIdByNormalized.values.toSet())
            TurnEntitiesCompanion.insert(entityId: entityId, turnId: turnId),
        ];
        await batch((b) => b.insertAll(turnEntities, linkRows));
      }
    });
  }

  /// The generated index for one turn (DESIGN.md §10 "Proposition index"): the
  /// turn's propositions (each with its open-vocab aspect tag) plus the names of
  /// the entities it mentions — the human-visible view of what indexing wrote.
  ///
  /// Both lists are ordered stably (propositions by id, entity names
  /// case-insensitively) so a repeated read renders identically; entity names
  /// are deduped (a turn links each entity once). Returns empty lists for a turn
  /// that hasn't been indexed yet.
  Future<TurnIndex> turnIndex(String turnId) async {
    final props = await (select(propositions)
          ..where((p) => p.turnId.equals(turnId))
          ..orderBy([(p) => OrderingTerm.asc(p.id)]))
        .get();

    final names = await (selectOnly(turnEntities)
          ..addColumns([entities.name])
          ..join([
            innerJoin(
              entities,
              entities.id.equalsExp(turnEntities.entityId),
            ),
          ])
          ..where(turnEntities.turnId.equals(turnId))
          ..orderBy([OrderingTerm.asc(entities.normalized)]))
        .map((row) => row.read(entities.name)!)
        .get();

    return TurnIndex(
      propositions: [
        for (final p in props) (text: p.propText, aspect: p.aspect),
      ],
      // Dedupe while preserving the normalized order (a turn can, defensively,
      // link two surfaces of the same name).
      entities: names.toSet().toList(),
    );
  }
}

/// The generated index of a single turn, as surfaced in the reader (DESIGN.md
/// §10): the turn's propositions (atomic standalone statements, each with its
/// open-vocab aspect tag) and the names of the entities it mentions. Both lists
/// are empty for a not-yet-indexed turn.
class TurnIndex {
  const TurnIndex({required this.propositions, required this.entities});

  final List<({String text, String? aspect})> propositions;
  final List<String> entities;

  bool get isEmpty => propositions.isEmpty && entities.isEmpty;
}
