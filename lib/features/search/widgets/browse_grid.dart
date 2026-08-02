import 'package:core/models/anime.dart';
import 'package:core/models/book.dart';
import 'package:core/models/collected_item_info.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/game.dart';
import 'package:core/models/manga.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/movie.dart';
import 'package:core/models/platform.dart';
import 'package:core/models/tv_show.dart';
import 'package:core/models/visual_novel.dart';
import 'package:core/utils/cover_image_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_cache_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/utils/url_launch.dart';
import '../../../shared/widgets/api_error_display.dart';
import '../../../shared/widgets/media_poster_card.dart';
import '../../../shared/widgets/shimmer_loading.dart' show ShimmerPosterCard;
import '../../collections/providers/collections_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/browse_provider.dart';

/// Sets of external IDs that already exist in the user's collections.
/// Multi-source types are keyed by `(source, id)` — their providers hand out
/// colliding numeric ids, so an id alone would badge the wrong card.
typedef _CollectedIds = ({
  Set<int> tmdbIds,
  Set<(DataSource, int)> tvKeys,
  Set<int> gameIds,
  Set<int> vnIds,
  Set<(DataSource, int)> mangaKeys,
  Set<(DataSource, int)> animeKeys,
  Set<(DataSource, int)> bookKeys,
});

const _CollectedIds _kNoCollected = (
  tmdbIds: <int>{},
  tvKeys: <(DataSource, int)>{},
  gameIds: <int>{},
  vnIds: <int>{},
  mangaKeys: <(DataSource, int)>{},
  animeKeys: <(DataSource, int)>{},
  bookKeys: <(DataSource, int)>{},
);

final FutureProvider<_CollectedIds> _collectedIdsProvider =
    FutureProvider<_CollectedIds>((Ref ref) async {
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
  final Map<int, List<CollectedItemInfo>> animes =
      await ref.watch(collectedAnimeIdsProvider.future);
  final Map<int, List<CollectedItemInfo>> books =
      await ref.watch(collectedBookIdsProvider.future);

  return (
    tmdbIds: <int>{...movies.keys, ...tvShows.keys, ...animations.keys},
    tvKeys: <(DataSource, int)>{
      ...tvShows.sourceKeys,
      ...animations.sourceKeys,
    },
    gameIds: games.keys.toSet(),
    vnIds: visualNovels.keys.toSet(),
    mangaKeys: mangas.sourceKeys,
    animeKeys: animes.sourceKeys,
    bookKeys: books.sourceKeys,
  );
});

class BrowseGrid extends ConsumerStatefulWidget {
  const BrowseGrid({
    required this.onItemTap,
    this.onOpenInCollection,
    this.clientFilter,
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

  /// Client-side type-to-filter query applied to titles.
  final String? clientFilter;

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
                l.searchNoResults,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Empty - no filters, no Discover
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

    // Collected IDs used to mark items already in a collection.
    final AsyncValue<_CollectedIds> collectedIds =
        ref.watch(_collectedIdsProvider);
    final _CollectedIds collected = collectedIds.valueOrNull ?? _kNoCollected;

    final List<Object> displayItems;
    final String? clientFilter = widget.clientFilter;
    if (clientFilter != null && clientFilter.isNotEmpty) {
      final String query = clientFilter.toLowerCase();
      displayItems = state.items
          .where((Object item) =>
              _extractTitle(item, animeMangaTitleLanguage)
                  .toLowerCase()
                  .contains(query))
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
        return _buildCard(item, state.source.outputMediaType,
            state.source.dataSource, collected, variant,
            animeMangaTitleLanguage);
      },
    );
  }

