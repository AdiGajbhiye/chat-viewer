import 'dart:io';

import 'package:canvas_chat/main.dart';
import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/data/import/chatgpt_importer.dart';
import 'package:canvas_chat/src/data/import/export_source.dart';
import 'package:canvas_chat/src/state/providers.dart';
import 'package:canvas_chat/src/ui/canvas/canvas_view.dart';
import 'package:canvas_chat/src/ui/canvas/node_card.dart';
import 'package:canvas_chat/src/ui/canvas/soft_edge_painter.dart';
import 'package:canvas_chat/src/ui/read_view.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

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

  /// Enters read mode on the current selection via the bottom-right view
  /// toggle. (The toggle sits outside the canvas gesture detector, so unlike a
  /// card tap it needs no double-tap-timeout wait.)
  Future<void> enterReadMode(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Read view'));
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
    // Far-off cards are culled (see the tall-conversation test below); the
    // node layer now pre-builds a viewport-sized margin of off-screen cards so
    // panning is a re-composite, not a rebuild — so this case no longer asserts
    // that immediate off-screen neighbours are absent.
    expect(find.byType(NodeCard), findsWidgets);
    expect(find.textContaining('edited v2'), findsOneWidget);

    // The selection starts on the conversation's current turn.
    expect(selectedCard(tester).cell.turn.id, 'conv-forked:f-u3b');

    // `f` fits the whole graph: all 5 folded turns visible. The regen prompt
    // is duplicated into both branches; no prompt-only/response-only cells.
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.pumpAndSettle();
    expect(find.byType(NodeCard), findsNWidgets(5));
    expect(find.textContaining('regenerate me'), findsNWidgets(2));
    expect(find.textContaining('edited v1'), findsOneWidget);
    expect(find.textContaining('follow up'), findsOneWidget);
    expect(find.text('(no prompt)'), findsNothing);

    // The edited-prompt fork parent ("second answer") still carries a fork
    // badge; the regen fork is now shown by the sibling edge, not a badge.
    expect(find.byIcon(Icons.alt_route), findsNWidgets(1));

    await unmountApp(tester);
  });

  testWidgets('arrow keys move the selection; cards carry no buttons',
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

    // The navigate card carries no buttons at all: the map moves via arrow
    // keys / tapping cells, and entering read mode is a card tap or the
    // bottom-right toggle, so the per-card maximize button was dropped.
    final card = find.byWidget(selectedCard(tester));
    expect(
      find.descendant(of: card, matching: find.byType(IconButton)),
      findsNothing,
    );

    await unmountApp(tester);
  });

  testWidgets('arrow navigation glides the selected node to the centre',
      (tester) async {
    await seed(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Forked chat'));
    await tester.pumpAndSettle();

    // The viewport centre is the centre of the canvas pane.
    final paneCentre = tester.getRect(find.byType(CanvasView)).center;

    // ↑ to the parent, which opens off the top of the view.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump(); // apply the selection and start the glide
    await tester.pump(const Duration(milliseconds: 30));

    // Mid-glide: the node is on its way but has not arrived — a snap would have
    // it centred already. (This is the "node is moving" transition.)
    final mid = tester.getRect(find.byWidget(selectedCard(tester))).center;
    expect((mid - paneCentre).distance, greaterThan(8));

    // Settled: the node has glided to the centre (not merely scrolled just
    // into view, which is what the old ensureVisible pan did).
    await tester.pumpAndSettle();
    final settled = tester.getRect(find.byWidget(selectedCard(tester))).center;
    expect(settled, offsetMoreOrLessEquals(paneCentre, epsilon: 1.0));

    await unmountApp(tester);
  });

  testWidgets('tall conversations are viewport-culled', (tester) async {
    await seed(tester, conversations: [longConversation()]);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Long chat'));
    await tester.pumpAndSettle();

    // Opened at 1:1 centered on the last turn: only a handful of the 40
    // rows get widgets, and the first turn is far off-screen.
    final culled = tester.widgetList(find.byType(NodeCard)).length;
    expect(culled, greaterThan(0));
    expect(culled, lessThan(15));
    expect(find.textContaining('question 39'), findsOneWidget);
    expect(find.textContaining('question 0'), findsNothing);

    // `f` (fit) zooms out, relaxing the cull so many more cards get built.
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.pumpAndSettle();
    final fitted = tester.widgetList(find.byType(NodeCard)).length;
    expect(fitted, greaterThan(culled));

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

    testWidgets('maximize fills the canvas pane and persists read mode',
        (tester) async {
      // Widget tests default to TargetPlatform.android; this test exercises
      // the desktop presentation. Reset inline: the binding's end-of-test
      // invariants run before tearDown callbacks.
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        await openForkedChat(tester);

        await enterReadMode(tester);

        // The reader floats as a card inset by an 18px margin inside the canvas
        // pane (sidebar 320 + divider 1 → 479×600), so it measures
        // (479-36)×(600-36), and the graph stays visible behind it (node cards
        // still in the tree).
        expect(find.byType(ReadOverlay), findsOneWidget);
        expect(tester.getSize(find.byType(ReadOverlay)), const Size(443, 564));
        expect(find.byType(NodeCard), findsWidgets);
        expect(
          inOverlay(find.textContaining('edited v2', findRichText: true)),
          findsOneWidget,
        );
        expect(inOverlay(find.text('(no response)')), findsOneWidget);
        expect(inOverlay(find.text('Branch 1 of 3')), findsOneWidget);

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

    testWidgets('read-mode markdown carries an explicit onSurface color',
        (tester) async {
      // GptMarkdown body text does not inherit the ambient DefaultTextStyle's
      // color, so in dark mode it renders near-black and vanishes on the dark
      // read surface unless we pass an explicit style. Guard that we do.
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await openForkedChat(tester);
      await enterReadMode(tester);

      final onSurface = Theme.of(tester.element(find.byType(ReadOverlay)))
          .colorScheme
          .onSurface;
      final markdowns = tester.widgetList<GptMarkdown>(
        inOverlay(find.byType(GptMarkdown)),
      );
      expect(markdowns, isNotEmpty);
      for (final md in markdowns) {
        expect(md.style?.color, onSurface);
      }

      await unmountApp(tester);
    });

    testWidgets('tap opens read mode; arrows traverse; minimize recenters',
        (tester) async {
      await openForkedChat(tester);

      // Tapping a node card enters read mode for that turn.
      await tester.tap(find.textContaining('edited v2'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.byType(ReadOverlay), findsOneWidget);
      expect(inOverlay(find.text('Branch 1 of 3')), findsOneWidget);

      // ↑ walks to the parent turn (the regenerated response).
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(
        inOverlay(find.textContaining('second answer', findRichText: true)),
        findsOneWidget,
      );
      expect(inOverlay(find.text('Branch 1 of 2')), findsOneWidget);

      // → jumps across branches at the same depth.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(
        inOverlay(find.textContaining('first answer', findRichText: true)),
        findsOneWidget,
      );
      expect(inOverlay(find.text('Branch 2 of 2')), findsOneWidget);

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

      // The bottom-right toggle returns to the graph centered on the node just
      // read (the in-header minimize button was removed).
      await tester.tap(find.byTooltip('Graph view'));
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

    testWidgets('a mouse click that drifts a few px still maximizes',
        (tester) async {
      await openForkedChat(tester);

      // A real desktop click rarely lands pixel-perfect. With a mouse the
      // canvas pan slop is only kPrecisePointerPanSlop (2px), so a click that
      // drifts a few pixels used to read as a pan and the card's maximize tap
      // was swallowed — the node never opened. The drift here (≈5.7px) is past
      // that 2px but well under kTouchSlop (18), so it must still be a tap.
      final gesture = await tester.startGesture(
        tester.getCenter(find.textContaining('edited v2')),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(4, 4));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.byType(ReadOverlay), findsOneWidget);

      await unmountApp(tester);
    });

    testWidgets('a deliberate mouse drag pans the canvas instead of maximizing',
        (tester) async {
      await openForkedChat(tester);

      // The other side of the slop from the drift test above: a drag past
      // kTouchSlop (18px) must win the gesture arena as a canvas pan, so the
      // card never maximizes and the whole graph slides under the pointer.
      // Guards the pan/zoom hot path against a gesture-recognizer regression.
      const card = ValueKey('node-conv-forked:f-u3b');
      final before = tester.getCenter(find.byKey(card));
      final gesture =
          await tester.startGesture(before, kind: PointerDeviceKind.mouse);
      await gesture.moveBy(const Offset(30, 20));
      await gesture.moveBy(const Offset(30, 20)); // 60×40 total — well past slop
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.byType(ReadOverlay), findsNothing);
      final after = tester.getCenter(find.byKey(card));
      expect(after.dx - before.dx, greaterThan(18));
      expect(after.dy - before.dy, greaterThan(10));

      await unmountApp(tester);
    });

    testWidgets('focus and viewport persist per conversation and restore',
        (tester) async {
      await openForkedChat(tester);

      // Fit the whole graph and move the selection up to the root turn (the
      // folded regen branch on the active path; a second ↑ has no parent).
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(selectedCard(tester).cell.turn.id, 'conv-forked:f-a2');
      // Let the debounced viewport write flush.
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.text('Linear chat'));
      await tester.pumpAndSettle();
      expect(find.textContaining('quantum entanglement'), findsOneWidget);

      await tester.tap(find.text('Forked chat'));
      await tester.pumpAndSettle();
      // Selection and the fitted viewport are restored: all 5 cells visible
      // (the default open would be 1:1 on the current turn, culling lanes).
      expect(selectedCard(tester).cell.turn.id, 'conv-forked:f-a2');
      expect(find.byType(NodeCard), findsNWidgets(5));
      expect(find.textContaining('edited v1'), findsOneWidget);

      await unmountApp(tester);
    });

    testWidgets('swipe up/down advances the reading focus', (tester) async {
      // The reader pages on a vertical overscroll past the transcript edge.
      await openForkedChat(tester);
      await enterReadMode(tester);
      expect(find.byType(ReadOverlay), findsOneWidget);
      expect(
        inOverlay(find.textContaining('edited v2', findRichText: true)),
        findsOneWidget,
      );
      final body = inOverlay(find.byType(ListView));

      // Swipe down past the top edge → previous turn.
      await tester.drag(body, const Offset(0, 250));
      await tester.pumpAndSettle();
      expect(
        inOverlay(find.textContaining('second answer', findRichText: true)),
        findsOneWidget,
      );

      // Swipe up past the bottom edge → next turn.
      await tester.drag(body, const Offset(0, -250));
      await tester.pumpAndSettle();
      expect(
        inOverlay(find.textContaining('edited v2', findRichText: true)),
        findsOneWidget,
      );

      // A drag below the threshold stays put.
      await tester.drag(body, const Offset(0, 40));
      await tester.pumpAndSettle();
      expect(
        inOverlay(find.textContaining('edited v2', findRichText: true)),
        findsOneWidget,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await unmountApp(tester);
    });

    testWidgets('horizontal swipe pages across sibling branches',
        (tester) async {
      await openForkedChat(tester);
      await enterReadMode(tester);
      expect(
        inOverlay(find.textContaining('edited v2', findRichText: true)),
        findsOneWidget,
      );

      // Swipe left → the next branch at this depth (lane 1 on this row).
      await tester.fling(
        find.byType(ReadOverlay),
        const Offset(-400, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(
        inOverlay(find.textContaining('follow up', findRichText: true)),
        findsOneWidget,
      );
      expect(inOverlay(find.text('Branch 2 of 3')), findsOneWidget);

      // Swipe right → back to the original branch.
      await tester.fling(find.byType(ReadOverlay), const Offset(400, 0), 1000);
      await tester.pumpAndSettle();
      expect(
        inOverlay(find.textContaining('edited v2', findRichText: true)),
        findsOneWidget,
      );
      expect(inOverlay(find.text('Branch 1 of 3')), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await unmountApp(tester);
    });

    testWidgets('selecting a conversation always opens navigate mode, '
        'even when it was last left in read mode', (tester) async {
      await openForkedChat(tester);
      await enterReadMode(tester);
      expect(find.byType(ReadOverlay), findsOneWidget);

      // "Quit" with read mode open (so canvas_state persists mode='read'),
      // then relaunch on the same database and reopen the conversation.
      await unmountApp(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forked chat'));
      await tester.pumpAndSettle();

      // It opens on the canvas, not the reader: read mode is never
      // auto-restored, so a sidebar click never jumps straight into reading.
      expect(find.byType(ReadOverlay), findsNothing);
      expect(find.byType(NodeCard), findsWidgets);

      await unmountApp(tester);
    });
  });

  group('polish (M5)', () {
    Finder inOverlay(Finder matching) =>
        find.descendant(of: find.byType(ReadOverlay), matching: matching);

    testWidgets('sidebar search filters conversations via FTS',
        (tester) async {
      await seed(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('Forked chat'), findsOneWidget);

      // Content match (prefix): only the linear chat mentions entanglement.
      await tester.enterText(find.byType(TextField), 'entangle');
      await tester.pumpAndSettle();
      expect(find.text('Linear chat'), findsOneWidget);
      expect(find.text('Forked chat'), findsNothing);
      expect(find.text('Assistant first'), findsNothing);

      // No matches.
      await tester.enterText(find.byType(TextField), 'xyzzy_not_there');
      await tester.pumpAndSettle();
      expect(find.text('No matching conversations.'), findsOneWidget);

      // Clearing restores the full list.
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('Forked chat'), findsOneWidget);
      expect(find.text('Linear chat'), findsOneWidget);
      expect(find.text('Assistant first'), findsOneWidget);

      await unmountApp(tester);
    });

    testWidgets('canvas search highlights matching turns and steps through them',
        (tester) async {
      await seed(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Forked chat'));
      await tester.pumpAndSettle();
      // Fit so every folded turn is built — search highlights all matches.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.pumpAndSettle();

      // The canvas's own field, distinct from the sidebar's.
      final canvasSearch = find.byWidgetPredicate((w) =>
          w is TextField && w.decoration?.hintText == 'Find in conversation');
      expect(canvasSearch, findsOneWidget);

      // "answer" (prefix) hits only the two regenerated responses.
      await tester.enterText(canvasSearch, 'answer');
      await tester.pumpAndSettle();
      final matched = tester
          .widgetList<NodeCard>(find.byType(NodeCard))
          .where((c) => c.matched)
          .map((c) => c.cell.turn.responseMd)
          .toList();
      expect(matched, unorderedEquals(['first answer', 'second answer']));

      // ↓ steps onto the first match and selects it; the counter advances.
      expect(selectedCard(tester).matched, isFalse);
      await tester.tap(find.byTooltip('Next match'));
      await tester.pumpAndSettle();
      expect(find.text('1/2'), findsOneWidget);
      expect(selectedCard(tester).matched, isTrue);
      expect(['first answer', 'second answer'],
          contains(selectedCard(tester).cell.turn.responseMd));

      // A query with no hits reports it and highlights nothing.
      await tester.enterText(canvasSearch, 'zzznope');
      await tester.pumpAndSettle();
      expect(find.text('No results'), findsOneWidget);
      expect(
        tester
            .widgetList<NodeCard>(find.byType(NodeCard))
            .where((c) => c.matched),
        isEmpty,
      );

      // Clearing the field removes the counter entirely.
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('No results'), findsNothing);

      await unmountApp(tester);
    });

    testWidgets('read mode renders image assets and missing placeholders',
        (tester) async {
      await seed(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Linear chat'));
      await tester.pumpAndSettle();
      // Fit the whole (short) chat so the multimodal card's wrapped prompt is
      // fully on-screen and its tap target isn't pushed past the window edge.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.pumpAndSettle();

      // Open read mode on the multimodal turn (present + missing pointer).
      await tester.tap(find.textContaining('look at these'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.byType(ReadOverlay), findsOneWidget);

      final image = tester.widget<Image>(inOverlay(find.byType(Image)));
      expect(
        (image.image as FileImage).file.path,
        endsWith('file_present.png'),
      );
      expect(
        inOverlay(find.text('Image not included in the export')),
        findsOneWidget,
      );
      // The raw markers (and M2's textual placeholder) are gone from the
      // transcript. (The collapsed card behind the overlay still shows the
      // prompt's raw text — only the overlay renders assets.)
      expect(
        inOverlay(find.textContaining('asset://', findRichText: true)),
        findsNothing,
      );
      expect(
        inOverlay(find.textContaining('[image attachment]', findRichText: true)),
        findsNothing,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await unmountApp(tester);
    });

    testWidgets('non-image assets render an attachment tile, not an image',
        (tester) async {
      // Defensive path: the real export never pointer-references its PDF/txt
      // attachments (they are not copied), but a non-image row must not be
      // fed to the image decoder.
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AssetBlock(
            asset: TurnAsset(
              turnId: 'conv-x:t1',
              kind: 'prompt',
              path: '/nowhere/file_doc.pdf',
              originalName: 'notes.pdf',
            ),
          ),
        ),
      ));
      expect(find.textContaining('notes.pdf'), findsOneWidget);
      expect(find.textContaining('Preview not available'), findsOneWidget);
      expect(find.byType(Image), findsNothing);

      await unmountApp(tester);
    });

    testWidgets('macOS gets a native menu bar and ⌘F focuses search',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        await seed(tester);
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();

        final menuBar =
            tester.widget<PlatformMenuBar>(find.byType(PlatformMenuBar));
        final labels = [
          for (final menu in menuBar.menus) (menu as PlatformMenu).label,
        ];
        expect(labels, ['Canvas Chat', 'File', 'Edit']);
        final fileItems = (menuBar.menus[1] as PlatformMenu)
            .menus
            .expand((item) => item is PlatformMenuItemGroup
                ? item.members
                : <PlatformMenuItem>[item])
            .map((item) => item.label)
            .toList();
        expect(
          fileItems,
          ['Import Export Zip…', 'Import Extracted Folder…',
              'Import Warnings…'],
        );

        // ⌘F focuses the sidebar search field even while the canvas has
        // keyboard focus.
        await tester.tap(find.text('Forked chat'));
        await tester.pumpAndSettle();
        await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
        await tester.pump();
        // The canvas also has its own "find in conversation" field, so target
        // the sidebar search field specifically by its hint.
        final sidebarField = find.byWidgetPredicate((w) =>
            w is TextField && w.decoration?.hintText == 'Search conversations');
        final editable = tester.widget<EditableText>(
          find.descendant(of: sidebarField, matching: find.byType(EditableText)),
        );
        expect(editable.focusNode.hasFocus, isTrue);

        await unmountApp(tester);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('import warnings dialog lists the last run\'s warnings',
        (tester) async {
      // The synthetic export yields two import warnings: an unsupported
      // content_type and the missing file_gone.dat asset.
      await seed(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      // No native menu bar outside macOS.
      expect(find.byType(PlatformMenuBar), findsNothing);

      await tester.tap(find.byTooltip('Import ChatGPT export'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last import warnings…'));
      await tester.pumpAndSettle();

      expect(find.text('Import warnings (2)'), findsOneWidget);
      expect(find.textContaining('file_gone.dat'), findsOneWidget);
      expect(find.textContaining('mystery_widget'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await unmountApp(tester);
    });
  });

  group('soft edges (M8.3)', () {
    /// The soft-edge layer's painter, if the layer is in the tree.
    Finder softEdgeLayer() => find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is SoftEdgePainter);

    /// Seeds two intra-conversation soft edges into the forked fixture (a
    /// semantic + an entity link between real, distant turns). Must run in
    /// [WidgetTester.runAsync] — it's real DB I/O.
    Future<void> seedSoftEdges(WidgetTester tester) async {
      await tester.runAsync(() async {
        await db.batch((b) => b.insertAll(db.softEdges, [
              SoftEdgesCompanion.insert(
                fromTurnId: 'conv-forked:f-a1',
                toTurnId: 'conv-forked:f-a2',
                kind: 'semantic',
                weight: 0.8,
                projectId: 'default',
              ),
              SoftEdgesCompanion.insert(
                fromTurnId: 'conv-forked:f-a1',
                toTurnId: 'conv-forked:f-u3b',
                kind: 'entity',
                weight: 0.4,
                projectId: 'default',
              ),
            ]));
      });
    }

    Future<void> openForkedChat(WidgetTester tester) async {
      await seed(tester);
      await seedSoftEdges(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forked chat'));
      await tester.pumpAndSettle();
      // Fit so every cell (hence every soft-edge endpoint) is built/in view.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.pumpAndSettle();
    }

    testWidgets('the soft-edge layer is off by default and toggles on/off',
        (tester) async {
      await openForkedChat(tester);

      // Default OFF: the toggle is present (graph mode) but the layer is not.
      expect(find.byType(SoftEdgesToggle), findsOneWidget);
      expect(softEdgeLayer(), findsNothing);

      // Flip on → the soft-edge painter layer appears.
      await tester.tap(find.byTooltip('Show related links'));
      await tester.pumpAndSettle();
      expect(softEdgeLayer(), findsOneWidget);

      // The painter carries exactly the two renderable intra-conversation edges.
      final paint = tester.widget<CustomPaint>(softEdgeLayer());
      final painter = paint.painter! as SoftEdgePainter;
      expect(painter.edges, hasLength(2));
      expect(
        painter.edges.map((e) => e.kind).toSet(),
        {'semantic', 'entity'},
      );

      // The structural cards/edges are unchanged — the layer is purely additive.
      expect(find.byType(NodeCard), findsNWidgets(5));

      // Flip off → the layer is removed again.
      await tester.tap(find.byTooltip('Hide related links'));
      await tester.pumpAndSettle();
      expect(softEdgeLayer(), findsNothing);

      await unmountApp(tester);
    });

    testWidgets('the soft-edge layer sits behind a RepaintBoundary (perf)',
        (tester) async {
      await openForkedChat(tester);
      await tester.tap(find.byTooltip('Show related links'));
      await tester.pumpAndSettle();

      // The perf-sensitive structure: the soft-edge CustomPaint is wrapped in a
      // RepaintBoundary, so a pan re-composites its cached layer instead of
      // repainting it every viewport tick (DESIGN.md §6 "Performance").
      expect(
        find.ancestor(
          of: softEdgeLayer(),
          matching: find.byType(RepaintBoundary),
        ),
        findsWidgets,
      );

      await unmountApp(tester);
    });

    testWidgets('the toggle is graph-only and absent in read mode',
        (tester) async {
      await openForkedChat(tester);
      expect(find.byType(SoftEdgesToggle), findsOneWidget);

      await enterReadMode(tester);
      // The associative overlay is a map control; it's hidden while reading.
      expect(find.byType(SoftEdgesToggle), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(SoftEdgesToggle), findsOneWidget);

      await unmountApp(tester);
    });
  });
}
