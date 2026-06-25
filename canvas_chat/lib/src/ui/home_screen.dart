import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/import_controller.dart';
import '../state/providers.dart';
import 'canvas/canvas_view.dart';
import 'conversation_list_pane.dart';
import 'import_warnings_dialog.dart';
import 'wiki/wiki_view.dart';

/// Two-pane home: conversation sidebar + canvas detail (DESIGN.md §6
/// "Sidebar / home"). On macOS the screen also owns the native menu bar
/// (File: import actions/warnings, Edit: Find) and the ⌘F shortcut that
/// focuses the sidebar search field (M5 polish).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedConversationIdProvider);
    final scaffold = Scaffold(
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyF, meta: true): () =>
              ref.read(searchFocusNodeProvider).requestFocus(),
        },
        child: Row(
          children: [
            const SizedBox(width: 320, child: ConversationListPane()),
            const VerticalDivider(width: 1),
            Expanded(
              child: selectedId == null
                  ? const Center(child: Text('Select a conversation'))
                  : CanvasView(
                      key: ValueKey(selectedId),
                      conversationId: selectedId,
                    ),
            ),
          ],
        ),
      ),
    );
    if (defaultTargetPlatform != TargetPlatform.macOS) return scaffold;
    return PlatformMenuBar(
      menus: _menus(context, ref),
      child: scaffold,
    );
  }

  /// macOS menu bar (DESIGN.md §7 "keyboard shortcuts" / M5 "macOS menu +
  /// shortcuts"). Canvas-local shortcuts (arrows, `f` fit, Esc) live on the
  /// canvas/read views themselves.
  List<PlatformMenu> _menus(BuildContext context, WidgetRef ref) {
    final importing = ref.watch(importControllerProvider) is ImportRunning;
    return [
      PlatformMenu(
        label: 'Canvas Chat',
        menus: [
          if (PlatformProvidedMenuItem.hasMenu(
              PlatformProvidedMenuItemType.quit))
            const PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.quit,
            ),
        ],
      ),
      PlatformMenu(
        label: 'File',
        menus: [
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: 'Import Export Zip…',
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyO,
                  meta: true,
                ),
                onSelected: importing ? null : () => pickAndImportZip(ref),
              ),
              PlatformMenuItem(
                label: 'Import Extracted Folder…',
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyO,
                  meta: true,
                  shift: true,
                ),
                onSelected: importing ? null : () => pickAndImportFolder(ref),
              ),
            ],
          ),
          PlatformMenuItem(
            label: 'Import Warnings…',
            onSelected: () =>
                showImportWarningsDialog(context, ref.read(databaseProvider)),
          ),
        ],
      ),
      PlatformMenu(
        label: 'Edit',
        menus: [
          PlatformMenuItem(
            label: 'Find',
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyF,
              meta: true,
            ),
            onSelected: () => ref.read(searchFocusNodeProvider).requestFocus(),
          ),
        ],
      ),
      PlatformMenu(
        label: 'View',
        menus: [
          PlatformMenuItem(
            label: 'Project Wiki…',
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyK,
              meta: true,
              shift: true,
            ),
            onSelected: () => _openWiki(context, ref),
          ),
        ],
      ),
    ];
  }

  /// Opens the generated wiki for the selected conversation's project (or
  /// 'default'). Mirrors the sidebar button (DESIGN.md §10), reachable from the
  /// macOS menu / ⌘⇧K.
  Future<void> _openWiki(BuildContext context, WidgetRef ref) async {
    final selected = ref.read(selectedConversationIdProvider);
    var projectId = 'default';
    if (selected != null) {
      final db = ref.read(databaseProvider);
      final conversation = await (db.select(db.conversations)
            ..where((c) => c.id.equals(selected)))
          .getSingleOrNull();
      projectId = conversation?.projectId ?? 'default';
    }
    if (!context.mounted) return;
    await WikiScreen.open(context, projectId);
  }
}
