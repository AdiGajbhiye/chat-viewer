import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../domain/grid_layout.dart';
import '../../state/providers.dart';
import '../read_view.dart';
import 'canvas_metrics.dart';
import 'canvas_viewport.dart';
import 'edge_painter.dart';
import 'node_card.dart';

/// The two views the bottom-right toggle switches between: [graph] is the
/// pannable canvas (the map); [read] is the full-screen reading pager. Both are
/// inline (no pushed route), so the toggle stays visible and switching them
/// cross-fades.
enum CanvasViewMode { graph, read }

/// The conversation surface (DESIGN.md §6): the turn tree on a pannable/zoomable
/// grid canvas — uniform collapsed cards, edges with active-path emphasis,
/// viewport culling, arrow-key/button selection — cross-faded with the reading
/// pager ([ReadOverlay]). Tapping a node, or the toggle's read button, switches
/// to the reader on the focused turn. Focused turn and viewport are persisted
/// per conversation in `canvas_state` and restored on open; the conversation
/// always opens on the graph (the reader is never auto-restored), so selecting
/// a conversation never jumps straight into reading.
class CanvasView extends ConsumerStatefulWidget {
  const CanvasView({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<CanvasView> createState() => _CanvasViewState();
}

class _CanvasViewState extends ConsumerState<CanvasView>
    with SingleTickerProviderStateMixin {
  final _viewport = CanvasViewport();
  String? _selectedId;
  CanvasViewMode _viewMode = CanvasViewMode.graph;
  bool _initialized = false;
  Size _viewSize = Size.zero;

  /// Bumped each time the reader is (re)entered so it rebuilds seated on the
  /// current selection. Focus changes *within* the reader leave it untouched,
  /// so paging through turns doesn't reset the reader.
  int _readEpoch = 0;

  /// In-canvas search state (DESIGN.md §4 FTS): matching turn ids in rank
  /// order, the search box's current query, and a cursor into the matches
  /// (-1 = nothing stepped to yet). [_matchedSet] mirrors [_matchedIds] for
  /// O(1) per-card highlight lookups during the build.
  List<String> _matchedIds = const [];
  Set<String> _matchedSet = const {};
  int _matchIndex = -1;
  bool _searching = false;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode(debugLabel: 'canvas search');

  /// The graph canvas's keyboard focus, re-grabbed when returning from the
  /// reader (the cross-fade means plain `autofocus` won't reclaim it).
  final _graphFocusNode = FocusNode(debugLabel: 'graph canvas');

  /// Captured in [initState]: the dispose-time flush below must not touch
  /// [ref] (the ProviderScope above may already be disposed during app
  /// teardown).
  late final AppDatabase _db;

  /// Debounces viewport-driven `canvas_state` writes (pan/zoom notifies per
  /// frame). 300 ms so the widget tests' standard ≥350 ms post-gesture pump
  /// flushes it; [dispose] flushes whatever is still pending.
  Timer? _saveTimer;

  // Scale-gesture bookkeeping (drag pan + pinch zoom share one recognizer).
  Offset _lastFocal = Offset.zero;
  double _lastGestureScale = 1;

  /// Glides the viewport between nodes during arrow / search navigation so the
  /// selection appears to travel across the map instead of the view snapping to
  /// it. Tweens [_navFrom] → [_navTo] (translation only, current scale held);
  /// timed to match the reader's page-slide so the two views feel the same.
  late final AnimationController _navAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  Offset? _navFrom;
  Offset? _navTo;

  @override
  void initState() {
    super.initState();
    _db = ref.read(databaseProvider);
    _viewport.addListener(_onViewportChanged);
    _navAnim.addListener(_onNavAnimTick);
  }

  @override
  void dispose() {
    _viewport.removeListener(_onViewportChanged);
    _navAnim.dispose();
    if (_saveTimer?.isActive ?? false) {
      _persistState(); // flush the pending debounced write
    }
    _saveTimer?.cancel();
    _viewport.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _graphFocusNode.dispose();
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
    // Wait for the persisted canvas state before the first layout pass so
    // selection/viewport/mode can be restored (one-shot read; load failures
    // just mean defaults).
    final savedAsync = ref.watch(canvasStateProvider(widget.conversationId));
    if (!_initialized && savedAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final saved = savedAsync.value;
    _reconcileSelection(graph, saved);
    _reconcileSearch(layout);

    return LayoutBuilder(
      builder: (context, constraints) {
        _viewSize = constraints.biggest;
        if (!_initialized) {
          _initialized = true;
          _restore(layout, saved);
        }
        return Stack(
          children: [
            // The graph is always the backdrop, so a margin of canvas stays
            // visible around the inset reader. Excluded from focus traversal
            // while reading so arrow keys reach the reader, not the map behind.
            Positioned.fill(
              child: ExcludeFocus(
                excluding: _viewMode == CanvasViewMode.read,
                child: _buildGraph(context, layout),
              ),
            ),
            // The reader floats over the graph as an inset card; it fades/scales
            // in and the exposed canvas around it is tappable to return to the
            // map.
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                layoutBuilder: (current, previous) => Stack(
                  fit: StackFit.expand,
                  children: [...previous, ?current],
                ),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.98, end: 1.0).animate(animation),
                    child: child,
                  ),
                ),
                child: _viewMode == CanvasViewMode.read
                    ? _buildReader(context, layout)
                    : const SizedBox.shrink(key: ValueKey('no-reader')),
              ),
            ),
            // Find-in-conversation is graph-only; the reader is navigated by
            // paging through turns.
            if (_viewMode == CanvasViewMode.graph)
              Positioned(
                top: 8,
                right: 8,
                child: CanvasSearchBar(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  matchCount: _matchedIds.length,
                  currentMatch: _matchIndex < 0 ? 0 : _matchIndex + 1,
                  searching: _searching,
                  onChanged: (_) => setState(() => _matchIndex = -1),
                  onClear: _clearSearch,
                  onPrev: () => _gotoMatch(-1),
                  onNext: () => _gotoMatch(1),
                ),
              ),
            // The view toggle (graph · read), always visible bottom-right.
            Positioned(
              right: 8,
              bottom: 8,
              child: SafeArea(
                child: ViewModeToggle(
                  mode: _viewMode,
                  onGraph: () => _setViewMode(CanvasViewMode.graph),
                  onRead: () => _setViewMode(CanvasViewMode.read),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// The reader floating over the graph: a faint, tap-to-dismiss scrim that
  /// lifts the card off the canvas while keeping the map visible behind it, and
  /// the reader itself as an inset, rounded, elevated card. Keyed by
  /// [_readEpoch] so re-entering reseats it on the current selection.
  Widget _buildReader(BuildContext context, TurnGridLayout layout) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      key: ValueKey('read-$_readEpoch'),
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _setViewMode(CanvasViewMode.graph),
          child: ColoredBox(color: Colors.black.withValues(alpha: 0.18)),
        ),
        Padding(
          // The margin that lets the canvas peek around the reader.
          padding: const EdgeInsets.all(18),
          child: GestureDetector(
            // Swallow taps on the card so they don't fall through to the
            // dismiss scrim; the reader's own gestures still win in the arena.
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: Material(
              color: scheme.surface,
              elevation: 6,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: ReadOverlay(
                conversationId: widget.conversationId,
                initialTurnId: _selectedId ?? layout.cells.first.turn.id,
                onFocusChanged: _onReadFocusChanged,
                onMinimize: () => _setViewMode(CanvasViewMode.graph),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// The pannable/zoomable graph canvas with its arrow-key / `f`-to-fit
  /// shortcuts and the pan-zoom gesture recognizer (extracted so the build body
  /// can layer the reader over it).
  Widget _buildGraph(BuildContext context, TurnGridLayout layout) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _navigate(layout, GridDirection.up),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _navigate(layout, GridDirection.down),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _navigate(layout, GridDirection.left),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _navigate(layout, GridDirection.right),
        const SingleActivator(LogicalKeyboardKey.keyF): () => _fit(layout),
      },
      child: Focus(
        focusNode: _graphFocusNode,
        autofocus: true,
        child: Listener(
          onPointerSignal: _onPointerSignal,
          // RawGestureDetector (not GestureDetector) so the canvas pan/zoom
          // uses [_PanZoomGestureRecognizer], which yields the arena to a
          // card's tap unless the gesture is a real drag — a plain scale
          // recognizer steals a slightly-imprecise mouse click before it can
          // maximize the node.
          child: RawGestureDetector(
            behavior: HitTestBehavior.opaque,
            gestures: {
              _PanZoomGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                    _PanZoomGestureRecognizer
                  >(
                    () => _PanZoomGestureRecognizer(debugOwner: this),
                    (instance) => instance
                      ..onStart = (details) {
                        _stopNavAnim();
                        _lastFocal = details.localFocalPoint;
                        _lastGestureScale = 1;
                      }
                      ..onUpdate = (details) {
                        _viewport.panBy(details.localFocalPoint - _lastFocal);
                        _lastFocal = details.localFocalPoint;
                        if (details.scale != _lastGestureScale) {
                          _viewport.zoomAt(
                            details.localFocalPoint,
                            details.scale / _lastGestureScale,
                          );
                          _lastGestureScale = details.scale;
                        }
                      },
                  ),
              DoubleTapGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                    DoubleTapGestureRecognizer
                  >(
                    () => DoubleTapGestureRecognizer(debugOwner: this),
                    (instance) => instance.onDoubleTap = () => _fit(layout),
                  ),
            },
            child: ClipRect(
              child: ListenableBuilder(
                listenable: _viewport,
                builder: (context, _) => _buildCanvas(context, layout),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Switches between the two views. Entering the reader re-seats it on the
  /// current selection; returning to the graph recenters the canvas on the turn
  /// just read so the two stay in step.
  void _setViewMode(CanvasViewMode mode) {
    if (_viewMode == mode) return;
    setState(() {
      if (mode == CanvasViewMode.read) _readEpoch++;
      _viewMode = mode;
    });
    if (mode == CanvasViewMode.graph) {
      final cell = ref
          .read(conversationGraphProvider(widget.conversationId))
          .value
          ?.layout
          .byId[_selectedId];
      if (cell != null) {
        _stopNavAnim();
        _viewport.centerOn(CanvasMetrics.cellRect(cell).center, _viewSize);
      }
      // Reclaim keyboard focus from the fading-out reader.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _graphFocusNode.requestFocus();
      });
    }
    _persistState();
  }

  /// Opens the reader on [turnId] (a node tap / maximize button). Same as
  /// switching to the read view, but anchored on the tapped turn.
  void _enterRead(String turnId) {
    setState(() {
      _selectedId = turnId;
      _readEpoch++;
      _viewMode = CanvasViewMode.read;
    });
    _persistState();
  }

  /// Recomputes the in-canvas search matches for the current query (held by
  /// the search field's controller) and keeps them scoped to turns still
  /// present in [layout]. The step cursor is reset on every edit by the
  /// field's `onChanged`, so the first Enter / ↓ lands on the first hit.
  void _reconcileSearch(TurnGridLayout layout) {
    final query = _searchController.text.trim();
    final async = query.isEmpty
        ? const AsyncData<List<String>>(<String>[])
        : ref.watch(
            canvasSearchResultsProvider((
              conversationId: widget.conversationId,
              query: query,
            )),
          );
    _searching = async.isLoading;
    final results = async.value ?? const <String>[];
    _matchedIds = [
      for (final id in results)
        if (layout.byId.containsKey(id)) id,
    ];
    _matchedSet = _matchedIds.toSet();
    if (_matchIndex >= _matchedIds.length) _matchIndex = -1;
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _matchIndex = -1);
    _searchFocusNode.requestFocus();
  }

  /// Steps the search cursor by [delta] (wrapping), then selects and centers
  /// that match. From the un-stepped state, ↓ lands on the first match and ↑
  /// on the last.
  void _gotoMatch(int delta) {
    final ids = _matchedIds;
    if (ids.isEmpty) return;
    final n = ids.length;
    final base = _matchIndex < 0 ? (delta >= 0 ? -1 : 0) : _matchIndex;
    final next = ((base + delta) % n + n) % n;
    setState(() => _matchIndex = next);
    final layout = ref
        .read(conversationGraphProvider(widget.conversationId))
        .value
        ?.layout;
    if (layout != null) _select(layout, ids[next]);
  }

  Widget _buildCanvas(BuildContext context, TurnGridLayout layout) {
    final scheme = Theme.of(context).colorScheme;
    final contentSize = CanvasMetrics.contentSize(layout);
    final visible = _viewport.visibleRect(_viewSize);
    final cullRect = visible.inflate(CanvasMetrics.rowGap);
    final visibleCells = [
      for (final cell in layout.cells)
        if (cullRect.overlaps(CanvasMetrics.cellRect(cell))) cell,
    ];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: ColoredBox(color: scheme.surfaceContainerHigh)),
        Positioned(
          left: 0,
          top: 0,
          child: Transform(
            transform: Matrix4.identity()
              ..translateByDouble(
                _viewport.translation.dx,
                _viewport.translation.dy,
                0,
                1,
              )
              ..scaleByDouble(
                _viewport.scale,
                _viewport.scale,
                _viewport.scale,
                1,
              ),
            child: SizedBox(
              width: contentSize.width,
              height: contentSize.height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: EdgePainter(
                        layout: layout,
                        visibleRect: visible,
                        activeColor: scheme.primary,
                        dimColor: scheme.outlineVariant,
                      ),
                    ),
                  ),
                  for (final cell in visibleCells)
                    Positioned.fromRect(
                      rect: CanvasMetrics.cellRect(cell),
                      child: NodeCard(
                        key: ValueKey('node-${cell.turn.id}'),
                        cell: cell,
                        selected: cell.turn.id == _selectedId,
                        matched: _matchedSet.contains(cell.turn.id),
                        onMaximize: () => _enterRead(cell.turn.id),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Keeps the selection valid across data refreshes (e.g. re-import while
  /// open); initializes it from the persisted `focused_turn_id`, falling
  /// back to the conversation's current turn.
  void _reconcileSelection(ConversationGraph graph, CanvasState? saved) {
    final layout = graph.layout;
    if (_selectedId != null && layout.byId.containsKey(_selectedId)) return;
    final savedId = _initialized ? null : saved?.focusedTurnId;
    final currentId = graph.conversation.currentTurnId;
    _selectedId = savedId != null && layout.byId.containsKey(savedId)
        ? savedId
        : currentId != null && layout.byId.containsKey(currentId)
        ? currentId
        : layout.activePathIds.isNotEmpty
        ? layout.activePathIds.last
        : layout.cells.first.turn.id;
  }

  /// First-layout initialization: the viewport from the persisted state
  /// (falling back to 1:1 centered on the selection). The view always starts on
  /// the graph — the reader is never auto-restored, so selecting a conversation
  /// shows the map, never jumps into reading.
  void _restore(TurnGridLayout layout, CanvasState? saved) {
    final viewport = _decodeViewport(saved?.viewportJson);
    if (viewport != null) {
      final (scale, center) = viewport;
      _viewport.reset(
        scale: scale,
        centerOnCanvasPoint: center,
        viewSize: _viewSize,
      );
    } else {
      final cell = layout.byId[_selectedId];
      _viewport.reset(
        scale: 1,
        centerOnCanvasPoint: cell == null
            ? CanvasMetrics.contentSize(layout).center(Offset.zero)
            : CanvasMetrics.cellRect(cell).center,
        viewSize: _viewSize,
      );
    }
  }

  (double, Offset)? _decodeViewport(String? json) {
    if (json == null) return null;
    try {
      if (jsonDecode(json) case {
        'scale': num scale,
        'cx': num cx,
        'cy': num cy,
      } when scale > 0) {
        return (scale.toDouble(), Offset(cx.toDouble(), cy.toDouble()));
      }
    } on FormatException {
      // Corrupt persisted state → defaults.
    }
    return null;
  }

  /// Reading focus moved inside the reader: mirror it into the shared
  /// selection (and persistence) so switching back to the graph lands on the
  /// right node.
  void _onReadFocusChanged(String turnId) {
    if (!mounted) return;
    setState(() => _selectedId = turnId);
    _persistState();
  }

  void _select(TurnGridLayout layout, String id) {
    if (_selectedId == id) return;
    setState(() => _selectedId = id);
    final cell = layout.byId[id];
    if (cell != null) {
      // Glide the map so the now-selected node travels to the centre, rather
      // than snapping the view to it — the "node is moving" feel.
      _animateCenterOn(CanvasMetrics.cellRect(cell).center);
    }
    _persistState();
  }

  /// Per-frame driver of the navigation glide: eased lerp of the viewport
  /// translation from [_navFrom] to [_navTo].
  void _onNavAnimTick() {
    final from = _navFrom, to = _navTo;
    if (from == null || to == null) return;
    final t = Curves.easeOutCubic.transform(_navAnim.value);
    _viewport.setTranslation(Offset.lerp(from, to, t)!);
  }

  /// Starts (or re-targets) the glide that ends with [canvasPoint] centred,
  /// tweening from wherever the view sits now so a mid-flight navigation
  /// redirects smoothly. A negligible move is skipped so a tap that doesn't
  /// shift the map doesn't run a no-op animation.
  void _animateCenterOn(Offset canvasPoint) {
    final target = _viewport.translationToCenter(canvasPoint, _viewSize);
    if ((target - _viewport.translation).distanceSquared < 0.25) return;
    _navFrom = _viewport.translation;
    _navTo = target;
    _navAnim.forward(from: 0);
  }

  /// Cancels an in-flight navigation glide so a manual pan/zoom/fit isn't
  /// fought by the tween writing translation back each frame.
  void _stopNavAnim() {
    if (_navAnim.isAnimating) _navAnim.stop();
  }

  void _navigate(TurnGridLayout layout, GridDirection direction) {
    final cell = layout.byId[_selectedId];
    if (cell == null) return;
    final target = switch (direction) {
      GridDirection.up => cell.up,
      GridDirection.down => cell.down,
      GridDirection.left => cell.left,
      GridDirection.right => cell.right,
    };
    if (target != null) _select(layout, target);
  }

  void _fit(TurnGridLayout layout) {
    _stopNavAnim();
    _viewport.fitContent(CanvasMetrics.contentSize(layout), _viewSize);
  }

  void _onViewportChanged() {
    if (!_initialized) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 300), _persistState);
  }

  /// Best-effort upsert of this conversation's `canvas_state` row
  /// (DESIGN.md §4): mode, focused turn, viewport scale + canvas-space
  /// center. Fire-and-forget — persistence must never break interaction.
  void _persistState() {
    _saveTimer?.cancel();
    final id = _selectedId;
    if (!_initialized || id == null) return;
    // The reader persists as 'read' but is never auto-restored; the graph
    // persists as 'navigate'.
    final mode = _viewMode == CanvasViewMode.read ? 'read' : 'navigate';
    final center = _viewport.visibleRect(_viewSize).center;
    unawaited(
      _db
          .into(_db.canvasStates)
          .insertOnConflictUpdate(
            CanvasStatesCompanion(
              conversationId: Value(widget.conversationId),
              mode: Value(mode),
              focusedTurnId: Value(id),
              viewportJson: Value(
                jsonEncode({
                  'scale': _viewport.scale,
                  'cx': center.dx,
                  'cy': center.dy,
                }),
              ),
            ),
          )
          .catchError((Object _) => 0),
    );
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    _stopNavAnim();
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isMetaPressed || keyboard.isControlPressed) {
      // Cmd/Ctrl + scroll = zoom around the cursor (DESIGN.md §6).
      _viewport.zoomAt(
        event.localPosition,
        math.exp(-event.scrollDelta.dy / 300),
      );
    } else {
      // Two-finger scroll = pan.
      _viewport.panBy(-event.scrollDelta);
    }
  }
}

/// "Find in conversation" box pinned to the canvas (a word-based FTS over the
/// open conversation's turns). Typing highlights every matching node;
/// Enter / the ↑ ↓ buttons step the canvas selection through the hits. It
/// lives outside the canvas's keyboard-shortcut subtree, so arrow keys edit
/// the field while it's focused and navigate the grid otherwise.
class CanvasSearchBar extends StatelessWidget {
  const CanvasSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.matchCount,
    required this.currentMatch,
    required this.searching,
    required this.onChanged,
    required this.onClear,
    required this.onPrev,
    required this.onNext,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int matchCount;

  /// 1-based index of the stepped-to match, or 0 before any step.
  final int currentMatch;

  /// The query is still running (no results yet) — show progress, not a
  /// premature "No results".
  final bool searching;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasMatches = matchCount > 0;

    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(8),
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 2, 4, 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            SizedBox(
              width: 170,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Find in conversation',
                ),
                textInputAction: TextInputAction.search,
                onChanged: onChanged,
                onSubmitted: (_) => onNext(),
              ),
            ),
            // ValueListenableBuilder so the counter/buttons appear and update
            // as the field text changes without rebuilding the whole canvas.
            ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, value, _) {
                if (value.text.trim().isEmpty) return const SizedBox.shrink();
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 4),
                    Text(
                      hasMatches
                          ? '${currentMatch == 0 ? '–' : currentMatch}'
                                '/$matchCount'
                          : searching
                          ? '…'
                          : 'No results',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    _IconButton(
                      icon: Icons.keyboard_arrow_up,
                      tooltip: 'Previous match',
                      onPressed: hasMatches ? onPrev : null,
                    ),
                    _IconButton(
                      icon: Icons.keyboard_arrow_down,
                      tooltip: 'Next match',
                      onPressed: hasMatches ? onNext : null,
                    ),
                    _IconButton(
                      icon: Icons.close,
                      tooltip: 'Clear search',
                      onPressed: onClear,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// The canvas's pan/zoom recognizer, tuned so it doesn't swallow a tap meant
/// for the node card beneath it. A plain [ScaleGestureRecognizer] claims the
/// gesture arena the instant a pointer drifts past the slop — only ~2px for a
/// mouse ([kPrecisePointerPanSlop]) — so a slightly-imprecise desktop click
/// reads as a pan and the card's "maximize" tap never fires. This subclass
/// withholds the single-pointer "accept" until the drag passes [kTouchSlop]
/// (the same tolerance the tap recognizer tolerates, so there is no gap where
/// neither wins), letting a click fall through to the card while a deliberate
/// drag still pans. Multi-pointer pinch and arena rejections are untouched.
class _PanZoomGestureRecognizer extends ScaleGestureRecognizer {
  _PanZoomGestureRecognizer({super.debugOwner});

  Offset? _origin;
  bool _passedSlop = false;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _origin = event.position;
    _passedSlop = false;
    super.addAllowedPointer(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (!_passedSlop &&
        pointerCount <= 1 &&
        event is PointerMoveEvent &&
        _origin != null &&
        (event.position - _origin!).distance > kTouchSlop) {
      _passedSlop = true;
    }
    super.handleEvent(event);
  }

  @override
  void resolve(GestureDisposition disposition) {
    // Hold off claiming the arena from a card's tap while a single pointer has
    // barely moved; a real drag (past the slop) and multi-pointer pinch accept
    // as usual, and rejections always pass through so the recognizer steps out
    // of the arena on a clean tap.
    if (disposition == GestureDisposition.accepted &&
        pointerCount <= 1 &&
        !_passedSlop) {
      return;
    }
    super.resolve(disposition);
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
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
      width: 28,
      height: 28,
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
        iconSize: 16,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          minimumSize: const Size(28, 28),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

/// The bottom-right, icons-only view switcher (DESIGN.md §6): graph · read.
/// Always visible in both views, with the current one shown as selected.
class ViewModeToggle extends StatelessWidget {
  const ViewModeToggle({
    super.key,
    required this.mode,
    required this.onGraph,
    required this.onRead,
  });

  final CanvasViewMode mode;
  final VoidCallback onGraph;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 3,
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToggleButton(
              icon: Icons.account_tree_outlined,
              tooltip: 'Graph view',
              selected: mode == CanvasViewMode.graph,
              onPressed: onGraph,
            ),
            _ToggleButton(
              icon: Icons.chrome_reader_mode_outlined,
              tooltip: 'Read view',
              selected: mode == CanvasViewMode.read,
              onPressed: onRead,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        isSelected: selected,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: selected
              ? scheme.primaryContainer
              : Colors.transparent,
          foregroundColor: selected
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
