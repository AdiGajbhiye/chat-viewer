import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:path/path.dart' as p;

import '../data/db/database.dart';
import '../domain/grid_layout.dart';
import '../domain/markdown_blocks.dart';
import '../state/branching.dart';
import '../state/facts.dart';
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

  /// Whether the right-hand-side generated-index panel is shown on wide
  /// layouts (DESIGN.md §10). Default on; the header toggle hides it to reclaim
  /// the width. Below the wide breakpoint the panel never shows regardless —
  /// the index falls back to a collapsible section at the foot of the body.
  bool _showIndexPanel = true;

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

  /// A chunk action just forked a child branch; once it lands in the layout
  /// (the turns stream re-emits after the insert) the next build glides focus
  /// onto it. Held here because the new row isn't in the layout the instant the
  /// fork is requested.
  String? _pendingBranchId;

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

    // A freshly forked branch has now appeared in the layout: glide focus onto
    // it, sliding right when it took a new lane (the usual horizontal branch),
    // otherwise down (the source turn was a leaf, so the child continues below).
    if (_pendingBranchId case final pendingId?
        when layout.byId.containsKey(pendingId)) {
      _pendingBranchId = null;
      final newCell = layout.byId[pendingId]!;
      final direction = newCell.lane > cell.lane
          ? GridDirection.right
          : GridDirection.down;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _animateTo(pendingId, direction);
      });
    }

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
    // One LayoutBuilder for the whole page so the header's panel toggle and the
    // body's panel both key off the same width: the toggle only appears when a
    // panel can actually fit, and the two never disagree.
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _indexPanelBreakpoint;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ReadHeader(
              cell: cell,
              layout: layout,
              onNavigate: (direction) => _go(cell, direction),
              indexPanelShown: _showIndexPanel,
              // The toggle is meaningful only on wide layouts; below the
              // breakpoint the index lives at the foot of the body, with no
              // panel to reclaim.
              onToggleIndexPanel: wide
                  ? () => setState(() => _showIndexPanel = !_showIndexPanel)
                  : null,
            ),
            const Divider(height: 1),
            Expanded(child: _body(cell, live: live, wide: wide)),
          ],
        );
      },
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

  /// Reader's available width at/above which the generated index lives in a
  /// persistent RHS panel (DESIGN.md §10). Below it the panel can't fit beside
  /// a comfortable reading column, so the index falls back to a collapsible
  /// section at the foot of the body instead.
  static const _indexPanelBreakpoint = 720.0;

  /// Width of the RHS index panel column on wide layouts.
  static const _indexPanelWidth = 320.0;

  /// One turn's body. On a wide pane it's a [Row]: the scrollable transcript
  /// (capped to a comfortable reading width + centered *within its own area*)
  /// on the left, and the focused turn's generated index as a fixed-width
  /// panel on the right (DESIGN.md §10), separated by a subtle divider. The
  /// panel scrolls independently. Below the breakpoint (narrow windows /
  /// Android) — or when the header toggle hides the panel — the body is just
  /// the transcript, and the index falls back to a collapsible foot section.
  ///
  /// The [live] transcript also watches for an overscroll past its edges to
  /// page up/down; the outgoing snapshot mid-slide doesn't. [wide] is decided
  /// by [_page]'s LayoutBuilder against [_indexPanelBreakpoint].
  Widget _body(GridCell cell, {required bool live, required bool wide}) {
    final showPanel = wide && _showIndexPanel;
    // The collapsible foot section only appears when the side panel isn't
    // (narrow layout, or the panel toggled off), so the index is never shown
    // twice — and never lost.
    final transcript = _transcript(cell, live: live, showFootIndex: !showPanel);
    if (!showPanel) return transcript;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: transcript),
        const VerticalDivider(width: 1),
        SizedBox(
          width: _indexPanelWidth,
          child: _TurnIndexPanel(turnId: cell.turn.id),
        ),
      ],
    );
  }

  /// The transcript column: capped to a comfortable reading width and centered
  /// within whatever horizontal space it's given. TurnBody is the scrollable
  /// (a lazy ListView), so a long transcript lays out only the on-screen chunks
  /// (DESIGN.md §6 "Performance").
  Widget _transcript(
    GridCell cell, {
    required bool live,
    required bool showFootIndex,
  }) {
    final body = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: TurnBody(
          // Keyed by turn so each turn gets a fresh scroll position (top).
          key: ValueKey('read-body-${cell.turn.id}'),
          turn: cell.turn,
          // Only the live page is interactive; the outgoing snapshot mid-slide
          // can't fork branches.
          onBranched: live ? _onBranchCreated : null,
          showFootIndex: showFootIndex,
        ),
      ),
    );
    if (!live) return body;
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) => _onScroll(notification, cell),
      child: body,
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
    if (target == null) return;
    _animateTo(target, direction);
  }

  /// Slides focus to [target], which enters from [direction] while the outgoing
  /// page leaves the opposite way. Shared by neighbour navigation ([_go]) and
  /// jumping to a freshly-forked branch.
  void _animateTo(String target, GridDirection direction) {
    if (target == _focusedId) return;
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

  /// A chunk action forked [newTurnId] off the focused turn; remember it so the
  /// next build (after the turns stream re-emits with the new row) glides focus
  /// onto the new branch.
  void _onBranchCreated(String newTurnId) {
    if (!mounted) return;
    setState(() => _pendingBranchId = newTurnId);
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
    this.indexPanelShown = true,
    this.onToggleIndexPanel,
  });

  final GridCell cell;
  final TurnGridLayout layout;
  final ValueChanged<GridDirection> onNavigate;

  /// Whether the RHS generated-index panel is currently shown (drives the
  /// header toggle's icon/tooltip). Only relevant on wide layouts; the toggle
  /// is hidden when [onToggleIndexPanel] is null.
  final bool indexPanelShown;

  /// Show/hide the RHS index panel. Null hides the toggle entirely.
  final VoidCallback? onToggleIndexPanel;

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
            if (onToggleIndexPanel != null) ...[
              const SizedBox(width: 4),
              IconButton(
                tooltip: indexPanelShown
                    ? 'Hide generated index'
                    : 'Show generated index',
                icon: Icon(
                  indexPanelShown
                      ? Icons.auto_awesome
                      : Icons.auto_awesome_outlined,
                ),
                isSelected: indexPanelShown,
                onPressed: onToggleIndexPanel,
              ),
            ],
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
    return 'Branch ${index + 1} of ${rowCells.length}';
  }
}

