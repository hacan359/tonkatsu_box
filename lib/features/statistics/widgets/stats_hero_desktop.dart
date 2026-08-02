import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../models/library_stats.dart';
import 'stats_cards.dart';
import 'stats_hero_common.dart';

/// Wide hero strip: a cover wall spanning the page behind an oversized item
/// count, the summary line, and every metric on one or two roomy rows.
class StatsHeroDesktop extends StatelessWidget {
  /// Creates the wide hero.
  const StatsHeroDesktop({
    required this.stats,
    required this.periodPicker,
    super.key,
  });

  /// The payload to render.
  final LibraryStats stats;

  /// The period dropdown, placed across from the headline number. It also
  /// replaces the eyebrow line, which named the same period twice.
  final Widget periodPicker;

  /// Target width of one wall cover; the count follows the window so covers
  /// keep their proportions instead of stretching on a wide monitor.
  static const double _wallCoverWidth = 155;

  /// Bounds on that count: enough to read as a wall, few enough to stay art.
  static const int _minWallCovers = 5;
  static const int _maxWallCovers = 14;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final NumberFormat numberFormat = statsNumberFormat(context);
    final int items = stats.totals.items;

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return StatsHeroWall(
                items: stats.wallItems,
                coverCount: (constraints.maxWidth / _wallCoverWidth)
                    .round()
                    .clamp(_minWallCovers, _maxWallCovers),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  // Scaled down, never clipped — see [StatsHeroMobile].
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        numberFormat.format(items),
                        style: AppTypography.h1.copyWith(
                          fontSize: 104,
                          height: 0.95,
                          letterSpacing: -4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  periodPicker,
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l.statsLede(numberFormat.format(items)),
                style:
                    AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.xl,
                runSpacing: AppSpacing.md,
                children: <Widget>[
                  for (final StatsHeroMetric metric
                      in statsHeroMetrics(context, stats))
                    StatsHeroMetricTile(metric: metric),
                ],
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
