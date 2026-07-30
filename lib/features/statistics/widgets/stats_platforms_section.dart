import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_ui.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../models/library_stats.dart';
import 'stats_cards.dart';
import 'stats_section_header.dart';

/// Game platform cards ordered by popularity (game count). Collapsed to two
/// rows; the rest unfolds on demand. Hours show as a dash when unknown.
class StatsPlatformsSection extends StatefulWidget {
  /// Creates the platforms section.
  const StatsPlatformsSection({required this.stats, super.key});

  /// The payload to render.
  final LibraryStats stats;

  @override
  State<StatsPlatformsSection> createState() => _StatsPlatformsSectionState();
}

class _StatsPlatformsSectionState extends State<StatsPlatformsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final List<PlatformStats> platforms = widget.stats.platforms;
    if (platforms.isEmpty) return const SizedBox.shrink();

    final NumberFormat numberFormat = statsNumberFormat(context);
    int totalMinutes = 0;
    int totalGames = 0;
    for (final PlatformStats p in platforms) {
      totalMinutes += p.minutes;
      totalGames += p.gameCount;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        StatsSectionHeader(
          title: MediaType.game.localizedPluralLabel(l),
          hint: l.statsPlatformsSummary(
            numberFormat.format(totalMinutes ~/ 60),
            totalGames,
          ),
        ),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final int columns =
                (constraints.maxWidth / 260).floor().clamp(1, 4);
            final double width = (constraints.maxWidth -
                    (columns - 1) * AppSpacing.md) /
                columns;
            final int collapsedCount = columns * 2;
            final List<PlatformStats> visible = _expanded
                ? platforms
                : platforms.take(collapsedCount).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: <Widget>[
                    for (final (int index, PlatformStats p)
                        in visible.indexed)
                      SizedBox(
                        width: width,
                        child: _PlatformCard(
                          platform: p,
                          stats: widget.stats,
                          numberFormat: numberFormat,
                          topPlatform: index == 0,
                        ),
                      ),
                  ],
                ),
                if (platforms.length > collapsedCount)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: TextButton(
                      onPressed: () =>
                          setState(() => _expanded = !_expanded),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm),
                        minimumSize:
                            const Size(0, AppSpacing.buttonHeightCompact),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        _expanded
                            ? l.statsPlatformsCollapse
                            : l.statsPlatformsShowAll(platforms.length),
                        style: AppTypography.bodySmall,
                      ),
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

class _PlatformCard extends StatelessWidget {
  const _PlatformCard({
    required this.platform,
    required this.stats,
    required this.numberFormat,
    required this.topPlatform,
  });

  final PlatformStats platform;
  final LibraryStats stats;
  final NumberFormat numberFormat;

  /// The most popular platform (most games) gets an accent border.
  final bool topPlatform;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return StatsCard(
      highlightColor: topPlatform ? AppColors.brand : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            platform.name ?? l.statsPlatformNone,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              text: numberFormat.format(platform.gameCount),
              style: AppTypography.h1.copyWith(fontSize: 30, height: 1.1),
              children: <InlineSpan>[
                TextSpan(
                  text: ' ${l.statsGamesUnit}',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          Text(
            <String>[
              platform.minutes > 0
                  ? l.statsHoursShort(numberFormat.format(platform.hours))
                  : '—',
              l.statsCompletedPercent(platform.statusCounts.completedPercent),
            ].join(' · '),
            style:
                AppTypography.caption.copyWith(color: AppColors.textTertiary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          StatusSplitBar(counts: platform.statusCounts),
          const SizedBox(height: AppSpacing.sm),
          if (platform.topItemIds.isNotEmpty) ...<Widget>[
            Text(
              platform.minutes > 0
                  ? l.statsPlatformMostPlayed
                  : l.statsTopHint(platform.topItemIds.length),
              style: AppTypography.caption
                  .copyWith(color: AppColors.textTertiary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          StatsTopCoversRow(
            itemIds: platform.topItemIds,
            coversById: stats.coversById,
          ),
        ],
      ),
    );
  }
}
