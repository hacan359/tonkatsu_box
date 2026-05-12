import 'package:flutter/material.dart';

import '../../../shared/models/mood_grid.dart';
import '../../../shared/models/mood_grid_cell.dart';
import '../../../shared/theme/app_spacing.dart';
import 'mood_grid_cell_widget.dart';

/// Lays out the cells of a [MoodGrid] in a `rows × cols` matrix.
class MoodGridView extends StatelessWidget {
  /// Creates a [MoodGridView].
  const MoodGridView({
    required this.grid,
    required this.cells,
    this.onCellTap,
    this.onCellContextMenu,
    this.cellWidth = 140,
    super.key,
  });

  /// Grid dimensions.
  final MoodGrid grid;

  /// All cells, ordered by position. Length is expected to equal
  /// [grid.rows] × [grid.cols].
  final List<MoodGridCell> cells;

  /// Primary tap on a cell.
  final void Function(MoodGridCell)? onCellTap;

  /// Right-click / long-press on a cell. The [Offset] is global position.
  final void Function(MoodGridCell, Offset)? onCellContextMenu;

  /// Logical width of a single cell.
  final double cellWidth;

  @override
  Widget build(BuildContext context) {
    // Wide grids may not fit horizontally on small screens; nested scrollers
    // give vertical wrap + horizontal pan in one go.
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int row = 0; row < grid.rows; row++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (int col = 0; col < grid.cols; col++)
                      _buildCell(_cellAt(row, col)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(MoodGridCell cell) {
    return Padding(
      key: ValueKey<int>(cell.position),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: MoodGridCellWidget(
        cell: cell,
        width: cellWidth,
        onTap: onCellTap == null ? null : () => onCellTap!(cell),
        onContextMenu: onCellContextMenu == null
            ? null
            : (Offset pos) => onCellContextMenu!(cell, pos),
      ),
    );
  }

  MoodGridCell _cellAt(int row, int col) {
    final int pos = row * grid.cols + col;
    return cells.firstWhere(
      (MoodGridCell c) => c.position == pos,
      orElse: () => MoodGridCell(id: -1, gridId: grid.id, position: pos),
    );
  }
}
