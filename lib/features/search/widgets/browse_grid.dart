import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/platform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error_extract.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/media_poster_card.dart';
import '../../../shared/widgets/shimmer_loading.dart' show ShimmerPosterCard;
import '../../settings/providers/settings_provider.dart';
import '../models/search_source.dart';
import '../providers/browse_provider.dart';
import 'browse_card.dart';
import 'source_error_strip.dart';

/// Flat results grid — used when a single source is active. Several sources at
/// once are laid out per provider instead, see `BrowseSections`.
class BrowseGrid extends ConsumerStatefulWidget {
  const BrowseGrid({
    required this.onItemTap,
    this.onOpenInCollection,
    this.platformMap = const <int, Platform>{},
    super.key,
  });

  final void Function(Object item, MediaType mediaType) onItemTap;

  /// [source] is the provider of a multi-source item, `null` otherwise; the
  /// receiver needs it to pick the right placement when two providers share a
  /// numeric id.
  final void Function(
    int externalId,
    MediaType mediaType,
    DataSource? source,
  )? onOpenInCollection;

  /// Platform lookup by IGDB ID, used to render platform labels on game cards.
  final Map<int, Platform> platformMap;

  @override
  ConsumerState<BrowseGrid> createState() => _BrowseGridState();
}

class _BrowseGridState extends ConsumerState<BrowseGrid> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // The grid may appear with a page already loaded (narrowing to one
    // provider) — ref.listen below only fires on later changes, and without
    // overflow there is no scroll to ask for more.
    _scheduleViewportFillCheck();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(browseProvider.notifier).loadMore();
    }
  }

  /// Loads the next page if the content does not reach the scroll threshold
  /// (300px from the end), i.e. it does not fill the viewport yet.
  void _scheduleViewportFillCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final ScrollPosition pos = _scrollController.position;
      if (pos.pixels >= pos.maxScrollExtent - 300) {
        ref.read(browseProvider.notifier).loadMore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final BrowseState state = ref.watch(browseProvider);
    final String animeMangaTitleLanguage = ref.watch(
      settingsNotifierProvider
          .select((SettingsState s) => s.animeMangaTitleLanguage),
    );
    final S l = S.of(context);

    // Auto-load more if content doesn't fill the viewport.
    ref.listen<BrowseState>(browseProvider,
        (BrowseState? prev, BrowseState next) {
      if (!next.isLoading &&
          !next.isLoadingMore &&
          next.items.isNotEmpty &&
          next.moreBySource.values.any((bool more) => more)) {
        _scheduleViewportFillCheck();
      }
    });

    if (state.isLoading && state.items.isEmpty) {
      return _buildShimmerGrid(context);
    }

    final bool hasErrors = state.activeSources
        .any((SearchSource source) => state.errors.containsKey(source.id));

    if (state.items.isEmpty && hasErrors) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[_buildErrors(state)],
      );
    }

    if (state.isEmpty && state.hasActiveQuery) {
      return _buildEmpty(l.searchNoResults, Icons.search_off);
    }

    if (state.isEmpty) {
      return _buildEmpty(l.browseEmptyFilters, Icons.filter_alt_outlined);
    }

    final CollectedIds collected =
        ref.watch(collectedIdsProvider).valueOrNull ?? kNoCollected;

    final List<Object> displayItems = state.items;

    final CardVariant variant = isCompactScreen(context)
        ? CardVariant.compact
        : CardVariant.grid;
    final DataSource fallbackSource = state.sources.first.dataSource;

    return CustomScrollView(
      controller: _scrollController,
      slivers: <Widget>[
        if (hasErrors)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            sliver: SliverToBoxAdapter(child: _buildErrors(state)),
          ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          sliver: SliverGrid(
            gridDelegate: _buildGridDelegate(context),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                if (index >= displayItems.length) {
                  return const ShimmerPosterCard();
                }
                return BrowseCard(
                  item: displayItems[index],
                  mediaType: state.mediaType,
                  fallbackSource: fallbackSource,
                  collected: collected,
                  variant: variant,
                  animeMangaTitleLanguage: animeMangaTitleLanguage,
                  platformMap: widget.platformMap,
                  onTap: widget.onItemTap,
                  onOpenInCollection: widget.onOpenInCollection,
                );
              },
              childCount: displayItems.length + (state.isLoadingMore ? 3 : 0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrors(BrowseState state) {
    return Column(
      children: <Widget>[
        // Active only: a provider the user switched off must not keep
        // reporting the failure of a query it is no longer part of.
        for (final SearchSource source in state.activeSources)
          if (state.errors[source.id] case final ApiError entry)
            SourceErrorStrip(
              source: source,
              error: entry,
              onRetry: () => ref.read(browseProvider.notifier).refresh(),
            ),
      ],
    );
  }

  Widget _buildEmpty(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  SliverGridDelegate _buildGridDelegate(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final double cardScale = ref.watch(
      settingsNotifierProvider.select((SettingsState s) => s.cardScale),
    );
    if (width >= 800) {
      return SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: AppSpacing.desktopMaxCardWidth * cardScale,
        childAspectRatio: AppSpacing.posterCardAspectRatio,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      );
    }
    final int baseCount = width >= 500
        ? AppSpacing.gridColumnsTablet
        : AppSpacing.gridColumnsMobile;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: AppSpacing.scaledColumns(baseCount, cardScale),
      childAspectRatio: AppSpacing.posterCardAspectRatio,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
    );
  }

  Widget _buildShimmerGrid(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final int shimmerCount = width >= 800
        ? 18
        : (width >= 500
            ? AppSpacing.gridColumnsTablet * 3
            : AppSpacing.gridColumnsMobile * 3);

    return GridView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      gridDelegate: _buildGridDelegate(context),
      itemCount: shimmerCount,
      itemBuilder: (BuildContext context, int index) =>
          const ShimmerPosterCard(),
    );
  }
}
