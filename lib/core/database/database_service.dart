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
import 'dao/canvas_dao.dart';
import 'dao/collection_dao.dart';
import 'dao/custom_media_dao.dart';
import 'dao/anime_dao.dart';
import 'dao/game_dao.dart';
import 'dao/movie_dao.dart';
import 'dao/tag_dao.dart';
import 'dao/tv_show_dao.dart';
import 'dao/manga_dao.dart';
import 'dao/visual_novel_dao.dart';
import 'dao/tier_list_dao.dart';
import 'dao/tracker_dao.dart';
import 'dao/wishlist_dao.dart';
import 'migrations/migration.dart';
import 'migrations/migration_registry.dart';
import 'migrations/migration_v24.dart';
import 'schema.dart';

/// Провайдер для доступа к сервису базы данных.
final Provider<DatabaseService> databaseServiceProvider =
    Provider<DatabaseService>((Ref ref) {
  return DatabaseService();
});

/// Провайдер для [GameDao].
final Provider<GameDao> gameDaoProvider = Provider<GameDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).gameDao;
});

/// Провайдер для [MovieDao].
final Provider<MovieDao> movieDaoProvider = Provider<MovieDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).movieDao;
});

/// Провайдер для [TvShowDao].
final Provider<TvShowDao> tvShowDaoProvider = Provider<TvShowDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).tvShowDao;
});

/// Провайдер для [VisualNovelDao].
final Provider<VisualNovelDao> visualNovelDaoProvider =
    Provider<VisualNovelDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).visualNovelDao;
});

/// Провайдер для [MangaDao].
final Provider<MangaDao> mangaDaoProvider = Provider<MangaDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).mangaDao;
});

/// Провайдер для [AnimeDao].
final Provider<AnimeDao> animeDaoProvider = Provider<AnimeDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).animeDao;
});

/// Провайдер для [CollectionDao].
final Provider<CollectionDao> collectionDaoProvider =
    Provider<CollectionDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).collectionDao;
});

/// Провайдер для [CanvasDao].
final Provider<CanvasDao> canvasDaoProvider = Provider<CanvasDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).canvasDao;
});

/// Провайдер для [TrackerDao].
final Provider<TrackerDao> trackerDaoProvider =
    Provider<TrackerDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).trackerDao;
});

/// Провайдер для [TierListDao].
final Provider<TierListDao> tierListDaoProvider =
    Provider<TierListDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).tierListDao;
});

/// Провайдер для [WishlistDao].
final Provider<WishlistDao> wishlistDaoProvider =
    Provider<WishlistDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).wishlistDao;
});

/// Провайдер для [CustomMediaDao].
final Provider<CustomMediaDao> customMediaDaoProvider =
    Provider<CustomMediaDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).customMediaDao;
});

/// Провайдер для [TagDao].
final Provider<TagDao> tagDaoProvider = Provider<TagDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).tagDao;
});

/// Сервис для работы с SQLite базой данных.
///
/// Управляет инициализацией базы данных и CRUD операциями для платформ.
class DatabaseService {
  static final Logger _log = Logger('DatabaseService');

  Database? _database;

  /// Возвращает экземпляр базы данных, инициализируя при необходимости.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // ==================== DAO ====================

  /// DAO для работы с играми, платформами и IGDB-жанрами.
  late final GameDao gameDao = GameDao(() => database);

  /// DAO для работы с фильмами и TMDB-жанрами.
  late final MovieDao movieDao = MovieDao(() => database);

  /// DAO для работы с сериалами, сезонами и эпизодами.
  late final TvShowDao tvShowDao = TvShowDao(() => database);

  /// DAO для работы с визуальными новеллами.
  late final VisualNovelDao visualNovelDao = VisualNovelDao(() => database);

  /// DAO для работы с мангой.
  late final MangaDao mangaDao = MangaDao(() => database);

  /// DAO для работы с аниме.
  late final AnimeDao animeDao = AnimeDao(() => database);

