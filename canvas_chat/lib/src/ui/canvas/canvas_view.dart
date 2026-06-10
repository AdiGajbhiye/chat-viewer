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
import 'minimap.dart';
import 'node_card.dart';

/// Navigate mode (DESIGN.md §6): the conversation's turn tree on a
/// pannable/zoomable grid canvas — uniform collapsed cards, edges with
/// active-path emphasis, viewport culling, arrow-key/button selection, and a
/// minimap. Tap / maximize enters read mode ([ReadOverlay] in a
/// [ReadModeRoute]); mode, focused turn, and viewport are persisted per
/// conversation in `canvas_state` and restored on open.
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

    return LayoutBuilder(builder: (context, constraints) {
      _viewSize = constraints.biggest;
      if (!_initialized) {
        _initialized = true;
        _restore(layout, saved);
      }
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
          autofocus: true,
          child: Listener(
            onPointerSignal: _onPointerSignal,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: (details) {
                _lastFocal = details.localFocalPoint;
                _lastGestureScale = 1;
              },
              onScaleUpdate: (details) {
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
              onDoubleTap: () => _fit(layout),
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
    });
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
                        onMaximize: () => _openReadMode(cell.turn.id),
                        onNavigate: (direction) {
                          _select(layout, cell.turn.id);
                          _navigate(layout, direction);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: Minimap(
            layout: layout,
            viewport: _viewport,
            viewSize: _viewSize,
            selectedId: _selectedId,
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
  /// back to 1:1 centered on the selection) and, when the user left this
  /// conversation in read mode, reopening the read overlay on it.
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
    if (saved?.mode == 'read') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedId != null) _openReadMode(_selectedId!);
      });
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
  /// the cell, full-screen route on Android, centered ~85% overlay on
  /// desktop. Returns to navigate mode centered on the node just read.
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

    await Navigator.of(context).push(ReadModeRoute<void>(
      sourceRect: sourceRect,
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
