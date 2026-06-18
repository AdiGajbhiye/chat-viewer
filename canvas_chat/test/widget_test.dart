import 'dart:io';

import 'package:canvas_chat/main.dart';
import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/data/import/chatgpt_importer.dart';
import 'package:canvas_chat/src/data/import/export_source.dart';
import 'package:canvas_chat/src/state/providers.dart';
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
    // The root ("regenerate me", several rows up) and the third lane
    // ("edited v1") are both off-screen — culled, not built.
    expect(find.byType(NodeCard), findsWidgets);
    expect(find.textContaining('edited v2'), findsOneWidget);
    expect(find.textContaining('regenerate me'), findsNothing);
    expect(find.textContaining('edited v1'), findsNothing);

    // The selection starts on the conversation's current turn.
    expect(selectedCard(tester).cell.turn.id, 'conv-forked:f-u3b');

    // `f` fits the whole graph: all 6 turns visible (2 turns from the
    // regeneration fork have no prompt).
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.pumpAndSettle();
    expect(find.byType(NodeCard), findsNWidgets(6));
    expect(find.textContaining('regenerate me'), findsOneWidget);
    expect(find.textContaining('edited v1'), findsOneWidget);
    expect(find.textContaining('follow up'), findsOneWidget);
    expect(find.text('(no prompt)'), findsNWidgets(2));

    // Fork parents carry the ⑂ badge: "regenerate me" (2 responses) and the
    // regenerated answer (2 edited prompts).
    expect(find.textContaining('⑂ 2'), findsNWidgets(2));

    await unmountApp(tester);
  });

  testWidgets('arrow keys move the selection; cards show only a zoom button',
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

    // The navigate card carries a single quick button — the zoom/maximize
    // control that enters read mode. The per-card nav arrows were removed (the
    // map moves via arrow keys / tapping cells), so none are rendered.
    final card = find.byWidget(selectedCard(tester));
    expect(
      find.descendant(of: card, matching: find.byType(IconButton)),
      findsOneWidget,
    );
    final maximize = tester.widget<IconButton>(find.descendant(
      of: card,
      matching: find.widgetWithIcon(IconButton, Icons.open_in_full),
    ));
    expect(maximize.onPressed, isNotNull);
    for (final icon in [
      Icons.arrow_upward,
      Icons.arrow_downward,
      Icons.arrow_back,
      Icons.arrow_forward,
    ]) {
      expect(
        find.descendant(
            of: card, matching: find.widgetWithIcon(IconButton, icon)),
        findsNothing,
      );
    }

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

        await tapSelectedCardButton(tester, 'Maximize (read mode)');

        // Desktop presentation: the read surface fills the canvas pane
        // (sidebar 320 + divider 1 → x ∈ [321, 800], y ∈ [0, 600] = 479×600)
        // over the still-mounted canvas.
        expect(find.byType(ReadOverlay), findsOneWidget);
        expect(tester.getSize(find.byType(ReadOverlay)), const Size(479, 600));
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

    testWidgets('Android: swipe up/down advances the reading focus',
        (tester) async {
      // Widget tests default to TargetPlatform.android — the swipe gesture
      // is only active there.
      await openForkedChat(tester);
      await tapSelectedCardButton(tester, 'Maximize (read mode)');
      expect(find.byType(ReadOverlay), findsOneWidget);
      expect(
        inOverlay(find.textContaining('edited v2', findRichText: true)),
        findsOneWidget,
      );
      final body = inOverlay(find.byType(SingleChildScrollView));

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
        final editable =
            tester.widget<EditableText>(find.byType(EditableText));
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
}