  /// DAO для работы с кастомными элементами.
  late final CustomMediaDao customMediaDao = CustomMediaDao(() => database);

  /// DAO для работы с коллекциями и элементами коллекций.
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

  /// DAO для работы с канвасом.
  late final CanvasDao canvasDao = CanvasDao(() => database);

  /// DAO для работы с тир-листами.
  late final TierListDao tierListDao = TierListDao(() => database);

  /// DAO для работы с трекерами (RA, Steam, Trakt).
  late final TrackerDao trackerDao = TrackerDao(() => database);

  /// DAO для работы с тегами коллекций.
  late final TagDao tagDao = TagDao(() => database);

  /// DAO для работы с вишлистом.
  late final WishlistDao wishlistDao = WishlistDao(() => database);

  // ==================== Init ====================

  Future<Database> _initDatabase() async {
    // AppSupport вместо Documents — Documents может быть под OneDrive,
    // который блокирует создание файлов (PathAccessException).
    final Directory appDir = await getApplicationSupportDirectory();

    // Debug → отдельная папка, чтобы не засорять основную коллекцию
    const String folderName =
        kReleaseMode ? 'tonkatsu_box' : 'tonkatsu_box_dev';

    // Если профильная система инициализирована — используем путь профиля
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

    // Создаём директорию, если не существует
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
        version: 33,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: (Database db) async {
          // Включаем foreign keys
          await db.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    _log.info('Creating database schema v$version');
    await DatabaseSchema.createAll(db);
    // Seed статических справочников (жанры, теги, платформы).
    // При fresh install миграции не запускаются, поэтому seed вызываем явно.
    await MigrationV24().migrate(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _log.info('Upgrading database from v$oldVersion to v$newVersion');
    for (final Migration migration in MigrationRegistry.pending(oldVersion)) {
      _log.fine('Running migration v${migration.version}: ${migration.description}');
      await migration.migrate(db);
    }
    _log.info('Database upgrade complete');
  }

  // ==================== IGDB Genres (delegates to GameDao) ====================

  /// Возвращает все жанры IGDB из кэша.
  Future<List<Map<String, dynamic>>> getIgdbGenres() => gameDao.getIgdbGenres();

  // ==================== Platforms (delegates to GameDao) ====================

  /// Возвращает все платформы из базы данных.
  Future<List<Platform>> getAllPlatforms() => gameDao.getAllPlatforms();

  /// Возвращает платформу по ID или null, если не найдена.
  Future<Platform?> getPlatformById(int id) => gameDao.getPlatformById(id);

  /// Возвращает количество платформ в базе данных.
  Future<int> getPlatformCount() => gameDao.getPlatformCount();

  /// Сохраняет или обновляет платформу в базе данных.
  Future<void> upsertPlatform(Platform platform) =>
      gameDao.upsertPlatform(platform);

  /// Сохраняет список платформ пакетно.
  Future<void> upsertPlatforms(List<Platform> platforms) =>
      gameDao.upsertPlatforms(platforms);

  /// Возвращает платформы по списку ID.
  Future<List<Platform>> getPlatformsByIds(List<int> ids) =>
      gameDao.getPlatformsByIds(ids);

  // ==================== Games (delegates to GameDao) ====================

  /// Возвращает игру по ID или null, если не найдена.
  Future<Game?> getGameById(int id) => gameDao.getGameById(id);

  /// Возвращает несколько игр по списку ID.
  Future<List<Game>> getGamesByIds(List<int> ids) => gameDao.getGamesByIds(ids);

  /// Ищет игры по названию в кеше.
  Future<List<Game>> searchGamesInCache(String query, {int limit = 20}) =>
      gameDao.searchGamesInCache(query, limit: limit);

  /// Возвращает количество игр в кеше.
  Future<int> getGameCount() => gameDao.getGameCount();

  /// Сохраняет или обновляет игру в базе данных.
  Future<void> upsertGame(Game game) => gameDao.upsertGame(game);

  /// Сохраняет список игр пакетно.
  Future<void> upsertGames(List<Game> games) => gameDao.upsertGames(games);

  /// Удаляет игру по ID.
  Future<void> deleteGame(int id) => gameDao.deleteGame(id);

  /// Удаляет все игры из кеша.
  Future<void> clearGames() => gameDao.clearGames();


  // ==================== Movies Cache (delegates to MovieDao) ====================

  /// Возвращает фильм по TMDB ID или null, если не найден.
  Future<Movie?> getMovieByTmdbId(int tmdbId) =>
      movieDao.getMovieByTmdbId(tmdbId);

  /// Сохраняет или обновляет фильм в кеше.
  Future<void> upsertMovie(Movie movie) => movieDao.upsertMovie(movie);

  /// Сохраняет список фильмов пакетно.
  Future<void> upsertMovies(List<Movie> movies) =>
      movieDao.upsertMovies(movies);

  /// Возвращает несколько фильмов по списку TMDB ID.
  Future<List<Movie>> getMoviesByTmdbIds(List<int> tmdbIds) =>
      movieDao.getMoviesByTmdbIds(tmdbIds);

  /// Удаляет все фильмы из кеша.
  Future<void> clearMovies() => movieDao.clearMovies();


  // ==================== TV Shows (delegates to TvShowDao) ====================

  /// Возвращает сериал по TMDB ID или null, если не найден.
  Future<TvShow?> getTvShowByTmdbId(int tmdbId) =>
      tvShowDao.getTvShowByTmdbId(tmdbId);

  /// Сохраняет или обновляет сериал в кеше.
  Future<void> upsertTvShow(TvShow tvShow) => tvShowDao.upsertTvShow(tvShow);

  /// Сохраняет список сериалов пакетно.
  Future<void> upsertTvShows(List<TvShow> tvShows) =>
      tvShowDao.upsertTvShows(tvShows);

  // ===== TMDB Жанры (delegates to MovieDao) =====

  /// Возвращает маппинг ID → имя жанров из кэша.
  Future<Map<String, String>> getTmdbGenreMap(
    String type, {
    String lang = 'en',
  }) =>
      movieDao.getTmdbGenreMap(type, lang: lang);

  /// Возвращает несколько сериалов по списку TMDB ID.
  Future<List<TvShow>> getTvShowsByTmdbIds(List<int> tmdbIds) =>
      tvShowDao.getTvShowsByTmdbIds(tmdbIds);

  /// Удаляет все сериалы из кеша.
  Future<void> clearTvShows() => tvShowDao.clearTvShows();


  // ==================== TV Seasons (delegates to TvShowDao) ====================

  /// Возвращает сезоны сериала.
  Future<List<TvSeason>> getTvSeasonsByShowId(int tmdbShowId) =>
      tvShowDao.getTvSeasonsByShowId(tmdbShowId);

  /// Сохраняет сезоны сериала пакетно.
  Future<void> upsertTvSeasons(List<TvSeason> seasons) =>
      tvShowDao.upsertTvSeasons(seasons);

  /// Удаляет все сезоны из кеша.
  Future<void> clearTvSeasons() => tvShowDao.clearTvSeasons();

  // ==================== TV Episodes (delegates to TvShowDao) ====================

  /// Возвращает все эпизоды сериала из кеша.
  Future<List<TvEpisode>> getEpisodesByShowId(int showId) =>
      tvShowDao.getEpisodesByShowId(showId);

  /// Возвращает эпизоды сезона сериала из кеша.
  Future<List<TvEpisode>> getEpisodesByShowAndSeason(
    int showId,
    int seasonNumber,
  ) =>
      tvShowDao.getEpisodesByShowAndSeason(showId, seasonNumber);

  /// Сохраняет список эпизодов пакетно (INSERT OR REPLACE).
  Future<void> upsertEpisodes(List<TvEpisode> episodes) =>
      tvShowDao.upsertEpisodes(episodes);

  /// Удаляет кешированные эпизоды сериала.
  Future<void> clearEpisodesByShow(int showId) =>
      tvShowDao.clearEpisodesByShow(showId);


  // ==================== Watched Episodes (delegates to TvShowDao) ====================

  /// Возвращает множество просмотренных эпизодов для сериала в коллекции.
  Future<Map<(int, int), DateTime?>> getWatchedEpisodes(
    int collectionId,
    int showId,
  ) =>
      tvShowDao.getWatchedEpisodes(collectionId, showId);

  /// Отмечает эпизод как просмотренный.
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

  /// Снимает отметку просмотра с эпизода.
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

  /// Возвращает количество просмотренных эпизодов для сериала в коллекции.
  Future<int> getWatchedEpisodeCount(
    int collectionId,
    int showId,
  ) =>
      tvShowDao.getWatchedEpisodeCount(collectionId, showId);

  /// Отмечает все эпизоды сезона как просмотренные.
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

  /// Снимает отметку просмотра со всех эпизодов сезона.
  Future<void> unmarkSeasonWatched(
    int collectionId,
    int showId,
    int seasonNumber,
  ) =>
      tvShowDao.unmarkSeasonWatched(collectionId, showId, seasonNumber);

  // ==================== Collections (delegates to CollectionDao) ====================

  /// Возвращает все коллекции.
  Future<List<Collection>> getAllCollections() =>
      collectionDao.getAllCollections();

  /// Возвращает коллекции по типу.
  Future<List<Collection>> getCollectionsByType(CollectionType type) =>
      collectionDao.getCollectionsByType(type);

  /// Возвращает коллекцию по ID или null, если не найдена.
  Future<Collection?> getCollectionById(int id) =>
      collectionDao.getCollectionById(id);

  /// Ищет ВСЕ элементы по mediaType + externalId во всех коллекциях.
  Future<List<CollectionItem>> findAllCollectionItems({
    required MediaType mediaType,
    required int externalId,
  }) =>
      collectionDao.findAllCollectionItems(
        mediaType: mediaType,
        externalId: externalId,
      );

  /// Ищет коллекцию по точному имени.
  Future<Collection?> findCollectionByName(String name) =>
      collectionDao.findCollectionByName(name);

  /// Создаёт новую коллекцию и возвращает её с присвоенным ID.
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

  /// Обновляет коллекцию.
  Future<void> updateCollection(int id, {String? name}) =>
      collectionDao.updateCollection(id, name: name);

  /// Удаляет коллекцию и все связанные игры (каскадно).
  Future<void> deleteCollection(int id) => collectionDao.deleteCollection(id);

  /// Возвращает количество коллекций.
  Future<int> getCollectionCount() => collectionDao.getCollectionCount();

  // ==================== Collection Items (delegates to CollectionDao) ====================

  /// Возвращает все элементы в коллекции.
  Future<List<CollectionItem>> getCollectionItems(
    int? collectionId, {
    MediaType? mediaType,
  }) =>
      collectionDao.getCollectionItems(collectionId, mediaType: mediaType);

  /// Возвращает элементы коллекции с подгруженными данными.
  Future<List<CollectionItem>> getCollectionItemsWithData(
    int? collectionId, {
    MediaType? mediaType,
  }) =>
      collectionDao.getCollectionItemsWithData(
        collectionId,
        mediaType: mediaType,
      );

  /// Возвращает все элементы из всех коллекций.
  Future<List<CollectionItem>> getAllCollectionItems({
    MediaType? mediaType,
  }) =>
      collectionDao.getAllCollectionItems(mediaType: mediaType);

  /// Возвращает все элементы из всех коллекций с подгруженными данными.
  Future<List<CollectionItem>> getAllCollectionItemsWithData({
    MediaType? mediaType,
  }) =>
      collectionDao.getAllCollectionItemsWithData(mediaType: mediaType);

  /// Возвращает элемент коллекции по ID.
  Future<CollectionItem?> getCollectionItemById(int id) =>
      collectionDao.getCollectionItemById(id);

  /// Находит элемент коллекции по типу медиа и внешнему ID.
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

  /// Добавляет элемент в коллекцию.
  Future<int?> addItemToCollection({
    required int? collectionId,
    required MediaType mediaType,
    required int externalId,
    int? platformId,
    String? authorComment,
    ItemStatus status = ItemStatus.notStarted,
  }) =>
      collectionDao.addItemToCollection(
        collectionId: collectionId,
        mediaType: mediaType,
        externalId: externalId,
        platformId: platformId,
        authorComment: authorComment,
        status: status,
      );

  /// Возвращает следующий sort_order для коллекции.
  Future<int> getNextSortOrder(int? collectionId) =>
      collectionDao.getNextSortOrder(collectionId);

  /// Пересортировывает элементы коллекции после drag-and-drop.
  Future<void> reorderItems(
    int? collectionId,
    List<int> orderedItemIds,
  ) =>
      collectionDao.reorderItems(collectionId, orderedItemIds);

  /// Удаляет элемент из коллекции.
  Future<void> removeItemFromCollection(int id) =>
      collectionDao.removeItemFromCollection(id);

  /// Обновляет статус элемента коллекции.
  Future<void> updateItemStatus(
    int id,
    ItemStatus status, {
    required MediaType mediaType,
  }) =>
      collectionDao.updateItemStatus(id, status, mediaType: mediaType);

  /// Обновляет даты активности элемента коллекции вручную.
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

  /// Возвращает (id, collectionId) всех collection_items
  /// с указанным external_id и media_type.
  Future<List<({int id, int? collectionId})>> getItemIdsByExternalId(
    int externalId,
    String mediaType,
  ) async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      'collection_items',
      columns: <String>['id', 'collection_id'],
      where: 'external_id = ? AND media_type = ?',
      whereArgs: <Object?>[externalId, mediaType],
    );
    return rows
        .map((Map<String, dynamic> r) => (
              id: r['id'] as int,
              collectionId: r['collection_id'] as int?,
            ))
        .toList();
  }

