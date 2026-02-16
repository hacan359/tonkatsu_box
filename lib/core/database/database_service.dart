import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../shared/models/collected_item_info.dart';
import '../../shared/models/collection.dart';
import '../../shared/models/collection_item.dart';
import '../../shared/models/game.dart';
import '../../shared/models/item_status.dart';
import '../../shared/models/media_type.dart';
import '../../shared/models/movie.dart';
import '../../shared/models/platform.dart';
import '../../shared/models/tv_episode.dart';
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
    final String dbDir = p.join(appDir.path, 'tonkatsu_box');
    final String dbPath = p.join(dbDir, 'tonkatsu_box.db');

    // Создаём директорию, если не существует
    final Directory dir = Directory(dbDir);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    return databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 14,
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
    await _createCanvasItemsTable(db);
    await _createCanvasViewportTable(db);
    await _createCanvasConnectionsTable(db);
    await _createGameCanvasViewportTable(db);
    await _createMoviesCacheTable(db);
    await _createTvShowsCacheTable(db);
    await _createTvSeasonsCacheTable(db);
    await _createCollectionItemsTable(db);
    await _createTvEpisodesCacheTable(db);
    await _createWatchedEpisodesTable(db);
    await _createTmdbGenresTable(db);
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

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createGamesTable(db);
    }
    if (oldVersion < 3) {
      await _createCollectionsTable(db);
      // Inline SQL — метод _createCollectionGamesTable удалён,
      // но таблица нужна для миграции v8 (collection_games → collection_items)
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
      await db.execute('''
        CREATE INDEX idx_collection_games_collection
        ON collection_games(collection_id)
      ''');
      await db.execute('''
        CREATE INDEX idx_collection_games_igdb
        ON collection_games(igdb_id)
      ''');
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
    if (oldVersion < 9) {
      await _migrateGameCanvas(db);
    }
    if (oldVersion < 10) {
      await _createTvEpisodesCacheTable(db);
      await _createWatchedEpisodesTable(db);
    }
    if (oldVersion < 11) {
      // sort_order для ручной сортировки элементов коллекции
      await db.execute(
        'ALTER TABLE collection_items '
        'ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0',
      );
      // Присвоить начальные значения по текущему порядку added_at DESC
      await db.execute('''
        UPDATE collection_items SET sort_order = (
          SELECT COUNT(*) FROM collection_items AS ci2
          WHERE ci2.collection_id = collection_items.collection_id
            AND ci2.added_at > collection_items.added_at
        )
      ''');
    }
    if (oldVersion < 12) {
      // Даты активности элементов коллекции
      await db.execute(
        'ALTER TABLE collection_items ADD COLUMN started_at INTEGER',
      );
      await db.execute(
        'ALTER TABLE collection_items ADD COLUMN completed_at INTEGER',
      );
      await db.execute(
        'ALTER TABLE collection_items ADD COLUMN last_activity_at INTEGER',
      );
      // Инициализируем last_activity_at из added_at для существующих записей
      await db.execute(
        'UPDATE collection_items SET last_activity_at = added_at',
      );
    }
    if (oldVersion < 13) {
      await _createTmdbGenresTable(db);
    }
    if (oldVersion < 14) {
      // Миграция: 'playing' → 'in_progress' для единообразия статусов
      await db.execute(
        "UPDATE collection_items SET status = 'in_progress' "
        "WHERE status = 'playing'",
      );
    }
  }

  Future<void> _migrateGameCanvas(Database db) async {
    // Добавляем collection_item_id в canvas_items
    await db.execute(
      'ALTER TABLE canvas_items ADD COLUMN collection_item_id INTEGER',
    );
    await db.execute('''
      CREATE INDEX idx_canvas_items_collection_item
      ON canvas_items(collection_item_id)
    ''');

    // Добавляем collection_item_id в canvas_connections
    await db.execute(
      'ALTER TABLE canvas_connections '
      'ADD COLUMN collection_item_id INTEGER',
    );
    await db.execute('''
      CREATE INDEX idx_canvas_connections_collection_item
      ON canvas_connections(collection_item_id)
    ''');

    // Создаём таблицу viewport для per-game canvas
    await _createGameCanvasViewportTable(db);
  }

  Future<void> _createTvEpisodesCacheTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tv_episodes_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tmdb_show_id INTEGER NOT NULL,
        season_number INTEGER NOT NULL,
        episode_number INTEGER NOT NULL,
        name TEXT,
        overview TEXT,
        air_date TEXT,
        still_url TEXT,
        runtime INTEGER,
        cached_at INTEGER,
        UNIQUE(tmdb_show_id, season_number, episode_number)
      )
    ''');
  }

  Future<void> _createWatchedEpisodesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS watched_episodes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        collection_id INTEGER NOT NULL,
        show_id INTEGER NOT NULL,
        season_number INTEGER NOT NULL,
        episode_number INTEGER NOT NULL,
        watched_at INTEGER,
        FOREIGN KEY (collection_id) REFERENCES collections(id)
          ON DELETE CASCADE,
        UNIQUE(collection_id, show_id, season_number, episode_number)
      )
    ''');
  }

  Future<void> _createCanvasItemsTable(Database db) async {
    await db.execute('''
      CREATE TABLE canvas_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        collection_id INTEGER NOT NULL,
        collection_item_id INTEGER,
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

    await db.execute('''
      CREATE INDEX idx_canvas_items_collection_item
      ON canvas_items(collection_item_id)
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

  Future<void> _createGameCanvasViewportTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS game_canvas_viewport (
        collection_item_id INTEGER PRIMARY KEY,
        scale REAL NOT NULL DEFAULT 1.0,
        offset_x REAL NOT NULL DEFAULT 0.0,
        offset_y REAL NOT NULL DEFAULT 0.0
      )
    ''');
  }

  Future<void> _createCanvasConnectionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE canvas_connections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        collection_id INTEGER NOT NULL,
        collection_item_id INTEGER,
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

    await db.execute('''
      CREATE INDEX idx_canvas_connections_collection_item
      ON canvas_connections(collection_item_id)
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
        sort_order INTEGER NOT NULL DEFAULT 0,
        started_at INTEGER,
        completed_at INTEGER,
        last_activity_at INTEGER,
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

  Future<void> _createTmdbGenresTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tmdb_genres (
        id INTEGER NOT NULL,
        type TEXT NOT NULL,
        name TEXT NOT NULL,
        PRIMARY KEY (id, type)
      )
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

  // ===== TMDB Жанры =====

  /// Сохраняет список жанров TMDB в кэш.
  ///
  /// [type] — тип медиа: `'movie'` или `'tv'`.
  Future<void> cacheTmdbGenres(
    String type,
    List<Map<String, dynamic>> genres,
  ) async {
    if (genres.isEmpty) return;

    final Database db = await database;
    await db.transaction((Transaction txn) async {
      // Удаляем старые записи этого типа
      await txn.delete(
        'tmdb_genres',
        where: 'type = ?',
        whereArgs: <Object?>[type],
      );
      final Batch batch = txn.batch();
      for (final Map<String, dynamic> genre in genres) {
        batch.insert('tmdb_genres', <String, Object?>{
          'id': genre['id'],
          'type': type,
          'name': genre['name'],
        });
      }
      await batch.commit(noResult: true);
    });
  }

  /// Возвращает маппинг ID → имя жанров из кэша.
  ///
  /// [type] — тип медиа: `'movie'` или `'tv'`.
  Future<Map<String, String>> getTmdbGenreMap(String type) async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      'tmdb_genres',
      where: 'type = ?',
      whereArgs: <Object?>[type],
    );

    return <String, String>{
      for (final Map<String, dynamic> row in rows)
        (row['id'] as int).toString(): row['name'] as String,
    };
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

  // ==================== TV Episodes Cache ====================

  /// Возвращает все эпизоды сериала из кеша.
  Future<List<TvEpisode>> getEpisodesByShowId(int showId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      'tv_episodes_cache',
      where: 'tmdb_show_id = ?',
      whereArgs: <Object?>[showId],
      orderBy: 'season_number ASC, episode_number ASC',
    );
    return rows.map(TvEpisode.fromDb).toList();
  }

  /// Возвращает эпизоды сезона сериала из кеша.
  Future<List<TvEpisode>> getEpisodesByShowAndSeason(
    int showId,
    int seasonNumber,
  ) async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      'tv_episodes_cache',
      where: 'tmdb_show_id = ? AND season_number = ?',
      whereArgs: <Object?>[showId, seasonNumber],
      orderBy: 'episode_number ASC',
    );
    return rows.map(TvEpisode.fromDb).toList();
  }

  /// Сохраняет список эпизодов пакетно (INSERT OR REPLACE).
  Future<void> upsertEpisodes(List<TvEpisode> episodes) async {
    if (episodes.isEmpty) return;

    final Database db = await database;
    await db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();
      for (final TvEpisode episode in episodes) {
        batch.insert(
          'tv_episodes_cache',
          episode.toDb(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Удаляет кешированные эпизоды сериала.
  Future<void> clearEpisodesByShow(int showId) async {
    final Database db = await database;
    await db.delete(
      'tv_episodes_cache',
      where: 'tmdb_show_id = ?',
      whereArgs: <Object?>[showId],
    );
  }

  // ==================== Watched Episodes ====================

  /// Возвращает множество просмотренных эпизодов для сериала в коллекции.
  ///
  /// Возвращает Set записей (seasonNumber, episodeNumber).
  Future<Map<(int, int), DateTime?>> getWatchedEpisodes(
    int collectionId,
    int showId,
  ) async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      'watched_episodes',
      columns: <String>['season_number', 'episode_number', 'watched_at'],
      where: 'collection_id = ? AND show_id = ?',
      whereArgs: <Object?>[collectionId, showId],
    );
    final Map<(int, int), DateTime?> result = <(int, int), DateTime?>{};
    for (final Map<String, dynamic> row in rows) {
      final int? watchedAtMs = row['watched_at'] as int?;
      result[(
        row['season_number'] as int,
        row['episode_number'] as int,
      )] = watchedAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(watchedAtMs)
          : null;
    }
    return result;
  }

  /// Отмечает эпизод как просмотренный.
  Future<void> markEpisodeWatched(
    int collectionId,
    int showId,
    int seasonNumber,
    int episodeNumber,
  ) async {
    final Database db = await database;
    await db.insert(
      'watched_episodes',
      <String, dynamic>{
        'collection_id': collectionId,
        'show_id': showId,
        'season_number': seasonNumber,
        'episode_number': episodeNumber,
        'watched_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Снимает отметку просмотра с эпизода.
  Future<void> markEpisodeUnwatched(
    int collectionId,
    int showId,
    int seasonNumber,
    int episodeNumber,
  ) async {
    final Database db = await database;
    await db.delete(
      'watched_episodes',
      where: 'collection_id = ? AND show_id = ? '
          'AND season_number = ? AND episode_number = ?',
      whereArgs: <Object?>[collectionId, showId, seasonNumber, episodeNumber],
    );
  }

  /// Возвращает количество просмотренных эпизодов для сериала в коллекции.
  Future<int> getWatchedEpisodeCount(
    int collectionId,
    int showId,
  ) async {
    final Database db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM watched_episodes '
      'WHERE collection_id = ? AND show_id = ?',
      <Object?>[collectionId, showId],
    );
    return result.first['cnt'] as int;
  }

  /// Отмечает все эпизоды сезона как просмотренные.
  Future<void> markSeasonWatched(
    int collectionId,
    int showId,
    int seasonNumber,
    List<int> episodeNumbers,
  ) async {
    if (episodeNumbers.isEmpty) return;

    final Database db = await database;
    final int now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((Transaction txn) async {
      final Batch batch = txn.batch();
      for (final int ep in episodeNumbers) {
        batch.insert(
          'watched_episodes',
          <String, dynamic>{
            'collection_id': collectionId,
            'show_id': showId,
            'season_number': seasonNumber,
            'episode_number': ep,
            'watched_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Снимает отметку просмотра со всех эпизодов сезона.
  Future<void> unmarkSeasonWatched(
    int collectionId,
    int showId,
    int seasonNumber,
  ) async {
    final Database db = await database;
    await db.delete(
      'watched_episodes',
      where: 'collection_id = ? AND show_id = ? AND season_number = ?',
      whereArgs: <Object?>[collectionId, showId, seasonNumber],
    );
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
      orderBy: 'sort_order ASC',
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
        case MediaType.animation:
          if (item.platformId == AnimationSource.tvShow) {
            tvShowIds.add(item.externalId);
          } else {
            movieIds.add(item.externalId);
          }
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

    // Резолвим жанры из числовых ID в имена (если есть нерезолвленные)
    final List<Movie> resolvedMovies = await _resolveGenresIfNeeded(
      movies,
      'movie',
      (Movie m) => m.genres,
      (Movie m, List<String> g) => m.copyWith(genres: g),
    );
    final List<TvShow> resolvedTvShows = await _resolveGenresIfNeeded(
      tvShows,
      'tv',
      (TvShow t) => t.genres,
      (TvShow t, List<String> g) => t.copyWith(genres: g),
    );

    // Создаём карты для быстрого поиска
    final Map<int, Game> gamesMap = <int, Game>{
      for (final Game g in games) g.id: g,
    };
    final Map<int, Movie> moviesMap = <int, Movie>{
      for (final Movie m in resolvedMovies) m.tmdbId: m,
    };
    final Map<int, TvShow> tvShowsMap = <int, TvShow>{
      for (final TvShow t in resolvedTvShows) t.tmdbId: t,
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
        case MediaType.animation:
          if (item.platformId == AnimationSource.tvShow) {
            return item.copyWith(tvShow: tvShowsMap[item.externalId]);
          }
          return item.copyWith(movie: moviesMap[item.externalId]);
      }
    }).toList();
  }

  /// Проверяет, является ли строка числовым ID (нерезолвленный жанр).
  static bool _isNumericGenre(String genre) {
    return int.tryParse(genre) != null;
  }

  /// Резолвит числовые genre_ids в имена для списка медиа-элементов.
  ///
  /// Проверяет жанры каждого элемента: если хотя бы один жанр — числовой ID,
  /// загружает маппинг из кэша `tmdb_genres` и заменяет ID на имена.
  /// Если кэш пуст или нет нерезолвленных жанров, возвращает исходный список.
  Future<List<T>> _resolveGenresIfNeeded<T>(
    List<T> items,
    String genreType,
    List<String>? Function(T item) getGenres,
    T Function(T item, List<String> genres) withGenres,
  ) async {
    if (items.isEmpty) return items;

    // Проверяем, есть ли нерезолвленные жанры (числовые ID)
    final bool hasUnresolved = items.any((T item) {
      final List<String>? genres = getGenres(item);
      return genres != null && genres.any(_isNumericGenre);
    });
    if (!hasUnresolved) return items;

    // Загружаем маппинг из кэша
    final Map<String, String> genreMap = await getTmdbGenreMap(genreType);
    if (genreMap.isEmpty) return items;

    return items.map((T item) {
      final List<String>? genres = getGenres(item);
      if (genres == null || genres.isEmpty) return item;
      if (!genres.any(_isNumericGenre)) return item;

      final List<String> resolved =
          genres.map((String g) => genreMap[g] ?? g).toList();
      return withGenres(item, resolved);
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
      final int sortOrder = await getNextSortOrder(collectionId);
      final int id = await db.insert(
        'collection_items',
        <String, dynamic>{
          'collection_id': collectionId,
          'media_type': mediaType.value,
          'external_id': externalId,
          'platform_id': platformId,
          'status': status.value,
          'author_comment': authorComment,
          'added_at': now,
          'sort_order': sortOrder,
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

  /// Возвращает следующий sort_order для коллекции.
  Future<int> getNextSortOrder(int collectionId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT MAX(sort_order) AS max_sort FROM collection_items '
      'WHERE collection_id = ?',
      <Object?>[collectionId],
    );
    final int maxSort = (result.first['max_sort'] as int?) ?? -1;
    return maxSort + 1;
  }

  /// Пересортировывает элементы коллекции после drag-and-drop.
  ///
  /// Обновляет sort_order всех элементов в транзакции.
  Future<void> reorderItems(
    int collectionId,
    List<int> orderedItemIds,
  ) async {
    final Database db = await database;
    await db.transaction((Transaction txn) async {
      for (int i = 0; i < orderedItemIds.length; i++) {
        await txn.update(
          'collection_items',
          <String, dynamic>{'sort_order': i},
          where: 'id = ?',
          whereArgs: <Object?>[orderedItemIds[i]],
        );
      }
    });
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
  ///
  /// Автоматически устанавливает даты активности:
  /// - `last_activity_at` обновляется всегда
  /// - `started_at` устанавливается при переходе в inProgress (если null)
  /// - `completed_at` устанавливается при переходе в completed
  Future<void> updateItemStatus(
    int id,
    ItemStatus status, {
    required MediaType mediaType,
  }) async {
    final Database db = await database;
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final Map<String, dynamic> updateData = <String, dynamic>{
      'status': status.value,
      'last_activity_at': now,
    };

    // Получаем текущий элемент для проверки дат
    final List<Map<String, dynamic>> rows = await db.query(
      'collection_items',
      columns: <String>['started_at'],
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );

    final bool hasStartedAt =
        rows.isNotEmpty && rows.first['started_at'] != null;

    if (status == ItemStatus.inProgress && !hasStartedAt) {
      updateData['started_at'] = now;
    }
    if (status == ItemStatus.completed) {
      updateData['completed_at'] = now;
      if (!hasStartedAt) {
        updateData['started_at'] = now;
      }
    }

    await db.update(
      'collection_items',
      updateData,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Обновляет даты активности элемента коллекции вручную.
  Future<void> updateItemActivityDates(
    int id, {
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? lastActivityAt,
  }) async {
    final Database db = await database;
    final Map<String, dynamic> data = <String, dynamic>{};
    if (startedAt != null) {
      data['started_at'] = startedAt.millisecondsSinceEpoch ~/ 1000;
    }
    if (completedAt != null) {
      data['completed_at'] = completedAt.millisecondsSinceEpoch ~/ 1000;
    }
    if (lastActivityAt != null) {
      data['last_activity_at'] =
          lastActivityAt.millisecondsSinceEpoch ~/ 1000;
    }
    if (data.isEmpty) return;
    await db.update(
      'collection_items',
      data,
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
      'inProgress': 0,
      'notStarted': 0,
      'dropped': 0,
      'planned': 0,
      'onHold': 0,
      'gameCount': 0,
      'movieCount': 0,
      'tvShowCount': 0,
      'animationCount': 0,
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
        case 'animation':
          stats['animationCount'] = (stats['animationCount'] ?? 0) + count;
      }

      // Подсчёт по статусам
      switch (status) {
        case 'completed':
          stats['completed'] = (stats['completed'] ?? 0) + count;
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

  // ==================== Canvas Items ====================

  /// Возвращает все элементы канваса для коллекции.
  Future<List<Map<String, dynamic>>> getCanvasItems(int collectionId) async {
    final Database db = await database;
    return db.query(
      'canvas_items',
      where: 'collection_id = ? AND collection_item_id IS NULL',
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
      where: 'collection_id = ? AND item_type = ? AND item_ref_id = ?'
          ' AND collection_item_id IS NULL',
      whereArgs: <Object?>[collectionId, itemType, itemRefId],
    );
  }

  /// Удаляет все элементы канваса коллекции (без per-item элементов).
  Future<void> deleteCanvasItemsByCollection(int collectionId) async {
    final Database db = await database;
    await db.delete(
      'canvas_items',
      where: 'collection_id = ? AND collection_item_id IS NULL',
      whereArgs: <Object?>[collectionId],
    );
  }

  /// Возвращает количество элементов канваса для коллекции.
  Future<int> getCanvasItemCount(int collectionId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM canvas_items'
          ' WHERE collection_id = ? AND collection_item_id IS NULL',
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

  /// Возвращает связи канваса коллекции (без per-item связей).
  Future<List<Map<String, dynamic>>> getCanvasConnections(
    int collectionId,
  ) async {
    final Database db = await database;
    return db.query(
      'canvas_connections',
      where: 'collection_id = ? AND collection_item_id IS NULL',
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

  /// Удаляет связи канваса коллекции (без per-item связей).
  Future<void> deleteCanvasConnectionsByCollection(int collectionId) async {
    final Database db = await database;
    await db.delete(
      'canvas_connections',
      where: 'collection_id = ? AND collection_item_id IS NULL',
      whereArgs: <Object?>[collectionId],
    );
  }

  // ==================== Game Canvas ====================

  /// Возвращает элементы game canvas по ID элемента коллекции.
  Future<List<Map<String, dynamic>>> getGameCanvasItems(
    int collectionItemId,
  ) async {
    final Database db = await database;
    return db.query(
      'canvas_items',
      where: 'collection_item_id = ?',
      whereArgs: <Object?>[collectionItemId],
    );
  }

  /// Возвращает количество элементов game canvas.
  Future<int> getGameCanvasItemCount(int collectionItemId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM canvas_items '
      'WHERE collection_item_id = ?',
      <Object?>[collectionItemId],
    );
    return result.first['cnt'] as int;
  }

  /// Возвращает связи game canvas.
  Future<List<Map<String, dynamic>>> getGameCanvasConnections(
    int collectionItemId,
  ) async {
    final Database db = await database;
    return db.query(
      'canvas_connections',
      where: 'collection_item_id = ?',
      whereArgs: <Object?>[collectionItemId],
    );
  }

  /// Возвращает viewport для game canvas.
  Future<Map<String, dynamic>?> getGameCanvasViewport(
    int collectionItemId,
  ) async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      'game_canvas_viewport',
      where: 'collection_item_id = ?',
      whereArgs: <Object?>[collectionItemId],
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Сохраняет или обновляет viewport для game canvas.
  Future<void> upsertGameCanvasViewport({
    required int collectionItemId,
    required double scale,
    required double offsetX,
    required double offsetY,
  }) async {
    final Database db = await database;
    await db.execute(
      'INSERT OR REPLACE INTO game_canvas_viewport '
      '(collection_item_id, scale, offset_x, offset_y) '
      'VALUES (?, ?, ?, ?)',
      <Object?>[collectionItemId, scale, offsetX, offsetY],
    );
  }

  /// Удаляет все элементы game canvas по collection_item_id.
  Future<void> deleteGameCanvasItems(int collectionItemId) async {
    final Database db = await database;
    await db.delete(
      'canvas_items',
      where: 'collection_item_id = ?',
      whereArgs: <Object?>[collectionItemId],
    );
  }

  /// Удаляет все связи game canvas по collection_item_id.
  Future<void> deleteGameCanvasConnections(int collectionItemId) async {
    final Database db = await database;
    await db.delete(
      'canvas_connections',
      where: 'collection_item_id = ?',
      whereArgs: <Object?>[collectionItemId],
    );
  }

  /// Удаляет viewport game canvas.
  Future<void> deleteGameCanvasViewport(int collectionItemId) async {
    final Database db = await database;
    await db.delete(
      'game_canvas_viewport',
      where: 'collection_item_id = ?',
      whereArgs: <Object?>[collectionItemId],
    );
  }

  /// Возвращает информацию о нахождении элементов заданного типа в коллекциях.
  ///
  /// Результат: `Map` external_id -> список записей в коллекциях.
  Future<Map<int, List<CollectedItemInfo>>> getCollectedItemInfos(
    MediaType mediaType,
  ) async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.rawQuery('''
      SELECT ci.id, ci.external_id, ci.collection_id, c.name
      FROM collection_items ci
      JOIN collections c ON c.id = ci.collection_id
      WHERE ci.media_type = ?
      ORDER BY ci.added_at ASC
    ''', <Object?>[mediaType.value]);

    final Map<int, List<CollectedItemInfo>> result =
        <int, List<CollectedItemInfo>>{};
    for (final Map<String, dynamic> row in rows) {
      final int externalId = row['external_id'] as int;
      final CollectedItemInfo info = CollectedItemInfo(
        recordId: row['id'] as int,
        collectionId: row['collection_id'] as int,
        collectionName: row['name'] as String,
      );
      result.putIfAbsent(externalId, () => <CollectedItemInfo>[]).add(info);
    }
    return result;
  }

  /// Очищает все данные из базы данных.
  ///
  /// Удаляет содержимое всех 14 таблиц в одной транзакции.
  /// Сначала зависимые таблицы (FK), затем основные.
  /// Настройки (SharedPreferences) не затрагиваются.
  Future<void> clearAllData() async {
    final Database db = await database;
    await db.transaction((Transaction txn) async {
      // Зависимые таблицы (FK CASCADE)
      await txn.delete('watched_episodes');
      await txn.delete('canvas_connections');
      await txn.delete('canvas_items');
      await txn.delete('canvas_viewport');
      await txn.delete('game_canvas_viewport');
      await txn.delete('collection_items');
      // Основные таблицы
      await txn.delete('collections');
      await txn.delete('tv_episodes_cache');
      await txn.delete('tv_seasons_cache');
      await txn.delete('tv_shows_cache');
      await txn.delete('movies_cache');
      await txn.delete('games');
      await txn.delete('platforms');
    });
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
