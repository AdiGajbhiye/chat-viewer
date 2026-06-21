import 'dart:async';

import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/state/providers.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the sidebar ordering (`conversationListProvider`) — the source of
/// truth for "most-recent activity first". A perf change that indexes or
/// denormalizes the sort must keep this exact ordering.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> insertConversation(
    String id, {
    int? lastMessageAt,
    int? updateTime,
    int? createTime,
  }) =>
      db.into(db.conversations).insert(ConversationsCompanion.insert(
            id: id,
            source: 'test',
            lastMessageAt: Value(lastMessageAt),
            updateTime: Value(updateTime),
            createTime: Value(createTime),
          ));

  Future<List<String>> sidebarOrder() async {
    final container =
        ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(container.dispose);
    // Listen so the drift `watch()` stream is actually subscribed, and grab its
    // first emitted value.
    final done = Completer<List<Conversation>>();
    final sub = container.listen<AsyncValue<List<Conversation>>>(
      conversationListProvider,
      (_, next) {
        final data = next.asData;
        if (data != null && !done.isCompleted) done.complete(data.value);
      },
      fireImmediately: true,
    );
    final convs = await done.future;
    sub.close();
    return [for (final c in convs) c.id];
  }

  test('orders by last_message_at, not the export header update_time',
      () async {
    // A conversation the server "touched" recently (huge update_time) but whose
    // newest *message* is old must sink below one with a genuinely recent
    // message — the whole reason last_message_at exists (DESIGN.md §4).
    await insertConversation('recent-touch',
        updateTime: 9000000, lastMessageAt: 1000);
    await insertConversation('real-recent',
        updateTime: 1000, lastMessageAt: 8000000);

    expect(await sidebarOrder(), ['real-recent', 'recent-touch']);
  });

  test('falls back update_time → create_time when no message is timestamped',
      () async {
    // last_message_at is NULL for conversations with no timestamped turn; the
    // coalesce chain then uses update_time, then create_time.
    await insertConversation('by-last', lastMessageAt: 8000000);
    await insertConversation('by-update', updateTime: 6000000);
    await insertConversation('by-create', createTime: 5000000);

    expect(await sidebarOrder(), ['by-last', 'by-update', 'by-create']);
  });

  test('breaks ties on equal activity by id, descending', () async {
    await insertConversation('aaa', lastMessageAt: 7000000);
    await insertConversation('zzz', lastMessageAt: 7000000);

    expect(await sidebarOrder(), ['zzz', 'aaa']);
  });
}
