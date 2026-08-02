import 'package:flutter/widgets.dart';

import '../../../shared/theme/app_spacing.dart';
import 'stats_layout.dart';

/// Layout numbers for the wide page. Column counts follow the target card
/// width, since the page fills the window instead of a centred 1240px column.
const StatsLayout kStatsLayoutDesktop = StatsLayout(
  sectionGap: AppSpacing.xl + AppSpacing.lg,
  horizontalPadding: AppSpacing.md,
  cardPadding: EdgeInsets.all(AppSpacing.md),
  typeCardMinWidth: 300,
  typeCardMaxColumns: 6,
  gridCardMinWidth: 260,
  gridCardMaxColumns: 8,
  showCardTopCovers: true,
);
