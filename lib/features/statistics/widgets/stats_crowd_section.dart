import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../models/library_stats.dart';
import 'stats_cards.dart';
import 'stats_poster.dart';
import 'stats_section_header.dart';

/// "Me vs the crowd": items where the user's rating differs most from the
/// source rating, as dumbbell rows on a shared 0–10 axis.
class StatsCrowdSection extends StatelessWidget {
  /// Creates the crowd section.
  const StatsCrowdSection({
    required this.stats,
    required this.titleLanguage,
    super.key,
  });

  /// The payload to render.
  final LibraryStats stats;

  /// AniList/Kitsu title language for display names.
  final String titleLanguage;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    if (stats.higherThanCrowd.isEmpty && stats.lowerThanCrowd.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        StatsSectionHeader(
          title: l.statsCrowdTitle,
          hint: l.statsCrowdHint,
        ),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool wide = constraints.maxWidth >= 860;
            final List<Widget> cards = <Widget>[
              if (stats.higherThanCrowd.isNotEmpty)
                _CrowdCard(
                  title: l.statsCrowdHigher,
                  rows: stats.higherThanCrowd,
                  accent: AppColors.brand,
                  titleLanguage: titleLanguage,
                ),
              if (stats.lowerThanCrowd.isNotEmpty)
                _CrowdCard(
                  title: l.statsCrowdLower,
                  rows: stats.lowerThanCrowd,
                  accent: AppColors.statusInProgress,
                  titleLanguage: titleLanguage,
                ),
            ];
            if (!wide || cards.length == 1) {
              return Column(
                children: <Widget>[
                  for (final Widget card in cards)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: card,
                    ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: cards[0]),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: cards[1]),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CrowdCard extends StatelessWidget {
  const _CrowdCard({
    required this.title,
    required this.rows,
    required this.accent,
    required this.titleLanguage,
  });

  final String title;
  final List<RatingDelta> rows;
  final Color accent;
  final String titleLanguage;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return StatsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title,
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.md),
          for (final RatingDelta row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _CrowdRow(
                delta: row,
                accent: accent,
                titleLanguage: titleLanguage,
              ),
            ),
          Row(
            children: <Widget>[
              StatsLegendDot(color: accent, label: l.statsCrowdMyRating),
              const SizedBox(width: AppSpacing.md),
              StatsLegendDot(
                color: AppColors.textTertiary,
                label: l.statsCrowdSource,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CrowdRow extends StatelessWidget {
  const _CrowdRow({
    required this.delta,
    required this.accent,
    required this.titleLanguage,
  });

  final RatingDelta delta;
  final Color accent;
  final String titleLanguage;

  @override
  Widget build(BuildContext context) {
    final double gap = delta.delta;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        StatsPoster(item: delta.item, width: 34, radius: AppSpacing.radiusXs),
        const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                delta.item.displayName(titleLanguage),
                style: AppTypography.caption
                    .copyWith(color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              _DumbbellTrack(delta: delta, accent: accent),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 48,
          child: Text(
            '${gap > 0 ? '+' : ''}${gap.toStringAsFixed(1)}',
            textAlign: TextAlign.right,
            style: AppTypography.bodySmall
                .copyWith(color: accent, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// The 0–10 axis with the source dot, the user dot and a connecting bar.
class _DumbbellTrack extends StatelessWidget {
  const _DumbbellTrack({required this.delta, required this.accent});

  final RatingDelta delta;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth;
          double x(double rating) =>
              (rating.clamp(0.0, 10.0) / 10.0) * (width - 12) + 6;
          final double mine = x(delta.mine);
          final double external = x(delta.external);
          final double left = mine < external ? mine : external;
          final double right = mine < external ? external : mine;
          return Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(
                left: 0,
                right: 0,
                top: 6.5,
                child: Container(height: 1, color: AppColors.surfaceLight),
              ),
              Positioned(
                left: left,
                width: right - left,
                top: 5.5,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: accent.withAlpha(110),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Positioned(
                left: external - 5,
                top: 2,
                child: const _Dot(color: AppColors.textTertiary),
              ),
              Positioned(
                left: mine - 5,
                top: 2,
                child: _Dot(color: accent),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 2),
      ),
    );
  }
}

