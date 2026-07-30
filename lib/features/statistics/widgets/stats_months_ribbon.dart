import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/widgets/scrollable_row_with_arrows.dart';
import '../models/library_stats.dart';
import 'stats_month_detail_dialog.dart';
import 'stats_poster.dart';
import 'stats_section_header.dart';

/// Active month columns: the best-rated cover of the month, counts, and a
/// bar relative to the peak month. The peak is outlined with the brand color.
class StatsMonthsRibbon extends StatefulWidget {
  /// Creates the ribbon.
  const StatsMonthsRibbon({required this.stats, super.key});

  /// The payload to render.
  final LibraryStats stats;

  @override
  State<StatsMonthsRibbon> createState() => _StatsMonthsRibbonState();
}

class _StatsMonthsRibbonState extends State<StatsMonthsRibbon> {
  static const double _columnWidth = 132;

  /// Cover (2:3 of the column) plus the caption block underneath.
  static const double _rowHeight = _columnWidth * 3 / 2 + 64;

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
    int peak = 0;
    for (final MonthActivity m in months) {
      if (m.activity > peak) peak = m.activity;
    }
    if (peak == 0) return const SizedBox.shrink();

    final String locale = Localizations.localeOf(context).toString();
    final DateFormat monthFormat = DateFormat.MMM(locale);

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
          height: _rowHeight,
          child: ScrollableRowWithArrows(
            controller: _scrollController,
            height: _rowHeight,
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: months.length,
              separatorBuilder: (BuildContext _, int _) =>
                  const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              itemBuilder: (BuildContext context, int index) {
                final MonthActivity month = months[index];
                final bool isPeak =
                    month.activity == peak && month.activity > 0;
                final bool active = month.activity > 0;
                final CollectionItem? cover = month.bestItemId != null
                    ? stats.coversById[month.bestItemId]
                    : null;
                final Widget column = SizedBox(
                  width: _columnWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        decoration: isPeak
                            ? BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusSm,
                                ),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: AppColors.brand.withAlpha(60),
                                    blurRadius: 18,
                                  ),
                                ],
                              )
                            : null,
                        // Foreground, not background — a background border would
                        // be painted under the poster and stay invisible.
                        foregroundDecoration: isPeak
                            ? BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusSm,
                                ),
                                border: Border.all(
                                  color: AppColors.brand,
                                  width: 2,
                                ),
                              )
                            : null,
                        child: cover?.thumbnailUrl != null
                            ? StatsPoster(item: cover)
                            : _EmptyMonthTile(itemsAdded: month.itemsAdded),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: <Widget>[
                          Text(
                            monthFormat.format(
                              DateTime(month.year, month.month),
                            ),
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isPeak) ...<Widget>[
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              l.statsPeakLabel.toUpperCase(),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.brand,
                                fontWeight: FontWeight.w700,
                                fontSize: 9,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        l.statsMonthCounts(
                          month.itemsAdded,
                          month.episodesWatched,
                        ),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs + 2),
                      _MonthBar(
                        fraction: peak > 0 ? month.activity / peak : 0,
                      ),
                    ],
                  ),
                );
                if (!active) return Opacity(opacity: 0.45, child: column);
                return InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  onTap: () => showStatsMonthDetailDialog(
                    context,
                    year: month.year,
                    month: month.month,
                    episodesWatched: month.episodesWatched,
                  ),
                  child: column,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Container(
        height: 3,
        color: AppColors.surfaceLight,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: fraction.clamp(0.0, 1.0),
          child: Container(color: AppColors.brand),
        ),
      ),
    );
  }
}

/// Stand-in for a month without a rated cover: the added count, big and dim,
/// instead of the broken-image icon.
class _EmptyMonthTile extends StatelessWidget {
  const _EmptyMonthTile({required this.itemsAdded});

  final int itemsAdded;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: AppSpacing.posterAspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.surfaceBorder, width: 0.5),
        ),
        alignment: Alignment.center,
        child: itemsAdded > 0
            ? Text(
                '$itemsAdded',
                style: AppTypography.h1.copyWith(
                  fontSize: 28,
                  color: AppColors.textTertiary,
                ),
              )
            : null,
      ),
    );
  }
}
