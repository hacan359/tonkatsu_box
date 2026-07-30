import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/constants/media_type_ui.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../models/library_stats.dart';
import 'stats_cards.dart';
import 'stats_section_header.dart';

/// Source-format cards for one media type (anime or manga) — the same card
/// shape as the games-by-platform block: count, status split, top covers.
class StatsFormatsSection extends StatelessWidget {
  /// Creates the formats section.
  const StatsFormatsSection({
    required this.stats,
    required this.mediaType,
    super.key,
  });

  /// The payload to render.
  final LibraryStats stats;

  /// Which type's formats this block shows (anime or manga).
  final MediaType mediaType;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final List<FormatStats> formats =
        stats.formatsByType[mediaType] ?? const <FormatStats>[];
    if (formats.isEmpty) return const SizedBox.shrink();

    final NumberFormat numberFormat = statsNumberFormat(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        StatsSectionHeader(
          title: mediaType.localizedLabel(l),
          hint: l.statsFormatsHint,
        ),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final int columns =
                (constraints.maxWidth / 260).floor().clamp(1, 4);
            final double width =
                (constraints.maxWidth - (columns - 1) * AppSpacing.md) /
                    columns;
            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: <Widget>[
                for (final (int index, FormatStats format)
                    in formats.indexed)
                  SizedBox(
                    width: width,
                    child: _FormatCard(
                      format: format,
                      stats: stats,
                      accent: MediaTypeTheme.colorFor(mediaType),
                      numberFormat: numberFormat,
                      topFormat: index == 0,
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

class _FormatCard extends StatelessWidget {
  const _FormatCard({
    required this.format,
    required this.stats,
    required this.accent,
    required this.numberFormat,
    required this.topFormat,
  });

  final FormatStats format;
  final LibraryStats stats;

  /// The owning media type's brand color.
  final Color accent;

  final NumberFormat numberFormat;

  /// The biggest format gets an accent border, like the top platform.
  final bool topFormat;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return StatsCard(
      highlightColor: topFormat ? accent : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            format.label,
            style: AppTypography.bodySmall.copyWith(color: accent),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              text: numberFormat.format(format.count),
              style: AppTypography.h1.copyWith(fontSize: 30, height: 1.1),
              children: <InlineSpan>[
                TextSpan(
                  text: ' ${l.statsTitlesUnit}',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          Text(
            l.statsCompletedPercent(format.statusCounts.completedPercent),
            style:
                AppTypography.caption.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          StatusSplitBar(counts: format.statusCounts),
          const SizedBox(height: AppSpacing.sm),
          if (format.topItemIds.isNotEmpty) ...<Widget>[
            Text(
              l.statsTopHint(format.topItemIds.length),
              style: AppTypography.caption
                  .copyWith(color: AppColors.textTertiary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          StatsTopCoversRow(
            itemIds: format.topItemIds,
            coversById: stats.coversById,
          ),
        ],
      ),
    );
  }
}
