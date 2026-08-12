import 'package:flutter/rendering.dart';

import '../theme/app_spacing.dart';

/// One poster-grid geometry for every card grid, honoring the user card scale.
SliverGridDelegate posterGridDelegate({
  required double width,
  required double cardScale,
}) {
  if (width >= 800) {
    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: AppSpacing.desktopMaxCardWidth * cardScale,
      childAspectRatio: AppSpacing.posterCardAspectRatio,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
    );
  }
  final int baseCount = width >= 500
      ? AppSpacing.gridColumnsTablet
      : AppSpacing.gridColumnsMobile;
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: AppSpacing.scaledColumns(baseCount, cardScale),
    childAspectRatio: AppSpacing.posterCardAspectRatio,
    crossAxisSpacing: AppSpacing.sm,
    mainAxisSpacing: AppSpacing.sm,
  );
}
