import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:path/path.dart' as p;

import '../data/db/database.dart';
import '../domain/grid_layout.dart';
import '../state/providers.dart';
import 'canvas/node_card.dart';

/// Read view (DESIGN.md §6): the conversation as a full-screen pager, one turn
/// at a time — full prompt + response markdown, collapsible reasoning, with a
/// quick-button strip on top. It is one of the two views the bottom-right
/// toggle switches between (the other is the graph), and is also where tapping
/// a node lands.
///
/// Navigation moves the *reading focus* one turn at a time, with a directional
/// slide between turns:
/// - ↑/↓ (arrows, buttons, or a vertical swipe past the transcript's edge) walk
///   the conversation like a transcript — parent/child along the branch.
/// - ←/→ (arrows, buttons, or a horizontal swipe) jump across branches at the
///   same depth, with a breadcrumb showing which branch you're on.
///
/// A turn taller than the screen scrolls normally; only an overscroll past the
/// top/bottom edge pages to the neighbour, so reading never fights paging.
/// Focus changes are reported through [onFocusChanged] so the shared selection
/// stays in sync; [onMinimize] (the quick-button strip's ⊖, or Esc) drops back
/// to the graph centered on the turn just read.
class ReadOverlay extends ConsumerStatefulWidget {
  const ReadOverlay({
    super.key,
    required this.conversationId,
    required this.initialTurnId,
    this.onFocusChanged,
    this.onMinimize,
  });

  final String conversationId;
  final String initialTurnId;

  /// Called whenever the reading focus moves to another turn.
  final ValueChanged<String>? onFocusChanged;

  /// Minimize back to the graph (⊖ / Esc). Null disables it.
  final VoidCallback? onMinimize;

  @override
  ConsumerState<ReadOverlay> createState() => _ReadOverlayState();
}

