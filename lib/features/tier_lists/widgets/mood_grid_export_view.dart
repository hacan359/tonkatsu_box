import 'package:flutter/material.dart';

import '../../../shared/models/mood_grid.dart';
import '../../../shared/models/mood_grid_cell.dart';
import '../../../shared/theme/app_assets.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import 'mood_grid_cell_widget.dart';

/// Off-screen render of a mood grid used by [RepaintBoundary.toImage] for
/// PNG export. Renders the grid title, the cells, and a small watermark.
class MoodGridExportView extends StatelessWidget {
  /// Creates a [MoodGridExportView].
  const MoodGridExportView({
    required this.repaintKey,
    required this.grid,
    required this.cells,
    this.authorName = '',
    super.key,
  });

  /// Key on the surrounding [RepaintBoundary].
  final GlobalKey repaintKey;

  /// Grid being rendered.
  final MoodGrid grid;

  /// All cells, ordered by position.
  final List<MoodGridCell> cells;

  /// Optional author name shown under the watermark.
  final String authorName;

  static const double _cellWidth = 140;

  @override
  Widget build(BuildContext context) {
    final double width =
        _cellWidth * grid.cols + AppSpacing.md * (grid.cols + 1);

    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        width: width,
        color: AppColors.background,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              grid.name,
              textAlign: TextAlign.center,
              style: AppTypography.h2,
            ),
            const SizedBox(height: AppSpacing.lg),
            for (int row = 0; row < grid.rows; row++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    for (int col = 0; col < grid.cols; col++)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        child: MoodGridCellWidget(
                          cell: _cellAt(row, col),
                          width: _cellWidth,
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, color: AppColors.surfaceBorder),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Image.asset(AppAssets.logo, width: 16, height: 16),
                const SizedBox(width: 4),
                Text(
                  authorName.isEmpty
                      ? 'made by Tonkatsu Box'
                      : 'made by Tonkatsu Box — $authorName',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
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
