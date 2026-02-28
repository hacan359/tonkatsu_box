// Вертикальный грид результатов Browse/Search.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_cache_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/game.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/movie.dart';
import '../../../shared/models/tv_show.dart';
import '../../../shared/models/visual_novel.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/media_poster_card.dart';
import '../utils/genre_utils.dart' show isAnimationGenre;
import '../../../shared/widgets/shimmer_loading.dart' show ShimmerPosterCard;
import '../../../shared/models/collected_item_info.dart';
import '../../collections/providers/collections_provider.dart';
import '../providers/browse_provider.dart';

/// Множества ID элементов, которые уже есть в коллекциях.
final FutureProvider<({Set<int> tmdbIds, Set<int> gameIds, Set<int> vnIds})>
    _collectedIdsProvider =
    FutureProvider<({Set<int> tmdbIds, Set<int> gameIds, Set<int> vnIds})>(
        (Ref ref) async {
  final Map<int, List<CollectedItemInfo>> movies =
      await ref.watch(collectedMovieIdsProvider.future);
  final Map<int, List<CollectedItemInfo>> tvShows =
      await ref.watch(collectedTvShowIdsProvider.future);
  final Map<int, List<CollectedItemInfo>> animations =
      await ref.watch(collectedAnimationIdsProvider.future);
  final Map<int, List<CollectedItemInfo>> games =
      await ref.watch(collectedGameIdsProvider.future);
  final Map<int, List<CollectedItemInfo>> visualNovels =
      await ref.watch(collectedVisualNovelIdsProvider.future);
  return (
    tmdbIds: <int>{...movies.keys, ...tvShows.keys, ...animations.keys},
    gameIds: games.keys.toSet(),
    vnIds: visualNovels.keys.toSet(),
  );
});

/// Грид результатов Browse/Search mode.
///
/// Отображает постерные карточки в виде сетки.
/// Поддерживает бесконечный скролл (пагинацию).
class BrowseGrid extends ConsumerStatefulWidget {
  /// Создаёт [BrowseGrid].
  const BrowseGrid({
    required this.onItemTap,
    super.key,
  });

  /// Callback при тапе на элемент.
  final void Function(Object item, MediaType mediaType) onItemTap;

  @override
  ConsumerState<BrowseGrid> createState() => _BrowseGridState();
}

