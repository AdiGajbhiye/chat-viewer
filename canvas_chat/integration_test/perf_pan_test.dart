// Profile-mode animation performance trace for the canvas over a large,
// heavily-forked conversation. Exercises the two paths the user reports as
// janky: an interactive pan (drag) and the arrow-key navigation glide — both
// funnel through `_viewport.notifyListeners() -> ListenableBuilder ->
// _buildCanvas`, rebuilding every visible NodeCard + the EdgePainter each frame.
//
// MUST run in --profile (debug-mode frame times are meaningless):
//   flutter drive --profile \
//     --driver=test_driver/perf_driver.dart \
//     --target=integration_test/perf_pan_test.dart -d macos
//
// Produces build/perf/canvas_pan.* and build/perf/canvas_nav.*.

import 'dart:io';

import 'package:canvas_chat/main.dart';
import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/data/import/chatgpt_importer.dart';
import 'package:canvas_chat/src/data/import/export_source.dart';
import 'package:canvas_chat/src/state/providers.dart';
import 'package:canvas_chat/src/ui/canvas/canvas_view.dart';
import 'package:canvas_chat/src/ui/canvas/node_card.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/synthetic_export.dart';

/// A large, heavily-forked conversation: [mainTurns] paired turns on the active
/// path, plus a 3-deep, 2-wide fork every [forkEvery] turns. With the defaults
/// that is ~440 paired turns spread across many lanes — the "large number of
/// nodes" case.
Map<String, dynamic> bigConversation({int mainTurns = 200, int forkEvery = 5}) {
  final nodes = <Map<String, dynamic>>[node('b-root')];
  var counter = 0;
  var time = 1700000000.0;

  // Appends one user->assistant pair under [parent]; returns the assistant id
  // (the next link in the chain).
  String pair(String parent) {
    final tag = counter++;
    final u = 'b-u$tag';
    final a = 'b-a$tag';
    nodes.add(node(u,
        parent: parent,
        message: message(u,
            role: 'user',
            parts: [
              'Question $tag about subject ${tag % 23}: please explain the '
                  'trade-offs in some detail so the card body has realistic '
                  'multi-line text to lay out, collapse and ellipsize.'
            ],
            time: time++)));
    nodes.add(node(a,
        parent: u,
        message: message(a,
            role: 'assistant',
            parts: ['Detailed answer number $tag.'],
            time: time++,
            modelSlug: 'gpt-4o')));
    return a;
  }

  var spine = 'b-root';
  for (var i = 0; i < mainTurns; i++) {
    spine = pair(spine);
    if (i % forkEvery == forkEvery - 1) {
      for (var b = 0; b < 2; b++) {
        var branch = spine;
        for (var d = 0; d < 3; d++) {
          branch = pair(branch);
        }
      }
    }
  }

  return conversation(
    id: 'conv-big',
    title: 'BIG perf chat',
    createTime: 1700000000,
    updateTime: time,
    currentNode: spine,
    defaultModelSlug: 'gpt-4o',
    nodes: nodes,
  );
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Render a real frame per pump so the gesture/glide loops below produce
  // measurable frames instead of being coalesced.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive;

  late Directory tempDir;
  late Directory assetsDir;
  late AppDatabase db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('canvas_perf');
    assetsDir = Directory('${tempDir.path}/assets')..createSync();
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('pan + nav-glide over a large forked graph', (tester) async {
    await tester.runAsync(() async {
      final exportDir = Directory('${tempDir.path}/export');
      await writeSyntheticExport(exportDir, conversations: [bigConversation()]);
      await ChatGptImporter(
        db: db,
        source: DirectoryExportSource(exportDir),
        assetsDir: assetsDir,
      ).run();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          assetsDirProvider.overrideWithValue(assetsDir),
        ],
        child: const CanvasChatApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Open the big conversation.
    await tester.tap(find.text('BIG perf chat'));
    await tester.pumpAndSettle();
    expect(find.byType(CanvasView), findsOneWidget);

    // Fit the whole map so many nodes are on screen at once (the canvas
    // autofocuses, so `f` reaches its fit shortcut). `physicalKey` is passed
    // explicitly because the real-engine key simulator can't infer it and
    // null-checks on the lookup otherwise.
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF,
        physicalKey: PhysicalKeyboardKey.keyF);
    await tester.pumpAndSettle();

    // Confirm we actually reproduced the "many nodes visible" condition; if this
    // fails the fit didn't happen (focus) and the trace would be unrepresentative.
    expect(find.byType(NodeCard), findsAtLeastNWidgets(25));

    final center = tester.getCenter(find.byType(CanvasView));

    // ---- Scenario 1: sustained interactive pan (drag) across the map. ----
    await binding.traceAction(() async {
      final gesture = await tester.startGesture(center);
      for (var i = 0; i < 90; i++) {
        await gesture.moveBy(const Offset(-7, -4));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 16));
    }, reportKey: 'canvas_pan');

    // ---- Scenario 2: the 260ms arrow-key navigation glide, repeated. ----
    // Selection starts at the active-path tip (bottom); arrowUp glides toward
    // the root, one valid step at a time.
    await binding.traceAction(() async {
      for (var i = 0; i < 12; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp,
            physicalKey: PhysicalKeyboardKey.arrowUp);
        for (var f = 0; f < 18; f++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
      }
    }, reportKey: 'canvas_nav');
  });
}
