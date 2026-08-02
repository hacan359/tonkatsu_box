import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/services/png_export_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/logo_loader.dart';
import '../../settings/providers/settings_provider.dart';
import '../layout/stats_layout_scope.dart';
import '../models/library_stats.dart';
import '../providers/statistics_provider.dart';
import '../views/statistics_view_desktop.dart';
import '../views/statistics_view_mobile.dart';
import '../widgets/stats_period_picker.dart';
import '../widgets/stats_share_card.dart';

final Logger _log = Logger('StatisticsScreen');

/// How many recent years the period picker offers besides "all time".
const int _maxYearOptions = 5;

/// The statistics tab. Owns the form-factor-independent parts — provider,
/// period picker, PNG export — and hands the payload to one of the two pages.
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
          Positioned.fill(child: _buildPage(l, stats, titleLanguage)),
          // Outside the page, so the export keeps its fixed width whichever
          // layout is showing.
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

  /// Picks the page by measured content width, not [MediaQuery]: the nav
  /// shell makes the window width overstate the room the sections get.
  Widget _buildPage(S l, LibraryStats stats, String titleLanguage) {
    // Assembled here, not inside the builder below: LayoutBuilder's callback
    // runs during layout, and ref.watch is only legal during build.
    final StatsPeriodPickerData picker = _buildPeriodPicker(l, stats);
    if (stats.isEmpty) {
      // No hero to host the dropdown, so it stands on its own — the year
      // picker still has to work when the period has no data.
      return SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: StatsPeriodPicker(data: picker),
              ),
            ),
            _buildEmptyState(l),
          ],
        ),
      );
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < kStatsMobileBreakpoint) {
          return StatisticsViewMobile(
            stats: stats,
            titleLanguage: titleLanguage,
            picker: picker,
          );
        }
        return StatisticsViewDesktop(
          stats: stats,
          titleLanguage: titleLanguage,
          picker: picker,
        );
      },
    );
  }

  /// The selectable periods and the share action.
  StatsPeriodPickerData _buildPeriodPicker(S l, LibraryStats stats) {
    return StatsPeriodPickerData(
      selected: ref.watch(statsPeriodProvider),
      onChanged: (StatsPeriod next) =>
          ref.read(statsPeriodProvider.notifier).state = next,
      periods: <StatsPeriod>[
        const StatsPeriod.allTime(),
        for (final int year in stats.availableYears.take(_maxYearOptions))
          StatsPeriod.year(year),
      ],
      trailing: stats.isEmpty
          ? null
          : IconButton(
              tooltip: l.statsExportTitle,
              onPressed: _exporting ? null : () => _exportShareCard(stats),
              icon: const Icon(Icons.ios_share, size: 20),
              style: IconButton.styleFrom(minimumSize: const Size(40, 40)),
            ),
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
