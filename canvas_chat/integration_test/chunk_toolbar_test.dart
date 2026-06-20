// Drives the read-mode chunk toolbar (Ask AI / Explain / Expand / Copy) and
// the "fork a horizontal branch" flow on the REAL macOS engine, writing
// screenshots to build/chunk_shots/ so the per-chunk highlight, the top-right
// toolbar, and the new branch can be eyeballed — the headless backend doesn't
// match real Impeller rendering.
//
// Run: flutter test -d macos integration_test/chunk_toolbar_test.dart

import 'dart:io';
import 'dart:ui' as ui;

import 'package:canvas_chat/main.dart';
import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/data/import/chatgpt_importer.dart';
import 'package:canvas_chat/src/data/import/export_source.dart';
import 'package:canvas_chat/src/state/providers.dart';
import 'package:canvas_chat/src/ui/read_view.dart';
import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/synthetic_export.dart';

class _FixedTheme extends ThemeModeNotifier {
  _FixedTheme(this.mode);
  final ThemeMode mode;
  @override
  ThemeMode build() => mode;
}

const _rich = 'Entanglement links two particles into a single shared state.\n\n'
    'Measuring one particle instantly constrains the other, no matter how far '
    'apart they are.\n\n'
    'Key points:\n\n'
    '- Correlations beat any classical bound.\n'
    '- No usable information travels faster than light.\n\n'
    'That is the whole idea, in a few pieces.';

/// Turn A (rich, multi-chunk response) already has a continuation turn B, so a
/// branch forked off A lands in a fresh lane to the right (a horizontal
/// branch) rather than continuing straight down.
Map<String, dynamic> chunkConversation() => conversation(
      id: 'conv-chunk',
      title: 'Chunk demo',
      createTime: 1710000000,
      updateTime: 1710009000,
      currentNode: 'k-a2',
      defaultModelSlug: 'gpt-4o',
      nodes: [
        node('k-root'),
        node('k-u1',
            parent: 'k-root',
            message: message('k-u1',
                role: 'user',
                parts: ['Explain entanglement.'],
                time: 1710000000)),
        node('k-a1',
            parent: 'k-u1',
            message: message('k-a1',
                role: 'assistant',
                parts: [_rich],
                time: 1710000001,
                modelSlug: 'gpt-4o')),
        node('k-u2',
            parent: 'k-a1',
            message: message('k-u2',
                role: 'user', parts: ['Thanks!'], time: 1710000002)),
        node('k-a2',
            parent: 'k-u2',
            message: message('k-a2',
                role: 'assistant',
                parts: ['You are welcome.'],
                time: 1710000003,
                modelSlug: 'gpt-4o')),
      ],
    );

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Directory assetsDir;
  late AppDatabase db;
  late Directory shotsDir;
  final boundaryKey = GlobalKey();

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('canvas_chunk');
    assetsDir = Directory('${tempDir.path}/assets')..createSync();
    db = AppDatabase(NativeDatabase.memory());
    shotsDir = Directory('${Directory.current.path}/build/chunk_shots')
      ..createSync(recursive: true);
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  Future<void> seed(WidgetTester tester) async {
    await tester.runAsync(() async {
      final exportDir = Directory('${tempDir.path}/export');
      await writeSyntheticExport(exportDir, conversations: [chunkConversation()]);
      await ChatGptImporter(
        db: db,
        source: DirectoryExportSource(exportDir),
        assetsDir: assetsDir,
      ).run();
    });
  }

  Widget appWith(ThemeMode mode) => RepaintBoundary(
        key: boundaryKey,
        child: ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            assetsDirProvider.overrideWithValue(assetsDir),
            themeModeProvider.overrideWith(() => _FixedTheme(mode)),
          ],
          child: const CanvasChatApp(),
        ),
      );

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      final boundary = boundaryKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      File('${shotsDir.path}/$name.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  Finder inReader(Finder matching) =>
      find.descendant(of: find.byType(ReadOverlay), matching: matching);

  testWidgets('chunk toolbar forks a horizontal branch with a stub answer',
      (tester) async {
    tester.view.physicalSize = const Size(1100, 820);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await seed(tester);
    await tester.pumpWidget(appWith(ThemeMode.dark));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chunk demo'));
    await tester.pumpAndSettle();

    // Open the reader (on the active leaf, turn B) and page up to the rich
    // turn A so the multi-chunk response is on screen.
    await tester.tap(find.byTooltip('Read view'));
    await tester.pumpAndSettle();
    await tester.tap(inReader(find.byTooltip('Go up')));
    await tester.pumpAndSettle();
    expect(
      inReader(find.textContaining('Entanglement links', findRichText: true)),
      findsWidgets,
    );
    await shot(tester, '01_chunks');

    // Hover the first chunk → its top-right toolbar fades in.
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(
      inReader(find.textContaining('Entanglement links', findRichText: true))
          .first,
    ));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Ask AI about this (new branch)'), findsWidgets);
    await shot(tester, '02_toolbar');

    // Explain → fork a child branch off A; the reader glides onto it and the
    // stub provider fills the response.
    await tester.tap(find.byTooltip('Explain this passage').first);
    await tester.pumpAndSettle();
    for (var i = 0;
        i < 15 &&
            inReader(find.textContaining('Offline stub', findRichText: true))
                .evaluate()
                .isEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    expect(
      inReader(find.textContaining('Offline stub', findRichText: true)),
      findsWidgets,
    );
    // The new branch's prompt quotes the passage it was forked from.
    expect(
      inReader(find.textContaining('Explain this passage', findRichText: true)),
      findsWidgets,
    );
    await shot(tester, '03_branch');

    // Back on the graph, turn A now has two children side by side — the
    // original continuation and the new horizontal branch.
    await tester.tap(find.byTooltip('Graph view'));
    await tester.pumpAndSettle();
    await shot(tester, '04_graph');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
