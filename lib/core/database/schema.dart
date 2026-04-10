// Определения таблиц базы данных.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Схема базы данных — статические методы для создания всех таблиц.
abstract final class DatabaseSchema {
  /// Создаёт все таблицы БД (вызывается при первой инициализации).
  static Future<void> createAll(Database db) async {
    await createPlatformsTable(db);
    await createGamesTable(db);
    await createCollectionsTable(db);
    await createCanvasItemsTable(db);
    await createCanvasViewportTable(db);
    await createCanvasConnectionsTable(db);
    await createGameCanvasViewportTable(db);
    await createMoviesCacheTable(db);
    await createTvShowsCacheTable(db);
    await createTvSeasonsCacheTable(db);
    await createCollectionItemsTable(db);
    await createTvEpisodesCacheTable(db);
    await createWatchedEpisodesTable(db);
    await createTmdbGenresTable(db);
    await createWishlistTable(db);
    await createIgdbGenresTable(db);
    await createVisualNovelsCacheTable(db);
    await createVndbTagsTable(db);
    await createMangaCacheTable(db);
    await createTierListsTable(db);
    await createTierDefinitionsTable(db);
    await createTierListEntriesTable(db);
    await createCustomItemsTable(db);
    await createCollectionTagsTable(db);
    await createTrackerProfilesTable(db);
    await createTrackerGameDataTable(db);
    await createTrackerAchievementsTable(db);
    await createAnimeCacheTable(db);
  }

  /// Таблица платформ (IGDB).
  static Future<void> createPlatformsTable(Database db) async {
    await db.execute('''
      CREATE TABLE platforms (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        abbreviation TEXT
      )
    ''');
  }

  /// Таблица игр (кэш IGDB).
  static Future<void> createGamesTable(Database db) async {
    await db.execute('''
      CREATE TABLE games (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        summary TEXT,
        cover_url TEXT,
        artwork_url TEXT,
        release_date INTEGER,
        rating REAL,
        rating_count INTEGER,
        genres TEXT,
        platform_ids TEXT,
        external_url TEXT,
        cached_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_games_name ON games(name)
    ''');
  }

  /// Таблица коллекций.
  static Future<void> createCollectionsTable(Database db) async {
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

  /// Таблица элементов канваса.
  static Future<void> createCanvasItemsTable(Database db) async {
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

  /// Таблица viewport канваса коллекции.
  static Future<void> createCanvasViewportTable(Database db) async {
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

  /// Таблица viewport канваса отдельного элемента.
  static Future<void> createGameCanvasViewportTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS game_canvas_viewport (
        collection_item_id INTEGER PRIMARY KEY,
        scale REAL NOT NULL DEFAULT 1.0,
        offset_x REAL NOT NULL DEFAULT 0.0,
        offset_y REAL NOT NULL DEFAULT 0.0
      )
    ''');
  }

  /// Таблица связей канваса.
  static Future<void> createCanvasConnectionsTable(Database db) async {
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

  /// Таблица кэша фильмов (TMDB).
  static Future<void> createMoviesCacheTable(Database db) async {
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
        external_url TEXT,
        cached_at INTEGER
      )
    ''');
  }

  /// Таблица кэша сериалов (TMDB).
  static Future<void> createTvShowsCacheTable(Database db) async {
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
        external_url TEXT,
        cached_at INTEGER
      )
    ''');
  }

  /// Таблица кэша сезонов (TMDB).
  static Future<void> createTvSeasonsCacheTable(Database db) async {
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

  /// Таблица элементов коллекции (универсальная).
  static Future<void> createCollectionItemsTable(Database db) async {
    await db.execute('''
      CREATE TABLE collection_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        collection_id INTEGER,
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
        user_rating INTEGER,
        tag_id INTEGER,
        FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES collection_tags(id) ON DELETE SET NULL
      )
    ''');

    // Игры: unique с platform_id (одна игра на разных платформах разрешена).
    await db.execute('''
      CREATE UNIQUE INDEX idx_ci_coll_game
      ON collection_items(collection_id, media_type, external_id, platform_id)
      WHERE collection_id IS NOT NULL AND media_type = 'game'
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX idx_ci_coll_other
      ON collection_items(collection_id, media_type, external_id)
      WHERE collection_id IS NOT NULL AND media_type != 'game'
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX idx_ci_uncat_game
      ON collection_items(media_type, external_id, platform_id)
      WHERE collection_id IS NULL AND media_type = 'game'
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX idx_ci_uncat_other
      ON collection_items(media_type, external_id)
      WHERE collection_id IS NULL AND media_type != 'game'
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

  /// Таблица кэша эпизодов (TMDB).
  static Future<void> createTvEpisodesCacheTable(Database db) async {
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

  /// Таблица просмотренных эпизодов.
  static Future<void> createWatchedEpisodesTable(Database db) async {
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

  /// Таблица жанров TMDB.
  static Future<void> createTmdbGenresTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tmdb_genres (
        id INTEGER NOT NULL,
        type TEXT NOT NULL,
        lang TEXT NOT NULL DEFAULT 'en',
        name TEXT NOT NULL,
        PRIMARY KEY (id, type, lang)
      )
    ''');
  }

  /// Таблица списка желаний.
  static Future<void> createWishlistTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS wishlist (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        media_type_hint TEXT,
        note TEXT,
        is_resolved INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        resolved_at INTEGER
      )
    ''');
  }

  /// Таблица жанров IGDB.
  static Future<void> createIgdbGenresTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS igdb_genres (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');
  }

