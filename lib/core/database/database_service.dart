import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../shared/models/collected_item_info.dart';
import '../../shared/models/profile.dart';
import '../services/profile_service.dart';
import '../../shared/models/collection.dart';
import '../../shared/models/collection_item.dart';
import '../../shared/models/cover_info.dart';
import '../../shared/models/data_source.dart';
import '../../shared/models/game.dart';
import '../../shared/models/item_status.dart';
import '../../shared/models/media_type.dart';
import '../../shared/models/movie.dart';
import '../../shared/models/platform.dart';
import '../../shared/models/tv_episode.dart';
import '../../shared/models/tv_season.dart';
import '../../shared/models/tv_show.dart';
import '../../shared/models/anime.dart';
import '../../shared/models/manga.dart';
import '../../shared/models/visual_novel.dart';
import '../../shared/models/wishlist_item.dart';
import '../../shared/models/wishlist_tag.dart';
import 'dao/anilist_tag_dao.dart';
import 'dao/canvas_dao.dart';
import 'dao/collection_dao.dart';
import 'dao/custom_media_dao.dart';
import 'dao/anime_dao.dart';
import 'dao/game_dao.dart';
import 'dao/movie_dao.dart';
import 'dao/tag_dao.dart';
import 'dao/tv_show_dao.dart';
import 'dao/manga_dao.dart';
import 'dao/mangabaka_genre_dao.dart';
import 'dao/mangabaka_tag_dao.dart';
import 'dao/visual_novel_dao.dart';
import 'dao/mood_grid_dao.dart';
import 'dao/tier_list_dao.dart';
import 'dao/tracked_release_dao.dart';
import 'dao/tracker_dao.dart';
import 'dao/wishlist_dao.dart';
import 'migrations/migration.dart';
import 'migrations/migration_registry.dart';
import 'migrations/migration_v24.dart';
import 'migrations/migration_v44.dart';
import 'schema.dart';

final Provider<DatabaseService> databaseServiceProvider =
    Provider<DatabaseService>((Ref ref) {
  return DatabaseService();
});

final Provider<GameDao> gameDaoProvider = Provider<GameDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).gameDao;
});

final Provider<MovieDao> movieDaoProvider = Provider<MovieDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).movieDao;
});

final Provider<TvShowDao> tvShowDaoProvider = Provider<TvShowDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).tvShowDao;
});

final Provider<VisualNovelDao> visualNovelDaoProvider =
    Provider<VisualNovelDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).visualNovelDao;
});

final Provider<MangaDao> mangaDaoProvider = Provider<MangaDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).mangaDao;
});

final Provider<AnimeDao> animeDaoProvider = Provider<AnimeDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).animeDao;
});

final Provider<CollectionDao> collectionDaoProvider =
    Provider<CollectionDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).collectionDao;
});

final Provider<CanvasDao> canvasDaoProvider = Provider<CanvasDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).canvasDao;
});

final Provider<TrackerDao> trackerDaoProvider =
    Provider<TrackerDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).trackerDao;
});

final Provider<TierListDao> tierListDaoProvider =
    Provider<TierListDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).tierListDao;
});

final Provider<MoodGridDao> moodGridDaoProvider =
    Provider<MoodGridDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).moodGridDao;
});

final Provider<WishlistDao> wishlistDaoProvider =
    Provider<WishlistDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).wishlistDao;
});

final Provider<CustomMediaDao> customMediaDaoProvider =
    Provider<CustomMediaDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).customMediaDao;
});

final Provider<TagDao> tagDaoProvider = Provider<TagDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).tagDao;
});

final Provider<AniListTagDao> aniListTagDaoProvider =
    Provider<AniListTagDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).aniListTagDao;
});

final Provider<MangaBakaGenreDao> mangaBakaGenreDaoProvider =
    Provider<MangaBakaGenreDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).mangaBakaGenreDao;
});

