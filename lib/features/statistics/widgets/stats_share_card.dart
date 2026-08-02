import 'package:core/models/collection_item.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../models/library_stats.dart';
import 'stats_cards.dart';
import 'stats_poster.dart';

/// Fixed export width — a constant, not a formula, so the offscreen layout
/// can never drift from the container (CLAUDE.md layout trap #3).
const double kStatsShareCardWidth = 620;

/// The share card exported as PNG: a cover collage, one big number and a
/// short stat grid. Rendered offscreen behind a [RepaintBoundary].
class StatsShareCard extends StatelessWidget {
  /// Creates the share card.
  const StatsShareCard({
    required this.repaintKey,
    required this.stats,
    required this.titleLanguage,
    super.key,
  });

  /// Key of the boundary the exporter captures.
  final GlobalKey repaintKey;

  /// The payload to render.
  final LibraryStats stats;

  /// AniList/Kitsu title language for the best-of caption.
  final String titleLanguage;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final NumberFormat numberFormat = statsNumberFormat(context);
    final LibraryTotals totals = stats.totals;
    final CollectionItem? best =
        stats.topRated.isNotEmpty ? stats.topRated.first : null;
    final List<CollectionItem> collage = stats.wallItems.take(8).toList();

    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        width: kStatsShareCardWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.brand.withAlpha(70)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              AppColors.brand.withAlpha(36),
              AppColors.background,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (collage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Row(
                  children: <Widget>[
                    for (final CollectionItem item in collage)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: StatsPoster(
                            item: item,
                            radius: AppSpacing.radiusXs,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    (stats.period.year != null
                            ? l.statsShareTitleYear(stats.period.year!)
                            : l.statsShareTitleAllTime)
                        .toUpperCase(),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l.statsHoursShort(
                        numberFormat.format(stats.hours.totalHours)),
                    style: AppTypography.h1
                        .copyWith(fontSize: 52, height: 1, letterSpacing: -2),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l.statsShareLede(
                      numberFormat.format(totals.items),
                      numberFormat.format(totals.completed),
                      totals.averageRating?.toStringAsFixed(1) ?? '—',
                    ),
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _ShareStat(
                          value: numberFormat.format(stats.units.episodes),
                          label: l.statsMetricEpisodes,
                        ),
                      ),
                      Expanded(
                        child: _ShareStat(
                          value: numberFormat.format(totals.replays),
                          label: l.statsMetricReplays,
                        ),
                      ),
                      Expanded(
                        child: _ShareStat(
                          value: numberFormat.format(totals.likedUnits),
                          label: l.statsMetricLikedUnits,
                        ),
                      ),
                      Expanded(
                        child: _ShareStat(
                          value:
                              numberFormat.format(stats.units.moviesWatched),
                          label: l.statsMetricMoviesWatched,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: AppColors.surfaceBorder,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Text(
                          'Tonkatsu Box',
                          style: AppTypography.caption
                              .copyWith(color: AppColors.textTertiary),
                        ),
                        const Spacer(),
                        if (best != null && best.userRating != null)
                          Flexible(
                            child: Text(
                              l.statsShareBest(
                                best.displayName(titleLanguage),
                                best.userRating!.toStringAsFixed(1),
                              ),
                              style: AppTypography.caption
                                  .copyWith(color: AppColors.textTertiary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareStat extends StatelessWidget {
  const _ShareStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(value, style: AppTypography.h3),
        Text(
          label,
          style:
              AppTypography.caption.copyWith(color: AppColors.textTertiary),
        ),
      ],
    );
  }
}
