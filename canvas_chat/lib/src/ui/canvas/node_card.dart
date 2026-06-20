import 'package:flutter/material.dart';

import '../../domain/grid_layout.dart';

/// Direction for grid navigation (arrow keys).
enum GridDirection { up, down, left, right }

/// Collapsed turn card for navigate mode (DESIGN.md §6 "Node card"): the user
/// query filling the card and a meta line with time · model · fork count.
/// Tapping the card opens it in read mode; the assistant reply is shown only
/// there. Uniform size — the parent positions it in a fixed [CanvasMetrics]
/// cell.
class NodeCard extends StatelessWidget {
  const NodeCard({
    super.key,
    required this.cell,
    required this.selected,
    this.matched = false,
    required this.onMaximize,
  });

  final GridCell cell;
  final bool selected;

  /// This turn matches the active in-canvas search — highlight it so hits
  /// stand out even when off the active path.
  final bool matched;

  /// Enter read mode for this turn (tapping the card, DESIGN.md §6).
  final VoidCallback onMaximize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // A search hit is never dimmed, so matches pop out of the dimmed lanes.
    final dimmed = !cell.onActivePath && !selected && !matched;

    return Opacity(
      opacity: dimmed ? 0.6 : 1,
      child: Material(
        color: matched && !selected
            ? scheme.tertiaryContainer
            : cell.onActivePath
                ? scheme.surfaceContainerLow
                : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        elevation: selected ? 3 : 1,
        child: InkWell(
          // Tap a node → read mode for that node (DESIGN.md §6).
          onTap: onMaximize,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? scheme.primary
                    : matched
                        ? scheme.tertiary
                        : cell.onActivePath
                            ? scheme.outlineVariant
                            : scheme.outlineVariant.withValues(alpha: 0.5),
                width: selected || matched ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The question fills the card (the assistant reply is read
                // mode only — navigate mode stays a map of prompts).
                Expanded(
                  child: Text(
                    cell.turn.promptMd.isEmpty
                        ? '(no prompt)'
                        : _collapseWhitespace(cell.turn.promptMd),
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _metaLine(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: scheme.outline),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _metaLine(BuildContext context) {
    final parts = <String>[
      if (cell.turn.createTime case final millis?)
        MaterialLocalizations.of(context).formatShortDate(
          DateTime.fromMillisecondsSinceEpoch(millis),
        ),
      ?cell.turn.modelSlug,
      if (cell.childCount > 1) '⑂ ${cell.childCount}',
    ];
    return parts.join(' · ');
  }
}

String _collapseWhitespace(String text) =>
    text.replaceAll(RegExp(r'\s+'), ' ').trim();
