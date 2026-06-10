import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

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
  late String _focusedId = widget.initialTurnId;
  final _scrollController = ScrollController();

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
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  child: _TurnBody(turn: cell.turn),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
/// card (DESIGN.md §6 "the quick-button strip stays on top"): minimize exits
/// read mode, maximize is a no-op shown disabled, arrows move the *reading
/// focus*.
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Minimize',
            icon: const Icon(Icons.close_fullscreen),
            onPressed: onMinimize,
          ),
          const IconButton(
            tooltip: 'Maximize (read mode)',
            icon: Icon(Icons.open_in_full),
            onPressed: null,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                crumb,
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: theme.colorScheme.primary),
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
            onPressed:
                cell.down == null ? null : () => onNavigate(GridDirection.down),
          ),
          IconButton(
            tooltip: 'Go left',
            icon: const Icon(Icons.arrow_back),
            onPressed:
                cell.left == null ? null : () => onNavigate(GridDirection.left),
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

/// Navigate → read transition (DESIGN.md §6 "Rendering approach"): a route
/// whose page grows hero-style from the tapped cell's on-screen rect to the
/// read surface — the full screen on Android, a centered ~85% overlay over
/// the dimmed canvas on macOS/desktop. The canvas underneath keeps its
/// viewport.
class ReadModeRoute<T> extends PopupRoute<T> {
  ReadModeRoute({
    required this.sourceRect,
    required this.fullScreen,
    required this.child,
  });

  /// Global on-screen rect of the cell the transition starts from.
  final Rect sourceRect;

  /// Full-screen page (Android) vs centered overlay dialog (desktop).
  final bool fullScreen;

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
      final targetRect = fullScreen
          ? Offset.zero & size
          : Rect.fromCenter(
              center: size.center(Offset.zero),
              width: size.width * 0.85,
              height: size.height * 0.85,
            );
      return AnimatedBuilder(
        animation: animation,
        builder: (context, page) {
          final t = Curves.easeOutCubic.transform(animation.value);
          final rect = Rect.lerp(sourceRect, targetRect, t)!;
          final radius = lerpDouble(12, fullScreen ? 0 : 16, t)!;
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