/// The full body of one turn: the user prompt card, optional collapsible
/// reasoning, and the assistant response — markdown with `asset://` markers
/// resolved against `turn_assets`. Shared by the read view (one turn at a
/// time) and anywhere else a turn's full content is shown.
class TurnBody extends ConsumerWidget {
  const TurnBody({
    super.key,
    required this.turn,
    this.onBranched,
    this.showFootIndex = true,
  });

  final Turn turn;

  /// Called with the new turn's id when a chunk action (Ask AI / Explain /
  /// Expand) forks a child branch off [turn], so the reader can glide focus to
  /// it. Null in non-interactive contexts (e.g. the outgoing page mid-slide).
  final ValueChanged<String>? onBranched;

  /// Whether to append the collapsible "Generated index" section at the foot of
  /// the body. The reader sets this false on wide layouts, where the index
  /// lives in a persistent RHS panel instead (DESIGN.md §10) — so it isn't
  /// shown twice.
  final bool showFootIndex;

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
    void onChunkAction(ChunkAction action, String chunk) =>
        _handleChunkAction(context, ref, action, chunk);
    final generating = ref.watch(generatingTurnsProvider).contains(turn.id);
    // Strip ChatGPT web citation markers (PUA tokens) that render as tofu.
    final prompt = stripChatMarkers(turn.promptMd);
    final response = stripChatMarkers(turn.responseMd);
    final thoughts =
        turn.thoughtsMd == null ? null : stripChatMarkers(turn.thoughtsMd!);
    return ListView(
      // TurnBody is the reader's scrollable. A lazy ListView lays out only the
      // on-screen transcript pieces, so paging to a long turn no longer lays the
      // whole thing out up front (DESIGN.md §6 "Performance"). The chunks are
      // flattened into this list (not nested in a Column) so each lays out only
      // when scrolled into view.
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        if (prompt.isNotEmpty)
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
                    markdown: prompt,
                    assetsByPointer: assetsByPointer,
                  ),
                ],
              ),
            ),
          ),
        if (thoughts != null && thoughts.isNotEmpty)
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
        if (response.isEmpty)
          generating
              ? const _GeneratingIndicator()
              : Text(
                  '(no response)',
                  style: TextStyle(color: theme.colorScheme.outline),
                )
        else ...[
          ..._responseChunks(
            markdown: response,
            assetsByPointer: assetsByPointer,
            onAction: onChunkAction,
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          if (generating) ...[
            const SizedBox(height: 12),
            const _GeneratingIndicator(),
          ],
        ],
        // The generated index for this turn (DESIGN.md §10). On narrow layouts
        // it's a collapsible metadata section at the very end of the body so it
        // never pushes the conversation content down — a trailing ListView
        // item, so it costs nothing until scrolled into view. On wide layouts
        // the reader shows it in a persistent RHS panel instead and sets
        // [showFootIndex] false, so it isn't shown twice.
        if (showFootIndex) ...[
          const SizedBox(height: 8),
          _TurnIndexSection(turnId: turn.id),
        ],
      ],
    );
  }

  void _handleChunkAction(
    BuildContext context,
    WidgetRef ref,
    ChunkAction action,
    String chunk,
  ) {
    final service = ref.read(branchServiceProvider);
    switch (action) {
      case ChunkAction.copy:
        Clipboard.setData(ClipboardData(text: chunk));
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text('Copied passage'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      case ChunkAction.explain:
        _branch(service, 'Explain this passage in more detail:', chunk);
      case ChunkAction.expand:
        _branch(service, 'Expand on this with concrete examples:', chunk);
      case ChunkAction.ask:
        _askThenBranch(context, service, chunk);
      case ChunkAction.commit:
        _commit(context, ref, chunk);
    }
  }

  /// Promotes [chunk] into the committed-facts layer (DESIGN.md §10, Layer 2):
  /// a project-scoped, session-pinned, turn-sourced fact. Embedding + persist
  /// run offline via [factsServiceProvider]; the source turn's conversation
  /// supplies the projectId (and pins the fact to the session). Gives a SnackBar
  /// just like the Copy action — committing is settled, not a fork.
  Future<void> _commit(
    BuildContext context,
    WidgetRef ref,
    String chunk,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final db = ref.read(databaseProvider);
    final conversation = await (db.select(db.conversations)
          ..where((c) => c.id.equals(turn.conversationId)))
        .getSingleOrNull();
    if (conversation == null) return;
    await ref.read(factsServiceProvider).commitFact(
          text: stripChatMarkers(chunk).trim(),
          sourceTurnIds: [turn.id],
          projectId: conversation.projectId,
          conversationId: conversation.id,
        );
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Committed as a fact'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Pops a composer prefilled with the quoted [chunk]; on submit, forks a
  /// branch whose prompt is the user's question followed by the quote.
  Future<void> _askThenBranch(
    BuildContext context,
    BranchService service,
    String chunk,
  ) async {
    final question = await showDialog<String>(
      context: context,
      builder: (_) => _AskChunkDialog(chunk: chunk),
    );
    final trimmed = question?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    await _branch(service, trimmed, chunk);
  }

  Future<void> _branch(
    BranchService service,
    String instruction,
    String chunk,
  ) async {
    final branch = await service.branchFrom(
      parent: turn,
      prompt: '$instruction\n\n${_blockquote(chunk)}',
    );
    onBranched?.call(branch.id);
  }

  /// Renders [chunk] as a markdown blockquote so the authored branch's prompt
  /// shows what it was asked about, set off from the instruction/question.
  static String _blockquote(String chunk) => chunk
      .split('\n')
      .map((line) => line.isEmpty ? '>' : '> $line')
      .join('\n');
}

/// The persistent right-hand-side "Generated index" panel shown beside the
/// transcript on wide layouts (DESIGN.md §10 "Proposition index"): the focused
/// turn's ~5 atomic propositions (each prefixed with its open-vocab aspect tag)
/// and a wrap of the entities it mentions. Always-on metadata margin — unlike
/// the narrow-layout [_TurnIndexSection] it isn't collapsible; it just scrolls
/// independently of the transcript when long.
///
/// Loads once per turn via [turnIndexProvider] (cached by turnId), so paging to
/// a turn re-subscribes once — not per frame. A turn that hasn't been indexed
/// yet shows a subtle "Not indexed yet" line instead of an empty panel.
class _TurnIndexPanel extends ConsumerWidget {
  const _TurnIndexPanel({required this.turnId});

  final String turnId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final outline = theme.colorScheme.outline;
    final async = ref.watch(turnIndexProvider(turnId));
    final index = async.value;

    Widget framed(Widget child) => Padding(
          key: const Key('read-index-panel'),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: child,
        );

    // While the one-shot read is still in flight, render nothing (no flicker);
    // it resolves to either the populated index or the not-indexed line.
    if (index == null) return framed(const SizedBox.shrink());

    if (index.isEmpty) {
      return framed(
        Row(
          children: [
            Icon(Icons.auto_awesome_outlined, size: 14, color: outline),
            const SizedBox(width: 8),
            Text(
              'Not indexed yet',
              style: theme.textTheme.bodySmall?.copyWith(color: outline),
            ),
          ],
        ),
      );
    }

    final count = index.propositions.length;
    // Scrolls independently of the transcript when the index is long.
    return framed(
      ListView(
        primary: false,
        padding: EdgeInsets.zero,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_outlined, size: 18, color: outline),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Generated index · $count proposition'
                  '${count == 1 ? '' : 's'}',
                  style: theme.textTheme.labelLarge?.copyWith(color: outline),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final prop in index.propositions)
            _PropositionBullet(text: prop.text, aspect: prop.aspect),
          if (index.entities.isNotEmpty) ...[
            const SizedBox(height: 8),
            _IndexEntityChips(names: index.entities),
          ],
        ],
      ),
    );
  }
}

