import 'dart:io';

import 'package:canvas_chat/main.dart';
import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/data/import/chatgpt_importer.dart';
import 'package:canvas_chat/src/data/import/export_source.dart';
import 'package:canvas_chat/src/state/backfill.dart';
import 'package:canvas_chat/src/state/indexing.dart';
import 'package:canvas_chat/src/state/providers.dart';
import 'package:canvas_chat/src/ui/read_view.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/synthetic_export.dart';

/// The reader's collapsible "Generated index" section (DESIGN.md §10): toggling
/// it open shows the focused turn's propositions (with aspect tags) + entity
/// chips, and a turn with no index shows the "Not indexed yet" line.
void main() {
  late Directory tempDir;
  late Directory assetsDir;
  late AppDatabase db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('canvas_chat_turn_index');
    assetsDir = Directory('${tempDir.path}/assets')..createSync();
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  /// Imports the forked fixture (the canvas opens focused on "edited v2",
  /// `conv-forked:f-u3b`). When [withIndex], also seeds that turn's generated
  /// index: two propositions with aspects + two entities.
  Future<void> seed(WidgetTester tester, {required bool withIndex}) async {
    await tester.runAsync(() async {
      final exportDir = Directory('${tempDir.path}/export');
      await writeSyntheticExport(exportDir, conversations: [
        forkedConversation(),
      ]);
      await ChatGptImporter(
        db: db,
        source: DirectoryExportSource(exportDir),
        assetsDir: assetsDir,
      ).run();

      if (!withIndex) return;
      await db.batch((b) {
        b.insertAll(db.propositions, [
          PropositionsCompanion.insert(
            id: 'conv-forked:f-u3b#0',
            turnId: 'conv-forked:f-u3b',
            conversationId: 'conv-forked',
            projectId: 'default',
            propText: 'The k-NN query should be optimized for speed.',
            aspect: const Value('perf'),
          ),
          PropositionsCompanion.insert(
            id: 'conv-forked:f-u3b#1',
            turnId: 'conv-forked:f-u3b',
            conversationId: 'conv-forked',
            projectId: 'default',
            propText: 'Which database should store the embeddings?',
            aspect: const Value('question'),
          ),
        ]);
        b.insertAll(db.entities, [
          EntitiesCompanion.insert(
            id: 'ent:default:sqlite',
            projectId: 'default',
            name: 'SQLite',
            normalized: 'sqlite',
          ),
          EntitiesCompanion.insert(
            id: 'ent:default:knn',
            projectId: 'default',
            name: 'k-NN',
            normalized: 'k-nn',
          ),
        ]);
        b.insertAll(db.turnEntities, [
          TurnEntitiesCompanion.insert(
            entityId: 'ent:default:sqlite',
            turnId: 'conv-forked:f-u3b',
          ),
          TurnEntitiesCompanion.insert(
            entityId: 'ent:default:knn',
            turnId: 'conv-forked:f-u3b',
          ),
        ]);
      });
    });
  }

  Future<void> launch(WidgetTester tester) async {
    // A tall surface so the short focused turn's whole body — including the
    // trailing index section — lays out on-screen without scrolling, so the
    // section (a lazy `ListView` trailing item) is built and its provider
    // subscribed on first layout.
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          assetsDirProvider.overrideWithValue(assetsDir),
          sharedPreferencesProvider.overrideWithValue(prefs),
          // Keep the on-open lazy indexer AND the idle-time backfill from
          // clobbering this test's seeded index rows (both delete + re-extract a
          // turn's propositions when the conversation opens). The index panel
          // renders whatever is in the DB, so freezing the data makes the
          // assertions deterministic.
          indexingEnabledProvider.overrideWithValue(false),
          backfillEnabledProvider.overrideWithValue(false),
        ],
        child: const CanvasChatApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Opens the forked chat and enters read mode on its current turn ("edited
  /// v2", `conv-forked:f-u3b`).
  Future<void> openReader(WidgetTester tester) async {
    await launch(tester);
    await tester.tap(find.text('Forked chat'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Read view'));
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  Finder inOverlay(Finder matching) =>
      find.descendant(of: find.byType(ReadOverlay), matching: matching);

  /// Scrolls the reader's transcript (a lazy `ListView`) toward the bottom so
  /// its trailing index section builds and lays out on-screen, then waits for
  /// [target] (the header / "Not indexed yet" line) to appear. Manual bounded
  /// drags (each below the 64px overscroll page-threshold, so they scroll in
  /// content rather than paging to the next turn); each pump builds the section
  /// and resolves its one-shot drift-backed future.
  Future<void> revealIndex(WidgetTester tester, Finder target) async {
    final body = inOverlay(find.byType(ListView)).first;
    for (var i = 0; i < 30 && target.evaluate().isEmpty; i++) {
      await tester.drag(body, const Offset(0, -50));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('the index section toggles open to show propositions '
      '(with aspect tags) and entity chips', (tester) async {
    await seed(tester, withIndex: true);
    await openReader(tester);

    // The collapsed header shows the proposition count; the bullets are not yet
    // built (collapsed by default).
    final header = inOverlay(find.text('Generated index · 2 propositions'));
    await revealIndex(tester, header);
    expect(header, findsOneWidget);
    expect(
      inOverlay(find.textContaining('k-NN query should be optimized')),
      findsNothing,
    );

    // Expand it.
    await tester.tap(header);
    await tester.pumpAndSettle();

    // Propositions render with their open-vocab aspect tag as a [tag] prefix.
    expect(
      inOverlay(find.textContaining('[perf]', findRichText: true)),
      findsOneWidget,
    );
    expect(
      inOverlay(find.textContaining('[question]', findRichText: true)),
      findsOneWidget,
    );
    expect(
      inOverlay(
        find.textContaining('optimized for speed', findRichText: true),
      ),
      findsOneWidget,
    );

    // Entities render as a wrap of chips.
    expect(inOverlay(find.widgetWithText(Chip, 'SQLite')), findsOneWidget);
    expect(inOverlay(find.widgetWithText(Chip, 'k-NN')), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('a not-yet-indexed turn shows the "Not indexed yet" line',
      (tester) async {
    await seed(tester, withIndex: false);
    await openReader(tester);

    final line = inOverlay(find.text('Not indexed yet'));
    await revealIndex(tester, line);
    expect(line, findsOneWidget);
    // No index header / toggle for an unindexed turn.
    expect(
      inOverlay(find.textContaining('Generated index')),
      findsNothing,
    );

    await unmount(tester);
  });
}
