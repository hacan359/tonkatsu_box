import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../data/repositories/canvas_repository.dart';
import '../../data/repositories/collection_repository.dart';
import '../../shared/models/canvas_connection.dart';
import '../../shared/models/canvas_item.dart';
import '../../shared/models/canvas_viewport.dart';
import '../../shared/models/collection.dart';
import '../../shared/models/collection_item.dart';
import '../../shared/models/collection_tag.dart';
import '../../shared/models/custom_media.dart';
import '../../shared/models/item_status.dart';
import '../../shared/models/tier_definition.dart';
import '../../shared/models/tier_list.dart';
import '../../shared/models/game.dart';
import '../../shared/models/media_type.dart';
import '../../shared/models/movie.dart';
import '../../shared/models/platform.dart' as model;
import '../../shared/models/tv_episode.dart';
import '../../shared/models/tv_season.dart';
import '../../shared/models/tv_show.dart';
import '../../shared/models/anime.dart';
import '../../shared/models/manga.dart';
import '../../shared/models/tracker_game_data.dart';
import '../../shared/models/visual_novel.dart';
import '../api/anilist_api.dart';
import '../api/igdb_api.dart';
import '../api/tmdb_api.dart';
import '../api/vndb_api.dart';
import '../database/dao/tracker_dao.dart';
import '../database/database_service.dart';
import 'collection_hero_service.dart';
import 'image_cache_service.dart';
import 'xcoll_file.dart';

final Provider<ImportService> importServiceProvider =
    Provider<ImportService>((Ref ref) {
  return ImportService(
    repository: ref.watch(collectionRepositoryProvider),
    igdbApi: ref.watch(igdbApiProvider),
    tmdbApi: ref.watch(tmdbApiProvider),
    vndbApi: ref.watch(vndbApiProvider),
    aniListApi: ref.watch(aniListApiProvider),
    database: ref.watch(databaseServiceProvider),
    canvasRepository: ref.watch(canvasRepositoryProvider),
    imageCacheService: ref.watch(imageCacheServiceProvider),
    trackerDao: ref.watch(trackerDaoProvider),
    heroService: ref.watch(collectionHeroServiceProvider),
  );
});

class ImportResult {
  const ImportResult({
    required this.success,
    this.collection,
    this.itemsImported,
    this.itemsUpdated = 0,
    this.error,
  });

  const ImportResult.success(Collection col, int items, {int updated = 0})
      : success = true,
        collection = col,
        itemsImported = items,
        itemsUpdated = updated,
        error = null;

  const ImportResult.failure(String message)
      : success = false,
        collection = null,
        itemsImported = null,
        itemsUpdated = 0,
        error = message;

  const ImportResult.cancelled()
      : success = false,
        collection = null,
        itemsImported = null,
        itemsUpdated = 0,
        error = null;

  final bool success;

  final Collection? collection;

  final int? itemsImported;

  final int itemsUpdated;

  final String? error;

  bool get isCancelled => !success && error == null;
}

typedef ImportProgressCallback = void Function(ImportProgress progress);

class ImportProgress {
  const ImportProgress({
    required this.stage,
    required this.current,
    required this.total,
    this.message,
  });

  final ImportStage stage;

  final int current;

  final int total;

  final String? message;

  double get progress => total > 0 ? current / total : 0;
}

enum ImportStage {
  reading('Reading file...'),

  fetchingGames('Fetching game data...'),

  fetchingMovies('Fetching movie data...'),

  fetchingTvShows('Fetching TV show data...'),

  fetchingVisualNovels('Fetching visual novel data...'),

  fetchingManga('Fetching manga data...'),

  fetchingAnime('Fetching anime data...'),

  cachingMedia('Caching media...'),

  creatingCollection('Creating collection...'),

  addingItems('Adding items...'),

  importingCanvas('Importing board...'),

  restoringMedia('Restoring media data...'),

  importingImages('Restoring images...'),

  completed('Import completed');

  const ImportStage(this.description);

  final String description;
}

class ImportService {
  ImportService({
    required CollectionRepository repository,
    required IgdbApi igdbApi,
    required DatabaseService database,
    TmdbApi? tmdbApi,
    VndbApi? vndbApi,
    AniListApi? aniListApi,
    CanvasRepository? canvasRepository,
    ImageCacheService? imageCacheService,
    TrackerDao? trackerDao,
    CollectionHeroService? heroService,
  })  : _repository = repository,
        _igdbApi = igdbApi,
        _tmdbApi = tmdbApi,
        _vndbApi = vndbApi,
        _aniListApi = aniListApi,
        _database = database,
        _canvasRepository = canvasRepository,
        _imageCacheService = imageCacheService,
        _trackerDao = trackerDao,
        _heroService = heroService;

  final CollectionRepository _repository;
  final IgdbApi _igdbApi;
  final TmdbApi? _tmdbApi;
  final VndbApi? _vndbApi;
  final AniListApi? _aniListApi;
  final DatabaseService _database;
  final CanvasRepository? _canvasRepository;
  final ImageCacheService? _imageCacheService;
  final TrackerDao? _trackerDao;
  final CollectionHeroService? _heroService;

  static final Logger _log = Logger('ImportService');

