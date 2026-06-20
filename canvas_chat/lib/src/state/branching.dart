import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../data/llm/llm_provider.dart';
import 'providers.dart';

/// The text-generation backend used when branching off a chunk. Defaults to the
/// fully-offline [StubLlmProvider]; override this provider to plug in a real
/// one (the rest of the app is provider-agnostic).
final llmProviderProvider = Provider<LlmProvider>(
  (ref) => const StubLlmProvider(),
);

final branchServiceProvider = Provider<BranchService>(
  (ref) => BranchService(
    ref.watch(databaseProvider),
    ref.watch(llmProviderProvider),
  ),
);

/// Creates new "authored" turns that branch off an existing one — the
/// read-mode chunk toolbar's Ask-AI / Explain / Expand actions (DESIGN.md §9
/// forking: "start a new child turn from any node and send its root-path as
/// context"). The new turn is a *child* of the source turn, so the grid layout
/// lays it out in a fresh lane to the right — a horizontal branch — whenever
/// the source already has a continuation below it.
class BranchService {
  BranchService(this._db, this._llm);

  final AppDatabase _db;
  final LlmProvider _llm;

  /// Authored turns get a distinct id namespace so they never collide with
  /// imported `<conversation>:<node>` ids.
  static const idPrefix = 'authored';
  static int _seq = 0;

  /// Branches off [parent] with a child turn whose prompt is [prompt], then
  /// streams the provider's response into it. Returns the new turn's id
  /// (already inserted, so the caller can focus it immediately) plus a [done]
  /// future that completes once the response has finished streaming in — the
  /// UI ignores it; tests await it.
  Future<({String id, Future<void> done})> branchFrom({
    required Turn parent,
    required String prompt,
  }) async {
    final id = '${parent.conversationId}:$idPrefix-'
        '${DateTime.now().microsecondsSinceEpoch}-${_seq++}';
    await _db.into(_db.turns).insert(
          TurnsCompanion.insert(
            id: id,
            conversationId: parent.conversationId,
            parentTurnId: Value(parent.id),
            promptMd: Value(prompt),
            createTime: Value(DateTime.now().millisecondsSinceEpoch),
            rawJson: '{"authored":true}',
          ),
        );
    // Kick off streaming now; hand the caller its future without awaiting so
    // the branch appears (and can be focused) before the answer arrives.
    return (id: id, done: _stream(id, parent, prompt));
  }

  Future<void> _stream(String id, Turn parent, String prompt) async {
    try {
      final context = await _ancestors(parent);
      final buffer = StringBuffer();
      await for (final delta in _llm.generate(prompt: prompt, context: context)) {
        buffer.write(delta);
        await _writeResponse(id, buffer.toString());
      }
    } catch (e) {
      await _writeResponse(id, '_Generation failed: ${e}_');
    }
  }

  Future<void> _writeResponse(String id, String md) =>
      (_db.update(_db.turns)..where((t) => t.id.equals(id)))
          .write(TurnsCompanion(responseMd: Value(md)));

  /// Root→[turn] path (inclusive), for providers that send conversation
  /// history. Walks `parent_turn_id` with a cycle guard over corrupt data.
  Future<List<Turn>> _ancestors(Turn turn) async {
    final all = await (_db.select(_db.turns)
          ..where((t) => t.conversationId.equals(turn.conversationId)))
        .get();
    final byId = {for (final t in all) t.id: t};
    final path = <Turn>[];
    final seen = <String>{};
    Turn? cursor = turn;
    while (cursor != null && seen.add(cursor.id)) {
      path.add(cursor);
      final parentId = cursor.parentTurnId;
      cursor = parentId == null ? null : byId[parentId];
    }
    return path.reversed.toList();
  }
}
