import 'package:flutter/widgets.dart';

import '../constants/platform_features.dart';
import '../theme/app_spacing.dart';
import '../widgets/poster_look.dart';

/// The one poster-grid geometry (delegate plus outer padding) for every card
/// grid and its loading skeleton, honoring the user card scale.
({SliverGridDelegate delegate, double padding}) posterGridGeometry(
  BuildContext context, {
  required double cardScale,
}) {
  final double screenWidth = MediaQuery.sizeOf(context).width;
  final bool isLandscape = isLandscapeMobile(context);
  final bool isDesktop = screenWidth >= kDesktopContentBreakpoint && !kIsMobile;

  final double padding = isLandscape ? AppSpacing.sm : AppSpacing.screenPadding;
  final double crossSpacing = isLandscape ? AppSpacing.sm : AppSpacing.gridGap;
  final double mainSpacing = isLandscape ? AppSpacing.sm : AppSpacing.lg;

  // These looks write the title on the picture, so the cell has no caption.
  final bool barePoster = switch (PosterLookScope.of(context)) {
    PosterLook.kino || PosterLook.cinema => true,
    _ => false,
  };
  final double ratio = barePoster
      ? AppSpacing.posterAspectRatio
      : AppSpacing.posterCardAspectRatio;
  final double gap = barePoster ? crossSpacing : mainSpacing;

  if (isDesktop) {
    return (
      delegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: AppSpacing.desktopMaxCardWidth * cardScale,
        crossAxisSpacing: crossSpacing,
        mainAxisSpacing: gap,
        childAspectRatio: ratio,
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
      mainAxisSpacing: gap,
      childAspectRatio: ratio,
    ),
    padding: padding,
  );
}
