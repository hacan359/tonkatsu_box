import 'package:flutter/material.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typography.dart';

/// Dark grid configuration tuned to the app theme: our surfaces, brand
/// accents, no harsh vertical rules and row heights that fit the 48×64
/// thumbnails.
TrinaGridConfiguration collectionTableConfiguration({required bool isRu}) {
  return TrinaGridConfiguration(
    selectingMode: TrinaGridSelectingMode.none,
    localeText: isRu
        ? const TrinaGridLocaleText.russian()
        : const TrinaGridLocaleText(),
    columnSize: const TrinaGridColumnSizeConfig(
      resizeMode: TrinaResizeMode.normal,
    ),
    style: TrinaGridStyleConfig.dark(
      gridBackgroundColor: AppColors.background,
      rowColor: AppColors.background,
      enableRowHoverColor: true,
      rowHoveredColor: AppColors.surfaceLight.withAlpha(50),
      activatedColor: AppColors.surfaceLight.withAlpha(40),
      activatedBorderColor: AppColors.brand.withAlpha(120),
      rowCheckedColor: AppColors.brand.withAlpha(40),
      // Checkbox colours: without these the checkmark defaults to
      // activatedColor (a dark translucent surface) and is invisible against
      // the fill. Brand fill + white tick reads in both header and rows.
      cellActiveColor: AppColors.brand,
      columnActiveColor: AppColors.brand,
      cellCheckedColor: Colors.white,
      columnCheckedColor: Colors.white,
      cellColorInReadOnlyState: Colors.transparent,
      borderColor: AppColors.surfaceBorder.withAlpha(40),
      enableColumnBorderVertical: false,
      enableCellBorderVertical: false,
      gridBorderColor: AppColors.surfaceBorder.withAlpha(40),
      gridBorderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      iconColor: AppColors.textTertiary,
      disabledIconColor: AppColors.textTertiary.withAlpha(80),
      menuBackgroundColor: AppColors.surface,
      dragTargetColumnColor: AppColors.brand.withAlpha(30),
      columnTextStyle: AppTypography.caption.copyWith(
        color: AppColors.textTertiary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        fontSize: 10.5,
      ),
      cellTextStyle: AppTypography.body,
      rowHeight: 72,
      columnHeight: 40,
      columnFilterHeight: 40,
    ),
  );
}