  /// Обновляет прогресс просмотра сериала.
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

  /// Обновляет комментарий автора элемента.
  Future<void> updateItemAuthorComment(int id, String? comment) =>
      collectionDao.updateItemAuthorComment(id, comment);

  /// Обновляет личный комментарий пользователя элемента.
  Future<void> updateItemUserComment(int id, String? comment) =>
      collectionDao.updateItemUserComment(id, comment);

  /// Обновляет пользовательский рейтинг элемента (1-10 или null).
  Future<void> updateItemUserRating(int id, int? rating) =>
      collectionDao.updateItemUserRating(id, rating);

  /// Обновляет collection_id элемента (перемещает в другую коллекцию).
  Future<bool> updateItemCollectionId(int id, int? collectionId) =>
      collectionDao.updateItemCollectionId(id, collectionId);

  /// Клонирует элемент в другую коллекцию (полная копия).
  Future<int?> cloneItemToCollection(int itemId, int targetCollectionId) =>
      collectionDao.cloneItemToCollection(itemId, targetCollectionId);

  /// Возвращает уникальные platform_id из игр в коллекциях.
  Future<List<int>> getUniquePlatformIds({int? collectionId}) =>
      collectionDao.getUniquePlatformIds(collectionId: collectionId);

  /// Возвращает общее количество элементов во всех коллекциях.
  Future<int> getTotalItemCount() => collectionDao.getTotalItemCount();

