import 'package:core/models/collection_item.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/constants/media_type_ui.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/segmented_pill.dart';
import '../models/library_stats.dart';
import 'stats_poster.dart';
import 'stats_section_header.dart';

/// Best/worst pair per media type, switched with a pill. Types with fewer
/// than the ratings threshold are absent from [LibraryStats.versus] already.
class StatsVersusSection extends StatefulWidget {
  /// Creates the versus section.
  const StatsVersusSection({
    required this.pairs,
    required this.titleLanguage,
    super.key,
  });

  /// Pairs to show, one per media type.
  final List<VersusPair> pairs;

  /// AniList/Kitsu title language for display names.
  final String titleLanguage;

  @override
  State<StatsVersusSection> createState() => _StatsVersusSectionState();
}

class _StatsVersusSectionState extends State<StatsVersusSection> {
  MediaType? _selected;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    if (widget.pairs.isEmpty) return const SizedBox.shrink();

    final VersusPair pair = widget.pairs.firstWhere(
      (VersusPair p) => p.mediaType == _selected,
      orElse: () => widget.pairs.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        StatsSectionHeader(
          title: l.statsVersusTitle,
          hint: l.statsVersusHint,
        ),
        if (widget.pairs.length > 1) ...<Widget>[
          // Scrollable: with the low ratings threshold most media types
          // qualify, and the tab row outgrows narrow layouts.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedPill<MediaType>(
              selected: pair.mediaType,
              onChanged: (MediaType type) => setState(() => _selected = type),
              options: <SegmentedPillOption<MediaType>>[
                for (final VersusPair p in widget.pairs)
                  SegmentedPillOption<MediaType>(
                    value: p.mediaType,
                    label: p.mediaType.localizedLabel(l),
                    color: MediaTypeTheme.colorFor(p.mediaType),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool wide = constraints.maxWidth >= 720;
            final Widget best = _VersusCard(
              item: pair.best,
              titleLanguage: widget.titleLanguage,
              label: l.statsBest,
              accent: AppColors.success,
              alignEnd: false,
            );
            final Widget worst = _VersusCard(
              item: pair.worst,
              titleLanguage: widget.titleLanguage,
              label: l.statsWorst,
              accent: AppColors.error,
              alignEnd: wide,
            );
            if (!wide) {
              return Column(
                children: <Widget>[
                  best,
                  const SizedBox(height: AppSpacing.sm),
                  worst,
                ],
              );
            }
            // IntrinsicHeight bounds the stretch: the scroll view offers
            // infinite height, and stretch would pass it straight down.
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(child: best),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Center(
                      child: Text(
                        'VS',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: worst),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _VersusCard extends StatelessWidget {
  const _VersusCard({
    required this.item,
    required this.titleLanguage,
    required this.label,
    required this.accent,
    required this.alignEnd,
  });

  final CollectionItem item;
  final String titleLanguage;
  final String label;
  final Color accent;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final double rating = item.userRating ?? 0;
    final String? comment =
        (item.userComment?.trim().isNotEmpty ?? false) ? item.userComment : null;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: accent.withAlpha(80)),
        gradient: LinearGradient(
          begin: alignEnd ? Alignment.topRight : Alignment.topLeft,
          end: Alignment.bottomCenter,
          colors: <Color>[accent.withAlpha(24), AppColors.surface],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          StatsPoster(item: item, width: 112),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label.toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.displayName(titleLanguage),
                  style:
                      AppTypography.h3.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.releaseYear != null)
                  Text(
                    '${item.releaseYear}',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textTertiary),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Text.rich(
                  TextSpan(
                    text: rating.toStringAsFixed(1),
                    style: AppTypography.h1
                        .copyWith(color: accent, fontSize: 44, height: 1),
                    children: <InlineSpan>[
                      TextSpan(
                        text: ' / 10',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                if (comment != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '«$comment»',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
