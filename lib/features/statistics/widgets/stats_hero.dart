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

/// Hero strip: a faded cover wall behind the headline item count, a summary
/// line and the key metric row.
class StatsHero extends StatelessWidget {
  /// Creates the hero strip.
  const StatsHero({required this.stats, super.key});

  /// The payload to render.
  final LibraryStats stats;

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
    final S l = S.of(context);
    final NumberFormat numberFormat = statsNumberFormat(context);
    final LibraryTotals totals = stats.totals;
    final UnitsWatched units = stats.units;
    final int? year = stats.period.year;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wide = constraints.maxWidth >= 720;
        return Stack(
          children: <Widget>[
            if (stats.wallItems.isNotEmpty) ...<Widget>[
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
                          // Fewer, wider covers — the wall reads as art, not
                          // as a thumbnail strip.
                          for (final CollectionItem item
                              in stats.wallItems.take(wide ? 8 : 5))
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(right: AppSpacing.xs),
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
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                wide ? AppSpacing.xl + AppSpacing.lg : AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    (year != null
                            ? l.statsEyebrowYear(year)
                            : l.statsEyebrowAllTime)
                        .toUpperCase(),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    numberFormat.format(totals.items),
                    style: AppTypography.h1.copyWith(
                      fontSize: wide ? 104 : 64,
                      height: 0.95,
                      letterSpacing: wide ? -4 : -2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l.statsLede(numberFormat.format(totals.items)),
                    style: AppTypography.body
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Library-wide consumption totals — per-type counts and
                  // splits live in the type cards right below the hero.
                  Wrap(
                    spacing: AppSpacing.xl,
                    runSpacing: AppSpacing.md,
                    children: <Widget>[
                      if (units.episodes > 0)
                        _Metric(
                          value: numberFormat.format(units.episodes),
                          label: l.statsMetricEpisodes,
                        ),
                      if (units.mangaChapters > 0)
                        _Metric(
                          value: numberFormat.format(units.mangaChapters),
                          label: l.statsMetricMangaChapters,
                        ),
                      if (units.bookPages > 0)
                        _Metric(
                          value: numberFormat.format(units.bookPages),
                          label: l.statsMetricBookPages,
                        ),
                      _Metric(
                        value: l.statsHoursShort(
                            numberFormat.format(stats.hours.totalHours)),
                        label: l.statsMetricHours,
                      ),
                      if (totals.averageRating != null)
                        _Metric(
                          value: totals.averageRating!.toStringAsFixed(1),
                          label: l.statsMetricAvgRating,
                        ),
                      _Metric(
                        value: numberFormat.format(totals.replays),
                        label: l.statsMetricReplays,
                      ),
                      _Metric(
                        value: numberFormat.format(totals.likedUnits),
                        label: l.statsMetricLikedUnits,
                      ),
                    ],
                  ),
                  if (stats.hours.totalMinutes > 0) ...<Widget>[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l.statsHoursBreakdown(
                        stats.hours.manualMinutes ~/ 60,
                        stats.hours.trackerMinutes ~/ 60,
                        stats.hours.estimatedMinutes ~/ 60,
                      ),
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          value,
          style: AppTypography.h2.copyWith(letterSpacing: -0.5),
        ),
        Text(
          label,
          style:
              AppTypography.caption.copyWith(color: AppColors.textTertiary),
        ),
      ],
    );
  }
}
