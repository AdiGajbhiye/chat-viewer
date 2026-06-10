import 'dart:io';

import 'package:canvas_chat/main.dart';
import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/data/import/chatgpt_importer.dart';
import 'package:canvas_chat/src/data/import/export_source.dart';
import 'package:canvas_chat/src/state/providers.dart';
import 'package:canvas_chat/src/ui/canvas/minimap.dart';
import 'package:canvas_chat/src/ui/canvas/node_card.dart';
import 'package:canvas_chat/src/ui/read_view.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/synthetic_export.dart';

/// Linear conversation with [turnCount] turns, `current_node` at the leaf —
/// tall enough that navigate mode must cull off-screen rows.
Map<String, dynamic> longConversation({int turnCount = 40}) {
  final nodes = <Map<String, dynamic>>[node('L-root')];
  var parent = 'L-root';
  for (var i = 0; i < turnCount; i++) {
    nodes.add(node('L-u$i',
        parent: parent,
        message: message('L-u$i',
            role: 'user',
            parts: ['question $i'],
            time: 1730000000.0 + 20 * i)));
    nodes.add(node('L-a$i',
        parent: 'L-u$i',
        message: message('L-a$i',
            role: 'assistant',
            parts: ['answer $i'],
            time: 1730000010.0 + 20 * i)));
    parent = 'L-a$i';
  }
  return conversation(
    id: 'conv-long',
    title: 'Long chat',
    createTime: 1730000000,
    updateTime: 1730099999,
    currentNode: 'L-a${turnCount - 1}',
    nodes: nodes,
  );
}

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

  /// Imports a synthetic export into [db].
  ///
  /// Must run inside [WidgetTester.runAsync]: the file I/O and importer are
  /// real async work, and awaiting it directly in testWidgets' FakeAsync zone
  /// deadlocks the test forever.
  Future<void> seed(
    WidgetTester tester, {
    List<Map<String, dynamic>>? conversations,
  }) async {
    await tester.runAsync(() async {
      final exportDir = Directory('${tempDir.path}/export');
      await writeSyntheticExport(exportDir, conversations: conversations);
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

  /// The single selected node card on the canvas.
  NodeCard selectedCard(WidgetTester tester) => tester
      .widgetList<NodeCard>(find.byType(NodeCard))
      .singleWhere((card) => card.selected);

  /// Taps [tooltip] inside the currently selected card, then waits out the
  /// canvas double-tap detector's tap delay.
  Future<void> tapSelectedCardButton(
      WidgetTester tester, String tooltip) async {
    await tester.tap(find.descendant(
      of: find.byWidget(selectedCard(tester)),
      matching: find.byTooltip(tooltip),
    ));
    // The canvas GestureDetector listens for double taps, which holds single
    // taps in the gesture arena for kDoubleTapTimeout.
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
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

  testWidgets('selecting a conversation opens the navigate canvas',
      (tester) async {
    await seed(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Forked chat'));
    await tester.pumpAndSettle();

    // Canvas opens centered at 1:1 on the current turn ("edited v2", lane 0).
    // The third lane ("edited v1") is off-screen — culled, not built.
    expect(find.byType(NodeCard), findsWidgets);
    expect(find.byType(Minimap), findsOneWidget);
    expect(find.textContaining('regenerate me'), findsOneWidget);
    expect(find.textContaining('edited v2'), findsOneWidget);
    expect(find.textContaining('edited v1'), findsNothing);

    // The selection starts on the conversation's current turn.
    expect(selectedCard(tester).cell.turn.id, 'conv-forked:f-u3b');

    // `f` fits the whole graph: all 6 turns visible (2 turns from the
    // regeneration fork have no prompt).
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.pumpAndSettle();
    expect(find.byType(NodeCard), findsNWidgets(6));
    expect(find.textContaining('edited v1'), findsOneWidget);
    expect(find.textContaining('follow up'), findsOneWidget);
    expect(find.text('(no prompt)'), findsNWidgets(2));

    // Fork parents carry the ⑂ badge: "regenerate me" (2 responses) and the
    // regenerated answer (2 edited prompts).
    expect(find.textContaining('⑂ 2'), findsNWidgets(2));

    await unmountApp(tester);
  });

  testWidgets('arrow keys and quick buttons move the selection',
      (tester) async {
    await seed(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Forked chat'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.pumpAndSettle();

    // Start: current turn (edited v2) at row 2, lane 0.
    expect(selectedCard(tester).cell.turn.id, 'conv-forked:f-u3b');

    // ↑ to its parent (the regenerated "second answer" turn).
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(selectedCard(tester).cell.turn.responseMd, 'second answer');

    // → to the sibling branch ("first answer" turn, lane 1, same row).
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(selectedCard(tester).cell.turn.responseMd, 'first answer');

    // ↓ continues down that branch.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(selectedCard(tester).cell.turn.promptMd, 'follow up');

    // ← back to the active lane: nearest cell in lane 0 to row 2.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(selectedCard(tester).cell.turn.id, 'conv-forked:f-u3b');

    // Quick buttons mirror the arrows: ↑ ↑ from the leaf reaches the prompt
    // turn; its ↑/← are disabled (no parent, lane 0).
    await tapSelectedCardButton(tester, 'Go up');
    expect(selectedCard(tester).cell.turn.responseMd, 'second answer');
    await tapSelectedCardButton(tester, 'Go up');
    expect(selectedCard(tester).cell.turn.id, 'conv-forked:f-u1');

    final upButton = tester.widget<IconButton>(find.descendant(
      of: find.byWidget(selectedCard(tester)),
      matching: find.widgetWithIcon(IconButton, Icons.arrow_upward),
    ));
    expect(upButton.onPressed, isNull);
    final leftButton = tester.widget<IconButton>(find.descendant(
      of: find.byWidget(selectedCard(tester)),
      matching: find.widgetWithIcon(IconButton, Icons.arrow_back),
    ));
    expect(leftButton.onPressed, isNull);
    // Maximize is enabled (enters read mode); minimize stays a disabled
    // no-op in navigate mode.
    final maximize = tester.widget<IconButton>(find.descendant(
      of: find.byWidget(selectedCard(tester)),
      matching: find.widgetWithIcon(IconButton, Icons.open_in_full),
    ));
    expect(maximize.onPressed, isNotNull);
    final minimize = tester.widget<IconButton>(find.descendant(
      of: find.byWidget(selectedCard(tester)),
      matching: find.widgetWithIcon(IconButton, Icons.close_fullscreen),
    ));
    expect(minimize.onPressed, isNull);

    await unmountApp(tester);
  });

  testWidgets('tall conversations are viewport-culled; minimap taps jump',
      (tester) async {
    await seed(tester, conversations: [longConversation()]);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Long chat'));
    await tester.pumpAndSettle();

    // Opened at 1:1 centered on the last turn: only a handful of the 40
    // rows get widgets.
    final builtCards = tester.widgetList(find.byType(NodeCard)).length;
    expect(builtCards, greaterThan(0));
    expect(builtCards, lessThan(15));
    expect(find.textContaining('question 39'), findsOneWidget);
    expect(find.textContaining('question 0'), findsNothing);

    // Tapping near the top of the minimap jumps the viewport to the top.
    final minimapRect = tester.getRect(find.byType(Minimap));
    await tester.tapAt(minimapRect.topLeft + const Offset(4, 4));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.textContaining('question 0'), findsOneWidget);
    expect(find.textContaining('question 39'), findsNothing);

    await unmountApp(tester);
  });

  group('read mode (M4)', () {
    Finder inOverlay(Finder matching) =>
        find.descendant(of: find.byType(ReadOverlay), matching: matching);

    /// This conversation's persisted `canvas_state` row, if any.
    Future<CanvasState?> readState(WidgetTester tester, String id) async {
      // Flush the canvas's fire-and-forget upsert before reading it back.
      await tester.pump();
      return await tester.runAsync<CanvasState?>(() => (db.select(db.canvasStates)
            ..where((s) => s.conversationId.equals(id)))
          .getSingleOrNull());
    }

    /// Opens the forked fixture's canvas (selection starts on "edited v2").
    Future<void> openForkedChat(WidgetTester tester) async {
      await seed(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forked chat'));
      await tester.pumpAndSettle();
    }

    testWidgets('maximize opens a centered overlay and persists read mode',
        (tester) async {
      // Widget tests default to TargetPlatform.android; this test exercises
      // the desktop presentation. Reset inline: the binding's end-of-test
      // invariants run before tearDown callbacks.
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        await openForkedChat(tester);

        await tapSelectedCardButton(tester, 'Maximize (read mode)');

        // Desktop presentation: centered ~85% overlay (800×600 → 680×510)
        // over the still-mounted canvas.
        expect(find.byType(ReadOverlay), findsOneWidget);
        expect(tester.getSize(find.byType(ReadOverlay)), const Size(680, 510));
        expect(find.byType(NodeCard), findsWidgets);
        expect(
          inOverlay(find.textContaining('edited v2', findRichText: true)),
          findsOneWidget,
        );
        expect(inOverlay(find.text('(no response)')), findsOneWidget);
        expect(inOverlay(find.text('⑂ Branch 1 of 3')), findsOneWidget);

        var state = await readState(tester, 'conv-forked');
        expect(state?.mode, 'read');
        expect(state?.focusedTurnId, 'conv-forked:f-u3b');

        // Esc exits back to navigate mode.
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byType(ReadOverlay), findsNothing);
        state = await readState(tester, 'conv-forked');
        expect(state?.mode, 'navigate');

        await unmountApp(tester);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('tap opens read mode; arrows traverse; minimize recenters',
        (tester) async {
      await openForkedChat(tester);

      // Tapping the card body (not a quick button) enters read mode.
      await tester.tap(find.textContaining('edited v2'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.byType(ReadOverlay), findsOneWidget);
      expect(inOverlay(find.text('⑂ Branch 1 of 3')), findsOneWidget);

      // ↑ walks to the parent turn (the regenerated response).
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(
        inOverlay(find.textContaining('second answer', findRichText: true)),
        findsOneWidget,
      );
      expect(inOverlay(find.text('⑂ Branch 1 of 2')), findsOneWidget);

      // → jumps across branches at the same depth.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(
        inOverlay(find.textContaining('first answer', findRichText: true)),
        findsOneWidget,
      );
      expect(inOverlay(find.text('⑂ Branch 2 of 2')), findsOneWidget);

      // ↓ continues down that branch; the quick button mirrors ↑.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(
        inOverlay(find.textContaining('follow up', findRichText: true)),
        findsOneWidget,
      );
      await tester.tap(inOverlay(find.byTooltip('Go up')));
      await tester.pumpAndSettle();
      expect(
        inOverlay(find.textContaining('first answer', findRichText: true)),
        findsOneWidget,
      );

      // Minimize returns to navigate mode centered on the node just read.
      await tester.tap(inOverlay(find.byTooltip('Minimize')));
      await tester.pumpAndSettle();
      expect(find.byType(ReadOverlay), findsNothing);
      expect(selectedCard(tester).cell.turn.responseMd, 'first answer');
      final cardCenter = tester
          .getCenter(find.byKey(const ValueKey('node-conv-forked:f-a1')));
      // Canvas pane spans x ∈ [321, 800], y ∈ [0, 600] → center (560.5, 300).
      expect(cardCenter.dx, closeTo(560.5, 1));
      expect(cardCenter.dy, closeTo(300, 1));

      final state = await readState(tester, 'conv-forked');
      expect(state?.mode, 'navigate');
      expect(state?.focusedTurnId, 'conv-forked:f-a1');

      await unmountApp(tester);
    });

    testWidgets('read mode is a full-screen route on Android',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await openForkedChat(tester);

        await tapSelectedCardButton(tester, 'Maximize (read mode)');
        expect(find.byType(ReadOverlay), findsOneWidget);
        expect(tester.getSize(find.byType(ReadOverlay)), const Size(800, 600));

        // Back (pop) returns to the canvas.
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byType(ReadOverlay), findsNothing);

        await unmountApp(tester);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('focus and viewport persist per conversation and restore',
        (tester) async {
      await openForkedChat(tester);

      // Fit the whole graph and move the selection to the root prompt.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(selectedCard(tester).cell.turn.id, 'conv-forked:f-u1');
      // Let the debounced viewport write flush.
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.text('Linear chat'));
      await tester.pumpAndSettle();
      expect(find.textContaining('quantum entanglement'), findsOneWidget);

      await tester.tap(find.text('Forked chat'));
      await tester.pumpAndSettle();
      // Selection and the fitted viewport are restored: all 6 cells visible
      // (the default open would be 1:1 on the current turn, culling lanes).
      expect(selectedCard(tester).cell.turn.id, 'conv-forked:f-u1');
      expect(find.byType(NodeCard), findsNWidgets(6));
      expect(find.textContaining('edited v1'), findsOneWidget);

      await unmountApp(tester);
    });

    testWidgets('read mode resumes after an app restart', (tester) async {
      await openForkedChat(tester);
      await tapSelectedCardButton(tester, 'Maximize (read mode)');
      expect(find.byType(ReadOverlay), findsOneWidget);

      // "Quit" with read mode open; relaunch on the same database.
      await unmountApp(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forked chat'));
      await tester.pumpAndSettle();

      // The conversation reopens in read mode on the focused turn.
      expect(find.byType(ReadOverlay), findsOneWidget);
      expect(
        inOverlay(find.textContaining('edited v2', findRichText: true)),
        findsOneWidget,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(ReadOverlay), findsNothing);

      await unmountApp(tester);
    });
  });
}