  /// Возвращает количество элементов в коллекции.
  Future<int> getCollectionItemCount(
    int? collectionId, {
    MediaType? mediaType,
  }) =>
      collectionDao.getCollectionItemCount(collectionId, mediaType: mediaType);

  /// Возвращает расширенную статистику по коллекции.
  Future<Map<String, int>> getCollectionItemStats(int? collectionId) =>
      collectionDao.getCollectionItemStats(collectionId);

  /// Удаляет все элементы из коллекции.
  Future<void> clearCollectionItems(int? collectionId) =>
      collectionDao.clearCollectionItems(collectionId);

  // ==================== Canvas Items (delegates to CanvasDao) ====================

  /// Возвращает все элементы канваса для коллекции.
  Future<List<Map<String, dynamic>>> getCanvasItems(int collectionId) =>
      canvasDao.getCanvasItems(collectionId);

  /// Вставляет элемент канваса и возвращает его ID.
  Future<int> insertCanvasItem(Map<String, dynamic> data) =>
      canvasDao.insertCanvasItem(data);

  /// Обновляет элемент канваса по ID.
  Future<void> updateCanvasItem(int id, Map<String, dynamic> data) =>
      canvasDao.updateCanvasItem(id, data);

  /// Удаляет элемент канваса по ID.
  Future<void> deleteCanvasItem(int id) => canvasDao.deleteCanvasItem(id);

