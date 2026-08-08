import 'dart:io';

import 'package:core/database/dao/anilist_tag_dao.dart';
import 'package:core/database/dao/anime_dao.dart';
import 'package:core/database/dao/book_dao.dart';
import 'package:core/database/dao/calendar_entry_dao.dart';
import 'package:core/database/dao/canvas_dao.dart';
import 'package:core/database/dao/collection_dao.dart';
import 'package:core/database/dao/custom_media_dao.dart';
import 'package:core/database/dao/game_dao.dart';
import 'package:core/database/dao/global_tag_dao.dart';
import 'package:core/database/dao/item_mark_dao.dart';
import 'package:core/database/dao/manga_dao.dart';
import 'package:core/database/dao/mangabaka_genre_dao.dart';
import 'package:core/database/dao/mangabaka_tag_dao.dart';
import 'package:core/database/dao/mangadex_tag_dao.dart';
import 'package:core/database/dao/mood_grid_dao.dart';
import 'package:core/database/dao/movie_dao.dart';
import 'package:core/database/dao/stats_dao.dart';
import 'package:core/database/dao/tier_list_dao.dart';
import 'package:core/database/dao/tracked_release_dao.dart';
import 'package:core/database/dao/tracker_dao.dart';
import 'package:core/database/dao/tv_show_dao.dart';
import 'package:core/database/dao/visual_novel_dao.dart';
import 'package:core/database/dao/wishlist_dao.dart';
import 'package:core/database/database_opener.dart';
import 'package:core/database/migrations/migration.dart';
import 'package:core/database/migrations/migration_runner.dart';
import 'package:core/models/collected_item_info.dart';
import 'package:core/models/collection.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/cover_info.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/profile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common/sqflite.dart';

import '../../shared/constants/platform_features.dart';
import '../services/profile_service.dart';
import '../services/storage_root.dart';

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

final Provider<BookDao> bookDaoProvider = Provider<BookDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).bookDao;
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

final Provider<GlobalTagDao> globalTagDaoProvider =
    Provider<GlobalTagDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).globalTagDao;
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

final Provider<MangaDexTagDao> mangaDexTagDaoProvider =
    Provider<MangaDexTagDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).mangaDexTagDao;
});

final Provider<TrackedReleaseDao> trackedReleaseDaoProvider =
    Provider<TrackedReleaseDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).trackedReleaseDao;
});

final Provider<CalendarEntryDao> calendarEntryDaoProvider =
    Provider<CalendarEntryDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).calendarEntryDao;
});

