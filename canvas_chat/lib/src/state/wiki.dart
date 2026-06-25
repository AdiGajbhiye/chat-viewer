import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import 'facts.dart';
import 'providers.dart';

/// The generated, **read-only** project wiki (DESIGN.md §10 "Project wiki …
/// entities as hyperlinked pages, facts as content, `fact_sources` for
/// click-through to the source turn; connective prose via GraphRAG-style
/// *topical* clustering (topics cross branches — don't cluster by fork
/// structure)").
///
/// This step is offline & deterministic: it lists/organizes the *already
/// committed* facts + extracted entities + soft edges; there is no LLM prose
/// generation. Topics are derived by **connected components over the
/// `soft_edges` graph** (semantic + entity edges), which is exactly the
/// machinery that crosses branches — a topic is a set of turns linked by
/// association, regardless of the fork tree.
///
/// Constructed with explicit dependencies so it is unit-testable without
/// Riverpod, mirroring [FactsService]; [wikiServiceProvider] wires the app's
/// providers into it.
class WikiService {
  WikiService({
    required AppDatabase db,
    required FactsService facts,
  })  : _db = db, // ignore: prefer_initializing_formals
        _facts = facts; // ignore: prefer_initializing_formals

  final AppDatabase _db;
  final FactsService _facts;

  /// The whole overview model for [projectId]: clustered topics, the
  /// all-entities index (with mention counts) and the active-facts list. Built
  /// lazily-but-once per open; detail (entity backlinks) is fetched separately
  /// via [entityPage] so the overview never eager-loads every turn's full text.
  Future<WikiOverview> overview(String projectId) async {
    final entities = await entitiesForProject(projectId);
    final facts = await _facts.activeFactsForProject(projectId);
    final topics = await topicsForProject(projectId, entities: entities);

    // Each fact's provenance (source turns), so the overview can render the
    // click-through without a per-fact round-trip in the UI build.
    final factSources = <String, List<String>>{};
    for (final fact in facts) {
      factSources[fact.id] = await _facts.factSources(fact.id);
    }

    return WikiOverview(
      projectId: projectId,
      topics: topics,
      entities: entities,
      facts: facts,
      factSourceTurnIds: factSources,
    );
  }

  /// Every entity in [projectId] with its mention count (`turn_entities` rows),
  /// ordered most-mentioned first, then by normalized name — a **stable,
  /// deterministic** ordering (ties never reorder run-to-run).
  Future<List<WikiEntityRef>> entitiesForProject(String projectId) async {
    final entities = await (_db.select(_db.entities)
          ..where((e) => e.projectId.equals(projectId)))
        .get();

    // One grouped count query rather than N per-entity counts.
    final counts = <String, int>{};
    final countExpr = _db.turnEntities.entityId.count();
    final rows = await (_db.selectOnly(_db.turnEntities)
          ..addColumns([_db.turnEntities.entityId, countExpr])
          ..groupBy([_db.turnEntities.entityId]))
        .get();
    for (final row in rows) {
      counts[row.read(_db.turnEntities.entityId)!] = row.read(countExpr) ?? 0;
    }

    final refs = [
      for (final e in entities)
        WikiEntityRef(
          id: e.id,
          name: e.name,
          normalized: e.normalized,
          mentionCount: counts[e.id] ?? 0,
        ),
    ];
    refs.sort((a, b) {
      final byCount = b.mentionCount.compareTo(a.mentionCount);
      if (byCount != 0) return byCount;
      final byName = a.normalized.compareTo(b.normalized);
      if (byName != 0) return byName;
      return a.id.compareTo(b.id);
    });
    return refs;
  }

  /// The detail page for one entity (Obsidian-style backlinks): the active
  /// facts and proposition snippets that mention it, each carrying the source
  /// turn(s) for click-through. Returns null when the entity doesn't exist.
  Future<WikiEntityPage?> entityPage(String entityId) async {
    final entity = await (_db.select(_db.entities)
          ..where((e) => e.id.equals(entityId)))
        .getSingleOrNull();
    if (entity == null) return null;

    // Turns that mention this entity (via turn_entities) — the backlink set.
    final turnIds = await (_db.selectOnly(_db.turnEntities)
          ..addColumns([_db.turnEntities.turnId])
          ..where(_db.turnEntities.entityId.equals(entityId)))
        .map((row) => row.read(_db.turnEntities.turnId)!)
        .get();
    final turnIdSet = turnIds.toSet();

    // Proposition snippets from those turns (the "what was said about it"),
    // deterministically ordered by turn then proposition id.
    final propositions = turnIdSet.isEmpty
        ? <Proposition>[]
        : await (_db.select(_db.propositions)
              ..where((p) => p.turnId.isIn(turnIdSet.toList()))
              ..orderBy([
                (p) => OrderingTerm.asc(p.turnId),
                (p) => OrderingTerm.asc(p.id),
              ]))
            .get();

    // Active facts whose provenance includes one of those turns (the "what was
    // decided about it"). Reuses the active-only facts list (superseded
    // excluded by FactsService).
    final allFacts = await _facts.activeFactsForProject(entity.projectId);
    final factBacklinks = <WikiFactBacklink>[];
    for (final fact in allFacts) {
      final sources = await _facts.factSources(fact.id);
      final mentioning = sources.where(turnIdSet.contains).toList();
      if (mentioning.isNotEmpty) {
        factBacklinks.add(WikiFactBacklink(fact: fact, sourceTurnIds: sources));
      }
    }

    return WikiEntityPage(
      entity: entity,
      facts: factBacklinks,
      propositions: propositions,
      mentionTurnIds: turnIds,
    );
  }