final Provider<MangaBakaTagDao> mangaBakaTagDaoProvider =
    Provider<MangaBakaTagDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).mangaBakaTagDao;
});

final Provider<TrackedReleaseDao> trackedReleaseDaoProvider =
    Provider<TrackedReleaseDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).trackedReleaseDao;
});

class DatabaseService {
  static final Logger _log = Logger('DatabaseService');

  Database? _database;
  Future<Database>? _opening;

  /// Single-flight: concurrent first-touch callers share one [_initDatabase]
  /// future so non-idempotent migrations (e.g. `ALTER TABLE ADD COLUMN`) can't race.
  Future<Database> get database {
    final Database? cached = _database;
    if (cached != null) return Future<Database>.value(cached);
    return _opening ??= () async {
      try {
        final Database db = await _initDatabase();
        _database = db;
        return db;
      } finally {
        _opening = null;
      }
    }();
  }

  late final GameDao gameDao = GameDao(() => database);

  late final MovieDao movieDao = MovieDao(() => database);

  late final TvShowDao tvShowDao = TvShowDao(() => database);

  late final VisualNovelDao visualNovelDao = VisualNovelDao(() => database);

  late final MangaDao mangaDao = MangaDao(() => database);

  late final AnimeDao animeDao = AnimeDao(() => database);

  late final CustomMediaDao customMediaDao = CustomMediaDao(() => database);

  late final CollectionDao collectionDao = CollectionDao(
    () => database,
    gameDao: gameDao,
    movieDao: movieDao,
    tvShowDao: tvShowDao,
    visualNovelDao: visualNovelDao,
    animeDao: animeDao,
    mangaDao: mangaDao,
    customMediaDao: customMediaDao,
  );

  late final CanvasDao canvasDao = CanvasDao(() => database);

  late final TierListDao tierListDao = TierListDao(() => database);

  late final MoodGridDao moodGridDao = MoodGridDao(() => database);

  late final TrackerDao trackerDao = TrackerDao(() => database);

  late final TagDao tagDao = TagDao(() => database);

  late final AniListTagDao aniListTagDao = AniListTagDao(() => database);

  late final MangaBakaGenreDao mangaBakaGenreDao =
      MangaBakaGenreDao(() => database);

  late final MangaBakaTagDao mangaBakaTagDao = MangaBakaTagDao(() => database);

  late final WishlistDao wishlistDao = WishlistDao(() => database);

  late final TrackedReleaseDao trackedReleaseDao =
      TrackedReleaseDao(() => database);