  static const List<String> _allowedExtensions = <String>[
    'xcoll',
    'xcollx',
    'json',
  ];

  /// Returns null if the user cancelled. Throws [FormatException] on invalid file.
  Future<XcollFile?> pickAndParseFile() async {
    // Android's FileType.custom does not filter custom extensions.
    final bool useAny = Platform.isAndroid;
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Import Collection',
      type: useAny ? FileType.any : FileType.custom,
      allowedExtensions: useAny ? null : _allowedExtensions,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final String? filePath = result.files.first.path;
    if (filePath == null) {
      throw const FormatException('Could not read file path');
    }

    // Android: validate extension manually since picker doesn't filter.
    if (useAny) {
      final String ext = filePath.split('.').last.toLowerCase();
      if (!_allowedExtensions.contains(ext)) {
        throw FormatException(
          'Unsupported file type: .$ext. '
          'Expected: ${_allowedExtensions.join(', ')}',
        );
      }
    }

    return parseFile(File(filePath));
  }

  Future<XcollFile> parseFile(File file) async {
    if (!await file.exists()) {
      throw const FormatException('File does not exist');
    }

    final String content = await file.readAsString();
    return XcollFile.fromJsonString(content);
  }

  /// [collectionId] non-null imports into an existing collection and updates
  /// duplicates; null creates a new collection.
  Future<ImportResult> importFromFile({
    int? collectionId,
    ImportProgressCallback? onProgress,
  }) async {
    try {
      onProgress?.call(const ImportProgress(
        stage: ImportStage.reading,
        current: 0,
        total: 1,
      ));

      final XcollFile? xcoll = await pickAndParseFile();
      if (xcoll == null) {
        return const ImportResult.cancelled();
      }

      return importFromXcoll(
        xcoll,
        collectionId: collectionId,
        onProgress: onProgress,
      );
    } on FormatException catch (e) {
      return ImportResult.failure('Invalid file format: ${e.message}');
    } catch (e) {
      return ImportResult.failure('Import failed: $e');
    }
  }

  Future<ImportResult> importFromXcoll(
    XcollFile xcoll, {
    int? collectionId,
    ImportProgressCallback? onProgress,
  }) async {
    return _importV2(xcoll, collectionId: collectionId, onProgress: onProgress);
  }