  /// **Topical clustering, offline & deterministic** (DESIGN.md §10): connected
  /// components over the project's `soft_edges` graph (semantic + entity edges
  /// — `crossSession` included, since topics span sessions). Each component
  /// with ≥2 turns becomes a [WikiTopic]; turns connected by association land
  /// in the same topic regardless of where they sit in the fork tree, which is
  /// the whole point of clustering over soft edges rather than the turn tree.
  ///
  /// Determinism: turns are unioned in a fixed (sorted-id) order via union-find,
  /// and the resulting components are sorted by size then least turn id, so the
  /// same graph always yields the same topics in the same order. Singleton /
  /// edge-less turns are deliberately *not* surfaced as their own topics here —
  /// they have nothing to connect — but their entities/facts still appear in the
  /// all-entities index and all-facts list.
  Future<List<WikiTopic>> topicsForProject(
    String projectId, {
    List<WikiEntityRef>? entities,
  }) async {
    final edges = await (_db.select(_db.softEdges)
          ..where((e) => e.projectId.equals(projectId)))
        .get();
    if (edges.isEmpty) return const [];

    // Union-find over turn ids, fed edges in a deterministic order.
    final sortedEdges = [...edges]..sort((a, b) {
        final f = a.fromTurnId.compareTo(b.fromTurnId);
        if (f != 0) return f;
        final t = a.toTurnId.compareTo(b.toTurnId);
        if (t != 0) return t;
        return a.kind.compareTo(b.kind);
      });
    final uf = _UnionFind();
    for (final e in sortedEdges) {
      uf.union(e.fromTurnId, e.toTurnId);
    }

    // Group turns by their component root.
    final byRoot = <String, List<String>>{};
    for (final turn in uf.members) {
      byRoot.putIfAbsent(uf.find(turn), () => []).add(turn);
    }
    final components = byRoot.values
        .map((turns) => turns..sort())
        .where((turns) => turns.length >= 2)
        .toList();
    // Stable component order: larger topics first, ties broken by least turn id.
    components.sort((a, b) {
      final bySize = b.length.compareTo(a.length);
      if (bySize != 0) return bySize;
      return a.first.compareTo(b.first);
    });

    // Resolve the entities + active facts attached to each component's turns.
    final entityRefs = entities ?? await entitiesForProject(projectId);
    final entityById = {for (final e in entityRefs) e.id: e};
    final facts = await _facts.activeFactsForProject(projectId);

    // turn -> entity ids (one query, then bucket per component).
    final teRows = await _db.select(_db.turnEntities).get();
    final entityIdsByTurn = <String, Set<String>>{};
    for (final row in teRows) {
      entityIdsByTurn.putIfAbsent(row.turnId, () => {}).add(row.entityId);
    }

    // turn -> fact ids (via fact_sources, restricted to active facts).
    final activeFactById = {for (final f in facts) f.id: f};
    final fsRows = await _db.select(_db.factSources).get();
    final factIdsByTurn = <String, Set<String>>{};
    for (final row in fsRows) {
      if (activeFactById.containsKey(row.factId)) {
        factIdsByTurn.putIfAbsent(row.turnId, () => {}).add(row.factId);
      }
    }

    final topics = <WikiTopic>[];
    for (var i = 0; i < components.length; i++) {
      final turns = components[i];
      final topicEntityIds = <String>{};
      final topicFactIds = <String>{};
      for (final turn in turns) {
        topicEntityIds.addAll(entityIdsByTurn[turn] ?? const {});
        topicFactIds.addAll(factIdsByTurn[turn] ?? const {});
      }
      final topicEntities = [
        for (final id in topicEntityIds) ?entityById[id],
      ]..sort((a, b) {
          final byCount = b.mentionCount.compareTo(a.mentionCount);
          if (byCount != 0) return byCount;
          return a.normalized.compareTo(b.normalized);
        });
      final topicFacts = [
        for (final id in topicFactIds) ?activeFactById[id],
      ]..sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));

      topics.add(WikiTopic(
        // Stable, content-free label; LLM cluster-summaries are deferred.
        title: 'Topic ${i + 1}',
        turnIds: turns,
        entities: topicEntities,
        facts: topicFacts,
      ));
    }
    return topics;
  }

  /// The provenance turn ids behind [factId] — re-exposed so the UI can resolve
  /// a fact's click-through targets without reaching past the service.
  Future<List<String>> factSources(String factId) => _facts.factSources(factId);

  /// The conversation id a turn belongs to (the wiki's click-through needs it to
  /// select the right canvas). Null when the turn is missing.
  Future<String?> conversationOfTurn(String turnId) async {
    final turn = await (_db.select(_db.turns)..where((t) => t.id.equals(turnId)))
        .getSingleOrNull();
    return turn?.conversationId;
  }
}