  /// Таблица кэша визуальных новелл (VNDB).
  static Future<void> createVisualNovelsCacheTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS visual_novels_cache (
        id TEXT PRIMARY KEY,
        numeric_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        alt_title TEXT,
        description TEXT,
        image_url TEXT,
        rating REAL,
        vote_count INTEGER,
        released TEXT,
        length_minutes INTEGER,
        length INTEGER,
        tags TEXT,
        developers TEXT,
        platforms TEXT,
        external_url TEXT,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_vn_numeric_id
      ON visual_novels_cache(numeric_id)
    ''');
  }

  /// Таблица тегов VNDB.
  static Future<void> createVndbTagsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vndb_tags (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');
  }

  /// Таблица кэша манги (AniList).
  static Future<void> createMangaCacheTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS manga_cache (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        title_english TEXT,
        title_native TEXT,
        description TEXT,
        cover_url TEXT,
        cover_url_medium TEXT,
        average_score INTEGER,
        mean_score INTEGER,
        popularity INTEGER,
        status TEXT,
        start_year INTEGER,
        start_month INTEGER,
        start_day INTEGER,
        chapters INTEGER,
        volumes INTEGER,
        format TEXT,
        country_of_origin TEXT,
        genres TEXT,
        authors TEXT,
        external_url TEXT,
        banner_url TEXT,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  /// Таблица кэша аниме (AniList).
  static Future<void> createAnimeCacheTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS anime_cache (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        title_english TEXT,
        title_native TEXT,
        description TEXT,
        cover_url TEXT,
        cover_url_medium TEXT,
        banner_url TEXT,
        average_score INTEGER,
        mean_score INTEGER,
        popularity INTEGER,
        status TEXT,
        season TEXT,
        season_year INTEGER,
        start_year INTEGER,
        start_month INTEGER,
        start_day INTEGER,
        episodes INTEGER,
        duration INTEGER,
        format TEXT,
        source TEXT,
        genres TEXT,
        studios TEXT,
        next_airing_episode INTEGER,
        next_airing_at INTEGER,
        external_url TEXT,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  /// Таблица тир-листов.
  static Future<void> createTierListsTable(Database db) async {
    await db.execute('''
      CREATE TABLE tier_lists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        collection_id INTEGER,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
        FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE
      )
    ''');
  }

  /// Таблица определений тиров (S/A/B/C + кастомные).
  static Future<void> createTierDefinitionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE tier_definitions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tier_list_id INTEGER NOT NULL,
        tier_key TEXT NOT NULL,
        label TEXT NOT NULL,
        color INTEGER NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (tier_list_id) REFERENCES tier_lists(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX idx_tier_def
      ON tier_definitions(tier_list_id, tier_key)
    ''');
  }

  /// Таблица привязок элементов к тирам.
  static Future<void> createTierListEntriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE tier_list_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tier_list_id INTEGER NOT NULL,
        collection_item_id INTEGER NOT NULL,
        tier_key TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (tier_list_id) REFERENCES tier_lists(id) ON DELETE CASCADE,
        FOREIGN KEY (collection_item_id) REFERENCES collection_items(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX idx_tier_entry
      ON tier_list_entries(tier_list_id, collection_item_id)
    ''');
  }

  /// Создаёт таблицу кастомных элементов.
  static Future<void> createCustomItemsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS custom_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        display_type TEXT,
        alt_title TEXT,
        description TEXT,
        cover_url TEXT,
        year INTEGER,
        genres TEXT,
        platform_name TEXT,
        external_url TEXT,
        cached_at INTEGER NOT NULL
      )
    ''');
  }

  /// Создаёт таблицу тегов коллекции.
  static Future<void> createCollectionTagsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS collection_tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        collection_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        color INTEGER,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_collection_tags_name
      ON collection_tags(collection_id, name)
    ''');
  }

  /// Таблица профилей внешних трекеров (RA, Steam, Trakt).
  static Future<void> createTrackerProfilesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tracker_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tracker_type TEXT NOT NULL UNIQUE,
        user_id TEXT NOT NULL,
        display_name TEXT NOT NULL,
        avatar_url TEXT,
        profile_url TEXT,
        total_points INTEGER,
        total_games INTEGER,
        total_achievements INTEGER,
        member_since INTEGER,
        profile_data TEXT,
        linked_collection_id INTEGER,
        last_synced_at INTEGER,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (linked_collection_id) REFERENCES collections(id) ON DELETE SET NULL
      )
    ''');
  }

  /// Таблица прогресса per-game от трекеров.
  static Future<void> createTrackerGameDataTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tracker_game_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tracker_type TEXT NOT NULL,
        game_id INTEGER NOT NULL,
        tracker_game_id TEXT NOT NULL,
        tracker_game_title TEXT,
        achievements_earned INTEGER,
        achievements_total INTEGER,
        achievements_earned_hardcore INTEGER,
        award_kind TEXT,
        award_date INTEGER,
        playtime_minutes INTEGER,
        last_played_at INTEGER,
        tracker_data TEXT,
        last_synced_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_tracker_game_data_unique
      ON tracker_game_data(tracker_type, game_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_tracker_game_data_game
      ON tracker_game_data(game_id)
    ''');
  }

  /// Таблица конкретных достижений per-game.
  static Future<void> createTrackerAchievementsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tracker_achievements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tracker_type TEXT NOT NULL,
        tracker_game_id TEXT NOT NULL,
        achievement_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        points INTEGER,
        badge_name TEXT,
        type TEXT,
        display_order INTEGER NOT NULL DEFAULT 0,
        earned INTEGER NOT NULL DEFAULT 0,
        earned_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_tracker_achievements_unique
      ON tracker_achievements(tracker_type, tracker_game_id, achievement_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_tracker_achievements_game
      ON tracker_achievements(tracker_type, tracker_game_id)
    ''');
  }

}
