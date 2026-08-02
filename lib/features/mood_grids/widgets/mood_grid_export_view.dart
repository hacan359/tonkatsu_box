import 'dart:math' as math;

import 'package:core/models/mood_grid.dart';
import 'package:core/models/mood_grid_cell.dart';
import 'package:flutter/material.dart';

import '../../../shared/theme/app_assets.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import 'mood_grid_cell_media.dart';
import 'mood_grid_cell_widget.dart';
import 'mood_grid_row_captions.dart';

/// Off-screen render of a mood grid for `RepaintBoundary.toImage` export.
/// Empty cells stay blank so unfilled slots don't clutter the image.
class MoodGridExportView extends StatelessWidget {
  const MoodGridExportView({
    required this.repaintKey,
    required this.grid,
    required this.cells,
    required this.mediaByPosition,
    this.cellWidth = 140,
    super.key,
  });

  final GlobalKey repaintKey;
  final MoodGrid grid;
  final List<MoodGridCell> cells;
  final Map<int, MoodGridCellMedia> mediaByPosition;
  final double cellWidth;

  static const double _captionWidth = 240;

  /// Canvas floor: a narrow grid (one column at the smallest cell size)
  /// must still fit the title and the footer credit line.
  static const double _minWidth = 320;

  @override
  Widget build(BuildContext context) {
    final String template = grid.captionTemplate ?? '';
    final bool showCaptions = template.trim().isNotEmpty;
    final Map<int, MoodGridCell> cellsByPosition = <int, MoodGridCell>{
      for (final MoodGridCell c in cells) c.position: c,
    };
    // Mirrors the row layout below: xs padding per cell, fixed-width
    // captions block, lg container padding.
    final double cellsWidth = (cellWidth + 2 * AppSpacing.xs) * grid.cols;
    final double width = math.max(
      cellsWidth + 2 * AppSpacing.lg + (showCaptions ? _captionWidth : 0),
      _minWidth,
    );

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (int col = 0; col < grid.cols; col++)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        child: _buildCell(
                          cellsByPosition[row * grid.cols + col],
                        ),
                      ),
                    if (showCaptions)
                      MoodGridRowCaptions(
                        template: template,
                        rowMedia: _rowMedia(row),
                        width: _captionWidth,
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
                  'made by Tonkatsu Box',
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

  Widget _buildCell(MoodGridCell? cell) {
    if (cell == null || cell.isEmpty) {
      return SizedBox(width: cellWidth);
    }
    return MoodGridCellWidget(
      cell: cell,
      media: mediaByPosition[cell.position] ?? MoodGridCellMedia.empty,
      width: cellWidth,
    );
  }

  List<MoodGridCellMedia> _rowMedia(int row) {
    return <MoodGridCellMedia>[
      for (int col = 0; col < grid.cols; col++)
        mediaByPosition[row * grid.cols + col] ?? MoodGridCellMedia.empty,
    ];
  }
}