  Widget _buildCard(
    Object item,
    MediaType mediaType,
    DataSource gridSource,
    _CollectedIds collected,
    CardVariant variant,
    String animeMangaTitleLanguage,
  ) {
    VoidCallback? openCallback(
      int externalId,
      bool inCollection, {
      DataSource? source,
    }) {
      if (!inCollection || widget.onOpenInCollection == null) return null;
      return () => widget.onOpenInCollection!(externalId, mediaType, source);
    }

    if (item is Movie) {
      final bool inColl = collected.tmdbIds.contains(item.tmdbId);
      return MediaPosterCard(
        variant: variant,
        title: item.title,
        imageUrl: item.posterUrl ?? '',
        cacheImageType: ImageType.moviePoster,
        cacheImageId: item.tmdbId.toString(),
        apiRating: item.rating,
        year: item.releaseYear,
        mediaType: mediaType,
        isInCollection: inColl,
        source: gridSource,
        onSourceTap: openUrlCallback(item.externalUrl),
        onTap: () => widget.onItemTap(item, mediaType),
        onOpenInCollection: openCallback(item.tmdbId, inColl),
      );
    }

    if (item is TvShow) {
      final bool inColl = collected.tvKeys.contains((item.source, item.tmdbId));
      return MediaPosterCard(
        variant: variant,
        title: item.title,
        imageUrl: item.posterUrl ?? '',
        cacheImageType: ImageType.tvShowPoster,
        cacheImageId: coverImageId(
          mediaType: MediaType.tvShow,
          externalId: item.tmdbId,
          source: item.source,
        ),
        apiRating: item.rating,
        year: item.firstAirYear,
        mediaType: mediaType,
        isInCollection: inColl,
        source: item.source,
        onSourceTap: openUrlCallback(item.externalUrl),
        onTap: () => widget.onItemTap(item, mediaType),
        onOpenInCollection:
            openCallback(item.tmdbId, inColl, source: item.source),
      );
    }

    if (item is Game) {
      final bool inColl = collected.gameIds.contains(item.id);
      return MediaPosterCard(
        variant: variant,
        title: item.name,
        imageUrl: item.coverUrl ?? '',
        cacheImageType: ImageType.gameCover,
        cacheImageId: item.id.toString(),
        apiRating: item.rating != null ? item.rating! / 10.0 : null,
        year: item.releaseYear,
        platformLabel: _buildPlatformLabel(item.platformIds),
        timeToBeatHours: item.timeToBeat?.primaryHours,
        mediaType: mediaType,
        isInCollection: inColl,
        source: gridSource,
        onSourceTap: openUrlCallback(item.externalUrl),
        onTap: () => widget.onItemTap(item, mediaType),
        onOpenInCollection: openCallback(item.id, inColl),
      );
    }

    if (item is VisualNovel) {
      final bool inColl = collected.vnIds.contains(item.numericId);
      return MediaPosterCard(
        variant: variant,
        title: item.title,
        imageUrl: item.imageUrl ?? '',
        cacheImageType: ImageType.vnCover,
        cacheImageId: item.numericId.toString(),
        apiRating: item.rating10,
        year: item.releaseYear,
        mediaType: mediaType,
        isInCollection: inColl,
        source: gridSource,
        onSourceTap: openUrlCallback(item.externalUrl),
        onTap: () => widget.onItemTap(item, mediaType),
        onOpenInCollection: openCallback(item.numericId, inColl),
      );
    }

    if (item is Manga) {
      final bool inColl = collected.mangaKeys.contains((item.source, item.id));
      return MediaPosterCard(
        variant: variant,
        title: item.titleByLanguage(animeMangaTitleLanguage),
        imageUrl: item.coverUrl ?? '',
        cacheImageType: ImageType.mangaCover,
        cacheImageId: coverImageId(
          mediaType: MediaType.manga,
          externalId: item.id,
          source: item.source,
        ),
        apiRating: item.rating10,
        year: item.releaseYear,
        mediaType: mediaType,
        typeLabelOverride: item.formatLabel,
        isInCollection: inColl,
        source: item.source,
        onSourceTap: openUrlCallback(item.externalUrl),
        onTap: () => widget.onItemTap(item, mediaType),
        onOpenInCollection: openCallback(item.id, inColl, source: item.source),
      );
    }

    if (item is Anime) {
      final bool inColl = collected.animeKeys.contains((item.source, item.id));
      return MediaPosterCard(
        variant: variant,
        title: item.titleByLanguage(animeMangaTitleLanguage),
        imageUrl: item.coverUrl ?? '',
        cacheImageType: ImageType.animeCover,
        cacheImageId: coverImageId(
          mediaType: MediaType.anime,
          externalId: item.id,
          source: item.source,
        ),
        apiRating: item.rating10,
        year: item.releaseYear,
        mediaType: mediaType,
        typeLabelOverride: item.formatLabel,
        isInCollection: inColl,
        source: item.source,
        onSourceTap: openUrlCallback(item.externalUrl),
        onTap: () => widget.onItemTap(item, mediaType),
        onOpenInCollection: openCallback(item.id, inColl, source: item.source),
      );
    }

    if (item is Book) {
      final int externalId = item.externalIdInt;
      final bool inColl = collected.bookKeys.contains((item.source, externalId));
      return MediaPosterCard(
        variant: variant,
        title: item.title,
        imageUrl: item.coverUrl ?? '',
        cacheImageType: ImageType.bookCover,
        cacheImageId: coverImageId(
          mediaType: MediaType.book,
          externalId: externalId,
          source: item.source,
          coverUrl: item.coverUrl,
        ),
        apiRating: item.rating,
        year: item.releaseYear,
        mediaType: mediaType,
        isInCollection: inColl,
        source: item.source,
        onSourceTap: openUrlCallback(item.externalUrl),
        onTap: () => widget.onItemTap(item, mediaType),
        onOpenInCollection:
            openCallback(externalId, inColl, source: item.source),
      );
    }

    return const SizedBox.shrink();
  }

  /// Joins up to 3 platform names, appending "+N" for the rest.
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

  static String _extractTitle(Object item, String animeMangaTitleLanguage) {
    if (item is Game) return item.name;
    if (item is Movie) return item.title;
    if (item is TvShow) return item.title;
    if (item is VisualNovel) return item.title;
    if (item is Manga) return item.titleByLanguage(animeMangaTitleLanguage);
    if (item is Anime) return item.titleByLanguage(animeMangaTitleLanguage);
    if (item is Book) return item.title;
    return '';
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

class AspectRatioPlaceholder extends StatelessWidget {
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