/// Minimal union-find over string keys, used for the soft-edge connected
/// components. Deterministic given a fixed edge order.
class _UnionFind {
  final Map<String, String> _parent = {};

  Iterable<String> get members => _parent.keys;

  String find(String x) {
    var root = _parent.putIfAbsent(x, () => x);
    while (root != _parent[root]) {
      root = _parent[root]!;
    }
    // Path-compress.
    var cur = x;
    while (_parent[cur] != root) {
      final next = _parent[cur]!;
      _parent[cur] = root;
      cur = next;
    }
    return root;
  }

  void union(String a, String b) {
    final ra = find(a);
    final rb = find(b);
    if (ra == rb) return;
    // Attach the lexicographically-larger root under the smaller one so the
    // chosen representative is stable regardless of union order.
    if (ra.compareTo(rb) < 0) {
      _parent[rb] = ra;
    } else {
      _parent[ra] = rb;
    }
  }
}

/// One entity as referenced from a list/index — its id, display name and how
/// many turns mention it. The wiki's hyperlink target.
class WikiEntityRef {
  const WikiEntityRef({
    required this.id,
    required this.name,
    required this.normalized,
    required this.mentionCount,
  });

  final String id;
  final String name;
  final String normalized;
  final int mentionCount;
}

/// One topic = a connected component of the soft-edge graph, with the entities
/// and active facts attached to its turns. Cross-branch by construction.
class WikiTopic {
  const WikiTopic({
    required this.title,
    required this.turnIds,
    required this.entities,
    required this.facts,
  });

  final String title;
  final List<String> turnIds;
  final List<WikiEntityRef> entities;
  final List<Fact> facts;
}

/// An active fact surfaced on an entity page, with its provenance turns for
/// click-through.
class WikiFactBacklink {
  const WikiFactBacklink({
    required this.fact,
    required this.sourceTurnIds,
  });

  final Fact fact;
  final List<String> sourceTurnIds;
}

/// The detail page for one entity: the facts + proposition snippets that
/// backlink to it, plus the turns mentioning it.
class WikiEntityPage {
  const WikiEntityPage({
    required this.entity,
    required this.facts,
    required this.propositions,
    required this.mentionTurnIds,
  });

  final Entity entity;
  final List<WikiFactBacklink> facts;
  final List<Proposition> propositions;
  final List<String> mentionTurnIds;
}

/// The whole overview model: clustered topics, all entities, all active facts
/// (with their provenance turns pre-resolved for click-through).
class WikiOverview {
  const WikiOverview({
    required this.projectId,
    required this.topics,
    required this.entities,
    required this.facts,
    required this.factSourceTurnIds,
  });

  final String projectId;
  final List<WikiTopic> topics;
  final List<WikiEntityRef> entities;
  final List<Fact> facts;
  final Map<String, List<String>> factSourceTurnIds;
}

/// Builds a [WikiService] from the app's providers, reusing [factsServiceProvider]
/// so the active-only facts logic (superseded excluded) is shared.
final wikiServiceProvider = Provider<WikiService>((ref) {
  return WikiService(
    db: ref.watch(databaseProvider),
    facts: ref.watch(factsServiceProvider),
  );
});

/// The wiki overview for a project (one-shot — the wiki is generated read-only,
/// it doesn't live-update while open). Scoped per project id.
final wikiOverviewProvider =
    FutureProvider.autoDispose.family<WikiOverview, String>((ref, projectId) {
  return ref.watch(wikiServiceProvider).overview(projectId);
});

/// The detail page for one entity, or null if it no longer exists. One-shot,
/// scoped per entity id.
final entityPageProvider =
    FutureProvider.autoDispose.family<WikiEntityPage?, String>((ref, entityId) {
  return ref.watch(wikiServiceProvider).entityPage(entityId);
});

/// A pending click-through from the wiki to a source turn: the wiki sets it,
/// the matching [CanvasView] consumes it (opens the reader on the turn) and
/// clears it. Reuses the existing reader/selection mechanism rather than
/// inventing routing. Null = no pending request.
class WikiNavRequest {
  const WikiNavRequest({required this.conversationId, required this.turnId});

  final String conversationId;
  final String turnId;
}

final wikiNavRequestProvider =
    NotifierProvider<WikiNavRequest_, WikiNavRequest?>(WikiNavRequest_.new);

// ignore: camel_case_types
class WikiNavRequest_ extends Notifier<WikiNavRequest?> {
  @override
  WikiNavRequest? build() => null;

  void set(WikiNavRequest request) => state = request;

  /// Called by the consuming canvas once it has honored a request, so a later
  /// re-open of the same turn fires again.
  void clear() => state = null;
}
