// Экран поиска и просмотра контента.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../core/api/tmdb_api.dart';
import '../../../core/database/database_service.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../shared/models/collected_item_info.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/game.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/movie.dart';
import '../../../shared/models/platform.dart';
import '../../../shared/models/tv_episode.dart';
import '../../../shared/models/tv_season.dart';
import '../../../shared/models/tv_show.dart';
import '../../../shared/models/manga.dart';
import '../../../shared/models/visual_novel.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/auto_breadcrumb_app_bar.dart';
import '../../../shared/widgets/collection_picker_dialog.dart';
import '../../../shared/widgets/type_to_filter_overlay.dart';
import '../../collections/providers/collections_provider.dart';
import '../../collections/screens/item_detail_screen.dart';
import '../providers/browse_provider.dart';
import '../widgets/browse_grid.dart';
import '../widgets/discover_customize_sheet.dart';
import '../widgets/discover_feed.dart';
import '../widgets/filter_bar.dart';
import '../widgets/game_details_sheet.dart';
import '../widgets/media_details_sheet.dart';
import '../widgets/manga_details_sheet.dart';
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
    this.initialSourceId,
    this.initialQuery,
    super.key,
  });

  /// Callback при выборе игры (устаревший режим).
  final void Function(Game game)? onGameSelected;

  /// ID коллекции для добавления элементов.
  final int? collectionId;

  /// Начальный индекс таба (legacy, используется для выбора источника).
  final int? initialTabIndex;

  /// ID источника для предвыбора (например 'manga', 'games', 'tv').
  final String? initialSourceId;

  /// Начальный запрос поиска (предзаполняет поле и запускает поиск).
  final String? initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _typeToFilterQuery = '';
  String? _lastSourceId;

  Map<int, Platform> _platformMap = <int, Platform>{};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
    _loadPlatforms();

    // Предвыбор источника
    final String? sourceToSet = widget.initialSourceId ??
        (widget.initialTabIndex == 1 ? 'games' : null);

    if (sourceToSet != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(browseProvider.notifier).setSource(sourceToSet);
        // Если есть начальный запрос — запускаем поиск после смены источника
        if (widget.initialQuery != null &&
            widget.initialQuery!.isNotEmpty) {
          _searchController.text = widget.initialQuery!;
          ref.read(browseProvider.notifier).search(widget.initialQuery!);
        }
      });
    } else if (widget.initialQuery != null &&
        widget.initialQuery!.isNotEmpty) {
      // Начальный запрос без смены источника
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    // Перерисовка для обновления крестика очистки
    setState(() {});
  }

  // ==================== Search ====================

  /// Синхронизирует текст из контроллера в провайдер перед сменой фильтра.
  void _syncSearchText() {
    final String text = _searchController.text.trim();
    if (text.length >= 2) {
      ref.read(browseProvider.notifier).setSearchQuery(text);
    }
  }

  void _onSearchSubmit() {
    final String query = _searchController.text;
    if (query.length < 2) return;
    ref.read(browseProvider.notifier).search(query);
  }

  void _onClearSearch() {
    _searchController.clear();
    ref.read(browseProvider.notifier).clearSearch();
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
      // Episode pre-cache failed (network/API error) — not critical,
      // episodes will be fetched on demand when user opens the show.
    }
  }

  // ==================== Open in collection ====================

  Future<void> _openItemInCollection(
    int externalId,
    MediaType mediaType,
  ) async {
    // Получаем List<CollectedItemInfo> для этого элемента
    final List<CollectedItemInfo> infos = await _getCollectedInfos(
      externalId,
      mediaType,
    );
    if (infos.isEmpty || !mounted) return;

    if (infos.length == 1) {
      _navigateToItemDetail(infos.first);
      return;
    }

    // Несколько коллекций — показываем диалог выбора
    if (!mounted) return;
    final CollectedItemInfo? chosen = await showDialog<CollectedItemInfo>(
      context: context,
      builder: (BuildContext context) {
        final S l = S.of(context);
        return SimpleDialog(
          title: Text(l.openInCollection),
          children: infos.map((CollectedItemInfo info) {
            return SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(info),
              child: Text(info.collectionName ?? l.collectionsUncategorized),
            );
          }).toList(),
        );
      },
    );
    if (chosen != null && mounted) {
      _navigateToItemDetail(chosen);
    }
  }

  Future<List<CollectedItemInfo>> _getCollectedInfos(
    int externalId,
    MediaType mediaType,
  ) async {
    final Map<int, List<CollectedItemInfo>> collected;
    switch (mediaType) {
      case MediaType.game:
        collected = await ref.read(collectedGameIdsProvider.future);
      case MediaType.movie:
        collected = await ref.read(collectedMovieIdsProvider.future);
      case MediaType.tvShow:
        collected = await ref.read(collectedTvShowIdsProvider.future);
      case MediaType.animation:
        collected = await ref.read(collectedAnimationIdsProvider.future);
      case MediaType.visualNovel:
        collected = await ref.read(collectedVisualNovelIdsProvider.future);
      case MediaType.manga:
        collected = await ref.read(collectedMangaIdsProvider.future);
    }
    return collected[externalId] ?? <CollectedItemInfo>[];
  }

  void _navigateToItemDetail(CollectedItemInfo info) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ItemDetailScreen(
          collectionId: info.collectionId,
          itemId: info.recordId,
          isEditable: true,
        ),
      ),
    );
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
    } else if (item is Manga) {
      _onMangaTap(item);
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

    final Map<int, List<CollectedItemInfo>> collectedGames =
        await ref.read(collectedGameIdsProvider.future);
    final List<CollectedItemInfo> infos =
        collectedGames[game.id] ?? <CollectedItemInfo>[];
    final Set<int?> alreadyIn =
        infos.map((CollectedItemInfo i) => i.collectionId).toSet();

    if (!mounted) return;
    final S l = S.of(context);
    final CollectionChoice? choice = await showCollectionPickerDialog(
      context: context,
      ref: ref,
      title: l.searchAddToCollection,
      alreadyInCollectionIds: alreadyIn,
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
        cacheImageType: ImageType.moviePoster,
        cacheImageId: movie.tmdbId.toString(),
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

    final Map<int, List<CollectedItemInfo>> collectedMovies =
        await ref.read(collectedMovieIdsProvider.future);
    final Map<int, List<CollectedItemInfo>> collectedAnimations =
        await ref.read(collectedAnimationIdsProvider.future);
    final List<CollectedItemInfo> infos = <CollectedItemInfo>[
      ...collectedMovies[movie.tmdbId] ?? <CollectedItemInfo>[],
      ...collectedAnimations[movie.tmdbId] ?? <CollectedItemInfo>[],
    ];
    final Set<int?> alreadyIn =
        infos.map((CollectedItemInfo i) => i.collectionId).toSet();

    if (!mounted) return;
    final S l = S.of(context);
    final CollectionChoice? choice = await showCollectionPickerDialog(
      context: context,
      ref: ref,
      title: l.searchAddToCollection,
      alreadyInCollectionIds: alreadyIn,
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
        cacheImageType: ImageType.tvShowPoster,
        cacheImageId: tvShow.tmdbId.toString(),
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

    final Map<int, List<CollectedItemInfo>> collectedTvShows =
        await ref.read(collectedTvShowIdsProvider.future);
    final Map<int, List<CollectedItemInfo>> collectedAnimations =
        await ref.read(collectedAnimationIdsProvider.future);
    final List<CollectedItemInfo> infos = <CollectedItemInfo>[
      ...collectedTvShows[tvShow.tmdbId] ?? <CollectedItemInfo>[],
      ...collectedAnimations[tvShow.tmdbId] ?? <CollectedItemInfo>[],
    ];
    final Set<int?> alreadyIn =
        infos.map((CollectedItemInfo i) => i.collectionId).toSet();

    if (!mounted) return;
    final S l = S.of(context);
    final CollectionChoice? choice = await showCollectionPickerDialog(
      context: context,
      ref: ref,
      title: l.searchAddToCollection,
      alreadyInCollectionIds: alreadyIn,
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

    final Map<int, List<CollectedItemInfo>> collectedAnimation =
        await ref.read(collectedAnimationIdsProvider.future);
    final Map<int, List<CollectedItemInfo>> collectedMovies =
        await ref.read(collectedMovieIdsProvider.future);
    final List<CollectedItemInfo> infos = <CollectedItemInfo>[
      ...collectedAnimation[movie.tmdbId] ?? <CollectedItemInfo>[],
      ...collectedMovies[movie.tmdbId] ?? <CollectedItemInfo>[],
    ];
    final Set<int?> alreadyIn =
        infos.map((CollectedItemInfo i) => i.collectionId).toSet();

    if (!mounted) return;
    final S l = S.of(context);
    final CollectionChoice? choice = await showCollectionPickerDialog(
      context: context,
      ref: ref,
      title: l.searchAddToCollection,
      alreadyInCollectionIds: alreadyIn,
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

    final Map<int, List<CollectedItemInfo>> collectedAnimation =
        await ref.read(collectedAnimationIdsProvider.future);
    final Map<int, List<CollectedItemInfo>> collectedTvShows =
        await ref.read(collectedTvShowIdsProvider.future);
    final List<CollectedItemInfo> infos = <CollectedItemInfo>[
      ...collectedAnimation[tvShow.tmdbId] ?? <CollectedItemInfo>[],
      ...collectedTvShows[tvShow.tmdbId] ?? <CollectedItemInfo>[],
    ];
    final Set<int?> alreadyIn =
        infos.map((CollectedItemInfo i) => i.collectionId).toSet();

    if (!mounted) return;
    final S l = S.of(context);
    final CollectionChoice? choice = await showCollectionPickerDialog(
      context: context,
      ref: ref,
      title: l.searchAddToCollection,
      alreadyInCollectionIds: alreadyIn,
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
              leading: const Icon(Icons.videogame_asset, size: 24),
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

    final Map<int, List<CollectedItemInfo>> collectedVns =
        await ref.read(collectedVisualNovelIdsProvider.future);
    final List<CollectedItemInfo> infos =
        collectedVns[vn.numericId] ?? <CollectedItemInfo>[];
    final Set<int?> alreadyIn =
        infos.map((CollectedItemInfo i) => i.collectionId).toSet();

    if (!mounted) return;
    final S l = S.of(context);
    final CollectionChoice? choice = await showCollectionPickerDialog(
      context: context,
      ref: ref,
      title: l.searchAddToCollection,
      alreadyInCollectionIds: alreadyIn,
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

  // ==================== Manga actions ====================

  void _onMangaTap(Manga manga) {
    if (widget.collectionId != null) {
      _addMangaToCollection(manga);
    } else {
      _showMangaDetails(manga);
    }
  }

  Future<void> _addMangaToCollection(Manga manga) async {
    final String title = manga.title;

    await ref.read(databaseServiceProvider).upsertManga(manga);

    final bool success = await ref
        .read(
            collectionItemsNotifierProvider(widget.collectionId).notifier)
        .addItem(
          mediaType: MediaType.manga,
          externalId: manga.id,
        );

    if (mounted) {
      final S l = S.of(context);
      if (success) {
        _cacheImage(
          ImageType.mangaCover,
          manga.id.toString(),
          manga.coverUrl,
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

  Future<void> _addMangaToAnyCollection(Manga manga) async {
    final String title = manga.title;

    final Map<int, List<CollectedItemInfo>> collectedManga =
        await ref.read(collectedMangaIdsProvider.future);
    final List<CollectedItemInfo> infos =
        collectedManga[manga.id] ?? <CollectedItemInfo>[];
    final Set<int?> alreadyIn =
        infos.map((CollectedItemInfo i) => i.collectionId).toSet();

    if (!mounted) return;
    final S l = S.of(context);
    final CollectionChoice? choice = await showCollectionPickerDialog(
      context: context,
      ref: ref,
      title: l.searchAddToCollection,
      alreadyInCollectionIds: alreadyIn,
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

    await ref.read(databaseServiceProvider).upsertManga(manga);

    final bool success = await ref
        .read(collectionItemsNotifierProvider(collectionId).notifier)
        .addItem(
          mediaType: MediaType.manga,
          externalId: manga.id,
        );

    if (mounted) {
      if (success) {
        _cacheImage(
          ImageType.mangaCover,
          manga.id.toString(),
          manga.coverUrl,
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

  void _showMangaDetails(Manga manga) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => MangaDetailsSheet(
        manga: manga,
        onAddToCollection: () => _addMangaToAnyCollection(manga),
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
      builder: (BuildContext _) => DiscoverCustomizeSheet(
        sourceId: ref.read(browseProvider).sourceId,
      ),
    );
  }

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    final BrowseState browseState = ref.watch(browseProvider);
    final bool isLandscape = isLandscapeMobile(context);

    // Очистка поля при смене источника
    if (_lastSourceId != null && _lastSourceId != browseState.sourceId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchController.clear();
      });
    }
    _lastSourceId = browseState.sourceId;

    // Discover Customize кнопка — только без запросов и фильтров
    // когда источник поддерживает Discover (TMDB)
    final bool showDiscoverCustomize = !browseState.hasActiveQuery &&
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
        ],
      ),
      body: TypeToFilterOverlay(
        onFilterChanged: (String query) {
          setState(() => _typeToFilterQuery = query);
        },
        child: Column(
          children: <Widget>[
            // Фильтр-бар: всегда видим
            FilterBar(onBeforeFilterChange: _syncSearchText),
            // Поле поиска: всегда видимо
            _buildSearchField(),
            const SizedBox(height: AppSpacing.xs),
            // Контент
            Expanded(
              child: _buildContent(browseState),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Search field ====================

  Widget _buildSearchField() {
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
    );
  }

  // ==================== Content ====================

  Widget _buildContent(BrowseState browseState) {
    // Без активного запроса (ни текста, ни фильтров)
    if (!browseState.hasActiveQuery) {
      final String sourceId = browseState.sourceId;

      // TMDB источники — показываем Discover feed
      if (sourceId == 'movies' || sourceId == 'tv' || sourceId == 'anime') {
        return DiscoverFeed(
          sourceId: sourceId,
          onAddMovie: (Movie movie) => _addMovieToAnyCollection(movie),
          onAddTvShow: (TvShow tvShow) => _addTvShowToAnyCollection(tvShow),
        );
      }

      // Другие источники без Discover — пустое состояние
      return _buildEmptyFilterState();
    }

    // Есть запрос (текст и/или фильтры) → показываем грид результатов
    return BrowseGrid(
      onItemTap: _onItemTap,
      onOpenInCollection: _openItemInCollection,
      clientFilter: _typeToFilterQuery,
      platformMap: _platformMap,
    );
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

}
