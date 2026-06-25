import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../data/llm/embedding_math.dart';
import '../data/llm/embedding_provider.dart';
import 'branching.dart';
import 'providers.dart';

/// The committed-facts layer (DESIGN.md §10, Layer 2 — "the keystone"). A user
/// *commits* a statement from a turn into `facts` + `fact_sources`; the result
/// is canonical ("what was decided", vs the raw graph's "what was said"), with
/// provenance back to its source turn(s) and an optional `supersedes` link.
/// Retrieval (M8.2) already boosts active facts, so a committed fact starts
/// feeding context the next time the session is continued.
///
/// Constructed with explicit dependencies so it is unit-testable without
/// Riverpod; [factsServiceProvider] wires the app's providers into it.
class FactsService {
  FactsService({
    required AppDatabase db,
    required EmbeddingProvider embedder,
  })  : _db = db, // ignore: prefer_initializing_formals
        _embedder = embedder; // ignore: prefer_initializing_formals

  final AppDatabase _db;
  final EmbeddingProvider _embedder;

  /// Committed facts get a distinct id namespace so they never collide with
  /// imported / authored turn ids.
  static const idPrefix = 'fact';
  static int _seq = 0;

  /// Promotes [text] into the facts layer: embeds it (offline stub →
  /// deterministic, no network), inserts an `active` fact, and records a
  /// `fact_sources` provenance row per id in [sourceTurnIds].
  ///
  /// [conversationId] null = project-wide; set = pinned to that session (the
  /// commit UI passes the source turn's conversation). When [supersedesId] is
  /// given, the prior fact is flipped to `superseded` and the new fact's
  /// `supersedesId` chains to it — done in one transaction so a fact and its
  /// supersession can never half-apply (DESIGN.md §10 "supersedes link …
  /// latest-decision vs most-similar").
  Future<Fact> commitFact({
    required String text,
    required List<String> sourceTurnIds,
    required String projectId,
    String? conversationId,
    String? supersedesId,
  }) async {
    final vector = (await _embedder.embed([text])).single;
    final embedding = encodeEmbedding(vector);
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = '$idPrefix-${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

    return _db.transaction(() async {
      if (supersedesId != null) {
        await (_db.update(_db.facts)..where((f) => f.id.equals(supersedesId)))
            .write(const FactsCompanion(status: Value('superseded')));
      }
      await _db.into(_db.facts).insert(
            FactsCompanion.insert(
              id: id,
              projectId: projectId,
              conversationId: Value(conversationId),
              factText: text,
              status: 'active',
              supersedesId: Value(supersedesId),
              embedding: Value(embedding),
              createdAt: Value(now),
            ),
          );
      for (final turnId in sourceTurnIds) {
        await _db.into(_db.factSources).insert(
              FactSourcesCompanion.insert(factId: id, turnId: turnId),
            );
      }
      return (_db.select(_db.facts)..where((f) => f.id.equals(id))).getSingle();
    });
  }

  /// Active (non-superseded) facts in [projectId], newest first — both
  /// project-wide and session-pinned. The wiki (M9.2) and any facts UI read
  /// this; superseded facts are excluded so a stale decision never resurfaces.
  Future<List<Fact>> activeFactsForProject(String projectId) {
    return (_db.select(_db.facts)
          ..where((f) => f.projectId.equals(projectId) & f.status.equals('active'))
          ..orderBy([(f) => OrderingTerm.desc(f.createdAt)]))
        .get();
  }

  /// Active facts visible to [conversationId]: the session-pinned ones plus the
  /// project-wide facts of its project, newest first. Mirrors how retrieval
  /// scopes facts for a session (DESIGN.md §10).
  Future<List<Fact>> activeFactsForConversation(String conversationId) async {
    final conversation = await (_db.select(_db.conversations)
          ..where((c) => c.id.equals(conversationId)))
        .getSingleOrNull();
    if (conversation == null) return const [];
    return (_db.select(_db.facts)
          ..where(
            (f) =>
                f.status.equals('active') &
                (f.conversationId.equals(conversationId) |
                    (f.conversationId.isNull() &
                        f.projectId.equals(conversation.projectId))),
          )
          ..orderBy([(f) => OrderingTerm.desc(f.createdAt)]))
        .get();
  }

  /// The provenance turn ids behind [factId] (its `fact_sources` rows) — the
  /// wiki's click-through back to the source turn(s).
  Future<List<String>> factSources(String factId) async {
    final rows = await (_db.select(_db.factSources)
          ..where((fs) => fs.factId.equals(factId)))
        .get();
    return [for (final r in rows) r.turnId];
  }
}

/// Builds a [FactsService] from the app's providers (DESIGN.md §10). The
/// embedder resolves to the offline stub until a backend is configured, so a
/// commit is fully offline and deterministic by default. Reading this needs
/// `sharedPreferencesProvider` (via the embedding config), so a no-prefs widget
/// test that exercises the commit action must override it.
final factsServiceProvider = Provider<FactsService>((ref) {
  return FactsService(
    db: ref.watch(databaseProvider),
    embedder: ref.watch(embeddingProviderProvider),
  );
});
