import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/grid_layout.dart';
import '../../state/providers.dart';
import 'canvas_metrics.dart';
import 'canvas_viewport.dart';
import 'edge_painter.dart';
import 'minimap.dart';
import 'node_card.dart';

/// Navigate mode (DESIGN.md §6): the conversation's turn tree on a
/// pannable/zoomable grid canvas — uniform collapsed cards, edges with
/// active-path emphasis, viewport culling, arrow-key/button selection, and a
/// minimap. Read mode integration (maximize/tap → overlay) arrives in M4.
class CanvasView extends ConsumerStatefulWidget {
  const CanvasView({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<CanvasView> createState() => _CanvasViewState();
}

class _CanvasViewState extends ConsumerState<CanvasView> {
  final _viewport = CanvasViewport();
  String? _selectedId;
  bool _viewportInitialized = false;
  Size _viewSize = Size.zero;

  // Scale-gesture bookkeeping (drag pan + pinch zoom share one recognizer).
  Offset _lastFocal = Offset.zero;
  double _lastGestureScale = 1;

  @override
  void dispose() {
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
    _reconcileSelection(graph);

    return LayoutBuilder(builder: (context, constraints) {
      _viewSize = constraints.biggest;
      if (!_viewportInitialized) {
        _viewportInitialized = true;
        // Open at 1:1 centered on the selection (the conversation's current
        // turn). Viewport persistence is M4; `f`/double-tap fits the whole
        // graph.
        final cell = layout.byId[_selectedId];
        _viewport.reset(
          scale: 1,
          centerOnCanvasPoint: cell == null
              ? CanvasMetrics.contentSize(layout).center(Offset.zero)
              : CanvasMetrics.cellRect(cell).center,
          viewSize: _viewSize,
        );
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
                        onSelect: () => _select(layout, cell.turn.id),
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
  /// open); initializes it to the conversation's current turn.
  void _reconcileSelection(ConversationGraph graph) {
    final layout = graph.layout;
    if (_selectedId != null && layout.byId.containsKey(_selectedId)) return;
    final currentId = graph.conversation.currentTurnId;
    _selectedId = currentId != null && layout.byId.containsKey(currentId)
        ? currentId
        : layout.activePathIds.isNotEmpty
            ? layout.activePathIds.last
            : layout.cells.first.turn.id;
  }

  void _select(TurnGridLayout layout, String id) {
    if (_selectedId == id) return;
    setState(() => _selectedId = id);
    final cell = layout.byId[id];
    if (cell != null) {
      _viewport.ensureVisible(CanvasMetrics.cellRect(cell), _viewSize);
    }
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
