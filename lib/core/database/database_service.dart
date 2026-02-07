import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../shared/models/collection.dart';
import '../../shared/models/collection_game.dart';
import '../../shared/models/collection_item.dart';
import '../../shared/models/game.dart';
import '../../shared/models/item_status.dart';
import '../../shared/models/media_type.dart';
import '../../shared/models/movie.dart';
import '../../shared/models/platform.dart';
import '../../shared/models/tv_season.dart';
import '../../shared/models/tv_show.dart';

/// Провайдер для доступа к сервису базы данных.
final Provider<DatabaseService> databaseServiceProvider =
    Provider<DatabaseService>((Ref ref) {
  return DatabaseService();
});

/// Сервис для работы с SQLite базой данных.
///
/// Управляет инициализацией базы данных и CRUD операциями для платформ.
class DatabaseService {
  Database? _database;

  /// Возвращает экземпляр базы данных, инициализируя при необходимости.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String dbDir = p.join(appDir.path, 'xerabora');
    final String dbPath = p.join(dbDir, 'xerabora.db');

    // Создаём директорию, если не существует
    final Directory dir = Directory(dbDir);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    return databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 8,
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
    await _createPlatformsTable(db);
    await _createGamesTable(db);
    await _createCollectionsTable(db);
    await _createCollectionGamesTable(db);
    await _createCanvasItemsTable(db);
    await _createCanvasViewportTable(db);
    await _createCanvasConnectionsTable(db);
    await _createMoviesCacheTable(db);
    await _createTvShowsCacheTable(db);
    await _createTvSeasonsCacheTable(db);
    await _createCollectionItemsTable(db);
  }

  Future<void> _createPlatformsTable(Database db) async {
    await db.execute('''
      CREATE TABLE platforms (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        abbreviation TEXT,
        logo_image_id TEXT,
        synced_at INTEGER
      )
    ''');
  }

  Future<void> _createGamesTable(Database db) async {
    await db.execute('''
      CREATE TABLE games (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        summary TEXT,
        cover_url TEXT,
        release_date INTEGER,
        rating REAL,
        rating_count INTEGER,
        genres TEXT,
        platform_ids TEXT,
        cached_at INTEGER
      )
    ''');

    // Индекс для поиска по имени
    await db.execute('''
      CREATE INDEX idx_games_name ON games(name)
    ''');
  }

  Future<void> _createCollectionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE collections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        author TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'own',
        created_at INTEGER NOT NULL,
        original_snapshot TEXT,
        forked_from_author TEXT,
        forked_from_name TEXT
      )
    ''');
  }

  Future<void> _createCollectionGamesTable(Database db) async {
    await db.execute('''
      CREATE TABLE collection_games (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        collection_id INTEGER NOT NULL,
        igdb_id INTEGER NOT NULL,
        platform_id INTEGER NOT NULL,
        author_comment TEXT,
        user_comment TEXT,
        status TEXT DEFAULT 'not_started',
        added_at INTEGER NOT NULL,
        FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE,
        UNIQUE(collection_id, igdb_id, platform_id)
      )
    ''');

    // Индексы для быстрого поиска
    await db.execute('''
      CREATE INDEX idx_collection_games_collection
      ON collection_games(collection_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_collection_games_igdb
      ON collection_games(igdb_id)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createGamesTable(db);
    }
    if (oldVersion < 3) {
      await _createCollectionsTable(db);
      await _createCollectionGamesTable(db);
    }
    if (oldVersion < 4) {
      // Добавляем колонку logo_image_id для хранения логотипов платформ
      await db.execute('ALTER TABLE platforms ADD COLUMN logo_image_id TEXT');
    }
    if (oldVersion < 5) {
      await _createCanvasItemsTable(db);
      await _createCanvasViewportTable(db);
    }
    if (oldVersion < 6) {
      await _createCanvasConnectionsTable(db);
    }
    if (oldVersion < 7) {
      await _createMoviesCacheTable(db);
      await _createTvShowsCacheTable(db);
      await _createTvSeasonsCacheTable(db);
    }
    if (oldVersion < 8) {
      await _createCollectionItemsTable(db);
      await _migrateCollectionGamesToItems(db);
    }
  }

  Future<void> _createCanvasItemsTable(Database db) async {
    await db.execute('''
      CREATE TABLE canvas_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        collection_id INTEGER NOT NULL,
        item_type TEXT NOT NULL,
        item_ref_id INTEGER,
        x REAL NOT NULL DEFAULT 0,
        y REAL NOT NULL DEFAULT 0,
        width REAL,
        height REAL,
        z_index INTEGER DEFAULT 0,
        data TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_canvas_items_collection
      ON canvas_items(collection_id)
    ''');
  }

  Future<void> _createCanvasViewportTable(Database db) async {
    await db.execute('''
      CREATE TABLE canvas_viewport (
        collection_id INTEGER PRIMARY KEY,
        scale REAL DEFAULT 1.0,
        offset_x REAL DEFAULT 0.0,
        offset_y REAL DEFAULT 0.0,
        FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createCanvasConnectionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE canvas_connections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        collection_id INTEGER NOT NULL,
        from_item_id INTEGER NOT NULL,
        to_item_id INTEGER NOT NULL,
        label TEXT,
        color TEXT DEFAULT '#666666',
        style TEXT DEFAULT 'solid',
        created_at INTEGER NOT NULL,
        FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE,
        FOREIGN KEY (from_item_id) REFERENCES canvas_items(id) ON DELETE CASCADE,
        FOREIGN KEY (to_item_id) REFERENCES canvas_items(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_canvas_connections_collection
      ON canvas_connections(collection_id)
    ''');
  }

  Future<void> _createMoviesCacheTable(Database db) async {
    await db.execute('''
      CREATE TABLE movies_cache (
        tmdb_id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        original_title TEXT,
        poster_url TEXT,
        backdrop_url TEXT,
        overview TEXT,
        genres TEXT,
        release_year INTEGER,
        rating REAL,
        runtime INTEGER,
        cached_at INTEGER
      )
    ''');
  }

  Future<void> _createTvShowsCacheTable(Database db) async {
    await db.execute('''
      CREATE TABLE tv_shows_cache (
        tmdb_id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        original_title TEXT,
        poster_url TEXT,
        backdrop_url TEXT,
        overview TEXT,
        genres TEXT,
        first_air_year INTEGER,
        total_seasons INTEGER,
        total_episodes INTEGER,
        rating REAL,
        status TEXT,
        cached_at INTEGER
      )
    ''');
  }

  Future<void> _createTvSeasonsCacheTable(Database db) async {
    await db.execute('''
      CREATE TABLE tv_seasons_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tmdb_show_id INTEGER NOT NULL,
        season_number INTEGER NOT NULL,
        name TEXT,
        episode_count INTEGER,
        poster_url TEXT,
        air_date TEXT,
        UNIQUE(tmdb_show_id, season_number)
      )
    ''');
  }

  Future<void> _createCollectionItemsTable(Database db) async {
    await db.execute('''
      CREATE TABLE collection_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        collection_id INTEGER NOT NULL,
        media_type TEXT NOT NULL DEFAULT 'game',
        external_id INTEGER NOT NULL,
        platform_id INTEGER,
        current_season INTEGER DEFAULT 0,
        current_episode INTEGER DEFAULT 0,
        status TEXT DEFAULT 'not_started',
        author_comment TEXT,
        user_comment TEXT,
        added_at INTEGER NOT NULL,
        FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE,
        UNIQUE(collection_id, media_type, external_id)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_collection_items_collection
      ON collection_items(collection_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_collection_items_type
      ON collection_items(media_type)
    ''');
  }

  /// Мигрирует данные из collection_games в collection_items.
  Future<void> _migrateCollectionGamesToItems(Database db) async {
    await db.execute('''
      INSERT OR IGNORE INTO collection_items
        (collection_id, media_type, external_id, platform_id, status,
         author_comment, user_comment, added_at)
      SELECT
        collection_id, 'game', igdb_id, platform_id, status,
        author_comment, user_comment, added_at
      FROM collection_games
    ''');
  }

  // ==================== Platforms ====================

  /// Возвращает все платформы из базы данных.
  Future<List<Platform>> getAllPlatforms() async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      'platforms',
      orderBy: 'name ASC',
    );
    return rows.map(Platform.fromDb).toList();
  }

  /// Возвращает платформу по ID или null, если не найдена.
  Future<Platform?> getPlatformById(int id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      'platforms',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Platform.fromDb(rows.first);
  }

  /// Возвращает количество платформ в базе данных.
  Future<int> getPlatformCount() async {
    final Database db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM platforms',
    );
    return result.first['count'] as int;
  }

  /// Сохраняет или обновляет платформу в базе данных.
  Future<void> upsertPlatform(Platform platform) async {
    final Database db = await database;
    await db.insert(
      'platforms',
      platform.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Сохраняет список платформ пакетно.
  ///
  /// Использует транзакцию для оптимизации производительности.
  Future<void> upsertPlatforms(List<Platform> platforms) async {
    final Database db = await database;
    await db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();
      for (final Platform platform in platforms) {
        batch.insert(
          'platforms',
          platform.toDb(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Удаляет все платформы из базы данных.
  Future<void> clearPlatforms() async {
    final Database db = await database;
    await db.delete('platforms');
  }

  // ==================== Games ====================

  /// Возвращает игру по ID или null, если не найдена.
  Future<Game?> getGameById(int id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      'games',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Game.fromDb(rows.first);
  }

  /// Возвращает несколько игр по списку ID.
  Future<List<Game>> getGamesByIds(List<int> ids) async {
    if (ids.isEmpty) return <Game>[];

    final Database db = await database;
    final String placeholders = List<String>.filled(ids.length, '?').join(',');
    final List<Map<String, dynamic>> rows = await db.query(
      'games',
      where: 'id IN ($placeholders)',
      whereArgs: ids.cast<Object?>(),
    );
    return rows.map(Game.fromDb).toList();
  }

  /// Ищет игры по названию в кеше.
  ///
  /// Возвращает список игр, название которых содержит [query].
  Future<List<Game>> searchGamesInCache(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) return <Game>[];

    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      'games',
      where: 'name LIKE ?',
      whereArgs: <Object?>['%$query%'],
      orderBy: 'name ASC',
      limit: limit,
    );
    return rows.map(Game.fromDb).toList();
  }

  /// Возвращает количество игр в кеше.
  Future<int> getGameCount() async {
    final Database db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM games',
    );
    return result.first['count'] as int;
  }

  /// Сохраняет или обновляет игру в базе данных.
  Future<void> upsertGame(Game game) async {
    final Database db = await database;
    await db.insert(
      'games',
      game.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Сохраняет список игр пакетно.
  ///
  /// Использует транзакцию для оптимизации производительности.
  Future<void> upsertGames(List<Game> games) async {
    if (games.isEmpty) return;

    final Database db = await database;
    await db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();
      for (final Game game in games) {
        batch.insert(
          'games',
          game.toDb(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Удаляет игру по ID.
  Future<void> deleteGame(int id) async {
    final Database db = await database;
    await db.delete(
      'games',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Удаляет все игры из кеша.
  Future<void> clearGames() async {
    final Database db = await database;
    await db.delete('games');
  }

  /// Удаляет устаревшие игры из кеша.
  ///
  /// [maxAgeSeconds] — максимальный возраст записи в секундах.
  Future<int> clearStaleGames({int maxAgeSeconds = 86400 * 30}) async {
    final Database db = await database;
    final int threshold =
        DateTime.now().millisecondsSinceEpoch ~/ 1000 - maxAgeSeconds;
    return db.delete(
      'games',
      where: 'cached_at < ?',
      whereArgs: <Object?>[threshold],
    );
  }

  // ==================== Movies Cache ====================

  /// Возвращает фильм по TMDB ID или null, если не найден.
  Future<Movie?> getMovieByTmdbId(int tmdbId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      'movies_cache',
      where: 'tmdb_id = ?',
      whereArgs: <Object?>[tmdbId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Movie.fromDb(rows.first);
  }

  /// Сохраняет или обновляет фильм в кеше.
  Future<void> upsertMovie(Movie movie) async {
    final Database db = await database;
    await db.insert(
      'movies_cache',
      movie.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Сохраняет список фильмов пакетно.
  Future<void> upsertMovies(List<Movie> movies) async {
    if (movies.isEmpty) return;

    final Database db = await database;
    await db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();
      for (final Movie movie in movies) {
        batch.insert(
          'movies_cache',
          movie.toDb(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Возвращает несколько фильмов по списку TMDB ID.
  Future<List<Movie>> getMoviesByTmdbIds(List<int> tmdbIds) async {
    if (tmdbIds.isEmpty) return <Movie>[];

    final Database db = await database;
    final String placeholders =
        List<String>.filled(tmdbIds.length, '?').join(',');
    final List<Map<String, dynamic>> rows = await db.query(
      'movies_cache',
      where: 'tmdb_id IN ($placeholders)',
      whereArgs: tmdbIds.cast<Object?>(),
    );
    return rows.map(Movie.fromDb).toList();
  }

  /// Удаляет все фильмы из кеша.
  Future<void> clearMovies() async {
    final Database db = await database;
    await db.delete('movies_cache');
  }

  // ==================== TV Shows Cache ====================

  /// Возвращает сериал по TMDB ID или null, если не найден.
  Future<TvShow?> getTvShowByTmdbId(int tmdbId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      'tv_shows_cache',
      where: 'tmdb_id = ?',
      whereArgs: <Object?>[tmdbId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TvShow.fromDb(rows.first);
  }

  /// Сохраняет или обновляет сериал в кеше.
  Future<void> upsertTvShow(TvShow tvShow) async {
    final Database db = await database;
    await db.insert(
      'tv_shows_cache',
      tvShow.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Сохраняет список сериалов пакетно.
  Future<void> upsertTvShows(List<TvShow> tvShows) async {
    if (tvShows.isEmpty) return;

    final Database db = await database;
    await db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();
      for (final TvShow tvShow in tvShows) {
        batch.insert(
          'tv_shows_cache',
          tvShow.toDb(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Возвращает несколько сериалов по списку TMDB ID.
  Future<List<TvShow>> getTvShowsByTmdbIds(List<int> tmdbIds) async {
    if (tmdbIds.isEmpty) return <TvShow>[];

    final Database db = await database;
    final String placeholders =
        List<String>.filled(tmdbIds.length, '?').join(',');
    final List<Map<String, dynamic>> rows = await db.query(
      'tv_shows_cache',
      where: 'tmdb_id IN ($placeholders)',
      whereArgs: tmdbIds.cast<Object?>(),
    );
    return rows.map(TvShow.fromDb).toList();
  }

  /// Удаляет все сериалы из кеша.
  Future<void> clearTvShows() async {
    final Database db = await database;
    await db.delete('tv_shows_cache');
  }

  // ==================== TV Seasons Cache ====================

  /// Возвращает сезоны сериала.
  Future<List<TvSeason>> getTvSeasonsByShowId(int tmdbShowId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      'tv_seasons_cache',
      where: 'tmdb_show_id = ?',
      whereArgs: <Object?>[tmdbShowId],
      orderBy: 'season_number ASC',
    );
    return rows.map(TvSeason.fromDb).toList();
  }

  /// Сохраняет сезоны сериала пакетно.
  Future<void> upsertTvSeasons(List<TvSeason> seasons) async {
    if (seasons.isEmpty) return;

    final Database db = await database;
    await db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();
      for (final TvSeason season in seasons) {
        batch.insert(
          'tv_seasons_cache',
          season.toDb(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Удаляет все сезоны из кеша.
  Future<void> clearTvSeasons() async {
    final Database db = await database;
    await db.delete('tv_seasons_cache');
  }

  // ==================== Collections ====================

  /// Возвращает все коллекции.
  Future<List<Collection>> getAllCollections() async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      'collections',
      orderBy: 'created_at DESC',
    );
    return rows.map(Collection.fromDb).toList();
  }

  /// Возвращает коллекции по типу.
  Future<List<Collection>> getCollectionsByType(CollectionType type) async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      'collections',
      where: 'type = ?',
      whereArgs: <Object?>[type.value],
      orderBy: 'created_at DESC',
    );
    return rows.map(Collection.fromDb).toList();
  }

  /// Возвращает коллекцию по ID или null, если не найдена.
  Future<Collection?> getCollectionById(int id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      'collections',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Collection.fromDb(rows.first);
  }

  /// Создаёт новую коллекцию и возвращает её с присвоенным ID.
  Future<Collection> createCollection({
    required String name,
    required String author,
    CollectionType type = CollectionType.own,
    String? originalSnapshot,
    String? forkedFromAuthor,
    String? forkedFromName,
  }) async {
    final Database db = await database;
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final int id = await db.insert(
      'collections',
      <String, dynamic>{
        'name': name,
        'author': author,
        'type': type.value,
        'created_at': now,
        'original_snapshot': originalSnapshot,
        'forked_from_author': forkedFromAuthor,
        'forked_from_name': forkedFromName,
      },
    );

    return Collection(
      id: id,
      name: name,
      author: author,
      type: type,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
      originalSnapshot: originalSnapshot,
      forkedFromAuthor: forkedFromAuthor,
      forkedFromName: forkedFromName,
    );
  }

  /// Обновляет коллекцию.
  Future<void> updateCollection(int id, {String? name}) async {
    if (name == null) return;

    final Database db = await database;
    await db.update(
      'collections',
      <String, dynamic>{'name': name},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Удаляет коллекцию и все связанные игры (каскадно).
  Future<void> deleteCollection(int id) async {
    final Database db = await database;
    await db.delete(
      'collections',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Возвращает количество коллекций.
  Future<int> getCollectionCount() async {
    final Database db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM collections',
    );
    return result.first['count'] as int;
  }

  // ==================== Collection Items ====================

  /// Возвращает все элементы в коллекции.
  Future<List<CollectionItem>> getCollectionItems(
    int collectionId, {
    MediaType? mediaType,
  }) async {
    final Database db = await database;
    String where = 'collection_id = ?';
    final List<Object?> whereArgs = <Object?>[collectionId];
    if (mediaType != null) {
      where += ' AND media_type = ?';
      whereArgs.add(mediaType.value);
    }
    final List<Map<String, dynamic>> rows = await db.query(
      'collection_items',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'added_at DESC',
    );
    return rows.map(CollectionItem.fromDb).toList();
  }

  /// Возвращает элементы коллекции с подгруженными данными.
  Future<List<CollectionItem>> getCollectionItemsWithData(
    int collectionId, {
    MediaType? mediaType,
  }) async {
    final List<CollectionItem> items = await getCollectionItems(
      collectionId,
      mediaType: mediaType,
    );
    if (items.isEmpty) return items;
    return _loadJoinedData(items);
  }

  /// Загружает связанные данные (Game, Movie, TvShow, Platform) для элементов.
  Future<List<CollectionItem>> _loadJoinedData(
    List<CollectionItem> items,
  ) async {
    // Собираем ID по типам
    final List<int> gameIds = <int>[];
    final List<int> movieIds = <int>[];
    final List<int> tvShowIds = <int>[];
    final Set<int> platformIds = <int>{};

    for (final CollectionItem item in items) {
      switch (item.mediaType) {
        case MediaType.game:
          gameIds.add(item.externalId);
          if (item.platformId != null) {
            platformIds.add(item.platformId!);
          }
        case MediaType.movie:
          movieIds.add(item.externalId);
        case MediaType.tvShow:
          tvShowIds.add(item.externalId);
      }
    }

    // Загружаем данные параллельно
    final List<Game> games =
        gameIds.isNotEmpty ? await getGamesByIds(gameIds) : <Game>[];
    final List<Movie> movies =
        movieIds.isNotEmpty ? await getMoviesByTmdbIds(movieIds) : <Movie>[];
    final List<TvShow> tvShows = tvShowIds.isNotEmpty
        ? await getTvShowsByTmdbIds(tvShowIds)
        : <TvShow>[];

    // Загружаем платформы
    Map<int, Platform> platformsMap = <int, Platform>{};
    if (platformIds.isNotEmpty) {
      final Database db = await database;
      final String placeholders =
          List<String>.filled(platformIds.length, '?').join(',');
      final List<Map<String, dynamic>> platformRows = await db.query(
        'platforms',
        where: 'id IN ($placeholders)',
        whereArgs: platformIds.toList().cast<Object?>(),
      );
      platformsMap = <int, Platform>{
        for (final Map<String, dynamic> row in platformRows)
          row['id'] as int: Platform.fromDb(row),
      };
    }

    // Создаём карты для быстрого поиска
    final Map<int, Game> gamesMap = <int, Game>{
      for (final Game g in games) g.id: g,
    };
    final Map<int, Movie> moviesMap = <int, Movie>{
      for (final Movie m in movies) m.tmdbId: m,
    };
    final Map<int, TvShow> tvShowsMap = <int, TvShow>{
      for (final TvShow t in tvShows) t.tmdbId: t,
    };

    // Собираем результат
    return items.map((CollectionItem item) {
      switch (item.mediaType) {
        case MediaType.game:
          return item.copyWith(
            game: gamesMap[item.externalId],
            platform: item.platformId != null
                ? platformsMap[item.platformId]
                : null,
          );
        case MediaType.movie:
          return item.copyWith(movie: moviesMap[item.externalId]);
        case MediaType.tvShow:
          return item.copyWith(tvShow: tvShowsMap[item.externalId]);
      }
    }).toList();
  }

  /// Возвращает элемент коллекции по ID.
  Future<CollectionItem?> getCollectionItemById(int id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      'collection_items',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CollectionItem.fromDb(rows.first);
  }

  /// Добавляет элемент в коллекцию.
  ///
  /// Возвращает ID созданной записи или null при конфликте.
  Future<int?> addItemToCollection({
    required int collectionId,
    required MediaType mediaType,
    required int externalId,
    int? platformId,
    String? authorComment,
    ItemStatus status = ItemStatus.notStarted,
  }) async {
    final Database db = await database;
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    try {
      final int id = await db.insert(
        'collection_items',
        <String, dynamic>{
          'collection_id': collectionId,
          'media_type': mediaType.value,
          'external_id': externalId,
          'platform_id': platformId,
          'status': status.dbValue(mediaType),
          'author_comment': authorComment,
          'added_at': now,
        },
      );
      return id;
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        return null;
      }
      rethrow;
    }
  }

  /// Удаляет элемент из коллекции.
  Future<void> removeItemFromCollection(int id) async {
    final Database db = await database;
    await db.delete(
      'collection_items',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Обновляет статус элемента коллекции.
  Future<void> updateItemStatus(
    int id,
    ItemStatus status, {
    required MediaType mediaType,
  }) async {
    final Database db = await database;
    await db.update(
      'collection_items',
      <String, dynamic>{'status': status.dbValue(mediaType)},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Обновляет прогресс просмотра сериала.
  Future<void> updateItemProgress(
    int id, {
    int? currentSeason,
    int? currentEpisode,
  }) async {
    final Database db = await database;
    final Map<String, dynamic> data = <String, dynamic>{};
    if (currentSeason != null) {
      data['current_season'] = currentSeason;
    }
    if (currentEpisode != null) {
      data['current_episode'] = currentEpisode;
    }
    if (data.isEmpty) return;
    await db.update(
      'collection_items',
      data,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Обновляет комментарий автора элемента.
  Future<void> updateItemAuthorComment(int id, String? comment) async {
    final Database db = await database;
    await db.update(
      'collection_items',
      <String, dynamic>{'author_comment': comment},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Обновляет личный комментарий пользователя элемента.
  Future<void> updateItemUserComment(int id, String? comment) async {
    final Database db = await database;
    await db.update(
      'collection_items',
      <String, dynamic>{'user_comment': comment},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Возвращает количество элементов в коллекции.
  Future<int> getCollectionItemCount(
    int collectionId, {
    MediaType? mediaType,
  }) async {
    final Database db = await database;
    String sql =
        'SELECT COUNT(*) as count FROM collection_items WHERE collection_id = ?';
    final List<Object?> args = <Object?>[collectionId];
    if (mediaType != null) {
      sql += ' AND media_type = ?';
      args.add(mediaType.value);
    }
    final List<Map<String, dynamic>> result = await db.rawQuery(sql, args);
    return result.first['count'] as int;
  }

  /// Возвращает расширенную статистику по коллекции.
  Future<Map<String, int>> getCollectionItemStats(int collectionId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''SELECT media_type, status, COUNT(*) as count FROM collection_items
         WHERE collection_id = ?
         GROUP BY media_type, status''',
      <Object?>[collectionId],
    );

    final Map<String, int> stats = <String, int>{
      'total': 0,
      'completed': 0,
      'playing': 0,
      'inProgress': 0,
      'notStarted': 0,
      'dropped': 0,
      'planned': 0,
      'onHold': 0,
      'gameCount': 0,
      'movieCount': 0,
      'tvShowCount': 0,
    };

    for (final Map<String, dynamic> row in result) {
      final String status = row['status'] as String;
      final String type = row['media_type'] as String;
      final int count = row['count'] as int;
      stats['total'] = (stats['total'] ?? 0) + count;

      // Подсчёт по типам медиа
      switch (type) {
        case 'game':
          stats['gameCount'] = (stats['gameCount'] ?? 0) + count;
        case 'movie':
          stats['movieCount'] = (stats['movieCount'] ?? 0) + count;
        case 'tv_show':
          stats['tvShowCount'] = (stats['tvShowCount'] ?? 0) + count;
      }

      // Подсчёт по статусам
      switch (status) {
        case 'completed':
          stats['completed'] = (stats['completed'] ?? 0) + count;
        case 'playing':
          // Legacy: playing = inProgress для игр
          stats['playing'] = (stats['playing'] ?? 0) + count;
          stats['inProgress'] = (stats['inProgress'] ?? 0) + count;
        case 'in_progress':
          stats['inProgress'] = (stats['inProgress'] ?? 0) + count;
        case 'not_started':
          stats['notStarted'] = (stats['notStarted'] ?? 0) + count;
        case 'dropped':
          stats['dropped'] = (stats['dropped'] ?? 0) + count;
        case 'planned':
          stats['planned'] = (stats['planned'] ?? 0) + count;
        case 'on_hold':
          stats['onHold'] = (stats['onHold'] ?? 0) + count;
      }
    }

    return stats;
  }

  /// Удаляет все элементы из коллекции.
  Future<void> clearCollectionItems(int collectionId) async {
    final Database db = await database;
    await db.delete(
      'collection_items',
      where: 'collection_id = ?',
      whereArgs: <Object?>[collectionId],
    );
  }

  // ==================== Collection Games (Legacy) ====================

  /// Возвращает все игры в коллекции.
  ///
  /// Читает из collection_items с фильтром media_type='game'.
  Future<List<CollectionGame>> getCollectionGames(int collectionId) async {
    final List<CollectionItem> items = await getCollectionItems(
      collectionId,
      mediaType: MediaType.game,
    );
    return items
        .map(CollectionGame.fromCollectionItem)
        .toList();
  }

  /// Возвращает игры в коллекции с подгруженными данными.
  Future<List<CollectionGame>> getCollectionGamesWithData(
    int collectionId,
  ) async {
    final List<CollectionItem> items = await getCollectionItemsWithData(
      collectionId,
      mediaType: MediaType.game,
    );
    return items
        .map(CollectionGame.fromCollectionItem)
        .toList();
  }

  /// Возвращает запись игры в коллекции по ID.
  Future<CollectionGame?> getCollectionGameById(int id) async {
    final CollectionItem? item = await getCollectionItemById(id);
    if (item == null) return null;
    return CollectionGame.fromCollectionItem(item);
  }

  /// Добавляет игру в коллекцию.
  ///
  /// Делегирует в [addItemToCollection] с mediaType=game.
  Future<int?> addGameToCollection({
    required int collectionId,
    required int igdbId,
    required int platformId,
    String? authorComment,
  }) async {
    return addItemToCollection(
      collectionId: collectionId,
      mediaType: MediaType.game,
      externalId: igdbId,
      platformId: platformId,
      authorComment: authorComment,
    );
  }

  /// Удаляет игру из коллекции.
  Future<void> removeGameFromCollection(int id) async {
    await removeItemFromCollection(id);
  }

  /// Обновляет статус игры в коллекции.
  Future<void> updateGameStatus(int id, GameStatus status) async {
    await updateItemStatus(
      id,
      status.toItemStatus(),
      mediaType: MediaType.game,
    );
  }

  /// Обновляет комментарий автора.
  Future<void> updateAuthorComment(int id, String? comment) async {
    await updateItemAuthorComment(id, comment);
  }

  /// Обновляет личный комментарий пользователя.
  Future<void> updateUserComment(int id, String? comment) async {
    await updateItemUserComment(id, comment);
  }

  /// Возвращает количество игр в коллекции.
  Future<int> getCollectionGameCount(int collectionId) async {
    return getCollectionItemCount(collectionId, mediaType: MediaType.game);
  }

  /// Возвращает количество пройденных игр в коллекции.
  Future<int> getCompletedGameCount(int collectionId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''SELECT COUNT(*) as count FROM collection_items
         WHERE collection_id = ? AND status = ?''',
      <Object?>[collectionId, 'completed'],
    );
    return result.first['count'] as int;
  }

  /// Возвращает статистику по коллекции.
  ///
  /// Обёртка над [getCollectionItemStats] для обратной совместимости.
  Future<Map<String, int>> getCollectionStats(int collectionId) async {
    return getCollectionItemStats(collectionId);
  }

  /// Удаляет все игры из коллекции.
  Future<void> clearCollectionGames(int collectionId) async {
    final Database db = await database;
    await db.delete(
      'collection_items',
      where: 'collection_id = ? AND media_type = ?',
      whereArgs: <Object?>[collectionId, MediaType.game.value],
    );
  }

  // ==================== Canvas Items ====================

  /// Возвращает все элементы канваса для коллекции.
  Future<List<Map<String, dynamic>>> getCanvasItems(int collectionId) async {
    final Database db = await database;
    return db.query(
      'canvas_items',
      where: 'collection_id = ?',
      whereArgs: <Object?>[collectionId],
      orderBy: 'z_index ASC',
    );
  }

  /// Вставляет элемент канваса и возвращает его ID.
  Future<int> insertCanvasItem(Map<String, dynamic> data) async {
    final Database db = await database;
    return db.insert('canvas_items', data);
  }

  /// Обновляет элемент канваса по ID.
  Future<void> updateCanvasItem(int id, Map<String, dynamic> data) async {
    final Database db = await database;
    await db.update(
      'canvas_items',
      data,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Удаляет элемент канваса по ID.
  Future<void> deleteCanvasItem(int id) async {
    final Database db = await database;
    await db.delete(
      'canvas_items',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Удаляет элемент канваса по типу и ID связанного объекта.
  Future<void> deleteCanvasItemByRef(
    int collectionId,
    String itemType,
    int itemRefId,
  ) async {
    final Database db = await database;
    await db.delete(
      'canvas_items',
      where: 'collection_id = ? AND item_type = ? AND item_ref_id = ?',
      whereArgs: <Object?>[collectionId, itemType, itemRefId],
    );
  }

  /// Удаляет все элементы канваса для коллекции.
  Future<void> deleteCanvasItemsByCollection(int collectionId) async {
    final Database db = await database;
    await db.delete(
      'canvas_items',
      where: 'collection_id = ?',
      whereArgs: <Object?>[collectionId],
    );
  }

  /// Возвращает количество элементов канваса для коллекции.
  Future<int> getCanvasItemCount(int collectionId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM canvas_items WHERE collection_id = ?',
      <Object?>[collectionId],
    );
    return result.first['count'] as int;
  }

  // ==================== Canvas Viewport ====================

  /// Возвращает состояние viewport канваса для коллекции.
  Future<Map<String, dynamic>?> getCanvasViewport(int collectionId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      'canvas_viewport',
      where: 'collection_id = ?',
      whereArgs: <Object?>[collectionId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Сохраняет или обновляет состояние viewport канваса.
  Future<void> upsertCanvasViewport({
    required int collectionId,
    required double scale,
    required double offsetX,
    required double offsetY,
  }) async {
    final Database db = await database;
    await db.insert(
      'canvas_viewport',
      <String, dynamic>{
        'collection_id': collectionId,
        'scale': scale,
        'offset_x': offsetX,
        'offset_y': offsetY,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==================== Canvas Connections ====================

  /// Возвращает все связи канваса для коллекции.
  Future<List<Map<String, dynamic>>> getCanvasConnections(
    int collectionId,
  ) async {
    final Database db = await database;
    return db.query(
      'canvas_connections',
      where: 'collection_id = ?',
      whereArgs: <Object?>[collectionId],
    );
  }

  /// Вставляет связь канваса и возвращает её ID.
  Future<int> insertCanvasConnection(Map<String, dynamic> data) async {
    final Database db = await database;
    return db.insert('canvas_connections', data);
  }

  /// Обновляет связь канваса по ID.
  Future<void> updateCanvasConnection(
    int id,
    Map<String, dynamic> data,
  ) async {
    final Database db = await database;
    await db.update(
      'canvas_connections',
      data,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Удаляет связь канваса по ID.
  Future<void> deleteCanvasConnection(int id) async {
    final Database db = await database;
    await db.delete(
      'canvas_connections',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Удаляет все связи канваса для коллекции.
  Future<void> deleteCanvasConnectionsByCollection(int collectionId) async {
    final Database db = await database;
    await db.delete(
      'canvas_connections',
      where: 'collection_id = ?',
      whereArgs: <Object?>[collectionId],
    );
  }

  /// Закрывает соединение с базой данных.
  Future<void> close() async {
    final Database? db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
