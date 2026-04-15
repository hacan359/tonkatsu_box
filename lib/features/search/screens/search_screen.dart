// Экран поиска и просмотра контента.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/navigation/search_providers.dart';
import '../../../shared/keyboard/keyboard_shortcuts.dart';
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
import '../../../shared/models/anime.dart';
import '../../../shared/models/manga.dart';
import '../../../shared/models/visual_novel.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/collection_picker_dialog.dart';
import '../../collections/providers/collections_provider.dart';
import '../../collections/screens/item_detail_screen.dart';
import '../providers/browse_provider.dart';
import '../widgets/browse_grid.dart';
import '../widgets/discover_customize_sheet.dart';
import '../widgets/discover_feed.dart';
import '../widgets/filter_bar.dart';
import '../widgets/item_details_sheet.dart';

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

  /// Группа хоткеев этого экрана для легенды F1.
  static const ShortcutGroup shortcutGroup = ShortcutGroup(
    title: 'Поиск',
    entries: <ShortcutEntry>[
      ShortcutEntry(keys: 'Ctrl+F', description: 'Фокус в поле поиска'),
      ShortcutEntry(keys: 'Escape', description: 'Очистить / назад'),
      ShortcutEntry(keys: 'Enter', description: 'Выполнить поиск'),
    ],
  );

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  Timer? _searchDebounce;

  Map<int, Platform> _platformMap = <int, Platform>{};

  @override
  void initState() {
    super.initState();
    _loadPlatforms();

    // Предвыбор источника
    final String? sourceToSet = widget.initialSourceId ??
        (widget.initialTabIndex == 1 ? 'games' : null);

    if (sourceToSet != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(browseProvider.notifier).setSource(sourceToSet);
        if (widget.initialQuery != null &&
            widget.initialQuery!.isNotEmpty) {
          ref.read(searchTabQueryProvider.notifier).state =
              widget.initialQuery!;
          ref.read(browseProvider.notifier).search(widget.initialQuery!);
        }
      });
    } else if (widget.initialQuery != null &&
        widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchTabQueryProvider.notifier).state =
            widget.initialQuery!;
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
    _searchDebounce?.cancel();
    super.dispose();
  }

  // ==================== Search ====================

  /// Синхронизирует текст из провайдера в browse перед сменой фильтра.
  void _syncSearchText() {
    final String text = ref.read(searchTabQueryProvider).trim();
    if (text.length >= 2) {
      ref.read(browseProvider.notifier).setSearchQuery(text);
    }
  }

  /// Debounced поиск при изменении query в top bar.
  void _onQueryChanged(String query) {
    _searchDebounce?.cancel();
    if (query.isEmpty) {
      ref.read(browseProvider.notifier).clearSearch();
      return;
    }
    if (query.length < 2) return;
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        ref.read(browseProvider.notifier).search(query);
      }
    });
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
            final String name =
                info.collectionName ?? l.collectionsUncategorized;
            final Platform? platform = info.platformId != null
                ? _platformMap[info.platformId]
                : null;
            return SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(info),
              child: Row(
                children: <Widget>[
                  if (platform != null) ...<Widget>[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: platform.familyColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(name),
                        if (platform != null)
                          Text(
                            platform.displayName,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textTertiary),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
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
      case MediaType.anime:
        collected = await ref.read(collectedAnimeIdsProvider.future);
      case MediaType.custom:
        return <CollectedItemInfo>[]; // Кастомные элементы не ищутся через API
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
    } else if (item is Anime) {
      _onAnimeTap(item);
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

    // Показываем какие платформы уже добавлены в текущую коллекцию.
    final Map<int, List<CollectedItemInfo>> collectedGames =
        await ref.read(collectedGameIdsProvider.future);
    final List<CollectedItemInfo> infos =
        collectedGames[game.id] ?? <CollectedItemInfo>[];
    final Set<int> alreadyPlatforms = infos
        .where((CollectedItemInfo i) => i.collectionId == widget.collectionId)
        .map((CollectedItemInfo i) => i.platformId)
        .whereType<int>()
        .toSet();

    final int? platformId = await _showPlatformSelectionDialog(
      game,
      alreadyAddedPlatformIds: alreadyPlatforms,
    );
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

    // Для игр не блокируем коллекции — та же игра на другой платформе разрешена.
    // Сохраняем infos для проверки конкретной платформы после выбора.
    final Map<int, List<CollectedItemInfo>> collectedGames =
        await ref.read(collectedGameIdsProvider.future);
    final List<CollectedItemInfo> infos =
        collectedGames[game.id] ?? <CollectedItemInfo>[];

    if (!mounted) return;
    final S l = S.of(context);
    final CollectionChoice? choice = await showCollectionPickerDialog(
      context: context,
      ref: ref,
      title: l.searchAddToCollection,
      // Не блокируем коллекции — игру можно добавить на другой платформе.
      alreadyInCollectionIds: const <int?>{},
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

    // Показываем какие платформы уже добавлены в выбранную коллекцию.
    final Set<int> alreadyPlatforms = infos
        .where((CollectedItemInfo i) => i.collectionId == collectionId)
        .map((CollectedItemInfo i) => i.platformId)
        .whereType<int>()
        .toSet();

    final int? platformId = await _showPlatformSelectionDialog(
      game,
      alreadyAddedPlatformIds: alreadyPlatforms,
    );
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
      builder: (BuildContext context) => ItemDetailsSheet.movie(
        movie,
        isAnimation: isAnim,
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
      builder: (BuildContext context) => ItemDetailsSheet.tvShow(
        tvShow,
        isAnimation: isAnim,
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

  Future<int?> _showPlatformSelectionDialog(
    Game game, {
    Set<int> alreadyAddedPlatformIds = const <int>{},
  }) async {
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
            final bool alreadyAdded = alreadyAddedPlatformIds.contains(id);
            return ListTile(
              leading: Icon(
                alreadyAdded
                    ? Icons.check_circle
                    : Icons.videogame_asset,
                size: 24,
                color: alreadyAdded ? AppColors.success : null,
              ),
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
      builder: (BuildContext context) => ItemDetailsSheet.visualNovel(
        vn,
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
      builder: (BuildContext context) => ItemDetailsSheet.manga(
        manga,
        onAddToCollection: () => _addMangaToAnyCollection(manga),
      ),
    );
  }

  // ==================== Anime actions ====================

  void _onAnimeTap(Anime anime) {
    if (widget.collectionId != null) {
      _addAnimeToCollection(anime);
    } else {
      _showAnimeDetails(anime);
    }
  }

  Future<void> _addAnimeToCollection(Anime anime) async {
    final String title = anime.title;

    await ref.read(databaseServiceProvider).upsertAnime(anime);

    final bool success = await ref
        .read(
            collectionItemsNotifierProvider(widget.collectionId).notifier)
        .addItem(
          mediaType: MediaType.anime,
          externalId: anime.id,
        );

    if (mounted) {
      final S l = S.of(context);
      if (success) {
        _cacheImage(
          ImageType.animeCover,
          anime.id.toString(),
          anime.coverUrl,
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

  Future<void> _addAnimeToAnyCollection(Anime anime) async {
    final String title = anime.title;

    final Map<int, List<CollectedItemInfo>> collectedAnime =
        await ref.read(collectedAnimeIdsProvider.future);
    final List<CollectedItemInfo> infos =
        collectedAnime[anime.id] ?? <CollectedItemInfo>[];
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

    await ref.read(databaseServiceProvider).upsertAnime(anime);

    final bool success = await ref
        .read(collectionItemsNotifierProvider(collectionId).notifier)
        .addItem(
          mediaType: MediaType.anime,
          externalId: anime.id,
        );

    if (mounted) {
      if (success) {
        _cacheImage(
          ImageType.animeCover,
          anime.id.toString(),
          anime.coverUrl,
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

  void _showAnimeDetails(Anime anime) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => ItemDetailsSheet.anime(
        anime,
        onAddToCollection: () => _addAnimeToAnyCollection(anime),
      ),
    );
  }

  void _showGameDetails(Game game) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => ItemDetailsSheet.game(
        game,
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

    // Слушаем глобальный поиск — debounced API запрос.
    ref.listen<String>(searchTabQueryProvider, (String? prev, String next) {
      _onQueryChanged(next);
    });

    return Column(
      children: <Widget>[
        FilterBar(
          onBeforeFilterChange: _syncSearchText,
          onDiscoverCustomize: _showDiscoverCustomizeSheet,
        ),
        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: _buildContent(browseState),
        ),
      ],
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
      clientFilter: '',
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
