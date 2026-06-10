import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../state/import_controller.dart';
import '../state/providers.dart';

/// Sidebar: import button + the conversation list, newest first
/// (DESIGN.md §6 "Sidebar / home"; search and filters arrive in M5).
class ConversationListPane extends ConsumerWidget {
  const ConversationListPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationListProvider);
    final importState = ref.watch(importControllerProvider);

    ref.listen(importControllerProvider, (previous, next) {
      final messenger = ScaffoldMessenger.of(context);
      switch (next) {
        case ImportSucceeded(:final result):
          messenger.showSnackBar(SnackBar(
            content: Text(
              'Imported ${result.conversations} conversations, '
              '${result.turns} turns'
              '${result.warnings.isEmpty ? '' : ' (${result.warnings.length} warnings)'}',
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
              const ImportMenuButton(),
            ],
          ),
        ),
        if (importState case ImportRunning(:final done, :final total))
          _ImportProgressBanner(done: done, total: total),
        const Divider(height: 1),
        Expanded(
          child: switch (conversations) {
            AsyncData(:final value) => value.isEmpty
                ? const _EmptyState()
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
        return ListTile(
          dense: true,
          selected: conversation.id == selectedId,
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
/// (DESIGN.md §5 step 1).
class ImportMenuButton extends ConsumerWidget {
  const ImportMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final running = ref.watch(importControllerProvider) is ImportRunning;
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.folder_zip_outlined),
          onPressed: running ? null : () => _pickZip(ref),
          child: const Text('Import export zip…'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.folder_open_outlined),
          onPressed: running ? null : () => _pickFolder(ref),
          child: const Text('Import extracted folder…'),
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

  Future<void> _pickZip(WidgetRef ref) async {
    final picked = await FilePicker.pickFiles(
      dialogTitle: 'Choose ChatGPT export zip',
      type: FileType.custom,
      allowedExtensions: const ['zip'],
    );
    final path = picked?.files.singleOrNull?.path;
    if (path == null) return;
    await ref.read(importControllerProvider.notifier).importFrom(path);
  }

  Future<void> _pickFolder(WidgetRef ref) async {
    final path = await FilePicker.getDirectoryPath(
      dialogTitle: 'Choose extracted ChatGPT export folder',
    );
    if (path == null) return;
    await ref.read(importControllerProvider.notifier).importFrom(path);
  }
}
