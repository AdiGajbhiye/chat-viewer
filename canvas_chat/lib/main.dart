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

/// Clamps [base] to the app's readable text-scale range: a 1.2x floor for a
/// larger, more readable default UI, while still honoring a larger system
/// text-scaling preference up to a finite 4x ceiling.
///
/// The ceiling MUST stay finite. A clamped [TextScaler] evaluates
/// `maxScaleFactor * fontSize`, and clamp()'s default ceiling of
/// `double.infinity` makes that `infinity * 0 == NaN` for a zero-size span —
/// which trips clampDouble's `min <= max` assert and crashes layout. Markdown
/// bodies hit this routinely: GptMarkdown inserts a `fontSize: 0` spacer after
/// every `#` H1, so an infinite ceiling blanks read mode. 4x is well above any
/// real platform accessibility scale.
TextScaler clampReadableTextScale(TextScaler base) =>
    base.clamp(minScaleFactor: 1.2, maxScaleFactor: 4);

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
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: clampReadableTextScale(mq.textScaler),
          ),
          child: child!,
        );
      },
      home: const HomeScreen(),
    );
  }
}
