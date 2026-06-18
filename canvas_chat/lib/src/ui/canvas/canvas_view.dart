import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
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

/// Navigate mode (DESIGN.md §6): the conversation's turn tree on a
/// pannable/zoomable grid canvas — uniform collapsed cards, edges with
/// active-path emphasis, viewport culling, and arrow-key/button selection.
/// Tap / maximize enters read mode ([ReadOverlay] in a [ReadModeRoute]) which
/// fills the canvas pane; focused turn and viewport are persisted per
/// conversation in `canvas_state` and restored on open. A conversation always
/// opens in navigate mode — read mode is reached only by tapping a node, never
/// auto-restored, so selecting a conversation never jumps straight into the
/// reader.
class CanvasView extends ConsumerStatefulWidget {
  const CanvasView({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<CanvasView> createState() => _CanvasViewState();
}

class _CanvasViewState extends ConsumerState<CanvasView> {
  final _viewport = CanvasViewport();
  String? _selectedId;
  String _mode = 'navigate';
  bool _initialized = false;
  bool _readOpen = false;
  Size _viewSize = Size.zero;

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

  @override
  void initState() {
    super.initState();
    _db = ref.read(databaseProvider);
    _viewport.addListener(_onViewportChanged);
  }

  @override
  void dispose() {
    _viewport.removeListener(_onViewportChanged);
    if (_saveTimer?.isActive ?? false) {
      _persistState(); // flush the pending debounced write
    }
    _saveTimer?.cancel();
    _viewport.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
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

    return LayoutBuilder(builder: (context, constraints) {
      _viewSize = constraints.biggest;
      if (!_initialized) {
        _initialized = true;
        _restore(layout, saved);
      }
      return Stack(
        children: [
          Positioned.fill(
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                    _navigate(layout, GridDirection.up),
                const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                    _navigate(layout, GridDirection.down),
                const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
                    _navigate(layout, GridDirection.left),
                const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
                    _navigate(layout, GridDirection.right),
                const SingleActivator(LogicalKeyboardKey.keyF): () =>
                    _fit(layout),
              },
              child: Focus(
                autofocus: true,
                child: Listener(
                  onPointerSignal: _onPointerSignal,
                  // RawGestureDetector (not GestureDetector) so the canvas
                  // pan/zoom uses [_PanZoomGestureRecognizer], which yields the
                  // arena to a card's tap unless the gesture is a real drag —
                  // a plain scale recognizer steals a slightly-imprecise mouse
                  // click before it can maximize the node.
                  child: RawGestureDetector(
                    behavior: HitTestBehavior.opaque,
                    gestures: {
                      _PanZoomGestureRecognizer:
                          GestureRecognizerFactoryWithHandlers<
                              _PanZoomGestureRecognizer>(
                        () => _PanZoomGestureRecognizer(debugOwner: this),
                        (instance) => instance
                          ..onStart = (details) {
                            _lastFocal = details.localFocalPoint;
                            _lastGestureScale = 1;
                          }
                          ..onUpdate = (details) {
                            _viewport
                                .panBy(details.localFocalPoint - _lastFocal);
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
                              DoubleTapGestureRecognizer>(
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
            ),
          ),
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
        ],
      );
    });
  }

  /// Recomputes the in-canvas search matches for the current query (held by
  /// the search field's controller) and keeps them scoped to turns still
  /// present in [layout]. The step cursor is reset on every edit by the
  /// field's `onChanged`, so the first Enter / ↓ lands on the first hit.
  void _reconcileSearch(TurnGridLayout layout) {
    final query = _searchController.text.trim();
    final async = query.isEmpty
        ? const AsyncData<List<String>>(<String>[])
        : ref.watch(canvasSearchResultsProvider(
            (conversationId: widget.conversationId, query: query),
          ));
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
                  _viewport.translation.dx, _viewport.translation.dy, 0, 1)
              ..scaleByDouble(
                  _viewport.scale, _viewport.scale, _viewport.scale, 1),
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
                        onMaximize: () => _openReadMode(cell.turn.id),
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

  /// First-layout initialization: viewport from the persisted state (falling
  /// back to 1:1 centered on the selection). Always lands in navigate mode —
  /// read mode is never auto-restored, so selecting a conversation shows the
  /// canvas rather than jumping into the reader.
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
      if (jsonDecode(json) case {'scale': num scale, 'cx': num cx, 'cy': num cy}
          when scale > 0) {
        return (scale.toDouble(), Offset(cx.toDouble(), cy.toDouble()));
      }
    } on FormatException {
      // Corrupt persisted state → defaults.
    }
    return null;
  }

  /// Enters read mode on [turnId] (DESIGN.md §6): hero-style transition from
  /// the cell to the read surface — full-screen on Android, filling the
  /// canvas pane on desktop. Returns to navigate mode centered on the node
  /// just read.
  Future<void> _openReadMode(String turnId) async {
    if (_readOpen || !mounted) return;
    final layout = ref
        .read(conversationGraphProvider(widget.conversationId))
        .value
        ?.layout;
    final cell = layout?.byId[turnId];
    if (layout == null || cell == null) return;
    _select(layout, turnId);
    _readOpen = true;
    _mode = 'read';
    _persistState();

    // The cell's current on-screen rect, in the navigator's global space.
    final cellRect = CanvasMetrics.cellRect(cell);
    final box = context.findRenderObject() as RenderBox?;
    final topLeft = _viewport.toScreen(cellRect.topLeft);
    final sourceRect = (box?.localToGlobal(topLeft) ?? topLeft) &
        cellRect.size * _viewport.scale;
    // The canvas pane's global rect: desktop read mode fills it rather than
    // floating as a centered dialog.
    final paneRect =
        box == null ? null : box.localToGlobal(Offset.zero) & box.size;

    await Navigator.of(context).push(ReadModeRoute<void>(
      sourceRect: sourceRect,
      fillRect: paneRect,
      fullScreen: defaultTargetPlatform == TargetPlatform.android,
      child: ReadOverlay(
        conversationId: widget.conversationId,
        initialTurnId: turnId,
        onFocusChanged: _onReadFocusChanged,
      ),
    ));
    if (!mounted) return;

    _readOpen = false;
    _mode = 'navigate';
    // Minimize returns to navigate mode centered on the node just read.
    final latest = ref
            .read(conversationGraphProvider(widget.conversationId))
            .value
            ?.layout ??
        layout;
    final focused = latest.byId[_selectedId];
    if (focused != null) {
      _viewport.centerOn(
        CanvasMetrics.cellRect(focused).center,
        _viewSize,
      );
    }
    _persistState();
  }

  /// Reading focus moved inside the overlay: mirror it into the canvas
  /// selection (and persistence) so minimize lands on the right node.
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
      _viewport.ensureVisible(CanvasMetrics.cellRect(cell), _viewSize);
    }
    _persistState();
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
    final center = _viewport.visibleRect(_viewSize).center;
    unawaited(
      _db
          .into(_db.canvasStates)
          .insertOnConflictUpdate(CanvasStatesCompanion(
            conversationId: Value(widget.conversationId),
            mode: Value(_mode),
            focusedTurnId: Value(id),
            viewportJson: Value(jsonEncode({
              'scale': _viewport.scale,
              'cx': center.dx,
              'cy': center.dy,
            })),
          ))
          .catchError((Object _) => 0),
    );
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
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
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
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
