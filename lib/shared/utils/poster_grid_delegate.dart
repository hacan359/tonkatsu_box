import 'package:flutter/widgets.dart';

import '../constants/platform_features.dart';
import '../theme/app_spacing.dart';

/// The one poster-grid geometry (delegate plus outer padding) for every card
/// grid and its loading skeleton, honoring the user card scale.
({SliverGridDelegate delegate, double padding}) posterGridGeometry(
  BuildContext context, {
  required double cardScale,
}) {
  final double screenWidth = MediaQuery.sizeOf(context).width;
  final bool isLandscape = isLandscapeMobile(context);
  final bool isDesktop =
      screenWidth >= kDesktopContentBreakpoint && !kIsMobile;

  final double padding = isLandscape ? AppSpacing.sm : AppSpacing.screenPadding;
  final double crossSpacing = isLandscape ? AppSpacing.sm : AppSpacing.gridGap;
  final double mainSpacing = isLandscape ? AppSpacing.sm : AppSpacing.lg;

  if (isDesktop) {
    return (
      delegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: AppSpacing.desktopMaxCardWidth * cardScale,
        crossAxisSpacing: crossSpacing,
        mainAxisSpacing: mainSpacing,
        childAspectRatio: AppSpacing.posterCardAspectRatio,
      ),
      padding: padding,
    );
  }
  final int baseCount;
  if (isLandscape) {
    baseCount = AppSpacing.gridColumnsDesktop;
  } else if (screenWidth >= 500) {
    baseCount = AppSpacing.gridColumnsTablet;
  } else {
    baseCount = AppSpacing.gridColumnsMobile;
  }
  return (
    delegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: AppSpacing.scaledColumns(baseCount, cardScale),
      crossAxisSpacing: crossSpacing,
      mainAxisSpacing: mainSpacing,
      childAspectRatio: AppSpacing.posterCardAspectRatio,
    ),
    padding: padding,
  );
}