class _ReadOverlayState extends ConsumerState<ReadOverlay>
    with SingleTickerProviderStateMixin {
  /// Drag-overscroll a vertical swipe must accumulate to page up/down.
  static const _swipeAdvanceThreshold = 64.0;

  /// Horizontal fling velocity (px/s) that pages to an adjacent branch.
  static const _branchFlingThreshold = 320.0;

  late String _focusedId = widget.initialTurnId;
  double _dragOverscroll = 0;

  /// Explicitly grabbed on mount: when the reader cross-fades in over the graph
  /// the graph still holds keyboard focus, so plain `autofocus` would be
  /// ignored and the arrow/Esc shortcuts would go nowhere.
  final _focusNode = FocusNode(debugLabel: 'reader');

  /// Drives the slide between the outgoing and incoming turn.
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  String? _outgoingId;
  Animation<Offset> _outSlide = const AlwaysStoppedAnimation(Offset.zero);
  Animation<Offset> _inSlide = const AlwaysStoppedAnimation(Offset.zero);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
    _anim.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _outgoingId = null);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(conversationGraphProvider(widget.conversationId));
    return switch (async) {
      AsyncData(:final value) => _buildLoaded(context, value),
      AsyncError(:final error) => Center(child: Text('Failed to load: $error')),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  Widget _buildLoaded(BuildContext context, ConversationGraph graph) {
    final layout = graph.layout;
    if (layout.isEmpty) {
      return const Center(child: Text('This conversation has no turns.'));
    }
    // Reconcile across data refreshes (e.g. re-import while reading).
    final cell =
        layout.byId[_focusedId] ??
        layout.byId[layout.activePathIds.isNotEmpty
            ? layout.activePathIds.last
            : layout.cells.first.turn.id]!;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _go(cell, GridDirection.up),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _go(cell, GridDirection.down),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _go(cell, GridDirection.left),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _go(cell, GridDirection.right),
        const SingleActivator(LogicalKeyboardKey.escape): ?widget.onMinimize,
      },
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // A horizontal swipe pages across branches; the vertical scroll view
          // owns vertical drags, so the gesture arena keeps the two axes
          // separate (no diagonal paging).
          onHorizontalDragEnd: (details) => _onHorizontalDragEnd(details, cell),
          child: SafeArea(child: _animatedPage(layout, cell)),
        ),
      ),
    );
  }

  /// One whole turn "page": header, divider, and transcript stacked together,
  /// so a navigation slides the entire node as a unit instead of only the
  /// transcript moving under a header that stays put.
  Widget _page(TurnGridLayout layout, GridCell cell, {required bool live}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReadHeader(
          cell: cell,
          layout: layout,
          onNavigate: (direction) => _go(cell, direction),
        ),
        const Divider(height: 1),
        Expanded(child: _body(cell, live: live)),
      ],
    );
  }

  /// The reader page, or — mid-navigation — the outgoing page sliding away while
  /// the incoming one slides in. The outgoing page is inert ([IgnorePointer])
  /// and is dropped once the slide completes.
  Widget _animatedPage(TurnGridLayout layout, GridCell cell) {
    final live = _page(layout, cell, live: true);
    final outgoing = _outgoingId == null ? null : layout.byId[_outgoingId!];
    if (outgoing == null) return live;
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: SlideTransition(
              position: _outSlide,
              child: _page(layout, outgoing, live: false),
            ),
          ),
        ),
        Positioned.fill(
          child: SlideTransition(position: _inSlide, child: live),
        ),
      ],
    );
  }

  /// One turn's scrollable transcript. The [live] one also watches for an
  /// overscroll past its edges to page up/down; the outgoing snapshot doesn't.
  Widget _body(GridCell cell, {required bool live}) {
    final scroll = SingleChildScrollView(
      // Keyed by turn so each turn gets a fresh scroll position (starts at top).
      key: ValueKey('read-body-${cell.turn.id}'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
      // Cap the line length and center on a wide pane so the transcript keeps a
      // comfortable reading width instead of running edge to edge.
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: TurnBody(turn: cell.turn),
        ),
      ),
    );
    if (!live) return scroll;
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) => _onScroll(notification, cell),
      child: scroll,
    );
  }

  /// Vertical swipe-to-advance: drag overscroll past the transcript's top/
  /// bottom edge accumulates; on release past the threshold the focus pages to
  /// the previous/next turn. Normal in-content scrolling never overscrolls, so
  /// it is unaffected. (Drag-driven only — a mouse wheel has no [dragDetails]
  /// and so never pages; desktop uses the arrows.)
  bool _onScroll(ScrollNotification notification, GridCell cell) {
    if (_anim.isAnimating) return false;
    switch (notification) {
      case ScrollStartNotification():
        _dragOverscroll = 0;
      case OverscrollNotification(:final overscroll, :final dragDetails)
          when dragDetails != null:
        _dragOverscroll += overscroll;
      case ScrollEndNotification():
        final accumulated = _dragOverscroll;
        _dragOverscroll = 0;
        if (accumulated <= -_swipeAdvanceThreshold) {
          _go(cell, GridDirection.up); // swipe down at the top → previous
        } else if (accumulated >= _swipeAdvanceThreshold) {
          _go(cell, GridDirection.down); // swipe up at the bottom → next
        }
      default:
        break;
    }
    return false;
  }

  void _onHorizontalDragEnd(DragEndDetails details, GridCell cell) {
    if (_anim.isAnimating) return;
    final velocity = details.primaryVelocity ?? 0;
    if (velocity <= -_branchFlingThreshold) {
      _go(cell, GridDirection.right); // swipe left → next branch
    } else if (velocity >= _branchFlingThreshold) {
      _go(cell, GridDirection.left); // swipe right → previous branch
    }
  }

  /// Moves the reading focus one turn in [direction] with a directional slide.
  void _go(GridCell cell, GridDirection direction) {
    if (_anim.isAnimating) return;
    final target = switch (direction) {
      GridDirection.up => cell.up,
      GridDirection.down => cell.down,
      GridDirection.left => cell.left,
      GridDirection.right => cell.right,
    };
    if (target == null || target == _focusedId) return;

    // The incoming turn enters from the direction of travel; the outgoing one
    // leaves the opposite way.
    final (Offset outEnd, Offset inBegin) = switch (direction) {
      GridDirection.down => (const Offset(0, -1), const Offset(0, 1)),
      GridDirection.up => (const Offset(0, 1), const Offset(0, -1)),
      GridDirection.right => (const Offset(-1, 0), const Offset(1, 0)),
      GridDirection.left => (const Offset(1, 0), const Offset(-1, 0)),
    };
    final curve = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    _outSlide = Tween(begin: Offset.zero, end: outEnd).animate(curve);
    _inSlide = Tween(begin: inBegin, end: Offset.zero).animate(curve);

    setState(() {
      _outgoingId = _focusedId;
      _focusedId = target;
    });
    _anim.forward(from: 0);
    widget.onFocusChanged?.call(target);
  }
}

