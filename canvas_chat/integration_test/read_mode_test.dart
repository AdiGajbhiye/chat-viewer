// Regression test for "node maximize → read mode renders blank".
//
// MUST run on the real engine: `flutter test -d macos integration_test/`.
// The headless `flutter test` backend lays GptMarkdown out differently and
// does NOT reproduce this crash, which is why the widget-test suite missed it.
//
// The bug: main.dart clamps the global textScaler with `minScaleFactor: 1.2`
// and the clamp() default `maxScaleFactor: double.infinity`. A clamped scaler
// evaluates `maxScaleFactor * fontSize`; for the `fontSize: 0` spacer span
// GptMarkdown inserts after a `#` H1, that is `infinity * 0 == NaN`, which
// trips clampDouble's `min <= max` assert during layout. The whole read-mode
// column then fails to lay out and paints nothing — in every theme. A finite
// maxScaleFactor fixes it.

import 'dart:io';

import 'package:canvas_chat/main.dart';
import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/data/import/chatgpt_importer.dart';
import 'package:canvas_chat/src/data/import/export_source.dart';
import 'package:canvas_chat/src/state/providers.dart';
import 'package:canvas_chat/src/ui/read_view.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/synthetic_export.dart';

/// Forces a fixed theme regardless of OS brightness.
class _FixedTheme extends ThemeModeNotifier {
  _FixedTheme(this.mode);
  final ThemeMode mode;
  @override
  ThemeMode build() => mode;
}

/// One paired turn whose assistant reply opens with a `#` H1 — the heading
/// that triggers GptMarkdown's fontSize:0 divider span — plus a paragraph,
/// list and code block so the whole transcript is exercised.
Map<String, dynamic> headingConversation() => conversation(
      id: 'conv-heading',
      title: 'Rich chat',
      createTime: 1710000000,
      updateTime: 1710000900,
      currentNode: 'r-a1',
      defaultModelSlug: 'gpt-4o',
      nodes: [
        node('r-root'),
        node('r-u1',
            parent: 'r-root',
            message: message('r-u1',
                role: 'user',
                parts: ['Give me a short summary'],
                time: 1710000000)),
        node('r-a1',
            parent: 'r-u1',
            message: message('r-a1',
                role: 'assistant',
                parts: [
                  '# Heading One\n\n'
                      'Here is a **bold** statement and some *italic* text in '
                      'a normal paragraph that should be clearly legible.\n\n'
                      '- First bullet point\n'
                      '- Second bullet point\n\n'
                      'Some `inline code` and then a block:\n\n'
                      '```dart\nvoid main() {\n  print(\'hi\');\n}\n```\n\n'
                      'A final closing paragraph of plain body text.'
                ],
                time: 1710000001,
                modelSlug: 'gpt-4o')),
      ],
    );

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Directory assetsDir;
  late AppDatabase db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('canvas_repro');
    assetsDir = Directory('${tempDir.path}/assets')..createSync();
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  Future<void> seed(WidgetTester tester) async {
    await tester.runAsync(() async {
      final exportDir = Directory('${tempDir.path}/export');
      await writeSyntheticExport(exportDir,
          conversations: [headingConversation()]);
      await ChatGptImporter(
        db: db,
        source: DirectoryExportSource(exportDir),
        assetsDir: assetsDir,
      ).run();
    });
  }

  Widget appWith(ThemeMode mode) => ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          assetsDirProvider.overrideWithValue(assetsDir),
          themeModeProvider.overrideWith(() => _FixedTheme(mode)),
        ],
        child: const CanvasChatApp(),
      );

  // The crash was theme-independent (it blanked read mode in light and dark
  // alike), so guard both.
  for (final (label, mode) in [
    ('dark', ThemeMode.dark),
    ('light', ThemeMode.light),
  ]) {
    testWidgets('read mode renders a heading transcript without crashing '
        '($label)', (tester) async {
      await seed(tester);
      await tester.pumpWidget(appWith(mode));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rich chat'));
      await tester.pumpAndSettle();

      // Enter read mode via the bottom-right view toggle.
      await tester.tap(find.byTooltip('Read view'));
      await tester.pumpAndSettle();

      // Read mode is open and the transcript — including the H1 that used to
      // crash layout — is actually painted, not a blank panel. (pumpAndSettle
      // above would already have rethrown the clampDouble assertion.)
      final inOverlay = find.descendant(
        of: find.byType(ReadOverlay),
        matching: find.textContaining('Heading One', findRichText: true),
      );
      expect(inOverlay, findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ReadOverlay),
          matching: find.textContaining('closing paragraph', findRichText: true),
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}
