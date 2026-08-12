import 'package:core/models/item_status.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/item_status_ui.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/constants/media_type_ui.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../layout/stats_layout.dart';
import '../layout/stats_layout_scope.dart';
import '../models/library_stats.dart';
import 'stats_cards.dart';
import 'stats_section_header.dart';

/// One card per media type: count, stacked status bar with a legend, and the
/// type's own consumption counter — the split the hero omits.
class StatsTypesSection extends StatelessWidget {
  /// Creates the per-type breakdown section.
  const StatsTypesSection({required this.stats, super.key});

  /// The payload to render.
  final LibraryStats stats;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final List<(MediaType, Map<ItemStatus, int>, int)> types =
        <(MediaType, Map<ItemStatus, int>, int)>[
      for (final MapEntry<MediaType, Map<ItemStatus, int>> entry
          in stats.typeStatus.entries)
        (
          entry.key,
          entry.value,
          entry.value.values.fold(0, (int sum, int c) => sum + c),
        ),
    ]
      ..removeWhere(((MediaType, Map<ItemStatus, int>, int) t) => t.$3 == 0)
      ..sort(((MediaType, Map<ItemStatus, int>, int) a,
              (MediaType, Map<ItemStatus, int>, int) b) =>
          b.$3.compareTo(a.$3));
    if (types.isEmpty) return const SizedBox.shrink();

    final NumberFormat numberFormat = statsNumberFormat(context);
    final StatsLayout layout = StatsLayoutScope.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        StatsSectionHeader(
          title: l.statsTypesTitle,
          hint: l.statsTypesHint,
        ),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final int columns = (constraints.maxWidth / layout.typeCardMinWidth)
                .floor()
                .clamp(1, layout.typeCardMaxColumns);
            final double width =
                (constraints.maxWidth - (columns - 1) * AppSpacing.md) /
                    columns;
            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: <Widget>[
                for (final (MediaType, Map<ItemStatus, int>, int) t in types)
                  SizedBox(
                    width: width,
                    child: _TypeCard(
                      mediaType: t.$1,
                      statusCounts: t.$2,
                      itemCount: t.$3,
                      stats: stats,
                      numberFormat: numberFormat,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.mediaType,
    required this.statusCounts,
    required this.itemCount,
    required this.stats,
    required this.numberFormat,
  });

  final MediaType mediaType;
  final Map<ItemStatus, int> statusCounts;
  final int itemCount;
  final LibraryStats stats;
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final Color accent = MediaTypeTheme.colorFor(mediaType);
    final String? unitsLine = _unitsLine(l);

    return StatsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            mediaType.localizedPluralLabel(l),
            style: AppTypography.bodySmall.copyWith(
              color: accent,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            numberFormat.format(itemCount),
            style: AppTypography.h1.copyWith(fontSize: 30, height: 1.1),
          ),
          // One caption shape for every type: units when the type has them,
          // completion always — the game card must not look different.
          Text(
            <String>[
              ?unitsLine,
              l.statsCompletedPercent(statusCounts.completedPercent),
            ].join(' · '),
            style:
                AppTypography.caption.copyWith(color: AppColors.textTertiary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          StatusSplitBar(counts: statusCounts),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              for (final MapEntry<ItemStatus, int> entry
                  in statusCounts.sortedSegments)
                StatsLegendDot(
                  color: entry.key.color,
                  label: entry.key.localizedLabel(l, mediaType),
                  count: numberFormat.format(entry.value),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// The type's own consumption counter (episodes / chapters / pages / liked
  /// units), or null when the type has none to show.
  String? _unitsLine(S l) {
    final UnitsWatched units = stats.units;
    final int liked = stats.likedByType[mediaType] ?? 0;
    final List<String> parts = <String>[
      switch (mediaType) {
        MediaType.tvShow when units.tvEpisodes > 0 =>
          '${numberFormat.format(units.tvEpisodes)} ${l.statsMetricEpisodes}',
        MediaType.anime when units.animeEpisodes > 0 =>
          '${numberFormat.format(units.animeEpisodes)} '
              '${l.statsMetricEpisodes}',
        MediaType.movie when units.moviesWatched > 0 =>
          '${numberFormat.format(units.moviesWatched)} '
              '${l.statsMetricMoviesWatched}',
        MediaType.manga when units.mangaChapters > 0 =>
          '${numberFormat.format(units.mangaChapters)} '
              '${l.statsMetricMangaChapters}',
        MediaType.book when units.bookPages > 0 =>
          '${numberFormat.format(units.bookPages)} ${l.statsMetricBookPages}',
        MediaType.music when units.musicTracks > 0 =>
          '${numberFormat.format(units.musicTracks)} ${l.statsMetricTracks}',
        _ => '',
      },
      if (liked > 0)
        '${numberFormat.format(liked)} ${l.statsMetricLikedUnits}',
    ]..removeWhere((String s) => s.isEmpty);
    return parts.isEmpty ? null : parts.join(' · ');
  }
}