/// Breadcrumb + reading-focus arrows (DESIGN.md §6). Read mode shows no title —
/// the transcript itself is the content, so the strip stays minimal; minimizing
/// back to the graph is the bottom-right view toggle (or Esc), not a button
/// here.
@visibleForTesting
class ReadHeader extends StatelessWidget {
  const ReadHeader({
    super.key,
    required this.cell,
    required this.layout,
    required this.onNavigate,
  });

  final GridCell cell;
  final TurnGridLayout layout;
  final ValueChanged<GridDirection> onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Compact icon buttons so the strip fits even when the reader fills a
    // narrow canvas pane.
    return IconButtonTheme(
      data: IconButtonThemeData(
        style: IconButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          minimumSize: const Size(36, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        child: Row(
          children: [
            // No title in read mode, but the breadcrumb and counter still live
            // inside one slack-absorbing region (right-aligned within it) so
            // the navigation arrows stay pinned to a fixed spot on the right —
            // regardless of counter width or whether a breadcrumb is showing.
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_breadcrumb() case final crumb?)
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          crumb,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '${cell.row + 1} / ${layout.rowCount}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Go up',
              icon: const Icon(Icons.arrow_upward),
              onPressed: cell.up == null
                  ? null
                  : () => onNavigate(GridDirection.up),
            ),
            IconButton(
              tooltip: 'Go down',
              icon: const Icon(Icons.arrow_downward),
              onPressed: cell.down == null
                  ? null
                  : () => onNavigate(GridDirection.down),
            ),
            IconButton(
              tooltip: 'Go left',
              icon: const Icon(Icons.arrow_back),
              onPressed: cell.left == null
                  ? null
                  : () => onNavigate(GridDirection.left),
            ),
            IconButton(
              tooltip: 'Go right',
              icon: const Icon(Icons.arrow_forward),
              onPressed: cell.right == null
                  ? null
                  : () => onNavigate(GridDirection.right),
            ),
          ],
        ),
      ),
    );
  }

  /// "Branch i of n" across the cells at this depth (the ←/→ targets,
  /// DESIGN.md §6); null when the row has no sibling branches.
  String? _breadcrumb() {
    final rowCells = [
      for (final c in layout.cells)
        if (c.row == cell.row) c,
    ]..sort((a, b) => a.lane.compareTo(b.lane));
    if (rowCells.length < 2) return null;
    final index = rowCells.indexWhere((c) => c.turn.id == cell.turn.id);
    return '⑂ Branch ${index + 1} of ${rowCells.length}';
  }
}

/// The full body of one turn: the user prompt card, optional collapsible
/// reasoning, and the assistant response — markdown with `asset://` markers
/// resolved against `turn_assets`. Shared by the read view (one turn at a
/// time) and anywhere else a turn's full content is shown.
class TurnBody extends ConsumerWidget {
  const TurnBody({super.key, required this.turn});

