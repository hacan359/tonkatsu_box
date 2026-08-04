import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_spacing.dart';
import '../models/library_stats.dart';
import 'stats_months_common.dart';
import 'stats_section_header.dart';

/// Phone activity ribbon: narrower columns, no hover arrows, and a list that
/// bleeds to the screen edges, so it applies the page inset itself.
class StatsMonthsRibbonMobile extends StatelessWidget {
  /// Creates the phone ribbon.
  const StatsMonthsRibbonMobile({
    required this.stats,
    required this.edgeInset,
    super.key,
  });

  /// The payload to render.
  final LibraryStats stats;

  /// The page's horizontal inset, applied to the header and to the list's
  /// content padding rather than to the list itself.
  final double edgeInset;

  /// Narrow enough that a third column peeks in at 360dp, which is what tells
  /// the user the strip scrolls.
  static const double _columnWidth = 104;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final List<MonthActivity> months = stats.months;
    final int peak = statsMonthsPeak(months);
    if (peak == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: edgeInset),
          child: StatsSectionHeader(
            title: stats.period.isAllTime
                ? l.statsMonthsTitleAllTime
                : l.statsMonthsTitle,
            hint: l.statsMonthsHint,
          ),
        ),
        SizedBox(
          height: statsMonthRowHeight(_columnWidth),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: edgeInset),
            itemCount: months.length,
            separatorBuilder: (BuildContext _, int _) =>
                const SizedBox(width: AppSpacing.sm),
            itemBuilder: (BuildContext context, int index) => StatsMonthColumn(
              month: months[index],
              stats: stats,
              peak: peak,
              width: _columnWidth,
            ),
          ),
        ),
      ],
    );
  }
}