class _BrowseGridState extends ConsumerState<BrowseGrid> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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

  @override
  Widget build(BuildContext context) {
    final BrowseState state = ref.watch(browseProvider);
    final S l = S.of(context);

    // Loading state
    if (state.isLoading && state.items.isEmpty) {
      return _buildShimmerGrid(context);
    }

    // Error state
    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                state.error!,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (state.isEmpty && state.hasFilters) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.search_off,
                size: 48,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l.browseEmptyResults,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Empty — no filters, no Discover
    if (state.isEmpty && !state.hasFilters && !state.isSearchMode) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.filter_alt_outlined,
                size: 48,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l.browseEmptyFilters,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Collected IDs для маркировки "уже в коллекции"
    final AsyncValue<({Set<int> tmdbIds, Set<int> gameIds, Set<int> vnIds})>
        collectedIds = ref.watch(_collectedIdsProvider);
    final Set<int> tmdbIds =
        collectedIds.valueOrNull?.tmdbIds ?? const <int>{};
    final Set<int> gameIds =
        collectedIds.valueOrNull?.gameIds ?? const <int>{};
    final Set<int> vnIds =
        collectedIds.valueOrNull?.vnIds ?? const <int>{};

    // Results grid
    final SliverGridDelegate gridDelegate = _buildGridDelegate(context);

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      gridDelegate: gridDelegate,
      itemCount: state.items.length + (state.isLoadingMore ? 3 : 0),
      itemBuilder: (BuildContext context, int index) {
        // Loading more indicators
        if (index >= state.items.length) {
          return const ShimmerPosterCard();
        }

        final Object item = state.items[index];
        return _buildCard(item, state.source.id, tmdbIds, gameIds, vnIds);
      },
    );
  }

  Widget _buildCard(
    Object item,
    String sourceId,
    Set<int> tmdbIds,
    Set<int> gameIds,
    Set<int> vnIds,
  ) {
    if (item is Movie) {
      return MediaPosterCard(
        variant: CardVariant.grid,
        title: item.title,
        imageUrl: item.posterUrl ?? '',
        cacheImageType: ImageType.moviePoster,
        cacheImageId: item.tmdbId.toString(),
        apiRating: item.rating,
        year: item.releaseYear,
        subtitle: item.genresString,
        mediaType: MediaType.movie,
        isInCollection: tmdbIds.contains(item.tmdbId),
        onTap: () => widget.onItemTap(item, MediaType.movie),
      );
    }

    if (item is TvShow) {
      final MediaType type = _isAnimation(item)
          ? MediaType.animation
          : MediaType.tvShow;
      return MediaPosterCard(
        variant: CardVariant.grid,
        title: item.title,
        imageUrl: item.posterUrl ?? '',
        cacheImageType: ImageType.tvShowPoster,
        cacheImageId: item.tmdbId.toString(),
        apiRating: item.rating,
        year: item.firstAirYear,
        subtitle: item.genresString,
        mediaType: type,
        isInCollection: tmdbIds.contains(item.tmdbId),
        onTap: () => widget.onItemTap(item, type),
      );
    }

    if (item is Game) {
      return MediaPosterCard(
        variant: CardVariant.grid,
        title: item.name,
        imageUrl: item.coverUrl ?? '',
        cacheImageType: ImageType.gameCover,
        cacheImageId: item.id.toString(),
        apiRating: item.rating != null ? item.rating! / 10.0 : null,
        year: item.releaseYear,
        subtitle: item.genresString,
        mediaType: MediaType.game,
        isInCollection: gameIds.contains(item.id),
        onTap: () => widget.onItemTap(item, MediaType.game),
      );
    }

    if (item is VisualNovel) {
      return MediaPosterCard(
        variant: CardVariant.grid,
        title: item.title,
        imageUrl: item.imageUrl ?? '',
        cacheImageType: ImageType.vnCover,
        cacheImageId: item.numericId.toString(),
        apiRating: item.rating10,
        year: item.releaseYear,
        subtitle: item.genresString,
        mediaType: MediaType.visualNovel,
        isInCollection: vnIds.contains(item.numericId),
        onTap: () => widget.onItemTap(item, MediaType.visualNovel),
      );
    }

    return const SizedBox.shrink();
  }

  bool _isAnimation(TvShow show) {
    if (show.genres == null) return false;
    return show.genres!.any(isAnimationGenre);
  }

  /// Максимальная ширина карточки на десктопе (как в collection_screen).
  static const double _desktopMaxCardWidth = 150;

  /// Aspect ratio карточки (как в collection_screen).
  static const double _cardAspectRatio = 0.55;

  SliverGridDelegate _buildGridDelegate(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    if (width >= 800) {
      return const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: _desktopMaxCardWidth,
        childAspectRatio: _cardAspectRatio,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      );
    }
    final int crossAxisCount = width >= 500
        ? AppSpacing.gridColumnsTablet
        : AppSpacing.gridColumnsMobile;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      childAspectRatio: _cardAspectRatio,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
    );
  }

  Widget _buildShimmerGrid(BuildContext context) {
    final SliverGridDelegate gridDelegate = _buildGridDelegate(context);
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
      gridDelegate: gridDelegate,
      itemCount: shimmerCount,
      itemBuilder: (BuildContext context, int index) {
        return const ShimmerPosterCard();
      },
    );
  }
}

/// Placeholder для шиммера.
class AspectRatioPlaceholder extends StatelessWidget {
  /// Создаёт [AspectRatioPlaceholder].
  const AspectRatioPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
    );
  }
}
