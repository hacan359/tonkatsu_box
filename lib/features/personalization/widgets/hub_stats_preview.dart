import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../statistics/models/library_stats.dart';
import '../../statistics/providers/statistics_provider.dart';
import '../../statistics/widgets/stats_cards.dart';
import '../../statistics/widgets/stats_hero_common.dart';
import 'hub_poster_strip.dart';

/// The headline numbers of the statistics hero, compressed into one strip.
class HubStatsPreview extends ConsumerWidget {
  const HubStatsPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final AsyncValue<LibraryStats> statsAsync =
        ref.watch(libraryStatsProvider);
    return statsAsync.when(
      loading: () => const SizedBox(height: kHubPreviewPlaceholderHeight),
      error: (Object error, StackTrace _) => Text(
        '${l.settingsError}: $error',
        style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      data: (LibraryStats stats) => stats.isEmpty
          ? HubPreviewNote(l.statsEmptyTitle)
          : _Metrics(stats: stats),
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.stats});

  final LibraryStats stats;

  /// Width of the fade that hides the cut at the right edge.
  static const double _fadeWidth = 32;

  @override
  Widget build(BuildContext context) {
    final List<StatsHeroMetric> metrics = statsHeroMetrics(context, stats);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          statsNumberFormat(context).format(stats.totals.items),
          style: AppTypography.h1.copyWith(
            fontSize: 40,
            height: 1,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          // One line that fades out instead of wrapping: the card is a
          // glance, the screen behind it has the full grid.
          child: ShaderMask(
            shaderCallback: (Rect bounds) => LinearGradient(
              colors: <Color>[
                Colors.white,
                Colors.white,
                Colors.white.withAlpha(0),
              ],
              stops: <double>[
                0,
                (1 - _fadeWidth / bounds.width).clamp(0.0, 1.0),
                1,
              ],
            ).createShader(bounds),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                children: <Widget>[
                  for (int i = 0; i < metrics.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(width: AppSpacing.lg),
                    StatsHeroMetricTile(metric: metrics[i]),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
