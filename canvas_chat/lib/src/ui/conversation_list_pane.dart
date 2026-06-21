import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../state/import_controller.dart';
import '../state/providers.dart';
import 'import_warnings_dialog.dart';
import 'llm_settings_dialog.dart';

/// Sidebar: import button, FTS search field (M5), and the conversation list
/// (newest first, or search results when a query is active) — DESIGN.md §6
/// "Sidebar / home".
class ConversationListPane extends ConsumerWidget {
  const ConversationListPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider).trim();
    final conversations = query.isEmpty
        ? ref.watch(conversationListProvider)
        : ref.watch(searchResultsProvider(query));
    final importState = ref.watch(importControllerProvider);

    ref.listen(importControllerProvider, (previous, next) {
      final messenger = ScaffoldMessenger.of(context);
      final db = ref.read(databaseProvider);
      switch (next) {
        case ImportSucceeded(:final result):
          messenger.showSnackBar(SnackBar(
            content: Text(
              'Imported ${result.conversations} conversations, '
              '${result.turns} turns'
              '${result.warnings.isEmpty ? '' : ' (${result.warnings.length} warnings)'}',
            ),
            action: result.warnings.isEmpty
                ? null
                : SnackBarAction(
                    label: 'Details',
                    onPressed: () => showImportWarningsDialog(context, db),
                  ),
          ));
        case ImportFailed(:final message):
          messenger.showSnackBar(SnackBar(content: Text('Import failed: $message')));
        default:
          break;
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Canvas Chat',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const _SettingsButton(),
              const _ThemeToggleButton(),
              const ImportMenuButton(),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: _SearchField(),
        ),
        if (importState case ImportRunning(:final done, :final total))
          _ImportProgressBanner(done: done, total: total),
        const Divider(height: 1),
        Expanded(
          child: switch (conversations) {
            AsyncData(:final value) => value.isEmpty
                ? (query.isEmpty
                    ? const _EmptyState()
                    : const Center(child: Text('No matching conversations.')))
                : _ConversationList(conversations: value),
            AsyncError(:final error) =>
              Center(child: Text('Failed to load conversations:\n$error')),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ],
    );
  }
}

/// FTS search over titles + prompt/response content (DESIGN.md §6). The
/// field's focus node comes from [searchFocusNodeProvider] so the macOS Find
/// menu / ⌘F can focus it.
class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    ref.read(searchQueryProvider.notifier).set('');
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    return TextField(
      controller: _controller,
      focusNode: ref.watch(searchFocusNodeProvider),
      decoration: InputDecoration(
        hintText: 'Search conversations',
        prefixIcon: const Icon(Icons.search, size: 18),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close, size: 18),
                onPressed: _clear,
              ),
        isDense: true,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      onChanged: (value) => ref.read(searchQueryProvider.notifier).set(value),
    );
  }
}

class _ConversationList extends ConsumerWidget {
  const _ConversationList({required this.conversations});

  final List<Conversation> conversations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedConversationIdProvider);
    return ListView.builder(
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        final colors = Theme.of(context).colorScheme;
        return ListTile(
          dense: true,
          selected: conversation.id == selectedId,
          selectedTileColor: colors.secondaryContainer,
          selectedColor: colors.onSecondaryContainer,
          title: Text(
            conversation.title.isEmpty ? '(untitled)' : conversation.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(_formatDate(context, conversation.updateTime)),
          onTap: () => ref
              .read(selectedConversationIdProvider.notifier)
              .select(conversation.id),
        );
      },
    );
  }

  String _formatDate(BuildContext context, int? millis) {
    if (millis == null) return '';
    return MaterialLocalizations.of(context)
        .formatShortDate(DateTime.fromMillisecondsSinceEpoch(millis));
  }
}

/// Opens the LLM connection settings (model / API key / base URL).
class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Model settings',
      icon: const Icon(Icons.settings_outlined),
      onPressed: () => showLlmSettingsDialog(context),
    );
  }
}

/// Flips between light and dark themes (DESIGN.md §6 sidebar). Shows a moon
/// while light, a sun while dark — i.e. the mode a tap would switch to.
class _ThemeToggleButton extends ConsumerWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: isDark ? 'Switch to light theme' : 'Switch to dark theme',
      icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: () => ref
          .read(themeModeProvider.notifier)
          .toggle(MediaQuery.platformBrightnessOf(context)),
    );
  }
}

class _ImportProgressBanner extends StatelessWidget {
  const _ImportProgressBanner({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Importing… $done / $total',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: total == 0 ? null : done / total),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No conversations yet.\nImport your ChatGPT export to begin.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// "Import…" menu: pick the export as a zip or as an extracted folder
/// (DESIGN.md §5 step 1), or review the last run's warnings (M5).
class ImportMenuButton extends ConsumerWidget {
  const ImportMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final running = ref.watch(importControllerProvider) is ImportRunning;
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.folder_zip_outlined),
          onPressed: running ? null : () => pickAndImportZip(ref),
          child: const Text('Import export zip…'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.folder_open_outlined),
          onPressed: running ? null : () => pickAndImportFolder(ref),
          child: const Text('Import extracted folder…'),
        ),
        const Divider(height: 8),
        MenuItemButton(
          leadingIcon: const Icon(Icons.warning_amber_outlined),
          onPressed: () =>
              showImportWarningsDialog(context, ref.read(databaseProvider)),
          child: const Text('Last import warnings…'),
        ),
      ],
      builder: (context, controller, child) => IconButton(
        tooltip: 'Import ChatGPT export',
        icon: const Icon(Icons.download_outlined),
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

/// Opens a zip picker and starts an import. Shared by the sidebar menu and
/// the macOS File menu.
Future<void> pickAndImportZip(WidgetRef ref) async {
  final picked = await FilePicker.pickFiles(
    dialogTitle: 'Choose ChatGPT export zip',
    type: FileType.custom,
    allowedExtensions: const ['zip'],
  );
  final path = picked?.files.singleOrNull?.path;
  if (path == null) return;
  await ref.read(importControllerProvider.notifier).importFrom(path);
}

/// Opens a folder picker and starts an import. Shared by the sidebar menu
/// and the macOS File menu.
Future<void> pickAndImportFolder(WidgetRef ref) async {
  final path = await FilePicker.getDirectoryPath(
    dialogTitle: 'Choose extracted ChatGPT export folder',
  );
  if (path == null) return;
  await ref.read(importControllerProvider.notifier).importFrom(path);
}
