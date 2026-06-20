// Drives the two-view (graph · read) UI on the REAL macOS engine and writes
// screenshots to build/reader_shots/ so the always-visible toggle, the reader
// pager (vertical page-up / horizontal branch paging) and the cross-fade can be
// eyeballed — the headless test backend doesn't match real Impeller rendering.
//
// Run: flutter test -d macos integration_test/reader_view_test.dart

import 'dart:io';
import 'dart:ui' as ui;

import 'package:canvas_chat/main.dart';
import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/data/import/chatgpt_importer.dart';
import 'package:canvas_chat/src/data/import/export_source.dart';
import 'package:canvas_chat/src/state/providers.dart';
import 'package:canvas_chat/src/ui/read_view.dart';
import 'package:drift/native.dart';
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

const _longA1 = '# Quantum entanglement\n\n'
    'When two particles become **entangled**, their states are described by a '
    'single shared wavefunction. Measuring one *instantly* constrains the '
    'outcome of measuring the other, no matter how far apart they are.\n\n'
    'Key properties:\n\n'
    '- Correlations beat any classical theory (Bell inequalities are violated).\n'
    '- No usable information travels faster than light.\n'
    '- Entanglement is *monogamous*.\n\n'
    '```text\n|ψ⟩ = (|↑↓⟩ − |↓↑⟩) / √2\n```\n\n'
    'A closing paragraph so this turn is tall enough to scroll before it pages.';

const _longA2 = '## Summary\n\n'
    '1. Entangled particles share one wavefunction.\n'
    '2. Measurement correlations beat all classical bounds.\n'
    '3. No faster-than-light signalling is possible.\n\n'
    '```dart\nbool measure(Spin s) => Random().nextBool();\n```\n\n'
    'A final paragraph rounding out the summary turn.';

/// Long active-path turns plus a regenerated-response fork at the second turn,
/// so the reader exercises vertical paging (lane 0) and horizontal branch
/// paging (to lane 1).
Map<String, dynamic> readerConversation() => conversation(
      id: 'conv-reader',
      title: 'Reader demo',
      createTime: 1710000000,
      updateTime: 1710009000,
      currentNode: 'c-a3',
      defaultModelSlug: 'gpt-4o',
      nodes: [
        node('c-root'),
        node('c-u1',
            parent: 'c-root',
            message: message('c-u1',
                role: 'user',
                parts: ['Explain quantum entanglement with an example.'],
                time: 1710000000)),
        node('c-a1',
            parent: 'c-u1',
            message: message('c-a1',
                role: 'assistant',
                parts: [_longA1],
                time: 1710000001,
                modelSlug: 'gpt-4o')),
        node('c-u2',
            parent: 'c-a1',
            message: message('c-u2',
                role: 'user',
                parts: ['Great — summarise the key points with a snippet.'],
                time: 1710000002)),
        node('c-a2',
            parent: 'c-u2',
            message: message('c-a2',
                role: 'assistant',
                parts: [_longA2],
                time: 1710000003,
                modelSlug: 'gpt-4o')),
        node('c-a2b',
            parent: 'c-u2',
            message: message('c-a2b',
                role: 'assistant',
                parts: ['### Shorter take\n\n'
                    'Entanglement = one shared state for two particles; '
                    'measuring one pins the other, but you cannot signal faster '
                    'than light. That is the whole story in a sentence.'],
                time: 1710000004,
                modelSlug: 'gpt-4o')),
        node('c-u3',
            parent: 'c-a2',
            message: message('c-u3',
                role: 'user',
                parts: ['How does this relate to quantum computing?'],
                time: 1710000005)),
        node('c-a3',
            parent: 'c-u3',
            message: message('c-a3',
                role: 'assistant',
                parts: ['Qubits use superposition and entanglement together: '
                    'entangling gates create correlations a classical computer '
                    'cannot represent compactly.'],
                time: 1710000006,
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
    tempDir = await Directory.systemTemp.createTemp('canvas_reader');
    assetsDir = Directory('${tempDir.path}/assets')..createSync();
    db = AppDatabase(NativeDatabase.memory());
    shotsDir = Directory('${Directory.current.path}/build/reader_shots')
      ..createSync(recursive: true);
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  Future<void> seed(WidgetTester tester) async {
    await tester.runAsync(() async {
      final exportDir = Directory('${tempDir.path}/export');
      await writeSyntheticExport(exportDir,
          conversations: [readerConversation()]);
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

  testWidgets('two-view toggle, reader paging up + across branches',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 820);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await seed(tester);
    await tester.pumpWidget(appWith(ThemeMode.dark));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reader demo'));
    await tester.pumpAndSettle();

    // Graph view: the two-icon toggle is present.
    expect(find.byTooltip('Graph view'), findsOneWidget);
    expect(find.byTooltip('Read view'), findsOneWidget);
    await shot(tester, '01_graph');

    // Toggle into the reader; it opens on the focused (active-leaf) turn, and
    // the toggle stays visible.
    await tester.tap(find.byTooltip('Read view'));
    await tester.pumpAndSettle();
    expect(find.byType(ReadOverlay), findsOneWidget);
    expect(find.byTooltip('Graph view'), findsOneWidget);
    expect(
      inReader(find.textContaining('quantum computing', findRichText: true)),
      findsWidgets,
    );
    await shot(tester, '02_reader_open');

    // Page up to the previous turn (the swipe path is covered by the headless
    // widget test; here the button drives it deterministically on the real
    // engine so the slide + breadcrumb can be captured).
    await tester.tap(inReader(find.byTooltip('Go up')));
    await tester.pumpAndSettle();
    expect(inReader(find.text('⑂ Branch 1 of 2')), findsOneWidget);
    expect(
      inReader(find.textContaining('Summary', findRichText: true)),
      findsWidgets,
    );
    await shot(tester, '03_reader_paged_up');

    // Horizontal fling left → page to the regenerated sibling branch.
    await tester.fling(
      find.byType(ReadOverlay),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(inReader(find.text('⑂ Branch 2 of 2')), findsOneWidget);
    expect(
      inReader(find.textContaining('Shorter take', findRichText: true)),
      findsWidgets,
    );
    await shot(tester, '04_reader_branch');

    // Back to the graph: the reader is gone, the canvas is back.
    await tester.tap(find.byTooltip('Graph view'));
    await tester.pumpAndSettle();
    expect(find.byType(ReadOverlay), findsNothing);
    await shot(tester, '05_back_to_graph');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
