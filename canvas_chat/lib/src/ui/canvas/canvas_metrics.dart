import 'dart:ui';

import '../../domain/grid_layout.dart';

/// Fixed cell geometry for navigate mode (DESIGN.md §6): collapsed cards are
/// uniform, so cell → pixel mapping is trivial and culling is exact.
abstract final class CanvasMetrics {
  static const double cardWidth = 260;
  static const double cardHeight = 112;

  /// Horizontal gap between lanes / vertical gap between rows.
  static const double laneGap = 56;
  static const double rowGap = 44;

  /// Blank margin around the whole grid.
  static const double padding = 48;

  static Offset cellOrigin(int row, int lane) => Offset(
        padding + lane * (cardWidth + laneGap),
        padding + row * (cardHeight + rowGap),
      );

  static Rect cellRect(GridCell cell) =>
      cellOrigin(cell.row, cell.lane) & const Size(cardWidth, cardHeight);

  static Size contentSize(TurnGridLayout layout) {
    if (layout.isEmpty) return const Size(2 * padding, 2 * padding);
    return Size(
      2 * padding +
          layout.laneCount * cardWidth +
          (layout.laneCount - 1) * laneGap,
      2 * padding + layout.rowCount * cardHeight + (layout.rowCount - 1) * rowGap,
    );
  }
}