  Future<Database> _initDatabase() async {
    // AppSupport rather than Documents: Documents may sit under OneDrive,
    // which blocks file creation (PathAccessException).
    final Directory appDir = await getApplicationSupportDirectory();

    // Separate folder in debug to avoid polluting the real collection.
    const String folderName =
        kReleaseMode ? 'tonkatsu_box' : 'tonkatsu_box_dev';

    // If profile system is initialised, use the per-profile path.
    final String basePath = p.join(appDir.path, folderName);
    final String dbDir;
    final File profilesFile = File(p.join(basePath, 'profiles.json'));
    if (profilesFile.existsSync()) {
      final ProfileService profileService = ProfileService();
      final ProfilesData data = await profileService.loadProfiles();
      dbDir = p.join(
        basePath,
        'profiles',
        data.currentProfileId,
      );
    } else {
      dbDir = basePath;
    }

    final String dbPath = p.join(dbDir, 'tonkatsu_box.db');

    final Directory dir = Directory(dbDir);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    _log.info(
      'Database path: $dbPath (${kReleaseMode ? 'release' : 'debug'} mode)',
    );

    return databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 45,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: (Database db) async {
          await db.execute('PRAGMA foreign_keys = ON');
          // WAL + NORMAL: SQLite-recommended durable-but-fast combo;
          // commits batch into one fsync per checkpoint instead of
          // one per write. `journal_mode` returns the resulting mode,
          // so Android's SQLiteDatabase rejects it via `execute()` —
          // use `rawQuery` cross-platform.
          await db.rawQuery('PRAGMA journal_mode = WAL');
          await db.execute('PRAGMA synchronous = NORMAL');
        },
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    _log.info('Creating database schema v$version');
    await DatabaseSchema.createAll(db);
    // Seed static reference tables (genres, tags, platforms): migrations don't
    // run on fresh install, so invoke the seed migration explicitly.
    await MigrationV24().migrate(db);
    await MigrationV44.seedGenres(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _log.info('Upgrading database from v$oldVersion to v$newVersion');
    for (final Migration migration in MigrationRegistry.pending(oldVersion)) {
      _log.fine('Running migration v${migration.version}: ${migration.description}');
      await migration.migrate(db);
    }
    _log.info('Database upgrade complete');
  }

  Future<List<Map<String, dynamic>>> getIgdbGenres() => gameDao.getIgdbGenres();

  Future<List<Platform>> getAllPlatforms() => gameDao.getAllPlatforms();

  Future<Platform?> getPlatformById(int id) => gameDao.getPlatformById(id);

  Future<int> getPlatformCount() => gameDao.getPlatformCount();

  Future<void> upsertPlatform(Platform platform) =>
      gameDao.upsertPlatform(platform);

  Future<void> upsertPlatforms(List<Platform> platforms) =>
      gameDao.upsertPlatforms(platforms);

  Future<List<Platform>> getPlatformsByIds(List<int> ids) =>
      gameDao.getPlatformsByIds(ids);

  Future<Game?> getGameById(int id) => gameDao.getGameById(id);

  Future<List<Game>> getGamesByIds(List<int> ids) => gameDao.getGamesByIds(ids);

  Future<List<Game>> searchGamesInCache(String query, {int limit = 20}) =>
      gameDao.searchGamesInCache(query, limit: limit);

  Future<int> getGameCount() => gameDao.getGameCount();

  Future<void> upsertGame(Game game) => gameDao.upsertGame(game);

  Future<void> upsertGames(List<Game> games) => gameDao.upsertGames(games);

  Future<void> deleteGame(int id) => gameDao.deleteGame(id);

  Future<void> clearGames() => gameDao.clearGames();


  Future<Movie?> getMovieByTmdbId(int tmdbId) =>
      movieDao.getMovieByTmdbId(tmdbId);

  Future<void> upsertMovie(Movie movie) => movieDao.upsertMovie(movie);

  Future<void> upsertMovies(List<Movie> movies) =>
      movieDao.upsertMovies(movies);

  Future<List<Movie>> getMoviesByTmdbIds(List<int> tmdbIds) =>
      movieDao.getMoviesByTmdbIds(tmdbIds);

  Future<void> clearMovies() => movieDao.clearMovies();


  Future<TvShow?> getTvShowByTmdbId(int tmdbId) =>
      tvShowDao.getTvShowByTmdbId(tmdbId);

  Future<void> upsertTvShow(TvShow tvShow) => tvShowDao.upsertTvShow(tvShow);

  Future<void> upsertTvShows(List<TvShow> tvShows) =>
      tvShowDao.upsertTvShows(tvShows);

  Future<Map<String, String>> getTmdbGenreMap(
    String type, {
    String lang = 'en',
  }) =>
      movieDao.getTmdbGenreMap(type, lang: lang);

  Future<List<TvShow>> getTvShowsByTmdbIds(List<int> tmdbIds) =>
      tvShowDao.getTvShowsByTmdbIds(tmdbIds);

  Future<void> clearTvShows() => tvShowDao.clearTvShows();


  Future<List<TvSeason>> getTvSeasonsByShowId(int tmdbShowId) =>
      tvShowDao.getTvSeasonsByShowId(tmdbShowId);

  Future<void> upsertTvSeasons(List<TvSeason> seasons) =>
      tvShowDao.upsertTvSeasons(seasons);

  Future<void> clearTvSeasons() => tvShowDao.clearTvSeasons();

  Future<List<TvEpisode>> getEpisodesByShowId(int showId) =>
      tvShowDao.getEpisodesByShowId(showId);

  Future<List<TvEpisode>> getEpisodesByShowAndSeason(
    int showId,
    int seasonNumber,
  ) =>
      tvShowDao.getEpisodesByShowAndSeason(showId, seasonNumber);

  Future<void> upsertEpisodes(List<TvEpisode> episodes) =>
      tvShowDao.upsertEpisodes(episodes);

  Future<void> clearEpisodesByShow(int showId) =>
      tvShowDao.clearEpisodesByShow(showId);


  Future<Map<(int, int), DateTime?>> getWatchedEpisodes(
    int collectionId,
    int showId,
  ) =>
      tvShowDao.getWatchedEpisodes(collectionId, showId);

  Future<void> markEpisodeWatched(
    int collectionId,
    int showId,
    int seasonNumber,
    int episodeNumber,
  ) =>
      tvShowDao.markEpisodeWatched(
        collectionId,
        showId,
        seasonNumber,
        episodeNumber,
      );

  Future<void> markEpisodeUnwatched(
    int collectionId,
    int showId,
    int seasonNumber,
    int episodeNumber,
  ) =>
      tvShowDao.markEpisodeUnwatched(
        collectionId,
        showId,
        seasonNumber,
        episodeNumber,
      );

  Future<int> getWatchedEpisodeCount(
    int collectionId,
    int showId,
  ) =>
      tvShowDao.getWatchedEpisodeCount(collectionId, showId);

  Future<void> markSeasonWatched(
    int collectionId,
    int showId,
    int seasonNumber,
    List<int> episodeNumbers,
  ) =>
      tvShowDao.markSeasonWatched(
        collectionId,
        showId,
        seasonNumber,
        episodeNumbers,
      );

  Future<void> unmarkSeasonWatched(
    int collectionId,
    int showId,
    int seasonNumber,
  ) =>
      tvShowDao.unmarkSeasonWatched(collectionId, showId, seasonNumber);

  Future<List<Collection>> getAllCollections() =>
      collectionDao.getAllCollections();

  Future<List<Collection>> getCollectionsByType(CollectionType type) =>
      collectionDao.getCollectionsByType(type);

  Future<Collection?> getCollectionById(int id) =>
      collectionDao.getCollectionById(id);

  Future<List<CollectionItem>> findAllCollectionItems({
    required MediaType mediaType,
    required int externalId,
  }) =>
      collectionDao.findAllCollectionItems(
        mediaType: mediaType,
        externalId: externalId,
      );

  Future<Collection?> findCollectionByName(String name) =>
      collectionDao.findCollectionByName(name);

  Future<Collection> createCollection({
    required String name,
    required String author,
    CollectionType type = CollectionType.own,
    String? originalSnapshot,
    String? forkedFromAuthor,
    String? forkedFromName,
  }) =>
      collectionDao.createCollection(
        name: name,
        author: author,
        type: type,
        originalSnapshot: originalSnapshot,
        forkedFromAuthor: forkedFromAuthor,
        forkedFromName: forkedFromName,
      );

  Future<void> updateCollection(
    int id, {
    String? name,
    String? heroImagePath,
    String? description,
    bool clearHeroImage = false,
    bool clearDescription = false,
  }) =>
      collectionDao.updateCollection(
        id,
        name: name,
        heroImagePath: heroImagePath,
        description: description,
        clearHeroImage: clearHeroImage,
        clearDescription: clearDescription,
      );

  /// Cascades to related items via FK.
  Future<void> deleteCollection(int id) => collectionDao.deleteCollection(id);

  Future<int> getCollectionCount() => collectionDao.getCollectionCount();

  Future<List<CollectionItem>> getCollectionItems(
    int? collectionId, {
    MediaType? mediaType,
  }) =>
      collectionDao.getCollectionItems(collectionId, mediaType: mediaType);

  Future<List<CollectionItem>> getCollectionItemsWithData(
    int? collectionId, {
    MediaType? mediaType,
  }) =>
      collectionDao.getCollectionItemsWithData(
        collectionId,
        mediaType: mediaType,
      );

  Future<List<CollectionItem>> getAllCollectionItems({
    MediaType? mediaType,
  }) =>
      collectionDao.getAllCollectionItems(mediaType: mediaType);

  Future<List<CollectionItem>> getAllCollectionItemsWithData({
    MediaType? mediaType,
  }) =>
      collectionDao.getAllCollectionItemsWithData(mediaType: mediaType);

  Future<CollectionItem?> getCollectionItemById(int id) =>
      collectionDao.getCollectionItemById(id);

  Future<CollectionItem?> findCollectionItem({
    required int? collectionId,
    required MediaType mediaType,
    required int externalId,
    int? platformId,
  }) =>
      collectionDao.findCollectionItem(
        collectionId: collectionId,
        mediaType: mediaType,
        externalId: externalId,
        platformId: platformId,
      );

  Future<int?> addItemToCollection({
    required int? collectionId,
    required MediaType mediaType,
    required int externalId,
    int? platformId,
    DataSource? source,
    String? authorComment,
    ItemStatus status = ItemStatus.notStarted,
  }) =>
      collectionDao.addItemToCollection(
        collectionId: collectionId,
        mediaType: mediaType,
        externalId: externalId,
        platformId: platformId,
        source: source,
        authorComment: authorComment,
        status: status,
      );

  Future<int> getNextSortOrder(int? collectionId) =>
      collectionDao.getNextSortOrder(collectionId);

  Future<void> reorderItems(
    int? collectionId,
    List<int> orderedItemIds,
  ) =>
      collectionDao.reorderItems(collectionId, orderedItemIds);

  Future<void> removeItemFromCollection(int id) =>
      collectionDao.removeItemFromCollection(id);

  Future<void> updateItemStatus(
    int id,
    ItemStatus status, {
    required MediaType mediaType,
  }) =>
      collectionDao.updateItemStatus(id, status, mediaType: mediaType);

  Future<void> updateItemActivityDates(
    int id, {
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? lastActivityAt,
  }) =>
      collectionDao.updateItemActivityDates(
        id,
        startedAt: startedAt,
        completedAt: completedAt,
        lastActivityAt: lastActivityAt,
      );

  Future<List<({int id, int? collectionId, int? platformId})>>
      getItemIdsByExternalId(
    int externalId,
    String mediaType, {
    int? platformId,
    bool filterByPlatform = false,
  }) async {
    final Database db = await database;
    final List<String> conditions = <String>[
      'external_id = ?',
      'media_type = ?',
    ];
    final List<Object?> args = <Object?>[externalId, mediaType];
    if (filterByPlatform) {
      if (platformId == null) {
        conditions.add('platform_id IS NULL');
      } else {
        conditions.add('platform_id = ?');
        args.add(platformId);
      }
    }
    final List<Map<String, dynamic>> rows = await db.query(
      'collection_items',
      columns: <String>['id', 'collection_id', 'platform_id'],
      where: conditions.join(' AND '),
      whereArgs: args,
    );
    return rows
        .map((Map<String, dynamic> r) => (
              id: r['id'] as int,
              collectionId: r['collection_id'] as int?,
              platformId: r['platform_id'] as int?,
            ))
        .toList();
  }

  Future<void> updateItemProgress(
    int id, {
    int? currentSeason,
    int? currentEpisode,
  }) =>
      collectionDao.updateItemProgress(
        id,
        currentSeason: currentSeason,
        currentEpisode: currentEpisode,
      );

  Future<void> updateItemAuthorComment(int id, String? comment) =>
      collectionDao.updateItemAuthorComment(id, comment);

  Future<void> updateItemUserComment(int id, String? comment) =>
      collectionDao.updateItemUserComment(id, comment);

  /// Rating range: 1.0-10.0 (step 0.1) or null.
  Future<void> updateItemUserRating(int id, double? rating) =>
      collectionDao.updateItemUserRating(id, rating);

  /// Empty / whitespace-only `name` clears the override (NULL).
  Future<void> setItemOverrideName(int id, String? name) =>
      collectionDao.setItemOverrideName(id, name);

  /// `totalMinutes` is stored in minutes.
  Future<void> updateItemTimeSpent(int id, int totalMinutes) =>
      collectionDao.updateItemTimeSpent(id, totalMinutes);

  Future<bool> updateItemCollectionId(int id, int? collectionId) =>
      collectionDao.updateItemCollectionId(id, collectionId);

  Future<int?> cloneItemToCollection(int itemId, int targetCollectionId) =>
      collectionDao.cloneItemToCollection(itemId, targetCollectionId);

  Future<List<int>> getUniquePlatformIds({int? collectionId}) =>
      collectionDao.getUniquePlatformIds(collectionId: collectionId);

  Future<int> getTotalItemCount() => collectionDao.getTotalItemCount();

  Future<int> getCollectionItemCount(
    int? collectionId, {
    MediaType? mediaType,
  }) =>
      collectionDao.getCollectionItemCount(collectionId, mediaType: mediaType);

  Future<Map<String, int>> getCollectionItemStats(int? collectionId) =>
      collectionDao.getCollectionItemStats(collectionId);

  Future<void> clearCollectionItems(int? collectionId) =>
      collectionDao.clearCollectionItems(collectionId);

  Future<List<Map<String, dynamic>>> getCanvasItems(int collectionId) =>
      canvasDao.getCanvasItems(collectionId);

  Future<int> insertCanvasItem(Map<String, dynamic> data) =>
      canvasDao.insertCanvasItem(data);

  Future<void> updateCanvasItem(int id, Map<String, dynamic> data) =>
      canvasDao.updateCanvasItem(id, data);

  Future<void> deleteCanvasItem(int id) => canvasDao.deleteCanvasItem(id);

  Future<void> deleteCanvasItemByRef(
    int collectionId,
    String itemType,
    int itemRefId,
  ) =>
      canvasDao.deleteCanvasItemByRef(collectionId, itemType, itemRefId);

  Future<void> deleteCanvasItemByCollectionItemId(
    int collectionId,
    int collectionItemId,
  ) =>
      canvasDao.deleteCanvasItemByCollectionItemId(
        collectionId,
        collectionItemId,
      );

  /// Excludes per-item canvas items.
  Future<void> deleteCanvasItemsByCollection(int collectionId) =>
      canvasDao.deleteCanvasItemsByCollection(collectionId);

  Future<List<int>> insertCanvasItemsBatch(
    List<Map<String, dynamic>> items,
  ) =>
      canvasDao.insertCanvasItemsBatch(items);

  Future<void> deleteCanvasItemsBatch(List<int> ids) =>
      canvasDao.deleteCanvasItemsBatch(ids);

  Future<int> getCanvasItemCount(int collectionId) =>
      canvasDao.getCanvasItemCount(collectionId);

  Future<Map<String, dynamic>?> getCanvasViewport(int collectionId) =>
      canvasDao.getCanvasViewport(collectionId);

  Future<void> upsertCanvasViewport({
    required int collectionId,
    required double scale,
    required double offsetX,
    required double offsetY,
  }) =>
      canvasDao.upsertCanvasViewport(
        collectionId: collectionId,
        scale: scale,
        offsetX: offsetX,
        offsetY: offsetY,
      );

  /// Excludes per-item canvas connections.
  Future<List<Map<String, dynamic>>> getCanvasConnections(
    int collectionId,
  ) =>
      canvasDao.getCanvasConnections(collectionId);

  Future<int> insertCanvasConnection(Map<String, dynamic> data) =>
      canvasDao.insertCanvasConnection(data);

  Future<void> updateCanvasConnection(
    int id,
    Map<String, dynamic> data,
  ) =>
      canvasDao.updateCanvasConnection(id, data);

  Future<void> deleteCanvasConnection(int id) =>
      canvasDao.deleteCanvasConnection(id);

  /// Excludes per-item canvas connections.
  Future<void> deleteCanvasConnectionsByCollection(int collectionId) =>
      canvasDao.deleteCanvasConnectionsByCollection(collectionId);

  Future<List<Map<String, dynamic>>> getGameCanvasItems(
    int collectionItemId,
  ) =>
      canvasDao.getGameCanvasItems(collectionItemId);

  Future<int> getGameCanvasItemCount(int collectionItemId) =>
      canvasDao.getGameCanvasItemCount(collectionItemId);

  Future<List<Map<String, dynamic>>> getGameCanvasConnections(
    int collectionItemId,
  ) =>
      canvasDao.getGameCanvasConnections(collectionItemId);

  Future<Map<String, dynamic>?> getGameCanvasViewport(
    int collectionItemId,
  ) =>
      canvasDao.getGameCanvasViewport(collectionItemId);

  Future<void> upsertGameCanvasViewport({
    required int collectionItemId,
    required double scale,
    required double offsetX,
    required double offsetY,
  }) =>
      canvasDao.upsertGameCanvasViewport(
        collectionItemId: collectionItemId,
        scale: scale,
        offsetX: offsetX,
        offsetY: offsetY,
      );

  Future<void> deleteGameCanvasItems(int collectionItemId) =>
      canvasDao.deleteGameCanvasItems(collectionItemId);

  Future<void> deleteGameCanvasConnections(int collectionItemId) =>
      canvasDao.deleteGameCanvasConnections(collectionItemId);

  Future<void> deleteGameCanvasViewport(int collectionItemId) =>
      canvasDao.deleteGameCanvasViewport(collectionItemId);

  Future<Map<int, List<CollectedItemInfo>>> getCollectedItemInfos(
    MediaType mediaType,
  ) =>
      collectionDao.getCollectedItemInfos(mediaType);

  Future<int> getUncategorizedItemCount() =>
      collectionDao.getUncategorizedItemCount();

  Future<WishlistItem> addWishlistItem({
    required String text,
    MediaType? mediaTypeHint,
    String? note,
    String? tag,
  }) =>
      wishlistDao.addWishlistItem(
        text: text,
        mediaTypeHint: mediaTypeHint,
        note: note,
        tag: tag,
      );

  Future<List<WishlistItem>> getWishlistItems({
    bool includeResolved = true,
    WishlistTagFilter tagFilter = const WishlistTagFilter.all(),
  }) =>
      wishlistDao.getWishlistItemsFiltered(
        includeResolved: includeResolved,
        tagFilter: tagFilter,
      );

  Future<int> getWishlistItemCount({bool onlyActive = true}) =>
      wishlistDao.getWishlistItemCount(onlyActive: onlyActive);

  Future<void> updateWishlistItem(
    int id, {
    String? text,
    MediaType? mediaTypeHint,
    bool clearMediaTypeHint = false,
    String? note,
    bool clearNote = false,
    String? tag,
    bool clearTag = false,
  }) =>
      wishlistDao.updateWishlistItem(
        id,
        text: text,
        mediaTypeHint: mediaTypeHint,
        clearMediaTypeHint: clearMediaTypeHint,
        note: note,
        clearNote: clearNote,
        tag: tag,
        clearTag: clearTag,
      );

  Future<void> resolveWishlistItem(int id) =>
      wishlistDao.resolveWishlistItem(id);

  Future<void> unresolveWishlistItem(int id) =>
      wishlistDao.unresolveWishlistItem(id);

  Future<void> deleteWishlistItem(int id) =>
      wishlistDao.deleteWishlistItem(id);

  Future<WishlistItem?> findUnresolvedWishlistItem(String text) =>
      wishlistDao.findUnresolvedByText(text);

  Future<int> clearResolvedWishlistItems() =>
      wishlistDao.clearResolvedWishlistItems();

  Future<int> deleteWishlistItemsByTag(String? tag) =>
      wishlistDao.deleteWishlistItemsByTag(tag);

  Future<int> renameWishlistTag(String? from, String to) =>
      wishlistDao.renameWishlistTag(from, to);

  /// Truncates every user table in a single transaction. FK-dependent tables
  /// are deleted before their parents. Static reference tables (platforms,
  /// tmdb_genres, igdb_genres, vndb_tags) are preserved — they're seeded by
  /// MigrationV24 and are not user data. SharedPreferences is untouched.
  Future<void> clearAllData() async {
    final Database db = await database;
    await db.transaction((Transaction txn) async {
      await txn.delete('mood_grid_cells');
      await txn.delete('mood_grids');
      await txn.delete('tier_list_entries');
      await txn.delete('tier_definitions');
      await txn.delete('tier_lists');
      await txn.delete('collection_tags');
      await txn.delete('tracker_achievements');
      await txn.delete('tracker_game_data');
      await txn.delete('tracker_profiles');
      await txn.delete('watched_episodes');
      await txn.delete('canvas_connections');
      await txn.delete('canvas_items');
      await txn.delete('canvas_viewport');
      await txn.delete('game_canvas_viewport');
      await txn.delete('custom_items');
      await txn.delete('collection_items');
      await txn.delete('collections');
      await txn.delete('tv_episodes_cache');
      await txn.delete('tv_seasons_cache');
      await txn.delete('tv_shows_cache');
      await txn.delete('movies_cache');
      await txn.delete('games');
      await txn.delete('visual_novels_cache');
      await txn.delete('manga_cache');
      await txn.delete('anime_cache');
      await txn.delete('wishlist');
    });
  }

  Future<void> upsertVisualNovel(VisualNovel vn) =>
      visualNovelDao.upsertVisualNovel(vn);

  Future<void> upsertVisualNovels(List<VisualNovel> vns) =>
      visualNovelDao.upsertVisualNovels(vns);

  Future<VisualNovel?> getVisualNovel(int numericId) =>
      visualNovelDao.getVisualNovel(numericId);

  Future<List<VisualNovel>> getVisualNovelsByNumericIds(
    List<int> numericIds,
  ) =>
      visualNovelDao.getVisualNovelsByNumericIds(numericIds);

  Future<List<VndbTag>> getVndbTags() => visualNovelDao.getVndbTags();

  Future<void> upsertManga(Manga manga) => mangaDao.upsertManga(manga);

  Future<void> upsertMangas(List<Manga> mangas) =>
      mangaDao.upsertMangas(mangas);

  Future<Manga?> getManga(int id, {DataSource source = DataSource.anilist}) =>
      mangaDao.getManga(id, source: source);

  Future<List<Manga>> getMangaByIds(List<int> ids) =>
      mangaDao.getMangaByIds(ids);

  Future<void> upsertAnime(Anime anime) => animeDao.upsertAnime(anime);

  Future<void> upsertAnimes(List<Anime> animes) =>
      animeDao.upsertAnimes(animes);

  Future<Anime?> getAnime(int id) => animeDao.getAnime(id);

  Future<List<Anime>> getAnimeByIds(List<int> ids) =>
      animeDao.getAnimeByIds(ids);

  Future<List<CoverInfo>> getCollectionCovers(
    int? collectionId, {
    int limit = 4,
  }) =>
      collectionDao.getCollectionCovers(collectionId, limit: limit);

  Future<void> close() async {
    final Database? db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