  final Turn turn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Pointer id (basename of the copied file) → asset row, for resolving
    // `asset://` markers. Null while the rows load; missing assets have
    // path='' rows and resolve to the "not in export" placeholder.
    final assetRows = ref.watch(turnAssetsProvider(turn.id)).value;
    final assetsByPointer = assetRows == null
        ? null
        : {
            for (final asset in assetRows)
              if (asset.path.isNotEmpty)
                p.basenameWithoutExtension(asset.path): asset,
          };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (turn.promptMd.isNotEmpty)
          Card.filled(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('You', style: theme.textTheme.labelSmall),
                  const SizedBox(height: 8),
                  _MarkdownWithAssets(
                    markdown: turn.promptMd,
                    assetsByPointer: assetsByPointer,
                  ),
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
            children: [
              GptMarkdown(
                thoughts,
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            ],
          ),
        Text(
          turn.modelSlug == null
              ? 'Assistant'
              : 'Assistant · ${turn.modelSlug}',
          style: theme.textTheme.labelSmall,
        ),
        const SizedBox(height: 8),
        if (turn.responseMd.isEmpty)
          Text(
            '(no response)',
            style: TextStyle(color: theme.colorScheme.outline),
          )
        else
          _MarkdownWithAssets(
            markdown: turn.responseMd,
            assetsByPointer: assetsByPointer,
          ),
      ],
    );
  }
}

/// Markdown with the importer's `![image](asset://<pointerId>)` markers
/// resolved against `turn_assets` rows (M5): markdown segments interleaved
/// with [AssetBlock]s. The `asset://` URIs never reach the markdown renderer,
/// so nothing ever hits the network.
class _MarkdownWithAssets extends StatelessWidget {
  const _MarkdownWithAssets({
    required this.markdown,
    required this.assetsByPointer,
  });

  static final _assetMarker = RegExp(r'!\[image\]\(asset://([^)]+)\)');

  final String markdown;

  /// Pointer id → copied asset row; null while the rows are still loading.
  final Map<String, TurnAsset>? assetsByPointer;

  @override
  Widget build(BuildContext context) {
    // GptMarkdown's body spans don't inherit the ambient DefaultTextStyle's
    // color, so without an explicit style they render with a light-theme
    // (near-black) default — invisible on the dark read surface. Pin the color
    // to onSurface so the transcript is legible in both themes.
    final style = TextStyle(color: Theme.of(context).colorScheme.onSurface);
    final children = <Widget>[];
    var start = 0;
    for (final match in _assetMarker.allMatches(markdown)) {
      final before = markdown.substring(start, match.start).trim();
      if (before.isNotEmpty) children.add(GptMarkdown(before, style: style));
      children.add(AssetBlock(asset: assetsByPointer?[match.group(1)!]));
      start = match.end;
    }
    final tail = markdown.substring(start).trim();
    if (tail.isNotEmpty || children.isEmpty) {
      children.add(GptMarkdown(tail, style: style));
    }
    if (children.length == 1) return children.single;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: children,
    );
  }
}

/// One resolved turn asset inside the read-mode transcript: an image
/// rendered from the copied file, a generic attachment tile for non-image
/// files (e.g. a PDF, defensive — the export never pointer-references them),
/// or a "not included" placeholder when the export was missing the file
/// (path='' rows) or the rows are still loading.
@visibleForTesting
class AssetBlock extends StatelessWidget {
  const AssetBlock({super.key, required this.asset});

  static const _imageExtensions = {
    '.png',
    '.jpg',
    '.jpeg',
    '.gif',
    '.webp',
    '.bmp',
  };

  /// The copied asset, or null when missing/unresolved.
  final TurnAsset? asset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asset = this.asset;
    if (asset == null || asset.path.isEmpty) {
      return _tile(
        theme,
        icon: Icons.image_not_supported_outlined,
        label: 'Image not included in the export',
      );
    }
    final extension = p.extension(asset.path).toLowerCase();
    if (!_imageExtensions.contains(extension)) {
      return _tile(
        theme,
        icon: Icons.attach_file,
        label: asset.originalName ?? p.basename(asset.path),
        detail: 'Preview not available',
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: (asset.width ?? 480).toDouble().clamp(64, 480),
          maxHeight: 480,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(asset.path),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => _tile(
              theme,
              icon: Icons.broken_image_outlined,
              label: asset.originalName ?? p.basename(asset.path),
              detail: 'Could not decode image',
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(
    ThemeData theme, {
    required IconData icon,
    required String label,
    String? detail,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              detail == null ? label : '$label · $detail',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
