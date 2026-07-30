import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/constants/media_type_ui.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../models/library_stats.dart';
import 'stats_cards.dart';
import 'stats_section_header.dart';

/// Source subgenre tags as chips — the anime and manga cards sit side by
/// side (50/50) on wide layouts and stack on narrow ones. The per-source
/// vocabularies differ, so the cards are never merged.
class StatsSubgenresSection extends StatelessWidget {
  /// Creates the subgenres section.
  const StatsSubgenresSection({required this.stats, super.key});

  /// The payload to render.
  final LibraryStats stats;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    if (stats.subgenres.isEmpty) return const SizedBox.shrink();

    final List<Widget> cards = <Widget>[
      for (final SubgenreGroup group in stats.subgenres)
        _TagCard(
          title: group.mediaType.localizedLabel(l),
          subtitle: l.statsSubgenresTitles(group.titleCount),
          color: MediaTypeTheme.colorFor(group.mediaType),
          tags: group.tags,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        StatsSectionHeader(
          title: l.statsSubgenresTitle,
          hint: l.statsSubgenresHint,
        ),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (cards.length < 2 || constraints.maxWidth < 720) {
              return Column(
                children: <Widget>[
                  for (final (int index, Widget card) in cards.indexed)
                    Padding(
                      padding: EdgeInsets.only(
                          top: index > 0 ? AppSpacing.md : 0),
                      child: card,
                    ),
                ],
              );
            }
            // Wide: anime and manga split the row 50/50. Top-aligned, no
            // IntrinsicHeight — the tag grids inside use LayoutBuilder,
            // which cannot answer intrinsic height queries.
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final (int index, Widget card) in cards.indexed)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          left: index > 0 ? AppSpacing.md : 0),
                      child: card,
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

class _TagCard extends StatelessWidget {
  const _TagCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.tags,
  });

  final String title;
  final String subtitle;
  final Color color;
  final List<TagCount> tags;

  @override
  Widget build(BuildContext context) {
    int max = 0;
    for (final TagCount tag in tags) {
      if (tag.count > max) max = tag.count;
    }
    return StatsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: AppTypography.body
                .copyWith(fontWeight: FontWeight.w600, color: color),
          ),
          Text(
            subtitle,
            style:
                AppTypography.caption.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final (int index, TagCount tag) in tags.indexed)
                _TagChip(
                  tag: tag,
                  fraction: max > 0 ? tag.count / max : 0,
                  color: color,
                  emphasized: index < 3,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.tag,
    required this.fraction,
    required this.color,
    required this.emphasized,
  });

  final TagCount tag;

  /// Fill length relative to the most frequent tag of the card.
  final double fraction;

  final Color color;

  /// Top chips of the card get a stronger border and a brighter label.
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                emphasized ? AppColors.textTertiary : AppColors.surfaceBorder,
            width: 0.5,
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fraction.clamp(0.0, 1.0),
                child: ColoredBox(color: color.withAlpha(56)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + AppSpacing.xs,
                vertical: 5,
              ),
              child: Text.rich(
                TextSpan(
                  text: tag.name,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: emphasized ? null : AppColors.textSecondary,
                  ),
                  children: <InlineSpan>[
                    TextSpan(
                      text: '  ${tag.count}',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
