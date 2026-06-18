import 'dart:io';
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:path/path.dart' as p;

import '../data/db/database.dart';
import '../domain/grid_layout.dart';
import '../state/providers.dart';
import 'canvas/node_card.dart';

/// Read mode (DESIGN.md §6): the focused turn maximized — full prompt +
/// response markdown, collapsible reasoning — with the quick-button strip on
/// top. ↑/↓ walk the conversation like a transcript (parent/child along the
/// lane), ←/→ jump across branches at the same depth, with a breadcrumb
/// showing which branch you're on. Esc / minimize / back exits.
///
/// Pushed by the canvas inside a [ReadModeRoute]; focus changes are reported
/// back through [onFocusChanged] so navigate mode ends up centered on the
/// node just read.
class ReadOverlay extends ConsumerStatefulWidget {
  const ReadOverlay({
    super.key,
    required this.conversationId,
    required this.initialTurnId,
    this.onFocusChanged,
  });

  final String conversationId;
  final String initialTurnId;

  /// Called whenever the reading focus moves to another turn.
  final ValueChanged<String>? onFocusChanged;

  @override
  ConsumerState<ReadOverlay> createState() => _ReadOverlayState();
}

class _ReadOverlayState extends ConsumerState<ReadOverlay> {
  /// Drag-overscroll a swipe must accumulate to advance (Android).
  static const _swipeAdvanceThreshold = 64.0;

  late String _focusedId = widget.initialTurnId;
  final _scrollController = ScrollController();
  double _dragOverscroll = 0;

  @override
  void dispose() {
    _scrollController.dispose();
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
    final cell = layout.byId[_focusedId] ??
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
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: Focus(
        autofocus: true,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ReadHeader(
                title: graph.conversation.title,
                cell: cell,
                layout: layout,
                onNavigate: (direction) => _go(cell, direction),
                onMinimize: () => Navigator.of(context).maybePop(),
              ),
              const Divider(height: 1),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) =>
                      _onScrollNotification(notification, cell),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    // Always accept drags so swipe-to-advance works even
                    // when the turn fits on one screen.
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: _TurnBody(turn: cell.turn),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Android: swipe up/down also advances (DESIGN.md §6 read mode). Drag
  /// overscroll past the transcript's top/bottom edge accumulates; on
  /// release past the threshold the focus moves to the previous/next turn.
  /// Normal in-content scrolling never overscrolls, so it is unaffected.
  bool _onScrollNotification(ScrollNotification notification, GridCell cell) {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
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

  void _go(GridCell cell, GridDirection direction) {
    final target = switch (direction) {
      GridDirection.up => cell.up,
      GridDirection.down => cell.down,
      GridDirection.left => cell.left,
      GridDirection.right => cell.right,
    };
    if (target == null || target == _focusedId) return;
    setState(() => _focusedId = target);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    widget.onFocusChanged?.call(target);
  }
}

/// Quick-button strip + title + breadcrumb. Same buttons as the navigate
/// card (DESIGN.md §6 "the quick-button strip stays on top"): a single zoom
/// button minimizes back out of read mode (the navigate card's maximize), and
/// the arrows move the *reading focus*.
class _ReadHeader extends StatelessWidget {
  const _ReadHeader({
    required this.title,
    required this.cell,
    required this.layout,
    required this.onNavigate,
    required this.onMinimize,
  });

  final String title;
  final GridCell cell;
  final TurnGridLayout layout;
  final ValueChanged<GridDirection> onNavigate;
  final VoidCallback onMinimize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Compact icon buttons so the strip fits even when read mode fills a
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Minimize',
              icon: const Icon(Icons.close_fullscreen),
              onPressed: onMinimize,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title.isEmpty ? '(untitled)' : title,
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_breadcrumb() case final crumb?)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    crumb,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: theme.colorScheme.primary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
              ),
            Text(
              '${cell.row + 1} / ${layout.rowCount}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Go up',
              icon: const Icon(Icons.arrow_upward),
              onPressed:
                  cell.up == null ? null : () => onNavigate(GridDirection.up),
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

class _TurnBody extends ConsumerWidget {
  const _TurnBody({required this.turn});

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
            children: [GptMarkdown(thoughts)],
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
    final children = <Widget>[];
    var start = 0;
    for (final match in _assetMarker.allMatches(markdown)) {
      final before = markdown.substring(start, match.start).trim();
      if (before.isNotEmpty) children.add(GptMarkdown(before));
      children.add(AssetBlock(asset: assetsByPointer?[match.group(1)!]));
      start = match.end;
    }
    final tail = markdown.substring(start).trim();
    if (tail.isNotEmpty || children.isEmpty) children.add(GptMarkdown(tail));
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
    '.png', '.jpg', '.jpeg', '.gif', '.webp', '.bmp',
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
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
        ],
      ),
    );
  }
}

/// Navigate → read transition (DESIGN.md §6 "Rendering approach"): a route
/// whose page grows hero-style from the tapped cell's on-screen rect to the
/// read surface — the full screen on Android, filling the canvas pane on
/// macOS/desktop. The canvas underneath keeps its viewport.
class ReadModeRoute<T> extends PopupRoute<T> {
  ReadModeRoute({
    required this.sourceRect,
    required this.fullScreen,
    this.fillRect,
    required this.child,
  });

  /// Global on-screen rect of the cell the transition starts from.
  final Rect sourceRect;

  /// Full-screen page (Android) vs an overlay filling [fillRect] (desktop).
  final bool fullScreen;

  /// Desktop: the canvas pane's global rect the read surface grows to fill.
  /// Null (or [fullScreen]) → the whole window.
  final Rect? fillRect;

  final Widget child;

  @override
  Color? get barrierColor => Colors.black38;

  @override
  bool get barrierDismissible => !fullScreen;

  @override
  String? get barrierLabel => 'Exit read mode';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 220);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      final targetRect =
          fullScreen ? Offset.zero & size : (fillRect ?? Offset.zero & size);
      return AnimatedBuilder(
        animation: animation,
        builder: (context, page) {
          final t = Curves.easeOutCubic.transform(animation.value);
          final rect = Rect.lerp(sourceRect, targetRect, t)!;
          // The surface fills its region (window or canvas pane), so the
          // rounded "card" corners flatten as it opens.
          final radius = lerpDouble(12, 0, t)!;
          return Stack(
            children: [
              Positioned.fromRect(
                rect: rect,
                child: Material(
                  clipBehavior: Clip.antiAlias,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(radius),
                  child: Opacity(
                    // Content fades in over the back half of the rect's
                    // flight so the card seems to "open up".
                    opacity: ((t - 0.4) / 0.6).clamp(0.0, 1.0),
                    child: page,
                  ),
                ),
              ),
            ],
          );
        },
        child: child,
      );
    });
  }
}
