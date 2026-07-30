import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/constants/media_type_ui.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/logo_loader.dart';
import '../models/library_stats.dart';
import '../providers/statistics_provider.dart';
import 'stats_cards.dart';

/// Opens the month drill-down dialog.
Future<void> showStatsMonthDetailDialog(
  BuildContext context, {
  required int year,
  required int month,
  required int episodesWatched,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext _) => StatsMonthDetailDialog(
      year: year,
      month: month,
      episodesWatched: episodesWatched,
    ),
  );
}

/// Month drill-down: week bars stacked by media type, with a per-type legend.
class StatsMonthDetailDialog extends ConsumerWidget {
  /// Creates the dialog.
  const StatsMonthDetailDialog({
    required this.year,
    required this.month,
    required this.episodesWatched,
    super.key,
  });

  /// Calendar year of the month shown.
  final int year;

  /// Calendar month, 1–12.
  final int month;

  /// Episodes watched this month (already computed by the ribbon).
  final int episodesWatched;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final AsyncValue<MonthDetail> detail =
        ref.watch(monthDetailProvider((year, month)));

    return AlertDialog(
      title: Text(DateFormat.yMMMM(locale).format(DateTime(year, month))),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: detail.when(
            loading: () => const SizedBox(
              height: 160,
              child: Center(child: LogoLoader()),
            ),
            error: (Object error, StackTrace _) => Text(
              '${l.settingsError}: $error',
              style:
                  AppTypography.body.copyWith(color: AppColors.textSecondary),
            ),
            data: (MonthDetail d) {
              // Per-type totals across the whole month feed the legend.
              final Map<MediaType, int> typeTotals = <MediaType, int>{};
              for (final Map<MediaType, int> week in d.weeks) {
                week.forEach((MediaType type, int count) {
                  typeTotals[type] = (typeTotals[type] ?? 0) + count;
                });
              }
              final List<MapEntry<MediaType, int>> legend =
                  typeTotals.entries.toList()
                    ..sort(
                      (MapEntry<MediaType, int> a, MapEntry<MediaType, int> b) =>
                          b.value.compareTo(a.value),
                    );
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l.statsMonthCounts(d.totalAdded, episodesWatched),
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _WeekBars(weeks: d.weeks),
                  if (legend.isNotEmpty) ...<Widget>[
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xs,
                      children: <Widget>[
                        for (final MapEntry<MediaType, int> entry in legend)
                          StatsLegendDot(
                            color: MediaTypeTheme.colorFor(entry.key),
                            label: entry.key.localizedLabel(l),
                            count: '${entry.value}',
                          ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Five day-bucket bars (1–7 … 29+), segments stacked by media-type color.
class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.weeks});

  final List<Map<MediaType, int>> weeks;

  static const double _barHeight = 72;
  static const List<String> _labels = <String>[
    '1–7',
    '8–14',
    '15–21',
    '22–28',
    '29+',
  ];

  @override
  Widget build(BuildContext context) {
    int maxTotal = 0;
    for (final Map<MediaType, int> week in weeks) {
      final int total = week.values.fold(0, (int sum, int c) => sum + c);
      if (total > maxTotal) maxTotal = total;
    }
    if (maxTotal == 0) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        for (final (int index, Map<MediaType, int> week) in weeks.indexed)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _WeekBar(
                  week: week,
                  maxTotal: maxTotal,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _labels[index],
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textTertiary, fontSize: 10),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One bucket bar: proportional flex segments can never overflow the track.
class _WeekBar extends StatelessWidget {
  const _WeekBar({required this.week, required this.maxTotal});

  final Map<MediaType, int> week;
  final int maxTotal;

  @override
  Widget build(BuildContext context) {
    final int total = week.values.fold(0, (int sum, int c) => sum + c);
    return SizedBox(
      height: _WeekBars._barHeight,
      width: 32,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          if (total == 0)
            Container(height: 2, color: AppColors.surfaceLight)
          else
            SizedBox(
              height: total / maxTotal * _WeekBars._barHeight,
              child: Column(
                children: <Widget>[
                  for (final MediaType type in MediaType.values)
                    if ((week[type] ?? 0) > 0)
                      Expanded(
                        flex: week[type]!,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 1),
                          decoration: BoxDecoration(
                            color: MediaTypeTheme.colorFor(type),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
