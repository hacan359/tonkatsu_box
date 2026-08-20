import 'package:core/models/mood_grid.dart';
import 'package:core/models/mood_grid_cell.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../shared/constants/platform_features.dart';
import '../../../shared/theme/app_spacing.dart';
import 'mood_grid_cell_media.dart';
import 'mood_grid_cell_widget.dart';
import 'mood_grid_row_captions.dart';

/// Lays out the cells of a [MoodGrid] in a `rows × cols` matrix, with an
/// optional caption column to the right of each row.
class MoodGridView extends StatefulWidget {
  const MoodGridView({
    required this.grid,
    required this.cells,
    required this.mediaByPosition,
    this.onCellTap,
    this.onCellLabelTap,
    this.onCellContextMenu,
    this.cellWidth = 140,
    this.captionWidth = 220,
    super.key,
  });

  final MoodGrid grid;
  final List<MoodGridCell> cells;

  /// Preloaded media for each cell keyed by position; cells without an item
  /// map to [MoodGridCellMedia.empty].
  final Map<int, MoodGridCellMedia> mediaByPosition;

  final void Function(MoodGridCell)? onCellTap;
  final void Function(MoodGridCell)? onCellLabelTap;
  final void Function(MoodGridCell, Offset)? onCellContextMenu;

  final double cellWidth;
  final double captionWidth;

  @override
  State<MoodGridView> createState() => _MoodGridViewState();
}

class _MoodGridViewState extends State<MoodGridView> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MoodGrid grid = widget.grid;
    final String template = grid.captionTemplate ?? '';
    final bool showCaptions = template.trim().isNotEmpty;
    final Map<int, MoodGridCell> cellsByPosition = <int, MoodGridCell>{
      for (final MoodGridCell c in widget.cells) c.position: c,
    };
    final bool desktop = !kIsMobile;

    // The horizontal scrollbar listens to the inner (depth 1) view. Mouse
    // drag pans on desktop, where the wheel only serves the vertical axis.
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: <PointerDeviceKind>{
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.stylus,
          PointerDeviceKind.trackpad,
        },
      ),
      child: Scrollbar(
        controller: _verticalController,
        thumbVisibility: desktop,
        child: Scrollbar(
          controller: _horizontalController,
          thumbVisibility: desktop,
          notificationPredicate: (ScrollNotification n) => n.depth == 1,
          child: SingleChildScrollView(
            controller: _verticalController,
            child: SingleChildScrollView(
              controller: _horizontalController,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          for (int col = 0; col < grid.cols; col++)
                            _buildCell(
                              _cellAt(cellsByPosition, row, col),
                            ),
                          if (showCaptions)
                            MoodGridRowCaptions(
                              template: template,
                              rowMedia: _rowMedia(row),
                              width: widget.captionWidth,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
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
        media:
            widget.mediaByPosition[cell.position] ?? MoodGridCellMedia.empty,
        width: widget.cellWidth,
        onTap: widget.onCellTap == null
            ? null
            : () => widget.onCellTap!(cell),
        onLabelTap: widget.onCellLabelTap == null
            ? null
            : () => widget.onCellLabelTap!(cell),
        onContextMenu: widget.onCellContextMenu == null
            ? null
            : (Offset pos) => widget.onCellContextMenu!(cell, pos),
      ),
    );
  }

  MoodGridCell _cellAt(Map<int, MoodGridCell> byPosition, int row, int col) {
    final int pos = row * widget.grid.cols + col;
    return byPosition[pos] ??
        MoodGridCell(id: -1, gridId: widget.grid.id, position: pos);
  }

  List<MoodGridCellMedia> _rowMedia(int row) {
    return <MoodGridCellMedia>[
      for (int col = 0; col < widget.grid.cols; col++)
        widget.mediaByPosition[row * widget.grid.cols + col] ??
            MoodGridCellMedia.empty,
    ];
  }
}
