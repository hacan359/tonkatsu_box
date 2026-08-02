import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../models/library_stats.dart';
import 'stats_cards.dart';
import 'stats_poster.dart';

/// One headline metric of the hero strip.
@immutable
class StatsHeroMetric {
  /// Creates a metric.
  const StatsHeroMetric({required this.value, required this.label});

  /// Formatted value.
  final String value;

  /// Caption under the value.
  final String label;
}

/// Library-wide consumption metrics, in display order. Per-type splits live
/// in the cards below, so both hero variants show this same list.
List<StatsHeroMetric> statsHeroMetrics(
  BuildContext context,
  LibraryStats stats,
) {
  final S l = S.of(context);
  final NumberFormat numberFormat = statsNumberFormat(context);
  final LibraryTotals totals = stats.totals;
  final UnitsWatched units = stats.units;
  return <StatsHeroMetric>[
    if (units.episodes > 0)
      StatsHeroMetric(
        value: numberFormat.format(units.episodes),
        label: l.statsMetricEpisodes,
      ),
    if (units.mangaChapters > 0)
      StatsHeroMetric(
        value: numberFormat.format(units.mangaChapters),
        label: l.statsMetricMangaChapters,
      ),
    if (units.bookPages > 0)
      StatsHeroMetric(
        value: numberFormat.format(units.bookPages),
        label: l.statsMetricBookPages,
      ),
    StatsHeroMetric(
      value: l.statsHoursShort(numberFormat.format(stats.hours.totalHours)),
      label: l.statsMetricHours,
    ),
    if (totals.averageRating != null)
      StatsHeroMetric(
        value: totals.averageRating!.toStringAsFixed(1),
        label: l.statsMetricAvgRating,
      ),
    StatsHeroMetric(
      value: numberFormat.format(totals.replays),
      label: l.statsMetricReplays,
    ),
    StatsHeroMetric(
      value: numberFormat.format(totals.likedUnits),
      label: l.statsMetricLikedUnits,
    ),
  ];
}

/// Faded cover wall behind the hero headline, with the scrims that keep the
/// text readable on top of it. Renders nothing when there are no covers.
class StatsHeroWall extends StatelessWidget {
  /// Creates the wall.
  const StatsHeroWall({
    required this.items,
    required this.coverCount,
    super.key,
  });

  /// Covers available for the wall; only the first [coverCount] are used.
  final List<CollectionItem> items;

  /// How many covers to spread across the strip. Fewer, wider covers read as
  /// art; more of them turn into a thumbnail strip.
  final int coverCount;

  /// Saturation 0.75, luminance-preserving — the wall must not out-shout the
  /// headline (mockup: `saturate(.75)`).
  static const ColorFilter _desaturate = ColorFilter.matrix(<double>[
    0.80315, 0.17880, 0.01805, 0, 0, //
    0.05315, 0.92880, 0.01805, 0, 0,
    0.05315, 0.17880, 0.76805, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Opacity(
            opacity: 0.5,
            child: ColorFiltered(
              colorFilter: _desaturate,
              child: ShaderMask(
                shaderCallback: (Rect bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Colors.white, Colors.transparent],
                  stops: <double>[0.0, 0.78],
                ).createShader(bounds),
                blendMode: BlendMode.dstIn,
                child: Row(
                  children: <Widget>[
                    for (final CollectionItem item in items.take(coverCount))
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.xs),
                          child: StatsPoster(item: item, radius: 0),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Scrim: solid at the left edge so the headline stays readable,
        // covers peeking through mid-right, brand glow top-left.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  AppColors.background,
                  AppColors.background.withAlpha(140),
                  AppColors.background,
                ],
                stops: const <double>[0.12, 0.55, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.8, -1.0),
                radius: 1.4,
                colors: <Color>[
                  AppColors.brand.withAlpha(46),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A hero metric rendered as a value over its caption.
class StatsHeroMetricTile extends StatelessWidget {
  /// Creates the tile.
  const StatsHeroMetricTile({required this.metric, super.key});

  /// What to render.
  final StatsHeroMetric metric;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          metric.value,
          style: AppTypography.h2.copyWith(letterSpacing: -0.5),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          metric.label,
          style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// The "manual / tracker / estimated" hours split under the metric row, or
/// nothing when no hours were logged.
class StatsHoursBreakdown extends StatelessWidget {
  /// Creates the breakdown line.
  const StatsHoursBreakdown({required this.hours, super.key});

  /// The hours payload.
  final StatsHours hours;

  @override
  Widget build(BuildContext context) {
    if (hours.totalMinutes <= 0) return const SizedBox.shrink();
    final S l = S.of(context);
    return Text(
      l.statsHoursBreakdown(
        hours.manualMinutes ~/ 60,
        hours.trackerMinutes ~/ 60,
        hours.estimatedMinutes ~/ 60,
      ),
      style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
    );
  }
}
