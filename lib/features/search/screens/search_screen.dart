// Экран поиска и просмотра контента.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../core/api/tmdb_api.dart';
import '../../../core/database/database_service.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/game.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/movie.dart';
import '../../../shared/models/platform.dart';
import '../../../shared/models/tv_episode.dart';
import '../../../shared/models/tv_season.dart';
import '../../../shared/models/tv_show.dart';
import '../../../shared/models/visual_novel.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/auto_breadcrumb_app_bar.dart';
import '../../../shared/widgets/collection_picker_dialog.dart';
import '../../../shared/widgets/cached_image.dart' as app_cached;
import '../../collections/providers/collections_provider.dart';
import '../providers/browse_provider.dart';
import '../widgets/browse_grid.dart';
import '../widgets/discover_customize_sheet.dart';
import '../widgets/discover_feed.dart';
import '../widgets/filter_bar.dart';
import '../widgets/game_details_sheet.dart';
import '../widgets/media_details_sheet.dart';
import '../widgets/vn_details_sheet.dart';

/// Экран поиска и просмотра контента.
///
/// Два режима:
/// - Browse: фильтр-бар + Discover feed / Browse grid
/// - Search: поле поиска + результаты
class SearchScreen extends ConsumerStatefulWidget {
  /// Создаёт [SearchScreen].
  const SearchScreen({
    this.onGameSelected,
    this.collectionId,
    this.initialTabIndex,
    this.initialQuery,
    super.key,
  });

  /// Callback при выборе игры (устаревший режим).
  final void Function(Game game)? onGameSelected;

  /// ID коллекции для добавления элементов.
  final int? collectionId;

  /// Начальный индекс таба (legacy, используется для выбора источника).
  final int? initialTabIndex;

  /// Начальный запрос поиска (предзаполняет поле и запускает поиск).
  final String? initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  Map<int, Platform> _platformMap = <int, Platform>{};