  /// Удаляет элемент канваса по типу и ID связанного объекта.
  Future<void> deleteCanvasItemByRef(
    int collectionId,
    String itemType,
    int itemRefId,
  ) =>
      canvasDao.deleteCanvasItemByRef(collectionId, itemType, itemRefId);

  /// Удаляет элемент канваса по collection_item_id.
  Future<void> deleteCanvasItemByCollectionItemId(
    int collectionId,
    int collectionItemId,
  ) =>
      canvasDao.deleteCanvasItemByCollectionItemId(
        collectionId,
        collectionItemId,
      );

  /// Удаляет все элементы канваса коллекции (без per-item элементов).
  Future<void> deleteCanvasItemsByCollection(int collectionId) =>
      canvasDao.deleteCanvasItemsByCollection(collectionId);

  /// Вставляет несколько элементов канваса в одной транзакции.
  Future<List<int>> insertCanvasItemsBatch(
    List<Map<String, dynamic>> items,
  ) =>
      canvasDao.insertCanvasItemsBatch(items);

  /// Удаляет несколько элементов канваса по ID в одной транзакции.
  Future<void> deleteCanvasItemsBatch(List<int> ids) =>
      canvasDao.deleteCanvasItemsBatch(ids);

  /// Возвращает количество элементов канваса для коллекции.
  Future<int> getCanvasItemCount(int collectionId) =>
      canvasDao.getCanvasItemCount(collectionId);

