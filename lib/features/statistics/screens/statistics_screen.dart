import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/services/png_export_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/logo_loader.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/library_stats.dart';
import '../providers/statistics_provider.dart';
import '../widgets/stats_crowd_section.dart';
import '../widgets/stats_formats_section.dart';
import '../widgets/stats_hero.dart';
import '../widgets/stats_months_ribbon.dart';
import '../widgets/stats_platforms_section.dart';
import '../widgets/stats_share_card.dart';
import '../widgets/stats_subgenres_section.dart';
import '../widgets/stats_types_section.dart';
import '../widgets/stats_versus_section.dart';

final Logger _log = Logger('StatisticsScreen');

/// How many recent years the period picker offers besides "all time".
const int _maxYearOptions = 5;

/// The statistics tab of the personalization hub.
class StatisticsScreen extends ConsumerStatefulWidget {
  /// Creates the statistics screen.
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  final GlobalKey _exportKey = GlobalKey();

  /// Mounts the offscreen share card only while exporting.
  bool _exporting = false;

  Future<void> _exportShareCard(LibraryStats stats) async {
    final S l = S.of(context);
    setState(() => _exporting = true);
    // Two frames with a pause in between so CachedImage covers land in the
    // capture (same rhythm as the mood grid export).
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 150));
    await WidgetsBinding.instance.endOfFrame;

    final String base = sanitizeFileName(
      stats.period.year != null
          ? l.statsShareTitleYear(stats.period.year!)
          : l.statsShareTitleAllTime,
    );
    final BulkExportResult result;
    try {
      result = await saveBoundaryAsPng(
        repaintKey: _exportKey,
        suggestedFileName: '${base.isEmpty ? 'library_stats' : base}.png',
        saveDialogTitle: l.statsExportTitle,
      );
    } finally {
      // Errors from toImage escape saveBoundaryAsPng; never leave the share
      // button wedged in the disabled state.
      if (mounted) setState(() => _exporting = false);
    }
    if (!mounted) return;

    switch (result.status) {
      case BulkExportStatus.saved:
        context.showSnack(l.imageSaved, type: SnackType.success);
      case BulkExportStatus.cancelled:
        break;
      case BulkExportStatus.failed:
        _log.warning('Failed to export the stats share card', result.error);
        context.showSnack(l.statsExportFailed, type: SnackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final AsyncValue<LibraryStats> statsAsync =
        ref.watch(libraryStatsProvider);
    final String titleLanguage = ref.watch(
      settingsNotifierProvider
          .select((SettingsState s) => s.animeMangaTitleLanguage),
    );

    return statsAsync.when(
      loading: () => const Center(child: LogoLoader()),
      error: (Object error, StackTrace _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            '${l.settingsError}: $error',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ),
      data: (LibraryStats stats) => Stack(
        children: <Widget>[
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl * 2),
              child: Center(
                child: ConstrainedBox(
                  // The mockup page column: sections never stretch edge to
                  // edge on a wide desktop window.
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        // No horizontal inset: the tabs line up with the
                        // full-bleed hero panel right below them.
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: _buildToolbar(l, stats),
                      ),
                      if (stats.isEmpty)
                        _buildEmptyState(l)
                      else ...<Widget>[
                        StatsHero(stats: stats),
                        for (final Widget section in <Widget>[
                          StatsTypesSection(stats: stats),
                          StatsMonthsRibbon(stats: stats),
                          StatsVersusSection(
                            pairs: stats.versus,
                            titleLanguage: titleLanguage,
                          ),
                          StatsPlatformsSection(stats: stats),
                          StatsFormatsSection(
                            stats: stats,
                            mediaType: MediaType.anime,
                          ),
                          StatsFormatsSection(
                            stats: stats,
                            mediaType: MediaType.manga,
                          ),
                          StatsSubgenresSection(stats: stats),
                          StatsCrowdSection(
                            stats: stats,
                            titleLanguage: titleLanguage,
                          ),
                        ])
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              0,
                              AppSpacing.md,
                              AppSpacing.xl + AppSpacing.lg,
                            ),
                            child: section,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Offscreen share card, mounted only during export.
          if (_exporting)
            Positioned(
              left: -10000,
              top: -10000,
              child: Material(
                type: MaterialType.transparency,
                child: StatsShareCard(
                  repaintKey: _exportKey,
                  stats: stats,
                  titleLanguage: titleLanguage,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToolbar(S l, LibraryStats stats) {
    final StatsPeriod period = ref.watch(statsPeriodProvider);
    final List<int> years =
        stats.availableYears.take(_maxYearOptions).toList();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            // No horizontal padding inside the tabs: the first label sits
            // flush with the section content below.
            child: Row(
              spacing: AppSpacing.lg,
              children: <Widget>[
                _PeriodTab(
                  label: l.statsPeriodAllTime,
                  selected: period.isAllTime,
                  onTap: () => ref.read(statsPeriodProvider.notifier).state =
                      const StatsPeriod.allTime(),
                ),
                for (final int year in years)
                  _PeriodTab(
                    label: '$year',
                    selected: period.year == year,
                    onTap: () => ref.read(statsPeriodProvider.notifier).state =
                        StatsPeriod.year(year),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (!stats.isEmpty)
          IconButton(
            tooltip: l.statsExportTitle,
            onPressed: _exporting ? null : () => _exportShareCard(stats),
            icon: const Icon(Icons.ios_share, size: 20),
            style: IconButton.styleFrom(minimumSize: const Size(40, 40)),
          ),
      ],
    );
  }

  Widget _buildEmptyState(S l) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl * 2),
      child: Center(
        child: Column(
          children: <Widget>[
            const Icon(
              Icons.insights_outlined,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l.statsEmptyTitle,
              style: AppTypography.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l.statsEmptyBody,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// One underline tab of the period picker: the active period gets a brand
/// underline and bright label, the rest stay muted.
class _PeriodTab extends StatelessWidget {
  const _PeriodTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.brand : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: selected ? null : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