  @override
  void initState() {
    super.initState();
    _loadPlatforms();

    // Совместимость: если передан initialTabIndex=1 (Games), выбираем games
    if (widget.initialTabIndex == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(browseProvider.notifier).setSource('games');
      });
    }

    // Если передан начальный запрос — сразу входим в режим поиска
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(browseProvider.notifier).enterSearchMode();
        _searchController.text = widget.initialQuery!;
        ref.read(browseProvider.notifier).search(widget.initialQuery!);
      });
    }
  }

  Future<void> _loadPlatforms() async {
    final DatabaseService db = ref.read(databaseServiceProvider);
    final List<Platform> platforms = await db.getAllPlatforms();
    if (mounted) {
      setState(() {
        _platformMap = <int, Platform>{
          for (final Platform p in platforms) p.id: p,
        };
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ==================== Search mode ====================

  void _enterSearchMode() {
    ref.read(browseProvider.notifier).enterSearchMode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  void _exitSearchMode() {
    _searchController.clear();
    ref.read(browseProvider.notifier).exitSearchMode();
  }

  void _onSearchSubmit() {
    final String query = _searchController.text;
    if (query.length < 2) return;
    ref.read(browseProvider.notifier).search(query);
  }

  void _onClearSearch() {
    _searchController.clear();
    _searchFocus.requestFocus();
  }

  // ==================== Image caching ====================

  void _cacheImage(ImageType type, String imageId, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return;
    final ImageCacheService cacheService = ref.read(imageCacheServiceProvider);
    cacheService.downloadImage(
      type: type,
      imageId: imageId,
      remoteUrl: imageUrl,
    );
  }

  Future<void> _preloadSeasonsAsync(int tmdbId) async {
    if (!mounted) return;
    try {
      final DatabaseService db = ref.read(databaseServiceProvider);
      final TmdbApi tmdb = ref.read(tmdbApiProvider);

      List<TvSeason> seasons = await db.getTvSeasonsByShowId(tmdbId);
      if (seasons.isEmpty) {
        seasons = await tmdb.getTvSeasons(tmdbId);
        if (seasons.isNotEmpty) await db.upsertTvSeasons(seasons);
      }

      for (final TvSeason season in seasons) {
        if (!mounted) return;
        final List<TvEpisode> cached =
            await db.getEpisodesByShowAndSeason(tmdbId, season.seasonNumber);
        if (cached.isEmpty) {
          final List<TvEpisode> episodes =
              await tmdb.getSeasonEpisodes(tmdbId, season.seasonNumber);
          if (episodes.isNotEmpty) await db.upsertEpisodes(episodes);
        }
      }
    } catch (_) {
      // Не критично
    }
  }

  // ==================== Item tap handler ====================

  void _onItemTap(Object item, MediaType mediaType) {
    if (item is Game) {
      _onGameTap(item);
    } else if (item is Movie) {
      _onMovieTap(item, mediaType);
    } else if (item is TvShow) {
      _onTvShowTap(item, mediaType);
    } else if (item is VisualNovel) {
      _onVisualNovelTap(item);
    }
  }

  // ==================== Game actions ====================

  void _onGameTap(Game game) {
    if (widget.onGameSelected != null) {
      widget.onGameSelected!(game);
    } else if (widget.collectionId != null) {
      _addGameToCollection(game);
    } else {
      _showGameDetails(game);
    }
  }

  Future<void> _addGameToCollection(Game game) async {
    final String gameName = game.name;

    final int? platformId = await _showPlatformSelectionDialog(game);
    if (platformId == null || !mounted) return;

    await ref.read(databaseServiceProvider).upsertGame(game);

    final bool success = await ref
        .read(collectionItemsNotifierProvider(widget.collectionId).notifier)
        .addItem(
          mediaType: MediaType.game,
          externalId: game.id,
          platformId: platformId,
        );

    if (mounted) {
      final S l = S.of(context);
      if (success) {
        _cacheImage(ImageType.gameCover, game.id.toString(), game.coverUrl);
        context.showSnack(
          l.searchAddedToCollection(gameName),
          type: SnackType.success,
        );
      } else {
        context.showSnack(
          l.searchAlreadyInCollection(gameName),
          type: SnackType.info,
        );
      }
    }
  }

  Future<void> _addGameToAnyCollection(Game game) async {
    final String gameName = game.name;

    final S l = S.of(context);
    final CollectionChoice? choice = await showCollectionPickerDialog(
      context: context,
      ref: ref,
      title: l.searchAddToCollection,
    );
    if (choice == null || !mounted) return;

    final int? collectionId;
    final String collectionName;
    switch (choice) {
      case ChosenCollection(:final Collection collection):
        collectionId = collection.id;
        collectionName = collection.name;
      case WithoutCollection():
        collectionId = null;
        collectionName = l.collectionsUncategorized;
    }

    final int? platformId = await _showPlatformSelectionDialog(game);
    if (platformId == null || !mounted) return;

    await ref.read(databaseServiceProvider).upsertGame(game);

    final bool success = await ref
        .read(collectionItemsNotifierProvider(collectionId).notifier)
        .addItem(
          mediaType: MediaType.game,
          externalId: game.id,
          platformId: platformId,
        );

    if (mounted) {
      if (success) {
        _cacheImage(ImageType.gameCover, game.id.toString(), game.coverUrl);
        context.showSnack(
          l.searchAddedToNamed(gameName, collectionName),
          type: SnackType.success,
        );
      } else {
        context.showSnack(
          l.searchAlreadyInNamed(gameName, collectionName),
          type: SnackType.info,
        );
      }
    }
  }

  // ==================== Movie actions ====================

  void _onMovieTap(Movie movie, MediaType mediaType) {
    if (widget.collectionId != null) {
      if (mediaType == MediaType.animation) {
        _addAnimationMovieToCollection(movie);
      } else {
        _addMovieToCollection(movie);
      }
    } else {
      _showMovieDetails(movie, mediaType);
    }
  }

  void _showMovieDetails(Movie movie, MediaType mediaType) {
    final bool isAnim = mediaType == MediaType.animation;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => MediaDetailsSheet(
        title: movie.title,
        overview: movie.overview,
        year: movie.releaseYear,
        rating: movie.formattedRating,
        genres: movie.genres,
        icon: isAnim ? Icons.animation : Icons.movie,
        extraInfo: movie.runtime != null ? '${movie.runtime} min' : null,
        posterUrl: movie.posterUrl,
        onAddToCollection: () => isAnim
            ? _addAnimationMovieToAnyCollection(movie)
            : _addMovieToAnyCollection(movie),
      ),
    );
  }

  Future<void> _addMovieToCollection(Movie movie) async {
    final String title = movie.title;

    await ref.read(databaseServiceProvider).upsertMovie(movie);

    final bool success = await ref
        .read(
            collectionItemsNotifierProvider(widget.collectionId).notifier)
        .addItem(
          mediaType: MediaType.movie,
          externalId: movie.tmdbId,
        );

    if (mounted) {
      final S l = S.of(context);
      if (success) {
        _cacheImage(
          ImageType.moviePoster,
          movie.tmdbId.toString(),
          movie.posterUrl,
        );
        context.showSnack(
          l.searchAddedToCollection(title),
          type: SnackType.success,
        );
      } else {
        context.showSnack(
          l.searchAlreadyInCollection(title),
          type: SnackType.info,
        );
      }
    }
  }

  Future<void> _addMovieToAnyCollection(Movie movie) async {
    final String title = movie.title;

    final S l = S.of(context);
    final CollectionChoice? choice = await showCollectionPickerDialog(
      context: context,
      ref: ref,
      title: l.searchAddToCollection,
    );
    if (choice == null || !mounted) return;

    final int? collectionId;
    final String collectionName;
    switch (choice) {
      case ChosenCollection(:final Collection collection):
        collectionId = collection.id;
        collectionName = collection.name;
      case WithoutCollection():
        collectionId = null;
        collectionName = l.collectionsUncategorized;
    }

    await ref.read(databaseServiceProvider).upsertMovie(movie);

    final bool success = await ref
        .read(collectionItemsNotifierProvider(collectionId).notifier)
        .addItem(
          mediaType: MediaType.movie,
          externalId: movie.tmdbId,
        );

    if (mounted) {
      if (success) {
        _cacheImage(
          ImageType.moviePoster,
          movie.tmdbId.toString(),
          movie.posterUrl,
        );
        context.showSnack(
          l.searchAddedToNamed(title, collectionName),
          type: SnackType.success,
        );
      } else {
        context.showSnack(
          l.searchAlreadyInNamed(title, collectionName),
          type: SnackType.info,
        );
      }
    }
  }

  // ==================== TV Show actions ====================

  void _onTvShowTap(TvShow tvShow, MediaType mediaType) {
    if (widget.collectionId != null) {
      if (mediaType == MediaType.animation) {
        _addAnimationTvShowToCollection(tvShow);
      } else {
        _addTvShowToCollection(tvShow);
      }
    } else {
      _showTvShowDetails(tvShow, mediaType);
    }
  }

  void _showTvShowDetails(TvShow tvShow, MediaType mediaType) {
    final bool isAnim = mediaType == MediaType.animation;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => MediaDetailsSheet(
        title: tvShow.title,
        overview: tvShow.overview,
        year: tvShow.firstAirYear,
        rating: tvShow.formattedRating,
        genres: tvShow.genres,
        icon: isAnim ? Icons.animation : Icons.tv,
        extraInfo: tvShow.status,
        posterUrl: tvShow.posterUrl,
        onAddToCollection: () => isAnim
            ? _addAnimationTvShowToAnyCollection(tvShow)
            : _addTvShowToAnyCollection(tvShow),
      ),
    );
  }

  Future<void> _addTvShowToCollection(TvShow tvShow) async {
    final String title = tvShow.title;

    await ref.read(databaseServiceProvider).upsertTvShow(tvShow);

    final bool success = await ref
        .read(
            collectionItemsNotifierProvider(widget.collectionId).notifier)
        .addItem(
          mediaType: MediaType.tvShow,
          externalId: tvShow.tmdbId,
        );

    if (mounted) {
      final S l = S.of(context);
      if (success) {
        _cacheImage(
          ImageType.tvShowPoster,
          tvShow.tmdbId.toString(),
          tvShow.posterUrl,
        );
        await _preloadSeasonsAsync(tvShow.tmdbId);
        if (mounted) {
          context.showSnack(
            l.searchAddedToCollection(title),
            type: SnackType.success,
          );
        }
      } else {
        context.showSnack(
          l.searchAlreadyInCollection(title),
          type: SnackType.info,
        );
      }
    }
  }

  Future<void> _addTvShowToAnyCollection(TvShow tvShow) async {
    final String title = tvShow.title;

    final S l = S.of(context);
    final CollectionChoice? choice = await showCollectionPickerDialog(
      context: context,
      ref: ref,
      title: l.searchAddToCollection,
    );
    if (choice == null || !mounted) return;

    final int? collectionId;
    final String collectionName;
    switch (choice) {
      case ChosenCollection(:final Collection collection):
        collectionId = collection.id;
        collectionName = collection.name;
      case WithoutCollection():
        collectionId = null;
        collectionName = l.collectionsUncategorized;
    }

    await ref.read(databaseServiceProvider).upsertTvShow(tvShow);

    final bool success = await ref
        .read(collectionItemsNotifierProvider(collectionId).notifier)
        .addItem(
          mediaType: MediaType.tvShow,
          externalId: tvShow.tmdbId,
        );

    if (mounted) {
      if (success) {
        _cacheImage(
          ImageType.tvShowPoster,
          tvShow.tmdbId.toString(),
          tvShow.posterUrl,
        );
        await _preloadSeasonsAsync(tvShow.tmdbId);
        if (mounted) {
          context.showSnack(
            l.searchAddedToNamed(title, collectionName),
            type: SnackType.success,
          );
        }
      } else {
        context.showSnack(
          l.searchAlreadyInNamed(title, collectionName),
          type: SnackType.info,
        );
      }
    }
  }

  // ==================== Animation actions ====================

  Future<void> _addAnimationMovieToCollection(Movie movie) async {
    final String title = movie.title;

    await ref.read(databaseServiceProvider).upsertMovie(movie);

    final bool success = await ref
        .read(
            collectionItemsNotifierProvider(widget.collectionId).notifier)
        .addItem(
          mediaType: MediaType.animation,
          externalId: movie.tmdbId,
          platformId: AnimationSource.movie,
        );

    if (mounted) {
      final S l = S.of(context);
      if (success) {
        _cacheImage(
          ImageType.moviePoster,
          movie.tmdbId.toString(),
          movie.posterUrl,
        );
        context.showSnack(
          l.searchAddedToCollection(title),
          type: SnackType.success,
        );
      } else {
        context.showSnack(
          l.searchAlreadyInCollection(title),
          type: SnackType.info,
        );
      }
    }
  }

  Future<void> _addAnimationTvShowToCollection(TvShow tvShow) async {
    final String title = tvShow.title;

    await ref.read(databaseServiceProvider).upsertTvShow(tvShow);

    final bool success = await ref
        .read(
            collectionItemsNotifierProvider(widget.collectionId).notifier)
        .addItem(
          mediaType: MediaType.animation,
          externalId: tvShow.tmdbId,
          platformId: AnimationSource.tvShow,
        );

    if (mounted) {
      final S l = S.of(context);
      if (success) {
        _cacheImage(
          ImageType.tvShowPoster,
          tvShow.tmdbId.toString(),
          tvShow.posterUrl,
        );
        await _preloadSeasonsAsync(tvShow.tmdbId);
        if (mounted) {
          context.showSnack(
            l.searchAddedToCollection(title),
            type: SnackType.success,
          );
        }
      } else {
        context.showSnack(
          l.searchAlreadyInCollection(title),
          type: SnackType.info,
        );
      }
    }
  }

  Future<void> _addAnimationMovieToAnyCollection(Movie movie) async {
    final String title = movie.title;

    final S l = S.of(context);
    final CollectionChoice? choice = await showCollectionPickerDialog(
      context: context,
      ref: ref,
      title: l.searchAddToCollection,
    );
    if (choice == null || !mounted) return;

    final int? collectionId;
    final String collectionName;
    switch (choice) {
      case ChosenCollection(:final Collection collection):
        collectionId = collection.id;
        collectionName = collection.name;
      case WithoutCollection():
        collectionId = null;
        collectionName = l.collectionsUncategorized;
    }

    await ref.read(databaseServiceProvider).upsertMovie(movie);

    final bool success = await ref
        .read(collectionItemsNotifierProvider(collectionId).notifier)
        .addItem(
          mediaType: MediaType.animation,
          externalId: movie.tmdbId,
          platformId: AnimationSource.movie,
        );

    if (mounted) {
      if (success) {
        _cacheImage(
          ImageType.moviePoster,
          movie.tmdbId.toString(),
          movie.posterUrl,
        );
        context.showSnack(
          l.searchAddedToNamed(title, collectionName),
          type: SnackType.success,
        );
      } else {
        context.showSnack(
          l.searchAlreadyInNamed(title, collectionName),
          type: SnackType.info,
        );
      }
    }
  }

  Future<void> _addAnimationTvShowToAnyCollection(TvShow tvShow) async {
    final String title = tvShow.title;

    final S l = S.of(context);
    final CollectionChoice? choice = await showCollectionPickerDialog(
      context: context,
      ref: ref,
      title: l.searchAddToCollection,
    );
    if (choice == null || !mounted) return;

    final int? collectionId;
    final String collectionName;
    switch (choice) {
      case ChosenCollection(:final Collection collection):
        collectionId = collection.id;
        collectionName = collection.name;
      case WithoutCollection():
        collectionId = null;
        collectionName = l.collectionsUncategorized;
    }

    await ref.read(databaseServiceProvider).upsertTvShow(tvShow);

    final bool success = await ref
        .read(collectionItemsNotifierProvider(collectionId).notifier)
        .addItem(
          mediaType: MediaType.animation,
          externalId: tvShow.tmdbId,
          platformId: AnimationSource.tvShow,
        );

    if (mounted) {
      if (success) {
        _cacheImage(
          ImageType.tvShowPoster,
          tvShow.tmdbId.toString(),
          tvShow.posterUrl,
        );
        await _preloadSeasonsAsync(tvShow.tmdbId);
        if (mounted) {
          context.showSnack(
            l.searchAddedToNamed(title, collectionName),
            type: SnackType.success,
          );
        }
      } else {
        context.showSnack(
          l.searchAlreadyInNamed(title, collectionName),
          type: SnackType.info,
        );
      }
    }
  }

  // ==================== Shared dialogs ====================

  Future<int?> _showPlatformSelectionDialog(Game game) async {
    final List<int>? platformIds = game.platformIds;

    if (platformIds == null || platformIds.isEmpty) {
      return -1;
    }

    if (platformIds.length == 1) {
      return platformIds.first;
    }

    return showDialog<int>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        scrollable: true,
        title: Text(S.of(context).searchSelectPlatform),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: platformIds.map((int id) {
            final Platform? platform = _platformMap[id];
            final String platformName =
                platform?.displayName ?? 'Platform $id';
            return ListTile(
              leading: _buildPlatformLogo(platform),
              title: Text(platformName),
              onTap: () => Navigator.of(context).pop(id),
            );
          }).toList(),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(S.of(context).cancel),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformLogo(Platform? platform) {
    if (platform?.logoUrl != null && platform?.logoImageId != null) {
      return app_cached.CachedImage(
        imageType: ImageType.platformLogo,
        imageId: platform!.logoImageId!,
        remoteUrl: platform.logoUrl!,
        width: 32,
        height: 32,
        fit: BoxFit.contain,
        placeholder: const Icon(Icons.videogame_asset, size: 24),
        errorWidget: const Icon(Icons.videogame_asset, size: 24),
      );
    }
    return const Icon(Icons.videogame_asset, size: 24);
  }

  // ==================== Detail sheets ====================

  // ==================== Visual Novel actions ====================

  void _onVisualNovelTap(VisualNovel vn) {
    if (widget.collectionId != null) {
      _addVisualNovelToCollection(vn);
    } else {
      _showVisualNovelDetails(vn);
    }
  }

  Future<void> _addVisualNovelToCollection(VisualNovel vn) async {
    final String title = vn.title;

    await ref.read(databaseServiceProvider).upsertVisualNovel(vn);

    final bool success = await ref
        .read(
            collectionItemsNotifierProvider(widget.collectionId).notifier)
        .addItem(
          mediaType: MediaType.visualNovel,
          externalId: vn.numericId,
        );

    if (mounted) {
      final S l = S.of(context);
      if (success) {
        _cacheImage(
          ImageType.vnCover,
          vn.numericId.toString(),
          vn.imageUrl,
        );
        context.showSnack(
          l.searchAddedToCollection(title),
          type: SnackType.success,
        );
      } else {
        context.showSnack(
          l.searchAlreadyInCollection(title),
          type: SnackType.info,
        );
      }
    }
  }

  Future<void> _addVisualNovelToAnyCollection(VisualNovel vn) async {
    final String title = vn.title;

    final S l = S.of(context);
    final CollectionChoice? choice = await showCollectionPickerDialog(
      context: context,
      ref: ref,
      title: l.searchAddToCollection,
    );
    if (choice == null || !mounted) return;

    final int? collectionId;
    final String collectionName;
    switch (choice) {
      case ChosenCollection(:final Collection collection):
        collectionId = collection.id;
        collectionName = collection.name;
      case WithoutCollection():
        collectionId = null;
        collectionName = l.collectionsUncategorized;
    }

    await ref.read(databaseServiceProvider).upsertVisualNovel(vn);

    final bool success = await ref
        .read(collectionItemsNotifierProvider(collectionId).notifier)
        .addItem(
          mediaType: MediaType.visualNovel,
          externalId: vn.numericId,
        );

    if (mounted) {
      if (success) {
        _cacheImage(
          ImageType.vnCover,
          vn.numericId.toString(),
          vn.imageUrl,
        );
        context.showSnack(
          l.searchAddedToNamed(title, collectionName),
          type: SnackType.success,
        );
      } else {
        context.showSnack(
          l.searchAlreadyInNamed(title, collectionName),
          type: SnackType.info,
        );
      }
    }
  }

  void _showVisualNovelDetails(VisualNovel vn) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => VnDetailsSheet(
        visualNovel: vn,
        onAddToCollection: () => _addVisualNovelToAnyCollection(vn),
      ),
    );
  }

  void _showGameDetails(Game game) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => GameDetailsSheet(
        game: game,
        onAddToCollection: () => _addGameToAnyCollection(game),
      ),
    );
  }

  void _showDiscoverCustomizeSheet() {
    final Size screenSize = MediaQuery.sizeOf(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      constraints: BoxConstraints(
        maxWidth: screenSize.width,
        maxHeight: screenSize.height * 0.85,
      ),
      builder: (BuildContext _) => const DiscoverCustomizeSheet(),
    );
  }

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    final BrowseState browseState = ref.watch(browseProvider);
    final bool isLandscape = isLandscapeMobile(context);

    // Discover Customize кнопка — только в Browse mode без фильтров
    // когда источник поддерживает Discover (TMDB)
    final bool showDiscoverCustomize = !browseState.isSearchMode &&
        !browseState.hasFilters &&
        (browseState.sourceId == 'movies' ||
            browseState.sourceId == 'tv' ||
            browseState.sourceId == 'anime');

    return Scaffold(
      resizeToAvoidBottomInset: !isLandscape,
      appBar: AutoBreadcrumbAppBar(
        actions: <Widget>[
          if (showDiscoverCustomize)
            IconButton(
              icon: const Icon(Icons.tune, size: 20),
              tooltip: S.of(context).discoverCustomize,
              onPressed: _showDiscoverCustomizeSheet,
            ),
          if (!browseState.isSearchMode)
            IconButton(
              icon: const Icon(Icons.search, size: 22),
              tooltip: S.of(context).navSearch,
              onPressed: _enterSearchMode,
            ),
        ],
      ),
      body: Column(
        children: <Widget>[
          // Фильтр-бар или поле поиска
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: browseState.isSearchMode
                ? _buildSearchBar()
                : const FilterBar(),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Контент
          Expanded(
            child: browseState.isSearchMode
                ? _buildSearchContent(browseState)
                : _buildBrowseContent(browseState),
          ),
        ],
      ),
    );
  }

  // ==================== Search bar ====================

  Widget _buildSearchBar() {
    final S l = S.of(context);
    final BrowseState browseState = ref.watch(browseProvider);
    final bool hasText = _searchController.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: SizedBox(
        height: 36,
        child: Row(
          children: <Widget>[
            // Back button
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              onPressed: _exitSearchMode,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            // Search field
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: browseState.source.searchHint(l),
                  hintStyle: AppTypography.body.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                  suffixIcon: hasText
                      ? IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: AppColors.textTertiary,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          onPressed: _onClearSearch,
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xs,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                    borderSide: BorderSide.none,
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _onSearchSubmit(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Browse content ====================

  Widget _buildBrowseContent(BrowseState browseState) {
    // Без фильтров → Discover feed (для TMDB источников)
    if (!browseState.hasFilters) {
      final String sourceId = browseState.sourceId;

      // TMDB источники — показываем Discover feed
      if (sourceId == 'movies' || sourceId == 'tv' || sourceId == 'anime') {
        return DiscoverFeed(
          onAddMovie: (Movie movie) => _addMovieToAnyCollection(movie),
          onAddTvShow: (TvShow tvShow) => _addTvShowToAnyCollection(tvShow),
        );
      }

      // Другие источники без Discover — пустое состояние
      return _buildEmptyFilterState();
    }

    // С фильтрами → Browse grid
    return BrowseGrid(onItemTap: _onItemTap);
  }

  // ==================== Search content ====================

  Widget _buildSearchContent(BrowseState browseState) {
    if (browseState.searchQuery.isEmpty && browseState.items.isEmpty) {
      return _buildEmptySearchState();
    }

    // Результаты через BrowseGrid
    return BrowseGrid(onItemTap: _onItemTap);
  }

  // ==================== Empty states ====================

  Widget _buildEmptyFilterState() {
    final S l = S.of(context);
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchState() {
    final S l = S.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.search,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l.browseSearchHint,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
