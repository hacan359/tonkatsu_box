import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../shared/models/collected_item_info.dart';
import '../../shared/models/profile.dart';
import '../services/profile_service.dart';
import '../services/storage_root.dart';
import '../../shared/models/collection.dart';
import '../../shared/models/collection_item.dart';
import '../../shared/models/cover_info.dart';
import '../../shared/models/data_source.dart';
import '../../shared/models/item_status.dart';
import '../../shared/models/media_type.dart';
import 'dao/anilist_tag_dao.dart';
import 'dao/canvas_dao.dart';
import 'dao/collection_dao.dart';
import 'dao/custom_media_dao.dart';
import 'dao/anime_dao.dart';
import 'dao/book_dao.dart';
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
import 'dao/calendar_entry_dao.dart';
import 'dao/tracked_release_dao.dart';
import 'dao/tracker_dao.dart';
import 'dao/wishlist_dao.dart';
import 'migrations/migration.dart';
import 'migrations/migration_registry.dart';

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

final Provider<CalendarEntryDao> calendarEntryDaoProvider =
    Provider<CalendarEntryDao>((Ref ref) {
  return ref.watch(databaseServiceProvider).calendarEntryDao;
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

  late final TagDao tagDao = TagDao(() => database);

  late final AniListTagDao aniListTagDao = AniListTagDao(() => database);

  late final MangaBakaGenreDao mangaBakaGenreDao =
      MangaBakaGenreDao(() => database);

  late final MangaBakaTagDao mangaBakaTagDao = MangaBakaTagDao(() => database);

  late final WishlistDao wishlistDao = WishlistDao(() => database);

  late final TrackedReleaseDao trackedReleaseDao =
      TrackedReleaseDao(() => database);

  late final CalendarEntryDao calendarEntryDao =
      CalendarEntryDao(() => database);

  Future<Database> _initDatabase() async {
    final String basePath = (await StorageRoot.resolve()).path;

    // If profile system is initialised, use the per-profile path.
    final String dbDir;
    final File profilesFile =
        File(p.join(basePath, StorageRoot.profilesFileName));
    if (profilesFile.existsSync()) {
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
        version: 50,
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
    // Single source of truth: a fresh DB is built by running the whole
    // migration chain (v1..N) in order, exactly like an upgrade from zero.
    for (final Migration migration in MigrationRegistry.all) {
      await migration.migrate(db);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _log.info('Upgrading database from v$oldVersion to v$newVersion');
    for (final Migration migration in MigrationRegistry.pending(oldVersion)) {
      _log.fine('Running migration v${migration.version}: ${migration.description}');
      await migration.migrate(db);
    }
    _log.info('Database upgrade complete');
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
      await txn.delete('books_cache');
      await txn.delete('wishlist');
    });
  }

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