  // ==================== Canvas Viewport (delegates to CanvasDao) ====================

  /// Возвращает состояние viewport канваса для коллекции.
  Future<Map<String, dynamic>?> getCanvasViewport(int collectionId) =>
      canvasDao.getCanvasViewport(collectionId);

  /// Сохраняет или обновляет состояние viewport канваса.
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

  // ==================== Canvas Connections (delegates to CanvasDao) ====================

  /// Возвращает связи канваса коллекции (без per-item связей).
  Future<List<Map<String, dynamic>>> getCanvasConnections(
    int collectionId,
  ) =>
      canvasDao.getCanvasConnections(collectionId);

  /// Вставляет связь канваса и возвращает её ID.
  Future<int> insertCanvasConnection(Map<String, dynamic> data) =>
      canvasDao.insertCanvasConnection(data);

  /// Обновляет связь канваса по ID.
  Future<void> updateCanvasConnection(
    int id,
    Map<String, dynamic> data,
  ) =>
      canvasDao.updateCanvasConnection(id, data);

  /// Удаляет связь канваса по ID.
  Future<void> deleteCanvasConnection(int id) =>
      canvasDao.deleteCanvasConnection(id);

  /// Удаляет связи канваса коллекции (без per-item связей).
  Future<void> deleteCanvasConnectionsByCollection(int collectionId) =>
      canvasDao.deleteCanvasConnectionsByCollection(collectionId);

  // ==================== Game Canvas (delegates to CanvasDao) ====================

  /// Возвращает элементы game canvas по ID элемента коллекции.
  Future<List<Map<String, dynamic>>> getGameCanvasItems(
    int collectionItemId,
  ) =>
      canvasDao.getGameCanvasItems(collectionItemId);

