import 'dart:math' as math;

import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error_extract.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/media_poster_card.dart';
import '../../../shared/widgets/shimmer_loading.dart' show ShimmerPosterCard;
import '../../../shared/widgets/source_logo.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/search_source.dart';
import '../providers/browse_provider.dart';
import 'browse_card.dart';
import 'source_error_strip.dart';

/// Desktop results layout for several sources at once: one block per provider,
/// cards wrapped into rows like the normal grid.
///
/// Each block is capped to [_kPreviewRows] so every source stays visible on the
/// first screen — with four manga providers an uncapped page would push the last
/// one far below the fold. "Show all" narrows to one source, where the flat grid
/// and its paging take over; that also keeps the overview to one request per
/// provider.
class BrowseSections extends ConsumerWidget {
  const BrowseSections({
    required this.onItemTap,
    this.onOpenInCollection,
    this.platformMap = const <int, Platform>{},
    super.key,
  });

  final void Function(Object item, MediaType mediaType) onItemTap;

  final void Function(
    int externalId,
    MediaType mediaType,
    DataSource? source,
  )? onOpenInCollection;

  final Map<int, Platform> platformMap;

  static const int _kPreviewRows = 2;

  /// Mirrors [SliverGridDelegateWithMaxCrossAxisExtent] so the cap lines up with
  /// whole rows instead of cutting one mid-way.
  static int columnsFor(double width, double cardScale) {
    final double maxExtent = AppSpacing.desktopMaxCardWidth * cardScale;
    return math.max(
      1,
      (width / (maxExtent + AppSpacing.sm)).ceil(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BrowseState state = ref.watch(browseProvider);
    final S l = S.of(context);
    final String animeMangaTitleLanguage = ref.watch(
      settingsNotifierProvider
          .select((SettingsState s) => s.animeMangaTitleLanguage),
    );
    final double cardScale = ref.watch(
      settingsNotifierProvider.select((SettingsState s) => s.cardScale),
    );
    final CollectedIds collected =
        ref.watch(collectedIdsProvider).valueOrNull ?? kNoCollected;

    if (state.isEmpty && !state.isLoading) {
      final bool queried = state.hasActiveQuery;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                queried ? Icons.search_off : Icons.filter_alt_outlined,
                size: 48,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                queried ? l.searchNoResults : l.browseEmptyFilters,
                textAlign: TextAlign.center,
                style:
                    AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = columnsFor(
          constraints.maxWidth - AppSpacing.md * 2,
          cardScale,
        );

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          children: <Widget>[
            for (final SearchSource source in state.activeSources)
              _Section(
                source: source,
                state: state,
                columns: columns,
                rows: _kPreviewRows,
                collected: collected,
                animeMangaTitleLanguage: animeMangaTitleLanguage,
                platformMap: platformMap,
                onItemTap: onItemTap,
                onOpenInCollection: onOpenInCollection,
                onShowAll: () =>
                    ref.read(browseProvider.notifier).narrowTo(source.id),
                onRetry: () => ref.read(browseProvider.notifier).refresh(),
              ),
          ],
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.source,
    required this.state,
    required this.columns,
    required this.rows,
    required this.collected,
    required this.animeMangaTitleLanguage,
    required this.platformMap,
    required this.onItemTap,
    required this.onOpenInCollection,
    required this.onShowAll,
    required this.onRetry,
  });

  final SearchSource source;
  final BrowseState state;
  final int columns;
  final int rows;
  final CollectedIds collected;
  final String animeMangaTitleLanguage;
  final Map<int, Platform> platformMap;
  final void Function(Object item, MediaType mediaType) onItemTap;
  final void Function(
    int externalId,
    MediaType mediaType,
    DataSource? source,
  )? onOpenInCollection;
  final VoidCallback onShowAll;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ApiError? error = state.errors[source.id];
    final List<Object> items = state.itemsBySource[source.id] ?? <Object>[];
    // A load-more failure keeps the page-1 results; the strip goes above them
    // instead of replacing them.
    if (error != null && items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: SourceErrorStrip(
          source: source,
          error: error,
          onRetry: onRetry,
        ),
      );
    }
    // This provider's own state, so one that already answered with nothing
    // collapses instead of shimmering until the slowest one lands.
    final bool loading = state.isSourceLoading(source.id) && items.isEmpty;
    if (items.isEmpty && !loading) return const SizedBox.shrink();

    final int shown = loading
        ? columns
        : math.min(items.length, columns * rows);
    final int hidden = loading ? 0 : items.length - shown;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: SourceErrorStrip(
                source: source,
                error: error,
                onRetry: onRetry,
              ),
            ),
          _SectionHeader(
            source: source,
            count: loading ? null : items.length,
            hidden: hidden,
            onShowAll: loading ? null : onShowAll,
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            // Bounded by the row cap, so shrinkWrap stays cheap here.
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                childAspectRatio: AppSpacing.posterCardAspectRatio,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
              ),
              itemCount: shown,
              itemBuilder: (BuildContext context, int index) {
                if (loading) return const ShimmerPosterCard();
                return BrowseCard(
                  item: items[index],
                  mediaType: state.mediaType,
                  fallbackSource: source.dataSource,
                  collected: collected,
                  variant: CardVariant.grid,
                  animeMangaTitleLanguage: animeMangaTitleLanguage,
                  platformMap: platformMap,
                  onTap: onItemTap,
                  onOpenInCollection: onOpenInCollection,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.source,
    required this.count,
    required this.hidden,
    required this.onShowAll,
  });

  final SearchSource source;
  final int? count;

  /// Loaded but cut off by the row cap; makes "show all" an honest offer.
  final int hidden;

  final VoidCallback? onShowAll;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: <Widget>[
          SourceLogo(source: source.dataSource, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Text(
            source.dataSource.label,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
          ),
          if (count != null) ...<Widget>[
            const SizedBox(width: AppSpacing.xs),
            Text(
              '$count',
              style: AppTypography.caption
                  .copyWith(color: AppColors.textTertiary),
            ),
          ],
          const Spacer(),
          if (onShowAll != null)
            // A Material button in a Row inherits the theme's infinite
            // minimumSize and would blow up the layout in debug.
            TextButton(
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                minimumSize: const Size(0, AppSpacing.buttonHeightDense),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              onPressed: onShowAll,
              child: Text(
                hidden > 0 ? '${l.searchShowAll} +$hidden →' : '${l.searchShowAll} →',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