/// The collapsible "Generated index" section at the foot of a turn (DESIGN.md
/// §10 "Proposition index"): the human-visible view of what indexing wrote for
/// this turn — its ~5 atomic propositions (each prefixed with its open-vocab
/// aspect tag) and a wrap of the entities it mentions. Visually distinct and
/// **collapsed by default**: it's metadata, not conversation. Used on narrow
/// layouts (below the RHS-panel breakpoint), where the [_TurnIndexPanel] won't
/// fit beside a comfortable reading column.
///
/// Mirrors the reasoning toggle's [ExpansionTile] pattern. Loads once per turn
/// via [turnIndexProvider] (cached by turnId), so it costs nothing per frame. A
/// turn that hasn't been indexed yet (indexing runs lazily on open) shows a
/// subtle "Not indexed yet" line instead of an empty box.
class _TurnIndexSection extends ConsumerWidget {
  const _TurnIndexSection({required this.turnId});

  final String turnId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(turnIndexProvider(turnId));
    final index = async.value;
    // While the one-shot read is still in flight, render nothing (no flicker);
    // it resolves to either the populated index or the not-indexed line.
    if (index == null) return const SizedBox.shrink();

    final outline = theme.colorScheme.outline;
    if (index.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(Icons.auto_awesome_outlined, size: 14, color: outline),
            const SizedBox(width: 8),
            Text(
              'Not indexed yet',
              style: theme.textTheme.bodySmall?.copyWith(color: outline),
            ),
          ],
        ),
      );
    }

    final count = index.propositions.length;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      leading: Icon(Icons.auto_awesome_outlined, size: 18, color: outline),
      title: Text(
        'Generated index · $count proposition${count == 1 ? '' : 's'}',
        style: theme.textTheme.labelLarge?.copyWith(color: outline),
      ),
      childrenPadding: const EdgeInsets.only(left: 4, bottom: 12),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final prop in index.propositions)
          _PropositionBullet(text: prop.text, aspect: prop.aspect),
        if (index.entities.isNotEmpty) ...[
          const SizedBox(height: 8),
          _IndexEntityChips(names: index.entities),
        ],
      ],
    );
  }
}