  Future<ImportResult> _importV2(
    XcollFile xcoll, {
    int? collectionId,
    ImportProgressCallback? onProgress,
  }) async {
    try {
      final bool hasEmbeddedMedia = xcoll.media.isNotEmpty;

      if (hasEmbeddedMedia) {
        await _restoreEmbeddedMedia(xcoll.media, onProgress: onProgress);
      } else {
        await _fetchMediaFromApi(xcoll.items, onProgress: onProgress);
      }

      final Collection collection;
      if (collectionId != null) {
        final Collection? existing =
            await _repository.getById(collectionId);
        if (existing == null) {
          return ImportResult.failure(
            'Collection with id $collectionId not found',
          );
        }
        collection = existing;
      } else {
        onProgress?.call(const ImportProgress(
          stage: ImportStage.creatingCollection,
          current: 0,
          total: 1,
        ));

        collection = await _repository.create(
          name: xcoll.name,
          author: xcoll.author,
          type: CollectionType.own,
        );

        await _restoreCollectionPersonalization(collection, xcoll);

        onProgress?.call(const ImportProgress(
          stage: ImportStage.creatingCollection,
          current: 1,
          total: 1,
        ));
      }

      // Maps (media_type:external_id[:platform_id]) to new collection_item_id
      // for tier-list/tag entries to resolve.
      final Map<String, int> itemIdMapping = <String, int>{};
      int addedCount = 0;
      int updatedCount = 0;
      for (int i = 0; i < xcoll.items.length; i++) {
        final Map<String, dynamic> itemData = xcoll.items[i];

        onProgress?.call(ImportProgress(
          stage: ImportStage.addingItems,
          current: i,
          total: xcoll.items.length,
        ));

        final CollectionItem parsed = CollectionItem.fromExport(itemData);

        final int? itemId = await _repository.addItem(
          collectionId: collection.id,
          mediaType: parsed.mediaType,
          externalId: parsed.externalId,
          platformId: parsed.platformId,
          authorComment: parsed.authorComment,
          status: xcoll.includesUserData ? parsed.status : ItemStatus.notStarted,
        );

        if (itemId != null) {
          addedCount++;
          final String key = _itemMappingKey(
            parsed.mediaType,
            parsed.externalId,
            parsed.platformId,
          );
          itemIdMapping[key] = itemId;
          // Fallback key without platform for backwards compatibility with
          // old exports where tier-list/tag entries lack platform_id.
          final String fallbackKey =
              '${parsed.mediaType.value}:${parsed.externalId}';
          itemIdMapping.putIfAbsent(fallbackKey, () => itemId);

          if (xcoll.includesUserData && _hasUserData(parsed)) {
            await _restoreUserData(itemId, parsed);
          }

          final Map<String, dynamic>? perItemCanvas =
              itemData['_canvas'] as Map<String, dynamic>?;
          if (perItemCanvas != null && _canvasRepository != null) {
            await _importPerItemCanvas(
                perItemCanvas, itemId, collection.id);
          }
        } else if (collectionId != null) {
          // Item already exists — update from file.
          final bool didUpdate = await _updateExistingItem(
            collectionId: collection.id,
            parsed: parsed,
            includesUserData: xcoll.includesUserData,
          );
          if (didUpdate) {
            updatedCount++;
          }
          // Tier-lists need the existing item's id.
          final CollectionItem? existing = await _repository.findItem(
            collectionId: collection.id,
            mediaType: parsed.mediaType,
            externalId: parsed.externalId,
            platformId: parsed.platformId,
          );
          if (existing != null) {
            final String key = _itemMappingKey(
              parsed.mediaType,
              parsed.externalId,
              parsed.platformId,
            );
            itemIdMapping[key] = existing.id;
            final String fallbackKey =
                '${parsed.mediaType.value}:${parsed.externalId}';
            itemIdMapping.putIfAbsent(fallbackKey, () => existing.id);
          }
        }
      }

      // Canvas only for new collections: canvas items have no unique
      // constraint and would duplicate on re-import.
      final bool isNewCollection = collectionId == null;

      if (xcoll.isFull && _canvasRepository != null && isNewCollection) {
        onProgress?.call(const ImportProgress(
          stage: ImportStage.importingCanvas,
          current: 0,
          total: 1,
          message: 'Importing board...',
        ));

        await _importCanvas(xcoll, collection.id);

        onProgress?.call(const ImportProgress(
          stage: ImportStage.importingCanvas,
          current: 1,
          total: 1,
        ));
      }

      if (xcoll.isFull &&
          xcoll.images.isNotEmpty &&
          _imageCacheService != null) {
        onProgress?.call(ImportProgress(
          stage: ImportStage.importingImages,
          current: 0,
          total: xcoll.images.length,
          message: 'Restoring cover images...',
        ));

        await _restoreImages(xcoll.images, onProgress: onProgress);
      }

      if (xcoll.isFull &&
          xcoll.tierLists != null &&
          xcoll.tierLists!.isNotEmpty) {
        await _importTierLists(
          xcoll.tierLists!,
          collection.id,
          itemIdMapping,
        );
      }

      if (xcoll.isFull &&
          xcoll.tags != null &&
          xcoll.tags!.isNotEmpty) {
        await _importTags(
          xcoll.tags!,
          xcoll.items,
          collection.id,
          itemIdMapping,
        );
      }

      if (xcoll.trackerData != null &&
          xcoll.trackerData!.isNotEmpty &&
          _trackerDao != null) {
        await _importTrackerData(xcoll.trackerData!);
      }

      onProgress?.call(ImportProgress(
        stage: ImportStage.completed,
        current: addedCount,
        total: xcoll.items.length,
        message: 'Imported $addedCount items',
      ));

      return ImportResult.success(collection, addedCount, updated: updatedCount);
    } on IgdbApiException catch (e) {
      return ImportResult.failure(
          'Failed to fetch games from IGDB: ${e.message}');
    } on FormatException catch (e) {
      return ImportResult.failure('Invalid file format: ${e.message}');
    } catch (e) {
      return ImportResult.failure('Import failed: $e');
    }
  }

  /// Updates authorComment/userRating only when the local field is empty so
  /// import never overwrites user-edited values. Returns true if any field changed.
  Future<bool> _updateExistingItem({
    required int collectionId,
    required CollectionItem parsed,
    bool includesUserData = false,
  }) async {
    final CollectionItem? existing = await _repository.findItem(
      collectionId: collectionId,
      mediaType: parsed.mediaType,
      externalId: parsed.externalId,
      platformId: parsed.platformId,
    );
    if (existing == null) return false;

    bool didUpdate = false;

    if (existing.authorComment == null &&
        parsed.authorComment != null &&
        parsed.authorComment!.isNotEmpty) {
      await _database.updateItemAuthorComment(
        existing.id,
        parsed.authorComment,
      );
      didUpdate = true;
    }

    if (existing.userRating == null && parsed.userRating != null) {
      await _database.updateItemUserRating(existing.id, parsed.userRating);
      didUpdate = true;
    }

    if (includesUserData && _hasUserData(parsed)) {
      await _restoreUserData(existing.id, parsed);
      didUpdate = true;
    }

    return didUpdate;
  }

  bool _hasUserData(CollectionItem parsed) {
    return parsed.status != ItemStatus.notStarted ||
        parsed.userComment != null ||
        parsed.userRating != null ||
        parsed.startedAt != null ||
        parsed.completedAt != null ||
        parsed.lastActivityAt != null ||
        parsed.currentSeason > 0 ||
        parsed.currentEpisode > 0;
  }

  Future<void> _restoreUserData(int itemId, CollectionItem parsed) async {
    if (parsed.status != ItemStatus.notStarted) {
      await _database.updateItemStatus(
        itemId,
        parsed.status,
        mediaType: parsed.mediaType,
      );
    }
    if (parsed.userComment != null) {
      await _database.updateItemUserComment(itemId, parsed.userComment);
    }
    if (parsed.userRating != null) {
      await _database.updateItemUserRating(itemId, parsed.userRating);
    }
    if (parsed.startedAt != null ||
        parsed.completedAt != null ||
        parsed.lastActivityAt != null) {
      await _database.updateItemActivityDates(
        itemId,
        startedAt: parsed.startedAt,
        completedAt: parsed.completedAt,
        lastActivityAt: parsed.lastActivityAt,
      );
    }
    if (parsed.currentSeason > 0 || parsed.currentEpisode > 0) {
      await _database.updateItemProgress(
        itemId,
        currentSeason: parsed.currentSeason,
        currentEpisode: parsed.currentEpisode,
      );
    }
  }