final Provider<StatsDao> statsDaoProvider = Provider<StatsDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).statsDao;
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

  late final BookDao bookDao = BookDao(() => database);

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
    bookDao: bookDao,
    customMediaDao: customMediaDao,
  );

  late final CanvasDao canvasDao = CanvasDao(() => database);

  late final TierListDao tierListDao = TierListDao(() => database);

  late final MoodGridDao moodGridDao = MoodGridDao(() => database);

  late final TrackerDao trackerDao = TrackerDao(() => database);

  late final GlobalTagDao globalTagDao = GlobalTagDao(() => database);

  late final AniListTagDao aniListTagDao = AniListTagDao(() => database);

  late final MangaBakaGenreDao mangaBakaGenreDao =
      MangaBakaGenreDao(() => database);

  late final MangaBakaTagDao mangaBakaTagDao = MangaBakaTagDao(() => database);

  late final MangaDexTagDao mangaDexTagDao = MangaDexTagDao(() => database);

  late final WishlistDao wishlistDao = WishlistDao(() => database);

  late final TrackedReleaseDao trackedReleaseDao =
      TrackedReleaseDao(() => database);

  late final CalendarEntryDao calendarEntryDao =
      CalendarEntryDao(() => database);

  late final ItemMarkDao itemMarkDao = ItemMarkDao(() => database);

  late final StatsDao statsDao = StatsDao(() => database);

  Future<Database> _initDatabase() async {
    final String basePath = (await StorageRoot.resolve()).path;

    // If profile system is initialised, use the per-profile path. Web has no
    // filesystem to probe — profiles come from prefs and always exist.
    final String dbDir;
    if (kIsWebBuild ||
        File(p.join(basePath, StorageRoot.profilesFileName)).existsSync()) {
      final ProfileService profileService = ProfileService();
      final ProfilesData data = await profileService.loadProfiles();
      dbDir = p.join(
        basePath,
        StorageRoot.profilesFolderName,
        data.currentProfileId,
      );
    } else {
      dbDir = basePath;
    }

    final String dbPath = p.join(dbDir, StorageRoot.dbFileName);

    if (!kIsWebBuild) {
      final Directory dir = Directory(dbDir);
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
    }

    _log.info(
      'Database path: $dbPath (${kReleaseMode ? 'release' : 'debug'} mode)',
    );

    return openAppDatabase(
      factory: databaseFactory,
      path: dbPath,
      onInfo: _log.info,
      onMigrationStart: (Migration m) =>
          _log.fine('Running migration v${m.version}: ${m.description}'),
      onMigrationFailure: (MigrationFailure failure, StackTrace stack) =>
          _log.severe('Migration v${failure.version} failed', failure, stack),
    );
  }

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
    DateTime? createdAt,
    bool isHidden = false,
  }) =>
      collectionDao.createCollection(
        name: name,
        author: author,
        type: type,
        originalSnapshot: originalSnapshot,
        forkedFromAuthor: forkedFromAuthor,
        forkedFromName: forkedFromName,
        createdAt: createdAt,
        isHidden: isHidden,
      );

  Future<void> updateCollection(
    int id, {
    String? name,
    String? heroImagePath,
    String? description,
    bool? isHidden,
    bool clearHeroImage = false,
    bool clearDescription = false,
  }) =>
      collectionDao.updateCollection(
        id,
        name: name,
        heroImagePath: heroImagePath,
        description: description,
        isHidden: isHidden,
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

  Future<List<CollectionItem>> resolveCardLink({
    required MediaType mediaType,
    required int externalId,
    DataSource? source,
    int? platformId,
    int? collectionId,
  }) =>
      collectionDao.resolveCardLink(
        mediaType: mediaType,
        externalId: externalId,
        source: source,
        platformId: platformId,
        collectionId: collectionId,
      );

  Future<CollectionItem?> findCollectionItem({
    required int? collectionId,
    required MediaType mediaType,
    required int externalId,
    int? platformId,
    DataSource? source,
  }) =>
      collectionDao.findCollectionItem(
        collectionId: collectionId,
        mediaType: mediaType,
        externalId: externalId,
        platformId: platformId,
        source: source,
      );

  Future<int?> addItemToCollection({
    required int? collectionId,
    required MediaType mediaType,
    required int externalId,
    int? platformId,
    DataSource? source,
    String? authorComment,
    ItemStatus status = ItemStatus.notStarted,
    DateTime? addedAt,
  }) =>
      collectionDao.addItemToCollection(
        collectionId: collectionId,
        mediaType: mediaType,
        externalId: externalId,
        platformId: platformId,
        source: source,
        authorComment: authorComment,
        status: status,
        addedAt: addedAt,
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

  Future<void> updateItemRewatchCount(int id, int? count) =>
      collectionDao.updateItemRewatchCount(id, count);

  Future<void> updateItemActivityDates(
    int id, {
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? lastActivityAt,
    bool clearStartedAt = false,
    bool clearCompletedAt = false,
  }) =>
      collectionDao.updateItemActivityDates(
        id,
        startedAt: startedAt,
        completedAt: completedAt,
        lastActivityAt: lastActivityAt,
        clearStartedAt: clearStartedAt,
        clearCompletedAt: clearCompletedAt,
      );

  Future<List<({int id, int? collectionId, int? platformId})>>
      getItemIdsByExternalId(
    int externalId,
    String mediaType, {
    int? platformId,
    bool filterByPlatform = false,
  }) =>
      collectionDao.getItemIdsByExternalId(
        externalId,
        mediaType,
        platformId: platformId,
        filterByPlatform: filterByPlatform,
      );

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

  Future<void> setItemFavorite(int id, {required bool isFavorite}) =>
      collectionDao.setItemFavorite(id, isFavorite: isFavorite);

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

  Future<Map<int, List<CollectedItemInfo>>> getCollectedItemInfos(
    MediaType mediaType,
  ) =>
      collectionDao.getCollectedItemInfos(mediaType);

  Future<int> getUncategorizedItemCount() =>
      collectionDao.getUncategorizedItemCount();

  /// Truncates every user table in a single transaction; static reference
  /// tables and SharedPreferences are untouched.
  Future<void> clearAllData() => collectionDao.clearAllData();

  Future<List<CoverInfo>> getCollectionCovers(
    int? collectionId, {
    int limit = 4,
  }) =>
      collectionDao.getCollectionCovers(collectionId, limit: limit);

  /// Empties the WAL into the main database file so a plain file copy
  /// of the open database is complete.
  Future<void> checkpointWal() async {
    final Database db = await database;
    final List<Map<String, Object?>> result =
        await db.rawQuery('PRAGMA wal_checkpoint(TRUNCATE)');
    // busy=1 means active readers kept the checkpoint incomplete; the
    // copied sidecars still carry the tail, but it is worth a trace.
    final Object? busy = result.isNotEmpty ? result.first['busy'] : null;
    if (busy != 0) {
      _log.warning('WAL checkpoint incomplete (busy=$busy)');
    }
  }

  Future<void> close() async {
    final Database? db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