/// One proposition as a bullet, its open-vocab aspect tag rendered as a small
/// `[aspect]` chip prefix (omitted when the proposition has no aspect). Short
/// plain text — a [Text], not markdown.
class _PropositionBullet extends StatelessWidget {
  const _PropositionBullet({required this.text, required this.aspect});

  final String text;
  final String? aspect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final aspect = this.aspect?.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 8),
            child: Icon(Icons.circle, size: 6, color: scheme.outline),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  if (aspect != null && aspect.isNotEmpty)
                    TextSpan(
                      text: '[$aspect] ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  TextSpan(text: text),
                ],
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurface),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A wrap of the turn's entity chips, echoing the wiki's entity-chip look
/// (`wiki_view.dart`) for visual consistency. Non-interactive here — the reader
/// surfaces the index, it isn't the wiki's hyperlink graph.
class _IndexEntityChips extends StatelessWidget {
  const _IndexEntityChips({required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final name in names)
          Chip(
            avatar: const Icon(Icons.link, size: 16),
            label: Text(name),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
      ],
    );
  }
}

/// A small spinner + label shown in the reader while a forked branch's
/// response is still streaming in from the provider (DESIGN.md §9 pending
/// state). Driven by [generatingTurnsProvider].
class _GeneratingIndicator extends StatelessWidget {
  const _GeneratingIndicator();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: color),
        ),
        const SizedBox(width: 10),
        Text('Generating…', style: TextStyle(color: color)),
      ],
    );
  }
}

