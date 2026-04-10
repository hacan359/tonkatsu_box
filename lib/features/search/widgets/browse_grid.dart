import '../../../shared/constants/platform_features.dart';
// Вертикальный грид результатов Browse/Search.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_cache_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/game.dart';
import '../../../shared/models/manga.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/movie.dart';
import '../../../shared/models/platform.dart';
import '../../../shared/models/tv_show.dart';
import '../../../shared/models/visual_novel.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/api_error_display.dart';
import '../../../shared/widgets/media_poster_card.dart';
import '../utils/genre_utils.dart' show isAnimationGenre;
import '../../../shared/widgets/shimmer_loading.dart' show ShimmerPosterCard;
import '../../../shared/models/collected_item_info.dart';
import '../../collections/providers/collections_provider.dart';
import '../providers/browse_provider.dart';

/// Множества ID элементов, которые уже есть в коллекциях.
final FutureProvider<
        ({
          Set<int> tmdbIds,
          Set<int> gameIds,
          Set<int> vnIds,
          Set<int> mangaIds,
        })>
    _collectedIdsProvider = FutureProvider<
        ({
          Set<int> tmdbIds,
          Set<int> gameIds,
          Set<int> vnIds,
          Set<int> mangaIds,
        })>((Ref ref) async {
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
  final Map<int, List<CollectedItemInfo>> mangas =
      await ref.watch(collectedMangaIdsProvider.future);
  return (
    tmdbIds: <int>{...movies.keys, ...tvShows.keys, ...animations.keys},
    gameIds: games.keys.toSet(),
    vnIds: visualNovels.keys.toSet(),
    mangaIds: mangas.keys.toSet(),
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
    this.onOpenInCollection,
    this.clientFilter,
    this.platformMap = const <int, Platform>{},
    super.key,
  });

  /// Callback при тапе на элемент.
  final void Function(Object item, MediaType mediaType) onItemTap;

  /// Callback "Открыть в коллекции" (externalId, mediaType).
  final void Function(int externalId, MediaType mediaType)? onOpenInCollection;

  /// Клиентский фильтр по названию (type-to-filter).
  final String? clientFilter;

  /// Карта платформ для отображения на карточках игр.
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

  /// Проверяет, заполнен ли viewport контентом после загрузки.
  ///
  /// Если контент не достигает порога прокрутки (300px от конца),
  /// автоматически подгружает следующую страницу.
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
    final S l = S.of(context);

    // Auto-load more if content doesn't fill the viewport.
    ref.listen<BrowseState>(browseProvider,
        (BrowseState? prev, BrowseState next) {
      if (next.hasMore &&
          !next.isLoading &&
          !next.isLoadingMore &&
          next.items.isNotEmpty) {
        _scheduleViewportFillCheck();
      }
    });

    // Loading state
    if (state.isLoading && state.items.isEmpty) {
      return _buildShimmerGrid(context);
    }

    // Error state
    if (state.error != null && state.items.isEmpty) {
      return ApiErrorDisplay(
        message: state.error!,
        detail: state.errorDetail,
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
    if (state.isEmpty && !state.hasActiveQuery) {
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
    final AsyncValue<
            ({
              Set<int> tmdbIds,
              Set<int> gameIds,
              Set<int> vnIds,
              Set<int> mangaIds,
            })> collectedIds =
        ref.watch(_collectedIdsProvider);
    final Set<int> tmdbIds =
        collectedIds.valueOrNull?.tmdbIds ?? const <int>{};
    final Set<int> gameIds =
        collectedIds.valueOrNull?.gameIds ?? const <int>{};
    final Set<int> vnIds =
        collectedIds.valueOrNull?.vnIds ?? const <int>{};
    final Set<int> mangaIds =
        collectedIds.valueOrNull?.mangaIds ?? const <int>{};

    // Применяем клиентский фильтр по названию
    final List<Object> displayItems;
    final String? clientFilter = widget.clientFilter;
    if (clientFilter != null && clientFilter.isNotEmpty) {
      final String query = clientFilter.toLowerCase();
      displayItems = state.items
          .where((Object item) =>
              _extractTitle(item).toLowerCase().contains(query))
          .toList();
    } else {
      displayItems = state.items;
    }

    // Results grid
    final SliverGridDelegate gridDelegate = _buildGridDelegate(context);
    final CardVariant variant = isCompactScreen(context)
        ? CardVariant.compact
        : CardVariant.grid;

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      gridDelegate: gridDelegate,
      itemCount: displayItems.length + (state.isLoadingMore ? 3 : 0),
      itemBuilder: (BuildContext context, int index) {
        // Loading more indicators
        if (index >= displayItems.length) {
          return const ShimmerPosterCard();
        }

        final Object item = displayItems[index];
        return _buildCard(
            item, state.source.id, tmdbIds, gameIds, vnIds, mangaIds,
            variant);
      },
    );
  }

  Widget _buildCard(
    Object item,
    String sourceId,
    Set<int> tmdbIds,
    Set<int> gameIds,
    Set<int> vnIds,
    Set<int> mangaIds,
    CardVariant variant,
  ) {
    VoidCallback? openCallback(int externalId, MediaType mediaType, bool inCollection) {
      if (!inCollection || widget.onOpenInCollection == null) return null;
      return () => widget.onOpenInCollection!(externalId, mediaType);
    }

    if (item is Movie) {
      final bool inColl = tmdbIds.contains(item.tmdbId);
      return MediaPosterCard(
        variant: variant,
        title: item.title,
        imageUrl: item.posterUrl ?? '',
        cacheImageType: ImageType.moviePoster,
        cacheImageId: item.tmdbId.toString(),
        apiRating: item.rating,
        year: item.releaseYear,

        mediaType: MediaType.movie,
        isInCollection: inColl,
        onTap: () => widget.onItemTap(item, MediaType.movie),
        onOpenInCollection: openCallback(item.tmdbId, MediaType.movie, inColl),
      );
    }

    if (item is TvShow) {
      final MediaType type = _isAnimation(item)
          ? MediaType.animation
          : MediaType.tvShow;
      final bool inColl = tmdbIds.contains(item.tmdbId);
      return MediaPosterCard(
        variant: variant,
        title: item.title,
        imageUrl: item.posterUrl ?? '',
        cacheImageType: ImageType.tvShowPoster,
        cacheImageId: item.tmdbId.toString(),
        apiRating: item.rating,
        year: item.firstAirYear,

        mediaType: type,
        isInCollection: inColl,
        onTap: () => widget.onItemTap(item, type),
        onOpenInCollection: openCallback(item.tmdbId, type, inColl),
      );
    }

    if (item is Game) {
      final bool inColl = gameIds.contains(item.id);
      return MediaPosterCard(
        variant: variant,
        title: item.name,
        imageUrl: item.coverUrl ?? '',
        cacheImageType: ImageType.gameCover,
        cacheImageId: item.id.toString(),
        apiRating: item.rating != null ? item.rating! / 10.0 : null,
        year: item.releaseYear,

        platformLabel: _buildPlatformLabel(item.platformIds),
        mediaType: MediaType.game,
        isInCollection: inColl,
        onTap: () => widget.onItemTap(item, MediaType.game),
        onOpenInCollection: openCallback(item.id, MediaType.game, inColl),
      );
    }

    if (item is VisualNovel) {
      final bool inColl = vnIds.contains(item.numericId);
      return MediaPosterCard(
        variant: variant,
        title: item.title,
        imageUrl: item.imageUrl ?? '',
        cacheImageType: ImageType.vnCover,
        cacheImageId: item.numericId.toString(),
        apiRating: item.rating10,
        year: item.releaseYear,

        mediaType: MediaType.visualNovel,
        isInCollection: inColl,
        onTap: () => widget.onItemTap(item, MediaType.visualNovel),
        onOpenInCollection: openCallback(item.numericId, MediaType.visualNovel, inColl),
      );
    }

    if (item is Manga) {
      final bool inColl = mangaIds.contains(item.id);
      return MediaPosterCard(
        variant: variant,
        title: item.title,
        imageUrl: item.coverUrl ?? '',
        cacheImageType: ImageType.mangaCover,
        cacheImageId: item.id.toString(),
        apiRating: item.rating10,
        year: item.releaseYear,

        mediaType: MediaType.manga,
        isInCollection: inColl,
        onTap: () => widget.onItemTap(item, MediaType.manga),
        onOpenInCollection: openCallback(item.id, MediaType.manga, inColl),
      );
    }

    return const SizedBox.shrink();
  }

  /// Строит строку платформ из списка ID.
  String? _buildPlatformLabel(List<int>? platformIds) {
    if (platformIds == null || platformIds.isEmpty) return null;
    if (widget.platformMap.isEmpty) return null;
    final List<String> allNames = platformIds
        .where((int id) => widget.platformMap.containsKey(id))
        .map((int id) => widget.platformMap[id]!.displayName)
        .toList();
    if (allNames.isEmpty) return null;
    if (allNames.length <= 3) return allNames.join(', ');
    final List<String> shown = allNames.take(3).toList();
    return '${shown.join(', ')} +${allNames.length - 3}';
  }

  /// Извлекает название из элемента для клиентской фильтрации.
  static String _extractTitle(Object item) {
    if (item is Game) return item.name;
    if (item is Movie) return item.title;
    if (item is TvShow) return item.title;
    if (item is VisualNovel) return item.title;
    if (item is Manga) return item.title;
    return '';
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
