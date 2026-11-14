import 'package:material_ui/material_ui.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typography.dart';

/// Dark grid configuration tuned to the app theme; row heights fit the
/// 48×64 thumbnails.
TrinaGridConfiguration collectionTableConfiguration({required bool isRu}) {
  return TrinaGridConfiguration(
    selectingMode: TrinaGridSelectingMode.none,
    localeText: isRu
        ? const TrinaGridLocaleText.russian()
        : const TrinaGridLocaleText(),
    columnSize: const TrinaGridColumnSizeConfig(
      resizeMode: TrinaResizeMode.normal,
    ),
    // The grid sits on the glass panel, so it paints no backing of its own;
    // hover and activation are neutral scrims that read on any wallpaper.
    style: TrinaGridStyleConfig.dark(
      gridBackgroundColor: Colors.transparent,
      rowColor: Colors.transparent,
      enableRowHoverColor: true,
      rowHoveredColor: AppColors.textPrimary.withAlpha(18),
      activatedColor: AppColors.textPrimary.withAlpha(14),
      activatedBorderColor: AppColors.brand.withAlpha(120),
      rowCheckedColor: AppColors.brand.withAlpha(40),
      // Without these the checkmark defaults to activatedColor (a dark
      // translucent surface) and is invisible against the fill.
      cellActiveColor: AppColors.brand,
      columnActiveColor: AppColors.brand,
      cellCheckedColor: AppColors.onOverlay,
      columnCheckedColor: AppColors.onOverlay,
      cellColorInReadOnlyState: Colors.transparent,
      borderColor: AppColors.textPrimary.withAlpha(24),
      enableColumnBorderVertical: false,
      enableCellBorderVertical: false,
      gridBorderColor: AppColors.textPrimary.withAlpha(24),
      gridBorderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      iconColor: AppColors.textTertiary,
      disabledIconColor: AppColors.textTertiary.withAlpha(80),
      menuBackgroundColor: AppColors.surface.withAlpha(215),
      dragTargetColumnColor: AppColors.brand.withAlpha(30),
      columnTextStyle: AppTypography.caption.copyWith(
        color: AppColors.textTertiary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        fontSize: 10.5,
      ),
      cellTextStyle: AppTypography.body,
      // The stock glyphs sit 12px inside the header and cover short titles.
      columnResizeWidget: const _HeaderEdge(child: _ResizeGrip()),
      columnAscendingIcon: _HeaderEdge(
        child: Icon(
          Icons.arrow_upward,
          size: _sortIconSize,
          color: AppColors.brand,
        ),
      ),
      columnDescendingIcon: _HeaderEdge(
        child: Icon(
          Icons.arrow_downward,
          size: _sortIconSize,
          color: AppColors.brand,
        ),
      ),
      rowHeight: 72,
      columnHeight: 40,
      columnFilterHeight: 40,
    ),
  );
}

const double _sortIconSize = 14;

// The grid centres its header icon in a box that ends 12px before the column
// edge; this shift moves the content out to the edge itself.
const double _headerEdgeShift = 10;

class _HeaderEdge extends StatelessWidget {
  const _HeaderEdge({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(_headerEdgeShift, 0),
      child: Align(alignment: Alignment.centerRight, child: child),
    );
  }
}

class _ResizeGrip extends StatelessWidget {
  const _ResizeGrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: 14,
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withAlpha(40),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}
