import 'dart:io';

import 'package:canvas_chat/main.dart';
import 'package:canvas_chat/src/data/db/database.dart';
import 'package:canvas_chat/src/data/import/chatgpt_importer.dart';
import 'package:canvas_chat/src/data/import/export_source.dart';
import 'package:canvas_chat/src/data/llm/embedding_provider.dart';
import 'package:canvas_chat/src/state/facts.dart';
import 'package:canvas_chat/src/state/providers.dart';
import 'package:canvas_chat/src/state/wiki.dart';
import 'package:canvas_chat/src/ui/read_view.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/synthetic_export.dart';

/// M9.2 — the read-only project wiki UI. Pumps the full app, opens the wiki
/// from the sidebar, asserts the overview renders topics + entities + facts,
/// that an entity chip navigates to its page, and that a fact's provenance
/// click-through publishes the nav request + selects the source conversation
/// (the existing reader/selection mechanism).
void main() {
  late Directory tempDir;
  late Directory assetsDir;
  late AppDatabase db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('canvas_chat_wiki');
    assetsDir = Directory('${tempDir.path}/assets')..createSync();
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  /// Imports the forked fixture, then seeds wiki inputs: two entities (one on
  /// two turns, one on one turn), two soft edges that connect three turns into
  /// one topic, and one committed fact sourced from a turn.
  Future<void> seedWiki(WidgetTester tester) async {
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

      // Entities (default project — the imported conversation backfills to it).
      await db.batch((b) {
        b.insertAll(db.entities, [
          EntitiesCompanion.insert(
            id: 'ent:default:sqlite',
            projectId: 'default',
            name: 'SQLite',
            normalized: 'sqlite',
          ),
          EntitiesCompanion.insert(
            id: 'ent:default:riverpod',
            projectId: 'default',
            name: 'Riverpod',
            normalized: 'riverpod',
          ),
        ]);
        b.insertAll(db.turnEntities, [
          // SQLite mentioned on two turns; Riverpod on one.
          TurnEntitiesCompanion.insert(
            entityId: 'ent:default:sqlite',
            turnId: 'conv-forked:f-a1',
          ),
          TurnEntitiesCompanion.insert(
            entityId: 'ent:default:sqlite',
            turnId: 'conv-forked:f-a2',
          ),
          TurnEntitiesCompanion.insert(
            entityId: 'ent:default:riverpod',
            turnId: 'conv-forked:f-u3b',
          ),
        ]);
        // Soft edges: a1-a2 (semantic) and a2-u3b (entity) → one 3-turn topic.
        b.insertAll(db.softEdges, [
          SoftEdgesCompanion.insert(
            fromTurnId: 'conv-forked:f-a1',
            toTurnId: 'conv-forked:f-a2',
            kind: 'semantic',
            weight: 0.8,
            projectId: 'default',
          ),
          SoftEdgesCompanion.insert(
            fromTurnId: 'conv-forked:f-a2',
            toTurnId: 'conv-forked:f-u3b',
            kind: 'entity',
            weight: 0.4,
            projectId: 'default',
          ),
        ]);
        // A proposition on the SQLite turn for the entity-page "Mentions".
        b.insert(
          db.propositions,
          PropositionsCompanion.insert(
            id: 'conv-forked:f-a1#0',
            turnId: 'conv-forked:f-a1',
            conversationId: 'conv-forked',
            projectId: 'default',
            propText: 'The project stores data in SQLite via drift.',
          ),
        );
      });

      // A committed, active fact sourced from the SQLite turn.
      await FactsService(db: db, embedder: const StubEmbeddingProvider())
          .commitFact(
        text: 'Decision: SQLite is the database.',
        sourceTurnIds: ['conv-forked:f-a1'],
        projectId: 'default',
        conversationId: 'conv-forked',
      );
    });
  }

  Future<ProviderContainer> makeContainer() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        assetsDirProvider.overrideWithValue(assetsDir),
        // The wiki reuses factsServiceProvider → embeddingProviderProvider,
        // which reads the (unconfigured → offline stub) embedding config from
        // prefs; without this it throws StateError and the overview can't build.
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
  }

  Widget host(ProviderContainer container) => UncontrolledProviderScope(
        container: container,
        child: const CanvasChatApp(),
      );

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  Future<void> openWiki(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Project wiki'));
    await tester.pumpAndSettle();
  }

  testWidgets('overview renders topics, entities and facts', (tester) async {
    await seedWiki(tester);
    final container = await makeContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(host(container));
    await tester.pumpAndSettle();
    await openWiki(tester);

    // Sections.
    expect(find.text('Topics'), findsOneWidget);
    expect(find.text('Entities'), findsOneWidget);
    expect(find.text('Facts'), findsOneWidget);

    // One topic (the 3-turn connected component).
    expect(find.text('Topic 1'), findsOneWidget);
    expect(find.textContaining('3 turns'), findsOneWidget);

    // Entities appear as hyperlinked chips (with counts in the index).
    expect(find.textContaining('SQLite · 2'), findsWidgets);
    expect(find.textContaining('Riverpod · 1'), findsWidgets);

    // The committed fact renders as content.
    expect(
      find.textContaining('SQLite is the database', findRichText: true),
      findsWidgets,
    );

    await unmount(tester);
  });

  testWidgets('tapping an entity chip opens its backlink page', (tester) async {
    await seedWiki(tester);
    final container = await makeContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(host(container));
    await tester.pumpAndSettle();
    await openWiki(tester);

    // Tap the SQLite entity in the index (scroll it into view first).
    final chip = find.widgetWithText(ActionChip, 'SQLite · 2').first;
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pumpAndSettle();

    // The entity page: title, the mention summary, the backlinked fact and a
    // proposition snippet.
    expect(find.widgetWithText(AppBar, 'SQLite'), findsOneWidget);
    expect(find.textContaining('Mentioned in 2 turns'), findsOneWidget);
    expect(find.text('Mentions'), findsOneWidget);
    expect(
      find.textContaining('stores data in SQLite', findRichText: true),
      findsWidgets,
    );

    await unmount(tester);
  });

  testWidgets('a fact provenance click-through selects the source turn '
      'and opens the reader', (tester) async {
    await seedWiki(tester);
    final container = await makeContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(host(container));
    await tester.pumpAndSettle();

    // Nothing selected; no nav request yet.
    expect(container.read(selectedConversationIdProvider), isNull);
    expect(container.read(wikiNavRequestProvider), isNull);

    await openWiki(tester);

    // Tap the fact's "Open source turn" button (the all-facts list tile, which
    // carries the pre-resolved provenance).
    final sourceBtn = find.byTooltip('Open source turn');
    expect(sourceBtn, findsWidgets);
    await tester.tap(sourceBtn.first);
    await tester.pumpAndSettle();

    // The wiki published a nav request for the fact's source turn AND selected
    // its conversation — the existing selection mechanism.
    expect(
      container.read(selectedConversationIdProvider),
      'conv-forked',
    );
    // The CanvasView consumes the request (clearing it) and opens the reader on
    // the source turn.
    expect(container.read(wikiNavRequestProvider), isNull);
    expect(find.byType(ReadOverlay), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ReadOverlay),
        matching: find.textContaining('first answer', findRichText: true),
      ),
      findsOneWidget,
    );

    await unmount(tester);
  });

  testWidgets('the wiki is empty when nothing is indexed/committed',
      (tester) async {
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
    });
    final container = await makeContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(host(container));
    await tester.pumpAndSettle();
    await openWiki(tester);

    expect(find.textContaining('Nothing in the wiki yet'), findsOneWidget);

    await unmount(tester);
  });
}
