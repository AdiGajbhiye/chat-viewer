import 'package:flutter/material.dart';

import '../../domain/grid_layout.dart';

/// Direction for grid navigation (quick buttons / arrow keys).
enum GridDirection { up, down, left, right }

/// Collapsed turn card for navigate mode (DESIGN.md §6 "Node card & quick
/// buttons"): quick-button strip, user query (max 2 lines), meta line with
/// time · model · fork count. Uniform size — the parent positions it in a
/// fixed [CanvasMetrics] cell.
class NodeCard extends StatelessWidget {
  const NodeCard({
    super.key,
    required this.cell,
    required this.selected,
    required this.onNavigate,
    required this.onMaximize,
  });

  final GridCell cell;
  final bool selected;
  final ValueChanged<GridDirection> onNavigate;

  /// Enter read mode for this turn (card tap or ⊕, DESIGN.md §6).
  final VoidCallback onMaximize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dimmed = !cell.onActivePath && !selected;

    return Opacity(
      opacity: dimmed ? 0.6 : 1,
      child: Material(
        color: cell.onActivePath
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
                    : cell.onActivePath
                        ? scheme.outlineVariant
                        : scheme.outlineVariant.withValues(alpha: 0.5),
                width: selected ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _QuickButtonStrip(
                  cell: cell,
                  onNavigate: onNavigate,
                  onMaximize: onMaximize,
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Text(
                    cell.turn.promptMd.isEmpty
                        ? '(no prompt)'
                        : _collapseWhitespace(cell.turn.promptMd),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
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

/// ⊖ ⊕ · ↑ ↓ ← → (DESIGN.md §6). In navigate mode the arrows move the
/// *selection*; minimize is a no-op shown disabled; maximize enters read
/// mode.
class _QuickButtonStrip extends StatelessWidget {
  const _QuickButtonStrip({
    required this.cell,
    required this.onNavigate,
    required this.onMaximize,
  });

  final GridCell cell;
  final ValueChanged<GridDirection> onNavigate;
  final VoidCallback onMaximize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _QuickButton(
          icon: Icons.close_fullscreen,
          tooltip: 'Minimize',
          onPressed: null,
        ),
        _QuickButton(
          icon: Icons.open_in_full,
          tooltip: 'Maximize (read mode)',
          onPressed: onMaximize,
        ),
        const Spacer(),
        _QuickButton(
          icon: Icons.arrow_upward,
          tooltip: 'Go up',
          onPressed: cell.up == null ? null : () => onNavigate(GridDirection.up),
        ),
        _QuickButton(
          icon: Icons.arrow_downward,
          tooltip: 'Go down',
          onPressed:
              cell.down == null ? null : () => onNavigate(GridDirection.down),
        ),
        _QuickButton(
          icon: Icons.arrow_back,
          tooltip: 'Go left',
          onPressed:
              cell.left == null ? null : () => onNavigate(GridDirection.left),
        ),
        _QuickButton(
          icon: Icons.arrow_forward,
          tooltip: 'Go right',
          onPressed:
              cell.right == null ? null : () => onNavigate(GridDirection.right),
        ),
      ],
    );
  }
}

class _QuickButton extends StatelessWidget {
  const _QuickButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 26,
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
        iconSize: 14,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          minimumSize: const Size(26, 26),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
