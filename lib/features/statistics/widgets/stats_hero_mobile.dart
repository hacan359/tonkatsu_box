import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../models/library_stats.dart';
import 'stats_cards.dart';
import 'stats_hero_common.dart';

/// Phone hero: same headline and metrics as the wide one, but in a fixed
/// two-column grid — a wrap reflows them into ragged rows with no left edge.
class StatsHeroMobile extends StatelessWidget {
  /// Creates the phone hero.
  const StatsHeroMobile({
    required this.stats,
    required this.periodPicker,
    super.key,
  });

  /// The payload to render.
  final LibraryStats stats;

  /// The period dropdown, placed across from the headline number — see
  /// [StatsHeroDesktop.periodPicker].
  final Widget periodPicker;

  /// Covers spread across the wall. Three at 360dp keeps each cover wide
  /// enough to read as art rather than as a thumbnail strip.
  static const int _wallCovers = 3;

  /// Metric columns. Two fits the longest localized captions at 360dp.
  static const int _metricColumns = 2;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final NumberFormat numberFormat = statsNumberFormat(context);
    final int items = stats.totals.items;
    final List<StatsHeroMetric> metrics = statsHeroMetrics(context, stats);

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: StatsHeroWall(
            items: stats.wallItems,
            coverCount: _wallCovers,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  // Scaled, never clipped: the count is the point of the
                  // hero, so a narrow phone shrinks it instead of cutting it.
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        numberFormat.format(items),
                        style: AppTypography.h1.copyWith(
                          fontSize: 56,
                          height: 0.95,
                          letterSpacing: -2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  periodPicker,
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l.statsLede(numberFormat.format(items)),
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double columnWidth = (constraints.maxWidth -
                          (_metricColumns - 1) * AppSpacing.md) /
                      _metricColumns;
                  return Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: <Widget>[
                      for (final StatsHeroMetric metric in metrics)
                        SizedBox(
                          width: columnWidth,
                          child: StatsHeroMetricTile(metric: metric),
                        ),
                    ],
                  );
                },
              ),
              if (stats.hours.totalMinutes > 0) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                StatsHoursBreakdown(hours: stats.hours),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
