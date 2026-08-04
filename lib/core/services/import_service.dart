import 'dart:convert';
import 'dart:io';

import 'package:core/database/dao/global_tag_dao.dart';
import 'package:core/database/dao/tracker_dao.dart';
import 'package:core/models/anime.dart';
import 'package:core/models/book.dart';
import 'package:core/models/canvas_connection.dart';
import 'package:core/models/canvas_item.dart';
import 'package:core/models/canvas_viewport.dart';
import 'package:core/models/collection.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/custom_media.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/game.dart';
import 'package:core/models/item_mark.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/manga.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/movie.dart';
import 'package:core/models/tag.dart';
import 'package:core/models/tier_definition.dart';
import 'package:core/models/tier_list.dart';
import 'package:core/models/tracker_game_data.dart';
import 'package:core/models/tv_episode.dart';
import 'package:core/models/tv_season.dart';
import 'package:core/models/tv_show.dart';
import 'package:core/models/visual_novel.dart';
import 'package:core/models/xcoll_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../data/repositories/canvas_repository.dart';
import '../../data/repositories/collection_repository.dart';
import 'package:core/models/platform.dart' as model;
import '../api/anilist_api.dart';
import '../api/comicvine_api.dart';
import '../api/fantlab_api.dart';
import '../api/google_books_api.dart';
import '../api/hardcover_api.dart';
import '../api/igdb_api.dart';
import '../api/kitsu_api.dart';
import '../api/mangabaka_api.dart';
import '../api/mangadex_api.dart';
import '../api/openlibrary_api.dart';
import '../api/tmdb_api.dart';
import '../api/tvmaze_api.dart';
import '../api/vndb_api.dart';
import '../database/database_service.dart';
import '../import/import_progress.dart';
import 'collection_hero_service.dart';
import 'image_cache_service.dart';

// Progress types moved to the import layer; re-exported so the many existing
// `services/import_service.dart` importers keep compiling.
export '../import/import_progress.dart';