  /// Возвращает количество элементов game canvas.
  Future<int> getGameCanvasItemCount(int collectionItemId) =>
      canvasDao.getGameCanvasItemCount(collectionItemId);

  /// Возвращает связи game canvas.
  Future<List<Map<String, dynamic>>> getGameCanvasConnections(
    int collectionItemId,
  ) =>
      canvasDao.getGameCanvasConnections(collectionItemId);

  /// Возвращает viewport для game canvas.
  Future<Map<String, dynamic>?> getGameCanvasViewport(
    int collectionItemId,
  ) =>
      canvasDao.getGameCanvasViewport(collectionItemId);

  /// Сохраняет или обновляет viewport для game canvas.
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

  /// Удаляет все элементы game canvas по collection_item_id.
  Future<void> deleteGameCanvasItems(int collectionItemId) =>
      canvasDao.deleteGameCanvasItems(collectionItemId);

  /// Удаляет все связи game canvas по collection_item_id.
  Future<void> deleteGameCanvasConnections(int collectionItemId) =>
      canvasDao.deleteGameCanvasConnections(collectionItemId);

  /// Удаляет viewport game canvas.
  Future<void> deleteGameCanvasViewport(int collectionItemId) =>
      canvasDao.deleteGameCanvasViewport(collectionItemId);

  // ==================== Info (delegates to CollectionDao) ====================

  /// Возвращает информацию о нахождении элементов заданного типа в коллекциях.
  Future<Map<int, List<CollectedItemInfo>>> getCollectedItemInfos(
    MediaType mediaType,
  ) =>
      collectionDao.getCollectedItemInfos(mediaType);

  /// Возвращает количество uncategorized элементов.
  Future<int> getUncategorizedItemCount() =>
      collectionDao.getUncategorizedItemCount();

  // ==================== Wishlist (delegates to WishlistDao) ====================

  /// Добавляет элемент в вишлист.
  Future<WishlistItem> addWishlistItem({
    required String text,
    MediaType? mediaTypeHint,
    String? note,
  }) =>
      wishlistDao.addWishlistItem(
        text: text,
        mediaTypeHint: mediaTypeHint,
        note: note,
      );

  /// Возвращает все элементы вишлиста.
  Future<List<WishlistItem>> getWishlistItems({
    bool includeResolved = true,
  }) =>
      wishlistDao.getWishlistItems(includeResolved: includeResolved);

  /// Возвращает количество элементов вишлиста.
  Future<int> getWishlistItemCount({bool onlyActive = true}) =>
      wishlistDao.getWishlistItemCount(onlyActive: onlyActive);

  /// Обновляет элемент вишлиста.
  Future<void> updateWishlistItem(
    int id, {
    String? text,
    MediaType? mediaTypeHint,
    bool clearMediaTypeHint = false,
    String? note,
    bool clearNote = false,
  }) =>
      wishlistDao.updateWishlistItem(
        id,
        text: text,
        mediaTypeHint: mediaTypeHint,
        clearMediaTypeHint: clearMediaTypeHint,
        note: note,
        clearNote: clearNote,
      );

  /// Помечает элемент вишлиста как resolved.
  Future<void> resolveWishlistItem(int id) =>
      wishlistDao.resolveWishlistItem(id);

  /// Снимает отметку resolved с элемента вишлиста.
  Future<void> unresolveWishlistItem(int id) =>
      wishlistDao.unresolveWishlistItem(id);

  /// Удаляет элемент вишлиста.
  Future<void> deleteWishlistItem(int id) =>
      wishlistDao.deleteWishlistItem(id);

  /// Находит активный (не resolved) элемент вишлиста по тексту.
  Future<WishlistItem?> findUnresolvedWishlistItem(String text) =>
      wishlistDao.findUnresolvedByText(text);

