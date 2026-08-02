import 'package:flutter/widgets.dart';

import '../../../shared/theme/app_spacing.dart';
import 'stats_layout.dart';

/// Layout numbers for the phone page. Tighter than desktop, and the grid
/// cards trade their cover strips for a second column.
const StatsLayout kStatsLayoutMobile = StatsLayout(
  sectionGap: AppSpacing.xl,
  horizontalPadding: AppSpacing.md,
  cardPadding: EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
  typeCardMinWidth: 260,
  typeCardMaxColumns: 1,
  gridCardMinWidth: 150,
  gridCardMaxColumns: 2,
  showCardTopCovers: false,
);
