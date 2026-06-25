import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/indexing.dart';

/// Small, unobtrusive on-canvas chip shown while a conversation is being lazily
/// indexed (DESIGN.md §10: "an on-canvas indexing indicator hides most of" the
/// first-open cost). Mirrors the sidebar's import-progress banner in spirit — a
/// label plus progress — but as a compact pill that sits on the map and
/// vanishes the moment the conversation finishes indexing. Renders nothing when
/// the conversation is not actively indexing.
class IndexingIndicator extends ConsumerWidget {
  const IndexingIndicator({super.key, required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(
      indexingProgressProvider.select((m) => m[conversationId]),
    );
    if (progress == null || !progress.isIndexing) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final total = progress.total;
    final done = progress.done;
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(16),
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: total == 0 ? null : done / total,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              total == 0 ? 'Indexing…' : 'Indexing $done/$total…',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
