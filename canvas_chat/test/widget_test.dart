import 'dart:io';

import 'package:canvas_chat/main.dart';
import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/data/import/chatgpt_importer.dart';
import 'package:canvas_chat/src/data/import/export_source.dart';
import 'package:canvas_chat/src/state/providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/synthetic_export.dart';

void main() {
  late Directory tempDir;
  late Directory assetsDir;
  late AppDatabase db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('canvas_chat_widget');
    assetsDir = Directory('${tempDir.path}/assets')..createSync();
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  /// Imports the synthetic three-conversation export into [db].
  ///
  /// Must run inside [WidgetTester.runAsync]: the file I/O and importer are
  /// real async work, and awaiting it directly in testWidgets' FakeAsync zone
  /// deadlocks the test forever.
  Future<void> seed(WidgetTester tester) async {
    await tester.runAsync(() async {
      final exportDir = Directory('${tempDir.path}/export');
      await writeSyntheticExport(exportDir);
      await ChatGptImporter(
        db: db,
        source: DirectoryExportSource(exportDir),
        assetsDir: assetsDir,
      ).run();
    });
  }

  Widget app() => ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          assetsDirProvider.overrideWithValue(assetsDir),
        ],
        child: const CanvasChatApp(),
      );

  /// Unmounts the app at the end of a test. Disposing ProviderScope cancels
  /// drift's stream queries, which schedules a zero-duration close timer; it
  /// must fire inside the test's FakeAsync zone or flutter_test fails the
  /// `!timersPending` invariant and `db.close()` in tearDown deadlocks.
  Future<void> unmountApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    // A zero-duration pump() does not advance the fake clock, so give the
    // zero-duration close timer a real tick to fire on.
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('app launches with an empty database', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.textContaining('No conversations yet'), findsOneWidget);
    expect(find.text('Select a conversation'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('sidebar lists conversations sorted by update_time desc',
      (tester) async {
    await seed(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // update_time: Assistant first (1720…) > Forked chat (1710…) >
    // Linear chat (1700…).
    final yAssistant = tester.getTopLeft(find.text('Assistant first')).dy;
    final yForked = tester.getTopLeft(find.text('Forked chat')).dy;
    final yLinear = tester.getTopLeft(find.text('Linear chat')).dy;
    expect(yAssistant, lessThan(yForked));
    expect(yForked, lessThan(yLinear));

    await unmountApp(tester);
  });

  testWidgets('selecting a conversation opens read mode on the active path',
      (tester) async {
    await seed(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Forked chat'));
    await tester.pumpAndSettle();

    // Active path (current_node = f-u3b): prompt turn, regenerated answer
    // "second answer", edited prompt "edited v2" — 3 turns.
    expect(find.text('1 / 3'), findsOneWidget);
    expect(
      find.textContaining('regenerate me', findRichText: true),
      findsWidgets,
    );
    // The inactive branch is not part of the path.
    expect(
      find.textContaining('first answer', findRichText: true),
      findsNothing,
    );

    // ↓ button advances.
    await tester.tap(find.byTooltip('Next turn (↓)'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    expect(
      find.textContaining('second answer', findRichText: true),
      findsWidgets,
    );

    // Arrow keys advance/retreat.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('3 / 3'), findsOneWidget);
    expect(
      find.textContaining('edited v2', findRichText: true),
      findsWidgets,
    );

    // At the leaf, ↓ is disabled and another ↓ keeps position.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('3 / 3'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);

    await unmountApp(tester);
  });

  testWidgets('read mode renders markdown, reasoning, and image placeholders',
      (tester) async {
    await seed(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Linear chat'));
    await tester.pumpAndSettle();

    // Turn 1: prompt + response + folded reasoning.
    expect(find.text('1 / 3'), findsOneWidget);
    expect(
      find.textContaining('hello quantum entanglement', findRichText: true),
      findsWidgets,
    );
    expect(
      find.textContaining('spooky action', findRichText: true),
      findsWidgets,
    );
    expect(find.text('Reasoning'), findsOneWidget);
    // Reasoning content is collapsed until expanded.
    expect(
      find.textContaining('deep thought trace', findRichText: true),
      findsNothing,
    );
    await tester.tap(find.text('Reasoning'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('deep thought trace', findRichText: true),
      findsWidgets,
    );

    // Turn 2 has image markers, shown as placeholders (assets render in M5).
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    expect(
      find.textContaining('image attachment', findRichText: true),
      findsWidgets,
    );

    // Switching conversations resets the reader.
    await tester.tap(find.text('Assistant first'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 1'), findsOneWidget);
    expect(
      find.textContaining('I speak first', findRichText: true),
      findsWidgets,
    );

    await unmountApp(tester);
  });
}
