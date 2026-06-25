// Real-engine (macOS/Impeller) visual verification of the Phase 2 UI.
//
// Mirrors chunk_toolbar_test.dart: seeds a small entity-rich forked
// conversation, indexes it + commits a fact (so the new surfaces have real
// content), then drives each new control on the REAL engine and writes
// screenshots to build/phase2_shots/ — widget tests / goldens don't match real
// Impeller rendering.
//
// Run: flutter test -d macos integration_test/phase2_visual_test.dart

import 'dart:io';
import 'dart:ui' as ui;

import 'package:canvas_chat/main.dart';
import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/data/import/chatgpt_importer.dart';
import 'package:canvas_chat/src/data/import/export_source.dart';
import 'package:canvas_chat/src/state/facts.dart';
import 'package:canvas_chat/src/state/indexing.dart';
import 'package:canvas_chat/src/state/providers.dart';
import 'package:canvas_chat/src/ui/canvas/canvas_view.dart';
import 'package:canvas_chat/src/ui/canvas/indexing_indicator.dart';
import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/helpers/synthetic_export.dart';

class _FixedTheme extends ThemeModeNotifier {
  _FixedTheme(this.mode);
  final ThemeMode mode;
  @override
  ThemeMode build() => mode;
}

/// A small forked conversation whose responses carry shared code-span entities
/// (`Postgres`, `SQLite`, `sqlite-vec`) so the stub extractor produces entities
/// that link turns with entity soft-edges and populate the wiki.
Map<String, dynamic> demoConversation() => conversation(
      id: 'conv-demo',
      title: 'Index store design',
      createTime: 1710000000,
      updateTime: 1710009000,
      currentNode: 'd-a2',
      defaultModelSlug: 'gpt-4o',
      nodes: [
        node('d-root'),
        node('d-u1',
            parent: 'd-root',
            message: message('d-u1',
                role: 'user',
                parts: ['How should I store the search index?'])),
        node('d-a1',
            parent: 'd-u1',
            message: message('d-a1',
                role: 'assistant',
                parts: [
                  'Use `Postgres` with the `pg_trgm` extension for fuzzy '
                      'search. `Postgres` handles this load well.'
                ])),
        // active branch: ask about the embedded case
        node('d-u2',
            parent: 'd-a1',
            message: message('d-u2',
                role: 'user', parts: ['What about the embedded case?'])),
        node('d-a2',
            parent: 'd-u2',
            message: message('d-a2',
                role: 'assistant',
                parts: [
                  'For the embedded case use `SQLite` paired with the '
                      '`sqlite-vec` extension.'
                ])),
        // forked sibling branch off d-a1: a comparison
        node('d-u3',
            parent: 'd-a1',
            message: message('d-u3',
                role: 'user', parts: ['Compare the two for vectors.'])),
        node('d-a3',
            parent: 'd-u3',
            message: message('d-a3',
                role: 'assistant',
                parts: [
                  '`Postgres` with `pgvector` scales; `SQLite` with '
                      '`sqlite-vec` is simpler.'
                ])),
      ],
    );

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Directory assetsDir;
  late AppDatabase db;
  late SharedPreferences prefs;
  late Directory shotsDir;
  final boundaryKey = GlobalKey();

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('canvas_phase2');
    assetsDir = Directory('${tempDir.path}/assets')..createSync();
    db = AppDatabase(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    shotsDir = Directory('${Directory.current.path}/build/phase2_shots')
      ..createSync(recursive: true);
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  // Import the demo conversation, then index it + compute soft edges + commit a
  // fact through a throwaway container on the SAME db, so every Phase 2 surface
  // has real content before the app boots. Offline stub providers (empty prefs).
  Future<void> seedIndexed(WidgetTester tester) async {
    await tester.runAsync(() async {
      final exportDir = Directory('${tempDir.path}/export');
      await writeSyntheticExport(exportDir, conversations: [demoConversation()]);
      await ChatGptImporter(
        db: db,
        source: DirectoryExportSource(exportDir),
        assetsDir: assetsDir,
      ).run();

      final c = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      await c.read(conversationIndexerProvider).ensureIndexed('conv-demo');
      await c.read(softEdgeComputerProvider)
          .recomputeForConversation('conv-demo');
      final turns = await db.select(db.turns).get();
      await c.read(factsServiceProvider).commitFact(
            text: 'Use Postgres with pg_trgm for the search index.',
            sourceTurnIds: [turns.first.id],
            projectId: 'default',
            conversationId: 'conv-demo',
          );
      c.dispose();
    });
  }

  Widget appWith(ThemeMode mode) => RepaintBoundary(
        key: boundaryKey,
        child: ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            assetsDirProvider.overrideWithValue(assetsDir),
            sharedPreferencesProvider.overrideWithValue(prefs),
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

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(CanvasChatApp)));

  testWidgets('canvas surfaces: soft-edge layer, scope selector, indicator',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await seedIndexed(tester);
    await tester.pumpWidget(appWith(ThemeMode.dark));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Index store design'));
    await tester.pumpAndSettle();
    await shot(tester, '01_graph');

    // Soft-edge layer: toggle ON (default off) → associative arcs draw.
    expect(find.byType(SoftEdgesToggle), findsOneWidget);
    await tester.tap(find.byTooltip('Show related links'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Hide related links'), findsOneWidget);
    await shot(tester, '02_soft_edges_on');

    // Retrieval scope selector popup.
    await tester.tap(find.byTooltip('Retrieval scope'));
    await tester.pumpAndSettle();
    expect(find.text('This conversation only'), findsOneWidget);
    await shot(tester, '03_scope_popup');
    // dismiss the menu
    await tester.tap(find.text('The whole project').last);
    await tester.pumpAndSettle();

    // Indexing indicator: drive the progress provider to an active state and
    // capture the real chip (a live conversation finishes too fast to catch).
    containerOf(tester).read(indexingProgressProvider.notifier).update(
          'conv-demo',
          const IndexingProgress(
              state: IndexState.indexing, done: 1, total: 3),
        );
    // pump() not pumpAndSettle() — the chip has a spinning CircularProgress.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byType(IndexingIndicator), findsOneWidget);
    expect(find.textContaining('Indexing'), findsWidgets);
    await shot(tester, '04_indexing_indicator');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('reader: commit a chunk as a fact (SnackBar feedback)',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await seedIndexed(tester);
    await tester.pumpWidget(appWith(ThemeMode.dark));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Index store design'));
    await tester.pumpAndSettle();

    // Ground truth: seedIndexed committed exactly 1 fact.
    final before = await tester.runAsync(
        () async => (await db.select(db.facts).get()).length);
    expect(before, 1);

    // Open the reader on the active leaf.
    await tester.tap(find.byTooltip('Read view'));
    await tester.pumpAndSettle();

    // Hover the response so the per-chunk toolbar fades in.
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(
        find.textContaining('embedded case', findRichText: true).first));
    await tester.pumpAndSettle();
    final commitBtn = find.byTooltip('Commit as a fact');
    expect(commitBtn, findsWidgets);
    await shot(tester, '05_commit_toolbar');

    // Move the pointer onto the commit button so the toolbar stays at full
    // opacity / hittable (an intervening runAsync lets it fade behind an
    // IgnorePointer and the tap falls through), then tap it.
    await mouse.moveTo(tester.getCenter(commitBtn.first));
    await tester.pumpAndSettle();
    await tester.tap(commitBtn.first);

    // Let the commit's real async (db read + embed/persist) complete; fake-clock
    // pumps don't advance real I/O.
    final after = await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return (await db.select(db.facts).get()).length;
    });
    await tester.pump();
    // The committed fact is the real product behavior — assert it landed.
    expect(after, 2);
    final snackFound = find.text('Committed as a fact').evaluate().isNotEmpty;
    await shot(tester, snackFound ? '06_commit_snackbar' : '06_commit_done');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('wiki: overview + entity page with backlinks', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await seedIndexed(tester);
    await tester.pumpWidget(appWith(ThemeMode.dark));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Index store design'));
    await tester.pumpAndSettle();

    // Open the project wiki from the sidebar.
    await tester.tap(find.byTooltip('Project wiki'));
    await tester.pumpAndSettle();
    expect(find.text('Project Wiki'), findsOneWidget);
    await shot(tester, '07_wiki_overview');

    // Tap an entity → its page (Obsidian-style backlinks).
    expect(find.text('Postgres'), findsWidgets);
    await tester.tap(find.text('Postgres').first);
    await tester.pumpAndSettle();
    await shot(tester, '08_wiki_entity');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
