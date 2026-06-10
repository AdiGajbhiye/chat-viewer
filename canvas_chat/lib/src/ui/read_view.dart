import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../data/db/database.dart';
import '../state/providers.dart';

/// M2's bare read mode: one turn of the active path at full width — prompt +
/// response markdown — with ↑/↓ (buttons and arrow keys) walking the path
/// like a transcript. The canvas-integrated read mode arrives in M4.
class ReadView extends ConsumerStatefulWidget {
  const ReadView({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ReadView> createState() => _ReadViewState();
}

class _ReadViewState extends ConsumerState<ReadView> {
  int _index = 0;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _goTo(int index, int pathLength) {
    final clamped = index.clamp(0, pathLength - 1);
    if (clamped == _index) return;
    setState(() => _index = clamped);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(conversationPathProvider(widget.conversationId));
    return switch (async) {
      AsyncData(:final value) => _buildLoaded(context, value),
      AsyncError(:final error) => Center(child: Text('Failed to load: $error')),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  Widget _buildLoaded(BuildContext context, ConversationPath data) {
    final path = data.path;
    if (path.isEmpty) {
      return const Center(child: Text('This conversation has no turns.'));
    }
    final index = _index.clamp(0, path.length - 1);
    final turn = path[index];

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _goTo(index - 1, path.length),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _goTo(index + 1, path.length),
      },
      child: Focus(
        autofocus: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ReadHeader(
              title: data.conversation.title,
              index: index,
              length: path.length,
              onUp: index > 0 ? () => _goTo(index - 1, path.length) : null,
              onDown: index < path.length - 1
                  ? () => _goTo(index + 1, path.length)
                  : null,
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                child: _TurnBody(turn: turn),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadHeader extends StatelessWidget {
  const _ReadHeader({
    required this.title,
    required this.index,
    required this.length,
    required this.onUp,
    required this.onDown,
  });

  final String title;
  final int index;
  final int length;
  final VoidCallback? onUp;
  final VoidCallback? onDown;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.isEmpty ? '(untitled)' : title,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text('${index + 1} / $length',
              style: Theme.of(context).textTheme.bodySmall),
          IconButton(
            tooltip: 'Previous turn (↑)',
            icon: const Icon(Icons.arrow_upward),
            onPressed: onUp,
          ),
          IconButton(
            tooltip: 'Next turn (↓)',
            icon: const Icon(Icons.arrow_downward),
            onPressed: onDown,
          ),
        ],
      ),
    );
  }
}

class _TurnBody extends StatelessWidget {
  const _TurnBody({required this.turn});

  final Turn turn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (turn.promptMd.isNotEmpty)
          Card.filled(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('You', style: theme.textTheme.labelSmall),
                  const SizedBox(height: 8),
                  GptMarkdown(_displayMarkdown(turn.promptMd)),
                ],
              ),
            ),
          ),
        if (turn.thoughtsMd case final thoughts?)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text('Reasoning', style: theme.textTheme.labelLarge),
            childrenPadding: const EdgeInsets.only(bottom: 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
            children: [GptMarkdown(_displayMarkdown(thoughts))],
          ),
        Text(
          turn.modelSlug == null ? 'Assistant' : 'Assistant · ${turn.modelSlug}',
          style: theme.textTheme.labelSmall,
        ),
        const SizedBox(height: 8),
        if (turn.responseMd.isEmpty)
          Text('(no response)',
              style: TextStyle(color: theme.colorScheme.outline))
        else
          GptMarkdown(_displayMarkdown(turn.responseMd)),
      ],
    );
  }
}

/// Image markers (`![image](asset://…)`) become a textual placeholder for
/// now — rendering imported assets is M5 scope, and the app must never hit
/// the network trying to resolve `asset://` as a URL.
String _displayMarkdown(String md) => md.replaceAll(
      RegExp(r'!\[image\]\(asset://[^)]*\)'),
      '*[image attachment]*',
    );
