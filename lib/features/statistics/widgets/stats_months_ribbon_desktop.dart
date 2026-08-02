import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/scrollable_row_with_arrows.dart';
import '../models/library_stats.dart';
import 'stats_months_common.dart';
import 'stats_section_header.dart';

/// Wide activity ribbon: month columns scrolled with hover arrows and the
/// mouse wheel.
class StatsMonthsRibbonDesktop extends StatefulWidget {
  /// Creates the wide ribbon.
  const StatsMonthsRibbonDesktop({required this.stats, super.key});

  /// The payload to render.
  final LibraryStats stats;

  @override
  State<StatsMonthsRibbonDesktop> createState() =>
      _StatsMonthsRibbonDesktopState();
}

class _StatsMonthsRibbonDesktopState extends State<StatsMonthsRibbonDesktop> {
  static const double _columnWidth = 132;

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final LibraryStats stats = widget.stats;
    final List<MonthActivity> months = stats.months;
    final int peak = statsMonthsPeak(months);
    if (peak == 0) return const SizedBox.shrink();

    final double rowHeight = statsMonthRowHeight(_columnWidth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        StatsSectionHeader(
          title: stats.period.isAllTime
              ? l.statsMonthsTitleAllTime
              : l.statsMonthsTitle,
          hint: l.statsMonthsHint,
        ),
        SizedBox(
          height: rowHeight,
          child: ScrollableRowWithArrows(
            controller: _scrollController,
            height: rowHeight,
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: months.length,
              separatorBuilder: (BuildContext _, int _) =>
                  const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              itemBuilder: (BuildContext context, int index) =>
                  StatsMonthColumn(
                month: months[index],
                stats: stats,
                peak: peak,
                width: _columnWidth,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