/// Markdown with the importer's `![image](asset://<pointerId>)` markers
/// resolved against `turn_assets` rows (M5): markdown segments interleaved
/// with [AssetBlock]s. The `asset://` URIs never reach the markdown renderer,
/// so nothing ever hits the network.
/// The importer's image marker: `![image](asset://<pointerId>)`. Matched out
/// before markdown rendering so `asset://` URIs never reach the renderer
/// (nothing ever hits the network). Shared by [_MarkdownWithAssets] (prompt /
/// reasoning) and [_ChunkedResponse] (the chunked response).
final _kAssetMarker = RegExp(r'!\[image\]\(asset://([^)]+)\)');

class _MarkdownWithAssets extends StatelessWidget {
  const _MarkdownWithAssets({
    required this.markdown,
    required this.assetsByPointer,
  });

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
    for (final match in _kAssetMarker.allMatches(markdown)) {
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

/// The actions a response chunk's hover toolbar can fire. [ask] / [explain] /
/// [expand] each fork a child branch off the turn (DESIGN.md §9 forking; the
/// answer comes from the pluggable [LlmProvider]); [commit] promotes the passage
/// into the committed-facts layer (DESIGN.md §10, Layer 2); [copy] is a local
/// clipboard copy.
enum ChunkAction { ask, explain, expand, commit, copy }

/// The assistant response, split into block-level chunks (paragraphs, lists,
/// code fences — [splitMarkdownBlocks]) interleaved with [AssetBlock]s, returned
/// as a flat list of widgets. Flat (not wrapped in a Column) so the reader's
/// [ListView] lays out only the on-screen chunks — paging to a long turn no
/// longer lays the whole transcript out at once. Each text chunk carries its own
/// hover toolbar so any passage can be asked about, explained, expanded, or
/// copied without leaving the reader. [style] pins the color to onSurface
/// because GptMarkdown spans don't inherit the ambient DefaultTextStyle color.
List<Widget> _responseChunks({
  required String markdown,
  required Map<String, TurnAsset>? assetsByPointer,
  required void Function(ChunkAction action, String chunk) onAction,
  required TextStyle style,
}) {
  final children = <Widget>[];

  void addBlocks(String md) {
    for (final block in splitMarkdownBlocks(md)) {
      children.add(
        _ResponseChunk(markdown: block, style: style, onAction: onAction),
      );
    }
  }

  var start = 0;
  for (final match in _kAssetMarker.allMatches(markdown)) {
    addBlocks(markdown.substring(start, match.start));
    children.add(AssetBlock(asset: assetsByPointer?[match.group(1)!]));
    start = match.end;
  }
  addBlocks(markdown.substring(start));

  return children;
}

/// One response chunk: its markdown plus a top-right toolbar that fades in on
/// hover (desktop) or after a long-press (touch), with the chunk subtly
/// highlighted while active. The toolbar is the per-passage "context menu".
class _ResponseChunk extends StatefulWidget {
  const _ResponseChunk({
    required this.markdown,
    required this.style,
    required this.onAction,
  });

  final String markdown;
  final TextStyle style;
  final void Function(ChunkAction action, String chunk) onAction;

  @override
  State<_ResponseChunk> createState() => _ResponseChunkState();
}

class _ResponseChunkState extends State<_ResponseChunk> {
  bool _hovering = false;
  bool _pinned = false;
  bool get _active => _hovering || _pinned;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            // Touch has no hover; a long-press pins the toolbar open.
            onLongPress: () => setState(() => _pinned = !_pinned),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              // Fill the column's width so the highlight spans the full reading
              // column, not just the text — the Stack hands loose constraints,
              // so without this the box shrinks to the markdown's intrinsic
              // width (a short line gets a stubby highlight).
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: _active
                    ? scheme.surfaceContainerHighest.withValues(alpha: 0.6)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: GptMarkdown(widget.markdown, style: widget.style),
            ),
          ),
          Positioned(
            top: -6,
            right: 2,
            child: IgnorePointer(
              ignoring: !_active,
              child: AnimatedOpacity(
                opacity: _active ? 1 : 0,
                duration: const Duration(milliseconds: 120),
                child: _ChunkToolbar(
                  onAction: (action) {
                    if (_pinned) setState(() => _pinned = false);
                    widget.onAction(action, widget.markdown);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The small pill of icon buttons shown at a chunk's top-right corner.
class _ChunkToolbar extends StatelessWidget {
  const _ChunkToolbar({required this.onAction});

  final ValueChanged<ChunkAction> onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 2,
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ChunkToolbarButton(
              icon: Icons.chat_bubble_outline,
              tooltip: 'Ask AI about this (new branch)',
              onPressed: () => onAction(ChunkAction.ask),
            ),
            _ChunkToolbarButton(
              icon: Icons.lightbulb_outline,
              tooltip: 'Explain this passage',
              onPressed: () => onAction(ChunkAction.explain),
            ),
            _ChunkToolbarButton(
              icon: Icons.unfold_more,
              tooltip: 'Expand on this',
              onPressed: () => onAction(ChunkAction.expand),
            ),
            _ChunkToolbarButton(
              icon: Icons.push_pin_outlined,
              tooltip: 'Commit as a fact',
              onPressed: () => onAction(ChunkAction.commit),
            ),
            _ChunkToolbarButton(
              icon: Icons.content_copy,
              tooltip: 'Copy passage',
              onPressed: () => onAction(ChunkAction.copy),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChunkToolbarButton extends StatelessWidget {
  const _ChunkToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 28,
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
        iconSize: 16,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          minimumSize: const Size(30, 28),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

/// Composer for the chunk toolbar's "Ask AI" action: shows the quoted passage
/// and takes a free-form question. Returns the question text (pop value), or
/// null on cancel.
class _AskChunkDialog extends StatefulWidget {
  const _AskChunkDialog({required this.chunk});

  final String chunk;

  @override
  State<_AskChunkDialog> createState() => _AskChunkDialogState();
}

class _AskChunkDialogState extends State<_AskChunkDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Ask about this passage'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 120),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  widget.chunk,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'What do you want to ask about this?',
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Ask & branch')),
      ],
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
