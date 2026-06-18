import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'src/data/db/database.dart';
import 'src/state/providers.dart';
import 'src/ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // DB + asset store live in the app documents dir (DESIGN.md §4).
  final documents = await getApplicationDocumentsDirectory();
  final dataDir = Directory(p.join(documents.path, 'canvas_chat'));
  final assetsDir = Directory(p.join(dataDir.path, 'assets'));
  assetsDir.createSync(recursive: true);

  final db = AppDatabase(
    NativeDatabase.createInBackground(
      File(p.join(dataDir.path, 'canvas_chat.db')),
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        assetsDirProvider.overrideWithValue(assetsDir),
      ],
      child: const CanvasChatApp(),
    ),
  );
}

class CanvasChatApp extends ConsumerWidget {
  const CanvasChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Canvas Chat',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
      ),
      themeMode: ref.watch(themeModeProvider),
      // Enforce a minimum 1.2x text scale for a larger, more readable UI,
      // while still honoring a larger system text-scaling preference.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(minScaleFactor: 1.2),
          ),
          child: child!,
        );
      },
      home: const HomeScreen(),
    );
  }
}