  /// Удаляет все resolved элементы вишлиста.
  Future<int> clearResolvedWishlistItems() =>
      wishlistDao.clearResolvedWishlistItems();

  // ==================== Clear All / Close ====================

  /// Очищает все данные из базы данных.
  ///
  /// Удаляет содержимое всех таблиц в одной транзакции.
  /// Сначала зависимые таблицы (FK), затем основные.
  /// Настройки (SharedPreferences) не затрагиваются.
  Future<void> clearAllData() async {
    final Database db = await database;
    await db.transaction((Transaction txn) async {
      // Зависимые таблицы (FK CASCADE) — удаляем до основных
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
      // Основные таблицы
      await txn.delete('collections');
      await txn.delete('tv_episodes_cache');
      await txn.delete('tv_seasons_cache');
      await txn.delete('tv_shows_cache');
      await txn.delete('movies_cache');
      await txn.delete('games');
      await txn.delete('visual_novels_cache');
      await txn.delete('manga_cache');
      await txn.delete('anime_cache');
      // Статические справочники (platforms, tmdb_genres, igdb_genres, vndb_tags)
      // не очищаются — они заполнены миграцией v24 и не являются пользовательскими.
      // Wishlist
      await txn.delete('wishlist');
    });
  }

  // ==================== Visual Novels (delegates to VisualNovelDao) ====================

  /// Сохраняет или обновляет визуальную новеллу в кэше.
  Future<void> upsertVisualNovel(VisualNovel vn) =>
      visualNovelDao.upsertVisualNovel(vn);

  /// Сохраняет или обновляет список визуальных новелл.
  Future<void> upsertVisualNovels(List<VisualNovel> vns) =>
      visualNovelDao.upsertVisualNovels(vns);

  /// Получает визуальную новеллу по числовому ID.
  Future<VisualNovel?> getVisualNovel(int numericId) =>
      visualNovelDao.getVisualNovel(numericId);

  /// Получает визуальные новеллы по списку числовых ID.
  Future<List<VisualNovel>> getVisualNovelsByNumericIds(
    List<int> numericIds,
  ) =>
      visualNovelDao.getVisualNovelsByNumericIds(numericIds);

  /// Получает кэшированные теги VNDB.
  Future<List<VndbTag>> getVndbTags() => visualNovelDao.getVndbTags();

  // ==================== Manga (delegates to MangaDao) ====================

  /// Сохраняет или обновляет мангу в кэше.
  Future<void> upsertManga(Manga manga) => mangaDao.upsertManga(manga);

  /// Сохраняет или обновляет список манг.
  Future<void> upsertMangas(List<Manga> mangas) =>
      mangaDao.upsertMangas(mangas);

  /// Получает мангу по AniList ID.
  Future<Manga?> getManga(int id) => mangaDao.getManga(id);

  /// Получает манги по списку ID.
  Future<List<Manga>> getMangaByIds(List<int> ids) =>
      mangaDao.getMangaByIds(ids);

  // ==================== Anime (delegates to AnimeDao) ====================

  /// Сохраняет или обновляет аниме в кэше.
  Future<void> upsertAnime(Anime anime) => animeDao.upsertAnime(anime);

  /// Сохраняет или обновляет список аниме.
  Future<void> upsertAnimes(List<Anime> animes) =>
      animeDao.upsertAnimes(animes);

  /// Получает аниме по AniList ID.
  Future<Anime?> getAnime(int id) => animeDao.getAnime(id);

  /// Получает аниме по списку ID.
  Future<List<Anime>> getAnimeByIds(List<int> ids) =>
      animeDao.getAnimeByIds(ids);

  // ==================== Collection Covers (delegates to CollectionDao) ====================

  /// Возвращает первые [limit] обложек элементов коллекции.
  Future<List<CoverInfo>> getCollectionCovers(
    int? collectionId, {
    int limit = 4,
  }) =>
      collectionDao.getCollectionCovers(collectionId, limit: limit);

  /// Закрывает соединение с базой данных.
  Future<void> close() async {
    final Database? db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