final Provider<ImportService> importServiceProvider =
    Provider<ImportService>((Ref ref) {
  return ImportService(
    repository: ref.watch(collectionRepositoryProvider),
    igdbApi: ref.watch(igdbApiProvider),
    tmdbApi: ref.watch(tmdbApiProvider),
    vndbApi: ref.watch(vndbApiProvider),
    aniListApi: ref.watch(aniListApiProvider),
    tvMazeApi: ref.watch(tvMazeApiProvider),
    kitsuApi: ref.watch(kitsuApiProvider),
    mangaBakaApi: ref.watch(mangaBakaApiProvider),
    mangaDexApi: ref.watch(mangaDexApiProvider),
    openLibraryApi: ref.watch(openLibraryApiProvider),
    googleBooksApi: ref.watch(googleBooksApiProvider),
    comicVineApi: ref.watch(comicVineApiProvider),
    hardcoverApi: ref.watch(hardcoverApiProvider),
    fantlabApi: ref.watch(fantlabApiProvider),
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

class ImportService {
  ImportService({
    required CollectionRepository repository,
    required IgdbApi igdbApi,
    required DatabaseService database,
    TmdbApi? tmdbApi,
    VndbApi? vndbApi,
    AniListApi? aniListApi,
    TvMazeApi? tvMazeApi,
    KitsuApi? kitsuApi,
    MangaBakaApi? mangaBakaApi,
    MangaDexApi? mangaDexApi,
    OpenLibraryApi? openLibraryApi,
    GoogleBooksApi? googleBooksApi,
    ComicVineApi? comicVineApi,
    HardcoverApi? hardcoverApi,
    FantlabApi? fantlabApi,
    CanvasRepository? canvasRepository,
    ImageCacheService? imageCacheService,
    TrackerDao? trackerDao,
    CollectionHeroService? heroService,
  })  : _repository = repository,
        _igdbApi = igdbApi,
        _tmdbApi = tmdbApi,
        _vndbApi = vndbApi,
        _aniListApi = aniListApi,
        _tvMazeApi = tvMazeApi,
        _kitsuApi = kitsuApi,
        _mangaBakaApi = mangaBakaApi,
        _mangaDexApi = mangaDexApi,
        _openLibraryApi = openLibraryApi,
        _googleBooksApi = googleBooksApi,
        _comicVineApi = comicVineApi,
        _hardcoverApi = hardcoverApi,
        _fantlabApi = fantlabApi,
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
  final TvMazeApi? _tvMazeApi;
  final KitsuApi? _kitsuApi;
  final MangaBakaApi? _mangaBakaApi;
  final MangaDexApi? _mangaDexApi;
  final OpenLibraryApi? _openLibraryApi;
  final GoogleBooksApi? _googleBooksApi;
  final ComicVineApi? _comicVineApi;
  final HardcoverApi? _hardcoverApi;
  final FantlabApi? _fantlabApi;
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

        // Keep the original creation date: a backup restore must not collapse
        // the collection's history onto the restore day.
        collection = await _repository.create(
          name: xcoll.name,
          author: xcoll.author,
          type: CollectionType.own,
          createdAt: xcoll.created,
        );

        await _restoreCollectionPersonalization(collection, xcoll);

        onProgress?.call(const ImportProgress(
          stage: ImportStage.creatingCollection,
          current: 1,
          total: 1,
        ));
      }

      // Item keys (see _itemMappingKeys) to new collection_item_id, so
      // tier-list and tag entries can resolve their item.
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
          source: parsed.source,
          authorComment: parsed.authorComment,
          status: xcoll.includesUserData ? parsed.status : ItemStatus.notStarted,
          // Keep the exported added date, otherwise a backup restore collapses
          // the whole "added by month" timeline onto the restore day.
          addedAt: xcoll.includesUserData ? parsed.addedAt : null,
        );

        if (itemId != null) {
          addedCount++;
          _registerItemMapping(itemIdMapping, parsed, itemId);

          if (xcoll.includesUserData && _hasUserData(parsed)) {
            await _restoreUserData(itemId, parsed);
          }

          final Map<String, dynamic>? perItemCanvas =
              itemData['_canvas'] as Map<String, dynamic>?;
          if (perItemCanvas != null && _canvasRepository != null) {
            await _importPerItemCanvas(
                perItemCanvas, itemId, collection.id);
          }

          if (xcoll.includesUserData) {
            await _importItemMarks(itemData, itemId);
            await _importWatchedEpisodes(itemData, collection.id, parsed);
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
            source: parsed.source,
          );
          if (existing != null) {
            _registerItemMapping(itemIdMapping, parsed, existing.id);

            // Marks are idempotent (insertMarks replaces on the unique key),
            // so re-importing onto an existing item merges, not duplicates.
            if (xcoll.includesUserData) {
              await _importItemMarks(itemData, existing.id);
              await _importWatchedEpisodes(itemData, collection.id, parsed);
            }
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
      source: parsed.source,
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
        parsed.currentEpisode > 0 ||
        parsed.overrideName != null ||
        parsed.isFavorite ||
        parsed.rewatchCount != null;
  }

  Future<void> _restoreUserData(int itemId, CollectionItem parsed) async {
    if (parsed.status != ItemStatus.notStarted) {
      await _database.updateItemStatus(
        itemId,
        parsed.status,
        mediaType: parsed.mediaType,
      );
    }
    // The file value must win over the bump a `completed` transition just
    // made; `null` is never applied — it would wipe a local counter.
    if (parsed.rewatchCount != null) {
      await _database.updateItemRewatchCount(itemId, parsed.rewatchCount);
    }
    if (parsed.userComment != null) {
      await _database.updateItemUserComment(itemId, parsed.userComment);
    }
    if (parsed.userRating != null) {
      await _database.updateItemUserRating(itemId, parsed.userRating);
    }
    if (parsed.overrideName != null) {
      await _database.setItemOverrideName(itemId, parsed.overrideName);
    }
    if (parsed.isFavorite) {
      await _database.setItemFavorite(itemId, isFavorite: true);
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
    final List<dynamic> rawBooks =
        media['books'] as List<dynamic>? ?? <dynamic>[];
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
        rawBooks.length +
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
      await _database.gameDao.upsertGames(games);
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
      await _database.movieDao.upsertMovies(movies);
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
      await _database.tvShowDao.upsertTvShows(tvShows);
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
      await _database.tvShowDao.upsertTvSeasons(seasons);
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
      await _database.tvShowDao.upsertEpisodes(episodes);
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
      await _database.gameDao.upsertPlatforms(platforms);
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
      await _database.visualNovelDao.upsertVisualNovels(visualNovels);
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
      await _database.mangaDao.upsertMangas(mangas);
    }

    if (rawBooks.isNotEmpty) {
      final List<Book> books = <Book>[];
      for (final dynamic raw in rawBooks) {
        final Map<String, dynamic> row =
            Map<String, dynamic>.from(raw as Map<String, dynamic>);
        row['cached_at'] = cachedAt;
        books.add(Book.fromDb(row));
        current++;
        onProgress?.call(ImportProgress(
          stage: ImportStage.restoringMedia,
          current: current,
          total: total,
        ));
      }
      await _database.bookDao.upsertBooks(books);
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
      await _database.animeDao.upsertAnimes(animes);
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

  /// Online fallback for exports without an embedded `media` section; items
  /// refetch grouped by (media type, source) — ids are not portable across providers.
  Future<void> _fetchMediaFromApi(
    List<Map<String, dynamic>> items, {
    ImportProgressCallback? onProgress,
  }) async {
    final List<int> gameIds = <int>[];
    final List<int> movieIds = <int>[];
    final List<String> vnIds = <String>[];
    final List<_MediaRef> tvRefs = <_MediaRef>[];
    final List<_MediaRef> mangaRefs = <_MediaRef>[];
    final List<_MediaRef> animeRefs = <_MediaRef>[];
    final List<_MediaRef> bookRefs = <_MediaRef>[];

    for (final Map<String, dynamic> item in items) {
      final MediaType? mediaType =
          MediaType.tryFromString(item['media_type'] as String);
      final int? externalId = item['external_id'] as int?;
      if (mediaType == null || externalId == null) continue;

      final _MediaRef ref = _MediaRef(
        externalId: externalId,
        source: DataSource.fromNameOr(
          item['source'] as String?,
          mediaType.defaultSource,
        ),
        nativeId: item['native_id'] as String?,
      );

      switch (mediaType) {
        case MediaType.game:
          gameIds.add(externalId);
        case MediaType.movie:
          movieIds.add(externalId);
        case MediaType.tvShow:
          tvRefs.add(ref);
        case MediaType.animation:
          // Animated films live in the movie cache, series in the show cache.
          if ((item['platform_id'] as int?) == AnimationSource.tvShow) {
            tvRefs.add(ref);
          } else {
            movieIds.add(externalId);
          }
        case MediaType.visualNovel:
          vnIds.add('v$externalId');
        case MediaType.manga:
          mangaRefs.add(ref);
        case MediaType.anime:
          animeRefs.add(ref);
        case MediaType.book:
          bookRefs.add(ref);
        case MediaType.custom:
          break;
      }
    }

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

    final List<TvShow> tvShows = <TvShow>[];
    if (tvRefs.isNotEmpty) {
      onProgress?.call(ImportProgress(
        stage: ImportStage.fetchingTvShows,
        current: 0,
        total: tvRefs.length,
        message: 'Fetching ${tvRefs.length} TV shows...',
      ));

      for (int i = 0; i < tvRefs.length; i++) {
        final TvShow? show = await _fetchTvShow(tvRefs[i]);
        if (show != null) {
          tvShows.add(show);
        }
        onProgress?.call(ImportProgress(
          stage: ImportStage.fetchingTvShows,
          current: i + 1,
          total: tvRefs.length,
        ));
      }
    }

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

    final AniListApi? aniList = _aniListApi;
    final List<Manga> mangas = await _fetchByRefs<Manga>(
      mangaRefs,
      stage: ImportStage.fetchingManga,
      label: 'manga',
      aniListBatch: (List<int> ids,
              void Function(Duration, int) onRateLimit) async =>
          aniList?.getMangaByIds(ids, onRateLimit: onRateLimit) ?? <Manga>[],
      fetchOne: _fetchOneManga,
      onProgress: onProgress,
    );
    final List<Anime> animes = await _fetchByRefs<Anime>(
      animeRefs,
      stage: ImportStage.fetchingAnime,
      label: 'anime',
      aniListBatch: (List<int> ids,
              void Function(Duration, int) onRateLimit) async =>
          aniList?.getAnimeByIds(ids, onRateLimit: onRateLimit) ?? <Anime>[],
      fetchOne: _fetchOneAnime,
      onProgress: onProgress,
    );
    final List<Book> books =
        await _fetchBookRefs(bookRefs, onProgress: onProgress);

    final int totalMedia = games.length +
        movies.length +
        tvShows.length +
        visualNovels.length +
        mangas.length +
        animes.length +
        books.length;
    onProgress?.call(ImportProgress(
      stage: ImportStage.cachingMedia,
      current: 0,
      total: totalMedia,
    ));

    int cachedCount = 0;
    void reportCached(int added) {
      cachedCount += added;
      onProgress?.call(ImportProgress(
        stage: ImportStage.cachingMedia,
        current: cachedCount,
        total: totalMedia,
      ));
    }

    for (final Game game in games) {
      await _database.gameDao.upsertGame(game);
      reportCached(1);
    }

    if (movies.isNotEmpty) {
      await _database.movieDao.upsertMovies(movies);
      reportCached(movies.length);
    }

    if (tvShows.isNotEmpty) {
      await _database.tvShowDao.upsertTvShows(tvShows);
      reportCached(tvShows.length);
    }

    if (visualNovels.isNotEmpty) {
      await _database.visualNovelDao.upsertVisualNovels(visualNovels);
      reportCached(visualNovels.length);
    }

    if (mangas.isNotEmpty) {
      await _database.mangaDao.upsertMangas(mangas);
      reportCached(mangas.length);
    }

    if (animes.isNotEmpty) {
      await _database.animeDao.upsertAnimes(animes);
      reportCached(animes.length);
    }

    if (books.isNotEmpty) {
      await _database.bookDao.upsertBooks(books);
      reportCached(books.length);
    }
  }

  Future<TvShow?> _fetchTvShow(_MediaRef ref) async {
    try {
      if (ref.source == DataSource.tvmaze) {
        return await _tvMazeApi?.getShow(ref.externalId);
      }
      return await _tmdbApi?.getTvShow(ref.externalId);
    } on Exception catch (e) {
      // One unavailable show must not abort the batch.
      _log.warning('Failed to fetch TV show ${ref.externalId} '
          'from ${ref.source.name}: $e');
      return null;
    }
  }

  /// AniList ids resolve in one batched query, all other providers per id.
  /// Shared by manga and anime so progress/rate-limit reporting can't drift.
  Future<List<T>> _fetchByRefs<T>(
    List<_MediaRef> refs, {
    required ImportStage stage,
    required String label,
    required Future<List<T>> Function(
      List<int> ids,
      void Function(Duration wait, int attempt) onRateLimit,
    ) aniListBatch,
    required Future<T?> Function(_MediaRef ref) fetchOne,
    ImportProgressCallback? onProgress,
  }) async {
    if (refs.isEmpty) return <T>[];

    final List<T> result = <T>[];
    int done = 0;
    void report({String? message}) => onProgress?.call(ImportProgress(
          stage: stage,
          current: done,
          total: refs.length,
          message: message,
        ));
    report(message: 'Fetching ${refs.length} $label...');

    final List<_MediaRef> byId = <_MediaRef>[];
    final List<int> aniListIds = <int>[];
    for (final _MediaRef ref in refs) {
      if (ref.source == DataSource.anilist) {
        aniListIds.add(ref.externalId);
      } else {
        byId.add(ref);
      }
    }

    if (aniListIds.isNotEmpty) {
      try {
        result.addAll(await aniListBatch(
          aniListIds,
          (Duration wait, int attempt) => report(
            message: 'Rate limited, waiting ${wait.inSeconds}s '
                '(attempt $attempt)...',
          ),
        ));
      } on AniListApiException catch (e) {
        _log.warning('Failed to fetch $label from AniList: ${e.message}');
      }
      done += aniListIds.length;
      report();
    }

    for (final _MediaRef ref in byId) {
      final T? item = await fetchOne(ref);
      if (item != null) {
        result.add(item);
      }
      done++;
      report();
    }
    return result;
  }

  Future<Manga?> _fetchOneManga(_MediaRef ref) async {
    try {
      switch (ref.source) {
        case DataSource.mangabaka:
          return await _mangaBakaApi?.getById(ref.externalId);
        case DataSource.kitsu:
          return await _kitsuApi?.getMangaById(ref.externalId);
        case DataSource.mangadex:
          // MangaDex is keyed by a UUID and external_id is only its hash, so
          // files written before native_id can't be resolved.
          final String? uuid = ref.nativeId;
          return uuid != null ? await _mangaDexApi?.getByUuid(uuid) : null;
        default:
          return await _aniListApi?.getMangaById(ref.externalId);
      }
    } on Exception catch (e) {
      _log.warning('Failed to fetch manga ${ref.externalId} '
          'from ${ref.source.name}: $e');
      return null;
    }
  }

  Future<Anime?> _fetchOneAnime(_MediaRef ref) async {
    try {
      if (ref.source == DataSource.kitsu) {
        return await _kitsuApi?.getAnimeById(ref.externalId);
      }
      return await _aniListApi?.getAnimeById(ref.externalId);
    } on Exception catch (e) {
      _log.warning('Failed to fetch anime ${ref.externalId} '
          'from ${ref.source.name}: $e');
      return null;
    }
  }

  Future<List<Book>> _fetchBookRefs(
    List<_MediaRef> refs, {
    ImportProgressCallback? onProgress,
  }) async {
    if (refs.isEmpty) return const <Book>[];

    final List<Book> result = <Book>[];
    onProgress?.call(ImportProgress(
      stage: ImportStage.fetchingBooks,
      current: 0,
      total: refs.length,
      message: 'Fetching ${refs.length} books...',
    ));

    for (int i = 0; i < refs.length; i++) {
      final Book? book = await _fetchOneBook(refs[i]);
      if (book != null) {
        result.add(book);
      }
      onProgress?.call(ImportProgress(
        stage: ImportStage.fetchingBooks,
        current: i + 1,
        total: refs.length,
      ));
    }
    return result;
  }

  Future<Book?> _fetchOneBook(_MediaRef ref) async {
    // external_id derives from the provider's string id and can't be turned
    // back, so files predating native_id leave their books unresolved.
    final String? nativeId = ref.nativeId;
    if (nativeId == null) return null;

    try {
      switch (ref.source) {
        case DataSource.openLibrary:
          return await _openLibraryApi?.getWork(nativeId);
        case DataSource.googleBooks:
          return await _googleBooksApi?.getVolume(nativeId);
        case DataSource.comicVine:
          return await _comicVineApi?.getVolume(nativeId);
        case DataSource.hardcover:
          return await _hardcoverApi?.getBook(nativeId);
        case DataSource.fantlab:
          return await _fantlabApi?.getWork(nativeId);
        default:
          return null;
      }
    } on Exception catch (e) {
      _log.warning('Failed to fetch book $nativeId '
          'from ${ref.source.name}: $e');
      return null;
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
      String imageId = parts[1];

      final ImageType? imageType = _imageTypeFromFolder(folder);
      if (imageType == null) continue;

      // Legacy backups stored manga/anime covers under the bare numeric id;
      // those rows were always AniList, so remap instead of re-downloading.
      if ((imageType == ImageType.mangaCover ||
              imageType == ImageType.animeCover) &&
          int.tryParse(imageId) != null) {
        imageId = 'anilist_$imageId';
      }

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

  /// Restores per-item marks (likes/notes) nested under the item's `_marks`
  /// key, re-anchoring each to the freshly assigned [collectionItemId].
  Future<void> _importItemMarks(
    Map<String, dynamic> itemData,
    int collectionItemId,
  ) async {
    final List<dynamic>? rawMarks = itemData['_marks'] as List<dynamic>?;
    if (rawMarks == null || rawMarks.isEmpty) return;
    final List<ItemMark> marks = <ItemMark>[
      for (final dynamic raw in rawMarks)
        if (raw is Map<String, dynamic>)
          ItemMark.fromExport(raw, itemId: collectionItemId),
    ];
    await _database.itemMarkDao.insertMarks(marks);
  }

  /// Restores watch marks under `_watched_episodes`, re-scoped to the target
  /// collection; already-marked rows stay (insert is conflict-ignoring).
  Future<void> _importWatchedEpisodes(
    Map<String, dynamic> itemData,
    int collectionId,
    CollectionItem parsed,
  ) async {
    if (!parsed.usesEpisodeTracker) return;
    final List<dynamic>? raw =
        itemData['_watched_episodes'] as List<dynamic>?;
    if (raw == null || raw.isEmpty) return;
    for (final dynamic entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      final Object? season = entry['season'];
      final Object? episode = entry['episode'];
      if (season is! int || episode is! int) continue;
      final Object? watchedAtSec = entry['watched_at'];
      await _database.tvShowDao.markEpisodeWatchedAt(
        collectionId,
        parsed.dataSource,
        parsed.externalId,
        season,
        episode,
        watchedAtSec is int ? watchedAtSec * 1000 : null,
      );
    }
  }

  /// [itemIdMapping]: item keys (see [_itemMappingKeys]) -> collection_item_id.
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

        final int? newItemId = _resolveMappedItem(
          itemIdMapping,
          mediaType: mediaType,
          externalId: externalId,
          platformId: platformId,
          source: entryData['source'] as String?,
        );
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

  /// Restores tags globally: names resolve case-insensitively, missing ones
  /// are created. Accepts `tag_names` arrays and the legacy `tag_name` string.
  Future<void> _importTags(
    List<Map<String, dynamic>> tagsData,
    List<Map<String, dynamic>> exportedItems,
    Map<String, int> itemIdMapping,
  ) async {
    final Map<String, int> tagNameToId =
        await _database.globalTagDao.resolveOrCreateAll(<TagSeed>[
      for (final Map<String, dynamic> tagData in tagsData)
        (
          name: tagData['name'] as String? ?? 'Imported Tag',
          color: tagData['color'] as int?,
          textColor: tagData['text_color'] as int?,
        ),
    ]);

    final List<Tag> allTags = await _database.globalTagDao.getAll();

    for (final Map<String, dynamic> itemData in exportedItems) {
      final List<String> tagNames = switch (itemData['tag_names']) {
        final List<dynamic> names => names.cast<String>(),
        _ => <String>[
            if (itemData['tag_name'] is String)
              itemData['tag_name'] as String,
          ],
      };
      if (tagNames.isEmpty) continue;

      // tag_names comes in the item's display order; keep it.
      final Set<int> tagIds = <int>{
        for (final String name in tagNames)
          if (tagNameToId[GlobalTagDao.nameKey(name)] case final int id) id,
      };
      if (tagIds.isEmpty) continue;
      final List<int> orderedIds = tagIds.toList();

      final String? mediaType = itemData['media_type'] as String?;
      final int? externalId = itemData['external_id'] as int?;
      final int? platformId = itemData['platform_id'] as int?;
      if (mediaType == null || externalId == null) continue;

      final int? itemId = _resolveMappedItem(
        itemIdMapping,
        mediaType: mediaType,
        externalId: externalId,
        platformId: platformId,
        source: itemData['source'] as String?,
      );
      if (itemId == null) continue;

      // Imported items are freshly created, so a replace-set write is safe
      // and avoids one INSERT round-trip per link.
      await _database.globalTagDao.setItemTags(itemId, tagIds);

      // Explicit positions only when the exported order differs from the
      // global fallback — otherwise the item keeps following the global sort.
      final List<int> globalOrder = <int>[
        for (final Tag tag in allTags)
          if (tagIds.contains(tag.id)) tag.id,
      ];
      if (!listEquals(orderedIds, globalOrder)) {
        await _database.globalTagDao
            .setItemTagPositions(itemId, orderedIds);
      }
    }
  }

  /// Keys an item is filed under for tier-list/tag lookup: `exact` qualifies
  /// by provider (ids collide across providers), `shared` serves legacy exports.
  static ({List<String> exact, List<String> shared}) _itemMappingKeys({
    required String mediaType,
    required int externalId,
    int? platformId,
    String? source,
  }) {
    final String withPlatform = '$mediaType:$externalId:$platformId';
    final String bare = '$mediaType:$externalId';
    return (
      exact: source == null
          ? const <String>[]
          : <String>['$withPlatform@$source', '$bare@$source'],
      shared: <String>[withPlatform, bare],
    );
  }

  static void _registerItemMapping(
    Map<String, int> mapping,
    CollectionItem item,
    int itemId,
  ) {
    final ({List<String> exact, List<String> shared}) keys = _itemMappingKeys(
      mediaType: item.mediaType.value,
      externalId: item.externalId,
      platformId: item.platformId,
      source: item.source?.name,
    );
    for (final String key in keys.exact) {
      mapping[key] = itemId;
    }
    // A shared key can name several items (same id from two providers, an
    // animation held as both a movie and a show) — the first one wins.
    for (final String key in keys.shared) {
      mapping.putIfAbsent(key, () => itemId);
    }
  }

  static int? _resolveMappedItem(
    Map<String, int> mapping, {
    required String mediaType,
    required int externalId,
    int? platformId,
    String? source,
  }) {
    final ({List<String> exact, List<String> shared}) keys = _itemMappingKeys(
      mediaType: mediaType,
      externalId: externalId,
      platformId: platformId,
      source: source,
    );
    for (final String key in <String>[...keys.exact, ...keys.shared]) {
      if (mapping[key] case final int id) return id;
    }
    return null;
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

/// One item's media reference from an export file; [nativeId] is the
/// provider's own string id for APIs unreachable via the numeric [externalId].
class _MediaRef {
  const _MediaRef({
    required this.externalId,
    required this.source,
    this.nativeId,
  });

  final int externalId;
  final DataSource source;
  final String? nativeId;
}