  /// Offline restore from the embedded `media` section of full exports.
  Future<void> _restoreEmbeddedMedia(
    Map<String, dynamic> media, {
    ImportProgressCallback? onProgress,
  }) async {
    final List<dynamic> rawGames =
        media['games'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawMovies =
        media['movies'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawTvShows =
        media['tv_shows'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawSeasons =
        media['tv_seasons'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawEpisodes =
        media['tv_episodes'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawPlatforms =
        media['platforms'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawVisualNovels =
        media['visual_novels'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawMangas =
        media['mangas'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawAnimes =
        media['animes'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawCustom =
        media['custom_items'] as List<dynamic>? ?? <dynamic>[];

    final int total = rawGames.length +
        rawMovies.length +
        rawTvShows.length +
        rawSeasons.length +
        rawEpisodes.length +
        rawPlatforms.length +
        rawVisualNovels.length +
        rawMangas.length +
        rawAnimes.length +
        rawCustom.length;
    final int cachedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    int current = 0;

    onProgress?.call(ImportProgress(
      stage: ImportStage.restoringMedia,
      current: 0,
      total: total,
      message: 'Restoring $total media entries...',
    ));

    if (rawGames.isNotEmpty) {
      final List<Game> games = <Game>[];
      for (final dynamic raw in rawGames) {
        final Map<String, dynamic> row =
            Map<String, dynamic>.from(raw as Map<String, dynamic>);
        row['cached_at'] = cachedAt;
        games.add(Game.fromDb(row));
        current++;
        onProgress?.call(ImportProgress(
          stage: ImportStage.restoringMedia,
          current: current,
          total: total,
        ));
      }
      await _database.upsertGames(games);
    }

    if (rawMovies.isNotEmpty) {
      final List<Movie> movies = <Movie>[];
      for (final dynamic raw in rawMovies) {
        final Map<String, dynamic> row =
            Map<String, dynamic>.from(raw as Map<String, dynamic>);
        row['cached_at'] = cachedAt;
        movies.add(Movie.fromDb(row));
        current++;
        onProgress?.call(ImportProgress(
          stage: ImportStage.restoringMedia,
          current: current,
          total: total,
        ));
      }
      await _database.upsertMovies(movies);
    }

    if (rawTvShows.isNotEmpty) {
      final List<TvShow> tvShows = <TvShow>[];
      for (final dynamic raw in rawTvShows) {
        final Map<String, dynamic> row =
            Map<String, dynamic>.from(raw as Map<String, dynamic>);
        row['cached_at'] = cachedAt;
        tvShows.add(TvShow.fromDb(row));
        current++;
        onProgress?.call(ImportProgress(
          stage: ImportStage.restoringMedia,
          current: current,
          total: total,
        ));
      }
      await _database.upsertTvShows(tvShows);
    }

    if (rawSeasons.isNotEmpty) {
      final List<TvSeason> seasons = <TvSeason>[];
      for (final dynamic raw in rawSeasons) {
        final Map<String, dynamic> row =
            Map<String, dynamic>.from(raw as Map<String, dynamic>);
        seasons.add(TvSeason.fromDb(row));
        current++;
        onProgress?.call(ImportProgress(
          stage: ImportStage.restoringMedia,
          current: current,
          total: total,
        ));
      }
      await _database.upsertTvSeasons(seasons);
    }

    if (rawEpisodes.isNotEmpty) {
      final List<TvEpisode> episodes = <TvEpisode>[];
      for (final dynamic raw in rawEpisodes) {
        final Map<String, dynamic> row =
            Map<String, dynamic>.from(raw as Map<String, dynamic>);
        row['cached_at'] = cachedAt;
        episodes.add(TvEpisode.fromDb(row));
        current++;
        onProgress?.call(ImportProgress(
          stage: ImportStage.restoringMedia,
          current: current,
          total: total,
        ));
      }
      await _database.upsertEpisodes(episodes);
    }

    if (rawPlatforms.isNotEmpty) {
      final List<model.Platform> platforms = <model.Platform>[];
      for (final dynamic raw in rawPlatforms) {
        final Map<String, dynamic> row =
            Map<String, dynamic>.from(raw as Map<String, dynamic>);
        platforms.add(model.Platform.fromDb(row));
        current++;
        onProgress?.call(ImportProgress(
          stage: ImportStage.restoringMedia,
          current: current,
          total: total,
        ));
      }
      await _database.upsertPlatforms(platforms);
    }

    if (rawVisualNovels.isNotEmpty) {
      final List<VisualNovel> visualNovels = <VisualNovel>[];
      for (final dynamic raw in rawVisualNovels) {
        final Map<String, dynamic> row =
            Map<String, dynamic>.from(raw as Map<String, dynamic>);
        if (!row.containsKey('updated_at') || row['updated_at'] == null) {
          row['updated_at'] = cachedAt;
        }
        visualNovels.add(VisualNovel.fromDb(row));
        current++;
        onProgress?.call(ImportProgress(
          stage: ImportStage.restoringMedia,
          current: current,
          total: total,
        ));
      }
      await _database.upsertVisualNovels(visualNovels);
    }

    if (rawMangas.isNotEmpty) {
      final List<Manga> mangas = <Manga>[];
      for (final dynamic raw in rawMangas) {
        final Map<String, dynamic> row =
            Map<String, dynamic>.from(raw as Map<String, dynamic>);
        row['cached_at'] = cachedAt;
        mangas.add(Manga.fromDb(row));
        current++;
        onProgress?.call(ImportProgress(
          stage: ImportStage.restoringMedia,
          current: current,
          total: total,
        ));
      }
      await _database.upsertMangas(mangas);
    }

    if (rawAnimes.isNotEmpty) {
      final List<Anime> animes = <Anime>[];
      for (final dynamic raw in rawAnimes) {
        final Map<String, dynamic> row =
            Map<String, dynamic>.from(raw as Map<String, dynamic>);
        row['updated_at'] = cachedAt;
        animes.add(Anime.fromDb(row));
        current++;
        onProgress?.call(ImportProgress(
          stage: ImportStage.restoringMedia,
          current: current,
          total: total,
        ));
      }
      await _database.upsertAnimes(animes);
    }

    if (rawCustom.isNotEmpty) {
      final List<CustomMedia> customItems = <CustomMedia>[];
      for (final dynamic raw in rawCustom) {
        final Map<String, dynamic> row =
            Map<String, dynamic>.from(raw as Map<String, dynamic>);
        row['cached_at'] = cachedAt;
        customItems.add(CustomMedia.fromDb(row));
        current++;
        onProgress?.call(ImportProgress(
          stage: ImportStage.restoringMedia,
          current: current,
          total: total,
        ));
      }
      await _database.customMediaDao.upsertAll(customItems);
    }
  }

  /// Online fallback for light exports or legacy full exports without
  /// an embedded `media` section.
  Future<void> _fetchMediaFromApi(
    List<Map<String, dynamic>> items, {
    ImportProgressCallback? onProgress,
  }) async {
    final List<Map<String, dynamic>> gameItems = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> movieItems = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> tvShowItems = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> vnItems = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> mangaItems = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> animeItems = <Map<String, dynamic>>[];

    for (final Map<String, dynamic> item in items) {
      final String mediaType = item['media_type'] as String;
      switch (mediaType) {
        case 'game':
          gameItems.add(item);
        case 'movie':
          movieItems.add(item);
        case 'tv_show':
          tvShowItems.add(item);
        case 'animation':
          final int? platformId = item['platform_id'] as int?;
          if (platformId == AnimationSource.tvShow) {
            tvShowItems.add(item);
          } else {
            movieItems.add(item);
          }
        case 'visual_novel':
          vnItems.add(item);
        case 'manga':
          mangaItems.add(item);
        case 'anime':
          animeItems.add(item);
      }
    }

    final List<int> gameIds = gameItems
        .map((Map<String, dynamic> i) => i['external_id'] as int)
        .toList();

    onProgress?.call(ImportProgress(
      stage: ImportStage.fetchingGames,
      current: 0,
      total: gameIds.length,
      message: 'Fetching ${gameIds.length} games from IGDB...',
    ));

    List<Game> games = <Game>[];
    if (gameIds.isNotEmpty) {
      games = await _igdbApi.getGamesByIds(gameIds);
    }

    final List<int> movieIds = movieItems
        .map((Map<String, dynamic> i) => i['external_id'] as int)
        .toList();
    final List<Movie> movies = <Movie>[];

    if (movieIds.isNotEmpty && _tmdbApi != null) {
      final TmdbApi tmdbApi = _tmdbApi;
      onProgress?.call(ImportProgress(
        stage: ImportStage.fetchingMovies,
        current: 0,
        total: movieIds.length,
        message: 'Fetching ${movieIds.length} movies from TMDB...',
      ));

      for (int i = 0; i < movieIds.length; i++) {
        try {
          final Movie? movie = await tmdbApi.getMovie(movieIds[i]);
          if (movie != null) {
            movies.add(movie);
          }
        } on TmdbApiException {
          // Skip unavailable movies so one failure doesn't abort the batch.
        }
        onProgress?.call(ImportProgress(
          stage: ImportStage.fetchingMovies,
          current: i + 1,
          total: movieIds.length,
        ));
      }
    }

    final List<int> tvShowIds = tvShowItems
        .map((Map<String, dynamic> i) => i['external_id'] as int)
        .toList();
    final List<TvShow> tvShows = <TvShow>[];

    if (tvShowIds.isNotEmpty && _tmdbApi != null) {
      final TmdbApi tmdbApi = _tmdbApi;
      onProgress?.call(ImportProgress(
        stage: ImportStage.fetchingTvShows,
        current: 0,
        total: tvShowIds.length,
        message: 'Fetching ${tvShowIds.length} TV shows from TMDB...',
      ));

      for (int i = 0; i < tvShowIds.length; i++) {
        try {
          final TvShow? tvShow = await tmdbApi.getTvShow(tvShowIds[i]);
          if (tvShow != null) {
            tvShows.add(tvShow);
          }
        } on TmdbApiException {
          // Skip unavailable TV shows so one failure doesn't abort the batch.
        }
        onProgress?.call(ImportProgress(
          stage: ImportStage.fetchingTvShows,
          current: i + 1,
          total: tvShowIds.length,
        ));
      }
    }

    final List<String> vnIds = vnItems
        .where((Map<String, dynamic> i) => i['external_id'] != null)
        .map((Map<String, dynamic> i) => 'v${i['external_id'] as int}')
        .toList();
    List<VisualNovel> visualNovels = <VisualNovel>[];

    if (vnIds.isNotEmpty && _vndbApi != null) {
      final VndbApi vndbApi = _vndbApi;
      onProgress?.call(ImportProgress(
        stage: ImportStage.fetchingVisualNovels,
        current: 0,
        total: vnIds.length,
        message: 'Fetching ${vnIds.length} visual novels from VNDB...',
      ));

      try {
        visualNovels = await vndbApi.getVnByIds(vnIds);
      } on VndbApiException catch (e) {
        _log.warning('Failed to fetch visual novels: ${e.message}');
      }
      onProgress?.call(ImportProgress(
        stage: ImportStage.fetchingVisualNovels,
        current: vnIds.length,
        total: vnIds.length,
      ));
    }

    final List<int> mangaIds = mangaItems
        .where((Map<String, dynamic> i) => i['external_id'] != null)
        .map((Map<String, dynamic> i) => i['external_id'] as int)
        .toList();
    List<Manga> mangas = <Manga>[];

    if (mangaIds.isNotEmpty && _aniListApi != null) {
      final AniListApi aniListApi = _aniListApi;
      onProgress?.call(ImportProgress(
        stage: ImportStage.fetchingManga,
        current: 0,
        total: mangaIds.length,
        message: 'Fetching ${mangaIds.length} manga from AniList...',
      ));

      try {
        mangas = await aniListApi.getMangaByIds(mangaIds);
      } on AniListApiException catch (e) {
        _log.warning('Failed to fetch manga: ${e.message}');
      }
      onProgress?.call(ImportProgress(
        stage: ImportStage.fetchingManga,
        current: mangaIds.length,
        total: mangaIds.length,
      ));
    }

    final List<int> animeIds = animeItems
        .where((Map<String, dynamic> i) => i['external_id'] != null)
        .map((Map<String, dynamic> i) => i['external_id'] as int)
        .toList();
    List<Anime> animes = <Anime>[];

    if (animeIds.isNotEmpty && _aniListApi != null) {
      final AniListApi aniListApi = _aniListApi;
      onProgress?.call(ImportProgress(
        stage: ImportStage.fetchingAnime,
        current: 0,
        total: animeIds.length,
        message: 'Fetching ${animeIds.length} anime from AniList...',
      ));

      try {
        animes = await aniListApi.getAnimeByIds(animeIds);
      } on AniListApiException catch (e) {
        _log.warning('Failed to fetch anime: ${e.message}');
      }
      onProgress?.call(ImportProgress(
        stage: ImportStage.fetchingAnime,
        current: animeIds.length,
        total: animeIds.length,
      ));
    }

    final int totalMedia = games.length +
        movies.length +
        tvShows.length +
        visualNovels.length +
        mangas.length +
        animes.length;
    onProgress?.call(ImportProgress(
      stage: ImportStage.cachingMedia,
      current: 0,
      total: totalMedia,
    ));

    int cachedCount = 0;
    for (final Game game in games) {
      await _database.upsertGame(game);
      cachedCount++;
      onProgress?.call(ImportProgress(
        stage: ImportStage.cachingMedia,
        current: cachedCount,
        total: totalMedia,
      ));
    }

    if (movies.isNotEmpty) {
      await _database.upsertMovies(movies);
      cachedCount += movies.length;
      onProgress?.call(ImportProgress(
        stage: ImportStage.cachingMedia,
        current: cachedCount,
        total: totalMedia,
      ));
    }

    if (tvShows.isNotEmpty) {
      await _database.upsertTvShows(tvShows);
      cachedCount += tvShows.length;
      onProgress?.call(ImportProgress(
        stage: ImportStage.cachingMedia,
        current: cachedCount,
        total: totalMedia,
      ));
    }

    if (visualNovels.isNotEmpty) {
      await _database.upsertVisualNovels(visualNovels);
      cachedCount += visualNovels.length;
      onProgress?.call(ImportProgress(
        stage: ImportStage.cachingMedia,
        current: cachedCount,
        total: totalMedia,
      ));
    }

    if (mangas.isNotEmpty) {
      await _database.upsertMangas(mangas);
      cachedCount += mangas.length;
      onProgress?.call(ImportProgress(
        stage: ImportStage.cachingMedia,
        current: cachedCount,
        total: totalMedia,
      ));
    }

    if (animes.isNotEmpty) {
      await _database.upsertAnimes(animes);
      cachedCount += animes.length;
      onProgress?.call(ImportProgress(
        stage: ImportStage.cachingMedia,
        current: cachedCount,
        total: totalMedia,
      ));
    }
  }

  /// Keys in [images] have the format '{ImageType.folder}/{imageId}'.
  Future<int> _restoreImages(
    Map<String, String> images, {
    ImportProgressCallback? onProgress,
  }) async {
    final ImageCacheService cache = _imageCacheService!;
    int restored = 0;
    int current = 0;

    for (final MapEntry<String, String> entry in images.entries) {
      current++;
      onProgress?.call(ImportProgress(
        stage: ImportStage.importingImages,
        current: current,
        total: images.length,
        message: 'Restoring image $current of ${images.length}',
      ));

      final List<String> parts = entry.key.split('/');
      if (parts.length != 2) continue;

      final String folder = parts[0];
      final String imageId = parts[1];

      final ImageType? imageType = _imageTypeFromFolder(folder);
      if (imageType == null) continue;

      try {
        final Uint8List bytes = base64Decode(entry.value);
        final bool success =
            await cache.saveImageBytes(imageType, imageId, bytes);
        if (success) restored++;
      } catch (e) {
        _log.warning('Failed to restore image from base64: $imageId', e);
      }
    }

    return restored;
  }

  ImageType? _imageTypeFromFolder(String folder) {
    for (final ImageType type in ImageType.values) {
      if (type.folder == folder) {
        return type;
      }
    }
    return null;
  }

  /// Remaps exported canvas item ids to new autoincrement ids so connections
  /// stay consistent after import.
  Future<void> _importCanvas(XcollFile xcoll, int collectionId) async {
    final CanvasRepository repo = _canvasRepository!;

    if (xcoll.canvas == null) return;

    final ExportCanvas canvas = xcoll.canvas!;

    if (canvas.viewport != null) {
      final CanvasViewport viewport = CanvasViewport.fromExport(
        canvas.viewport!,
        collectionId: collectionId,
      );
      await repo.saveViewport(viewport);
    }

    final Map<int, int> idRemap = <int, int>{};

    for (final Map<String, dynamic> itemData in canvas.items) {
      final int exportId = itemData['id'] as int? ?? 0;

      final CanvasItem item = CanvasItem.fromExport(
        itemData,
        collectionId: collectionId,
      ).copyWith(id: 0); // Reset id for autoincrement.

      final CanvasItem created = await repo.createItem(item);
      if (exportId != 0) {
        idRemap[exportId] = created.id;
      }
    }

    for (final Map<String, dynamic> connData in canvas.connections) {
      final int exportFromId = connData['from_item_id'] as int;
      final int exportToId = connData['to_item_id'] as int;

      final int? newFromId = idRemap[exportFromId];
      final int? newToId = idRemap[exportToId];

      // Skip connection if either endpoint failed to remap.
      if (newFromId == null || newToId == null) continue;

      final CanvasConnection conn = CanvasConnection.fromExport(
        connData,
        collectionId: collectionId,
      ).copyWith(
        id: 0,
        fromItemId: newFromId,
        toItemId: newToId,
      );

      await repo.createConnection(conn);
    }
  }

  /// Per-item canvas variant: same remap logic but scoped to a collectionItemId.
  Future<void> _importPerItemCanvas(
    Map<String, dynamic> canvasData,
    int collectionItemId,
    int collectionId,
  ) async {
    final CanvasRepository repo = _canvasRepository!;
    final ExportCanvas canvas = ExportCanvas.fromJson(canvasData);

    // For game canvas the viewport's collectionId field stores collectionItemId.
    if (canvas.viewport != null) {
      final CanvasViewport viewport = CanvasViewport.fromExport(
        canvas.viewport!,
        collectionId: collectionItemId,
      );
      await repo.saveGameCanvasViewport(collectionItemId, viewport);
    }

    final Map<int, int> idRemap = <int, int>{};

    for (final Map<String, dynamic> itemData in canvas.items) {
      final int exportId = itemData['id'] as int? ?? 0;

      final CanvasItem item = CanvasItem.fromExport(
        itemData,
        collectionId: collectionId,
      ).copyWith(id: 0, collectionItemId: collectionItemId);

      final CanvasItem created = await repo.createItem(item);
      if (exportId != 0) {
        idRemap[exportId] = created.id;
      }
    }

    for (final Map<String, dynamic> connData in canvas.connections) {
      final int exportFromId = connData['from_item_id'] as int;
      final int exportToId = connData['to_item_id'] as int;

      final int? newFromId = idRemap[exportFromId];
      final int? newToId = idRemap[exportToId];

      // Skip connection if either endpoint failed to remap.
      if (newFromId == null || newToId == null) continue;

      final CanvasConnection conn = CanvasConnection.fromExport(
        connData,
        collectionId: collectionId,
      ).copyWith(
        id: 0,
        collectionItemId: collectionItemId,
        fromItemId: newFromId,
        toItemId: newToId,
      );

      await repo.createConnection(conn);
    }
  }

  /// [itemIdMapping]: 'media_type:external_id[:platform_id]' -> new collection_item_id.
  Future<void> _importTierLists(
    List<Map<String, dynamic>> tierListsData,
    int collectionId,
    Map<String, int> itemIdMapping,
  ) async {
    for (final Map<String, dynamic> tlData in tierListsData) {
      final String name = tlData['name'] as String? ?? 'Imported Tier List';

      final TierList tierList = await _database.tierListDao.createTierList(
        name,
        collectionId: collectionId,
      );

      final List<dynamic>? rawDefs =
          tlData['definitions'] as List<dynamic>?;
      if (rawDefs != null && rawDefs.isNotEmpty) {
        final List<TierDefinition> defs = rawDefs
            .map((dynamic d) =>
                TierDefinition.fromExport(d as Map<String, dynamic>))
            .toList();
        await _database.tierListDao.saveTierDefinitions(tierList.id, defs);
      }

      final List<dynamic>? rawEntries =
          tlData['entries'] as List<dynamic>?;
      if (rawEntries == null) continue;

      for (final dynamic entryRaw in rawEntries) {
        final Map<String, dynamic> entryData =
            entryRaw as Map<String, dynamic>;

        final int? externalId = entryData['external_id'] as int?;
        final String? mediaType = entryData['media_type'] as String?;
        final int? platformId = entryData['platform_id'] as int?;

        if (externalId == null || mediaType == null) continue;

        // Try platform-qualified key, then fall back for legacy exports.
        final String keyWithPlatform = '$mediaType:$externalId:$platformId';
        final String keyWithout = '$mediaType:$externalId';
        final int? newItemId =
            itemIdMapping[keyWithPlatform] ?? itemIdMapping[keyWithout];
        if (newItemId == null) continue;

        final String tierKey = entryData['tier_key'] as String;
        final int sortOrder = entryData['sort_order'] as int? ?? 0;

        await _database.tierListDao.setItemTier(
          tierList.id,
          newItemId,
          tierKey,
          sortOrder,
        );
      }
    }
  }

  Future<void> _importTags(
    List<Map<String, dynamic>> tagsData,
    List<Map<String, dynamic>> exportedItems,
    int collectionId,
    Map<String, int> itemIdMapping,
  ) async {
    final Map<String, int> tagNameToId = <String, int>{};
    for (final Map<String, dynamic> tagData in tagsData) {
      final String name = tagData['name'] as String? ?? 'Imported Tag';
      final int? color = tagData['color'] as int?;

      final CollectionTag tag = await _database.tagDao.createTag(
        collectionId,
        name,
        color: color,
      );
      tagNameToId[name] = tag.id;
    }

    for (final Map<String, dynamic> itemData in exportedItems) {
      final String? tagName = itemData['tag_name'] as String?;
      if (tagName == null) continue;

      final int? tagId = tagNameToId[tagName];
      if (tagId == null) continue;

      final String? mediaType = itemData['media_type'] as String?;
      final int? externalId = itemData['external_id'] as int?;
      final int? platformId = itemData['platform_id'] as int?;
      if (mediaType == null || externalId == null) continue;

      // Try platform-qualified key, then fall back for legacy exports.
      final String keyWithPlatform = '$mediaType:$externalId:$platformId';
      final String keyWithout = '$mediaType:$externalId';
      final int? itemId =
          itemIdMapping[keyWithPlatform] ?? itemIdMapping[keyWithout];
      if (itemId == null) continue;

      await _database.tagDao.setItemTag(itemId, tagId);
    }
  }

  /// Games include platform_id in the key to distinguish per-platform versions;
  /// other media types use only media_type:external_id.
  static String _itemMappingKey(
    MediaType mediaType,
    int externalId,
    int? platformId,
  ) {
    if (mediaType == MediaType.game && platformId != null) {
      return '${mediaType.value}:$externalId:$platformId';
    }
    return '${mediaType.value}:$externalId';
  }

  Future<void> _importTrackerData(
    List<Map<String, dynamic>> trackerData,
  ) async {
    final List<TrackerGameData> items = trackerData
        .map((Map<String, dynamic> d) => TrackerGameData.fromDb(d))
        .toList();
    await _trackerDao!.upsertGameDataBatch(items);
  }

  /// Hero image is located by scanning `xcoll.images` for the
  /// `collection_hero/` prefix; old id is ignored since we take the first match.
  Future<void> _restoreCollectionPersonalization(
    Collection collection,
    XcollFile xcoll,
  ) async {
    String? heroFileName;
    if (_heroService != null) {
      MapEntry<String, String>? heroEntry;
      for (final MapEntry<String, String> entry in xcoll.images.entries) {
        if (entry.key.startsWith('collection_hero/')) {
          heroEntry = entry;
          break;
        }
      }
      if (heroEntry != null) {
        try {
          final List<int> bytes = base64Decode(heroEntry.value);
          final String ext = _heroExtensionFromKey(heroEntry.key);
          heroFileName = await _heroService.saveBytes(
            collectionId: collection.id,
            bytes: bytes,
            extension: ext,
          );
        } on FormatException catch (e) {
          _log.warning('Failed to decode hero image: $e');
        }
      }
    }

    final bool hasDescription =
        xcoll.description != null && xcoll.description!.isNotEmpty;

    if (heroFileName != null || hasDescription) {
      await _repository.updatePersonalization(
        collection.id,
        heroImagePath: heroFileName,
        description: hasDescription ? xcoll.description : null,
      );
    }
  }

  static String _heroExtensionFromKey(String key) {
    final int dot = key.lastIndexOf('.');
    if (dot == -1) return 'png';
    return key.substring(dot + 1).toLowerCase();
  }
}
