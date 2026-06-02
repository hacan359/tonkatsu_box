import 'package:sqflite_common_ffi/sqflite_ffi.dart';

abstract final class DatabaseSchema {
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
    await createMoodGridsTable(db);
    await createMoodGridCellsTable(db);
    await createAniListTagsTable(db);
    await createMangaBakaGenresTable(db);
    await createMangaBakaTagsTable(db);
    await createTrackedReleasesTable(db);
  }

  static Future<void> createPlatformsTable(Database db) async {
    await db.execute('''
      CREATE TABLE platforms (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        abbreviation TEXT
      )
    ''');
  }

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
        forked_from_name TEXT,
        hero_image_path TEXT,
        description TEXT
      )
    ''');
  }

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

  /// Release-tracking subscriptions, keyed by the title identity
  /// `(external_id, source, media_type)` so the same numeric id from different
  /// providers (e.g. AniList vs MangaBaka) never collides. Independent of
  /// `collection_items`: one subscription per title regardless of how many
  /// collections it sits in. The Releases calendar reads dates straight from
  /// `tv_episodes_cache`; this table only records what the user opted into.
  static Future<void> createTrackedReleasesTable(Database db) async {
    await db.execute('''
      CREATE TABLE tracked_releases (
        external_id INTEGER NOT NULL,
        source TEXT NOT NULL,
        media_type TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        PRIMARY KEY (external_id, source, media_type)
      )
    ''');
  }

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
        user_rating INTEGER, -- stores fractional rating 1.0-10.0; REAL via type affinity, type kept INTEGER for history
        tag_id INTEGER,
        time_spent_minutes INTEGER NOT NULL DEFAULT 0,
        override_name TEXT,
        source TEXT,
        FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES collection_tags(id) ON DELETE SET NULL
      )
    ''');

    // Games: UNIQUE includes platform_id so the same game on different
    // platforms can coexist as separate rows in one collection.
    await db.execute('''
      CREATE UNIQUE INDEX idx_ci_coll_game
      ON collection_items(collection_id, media_type, external_id, platform_id)
      WHERE collection_id IS NOT NULL AND media_type = 'game'
    ''');
    // Manga: identity includes `source` so the same external_id from AniList
    // and MangaBaka coexist as separate rows. COALESCE keeps legacy NULL
    // sources (pre-v44) collapsing to a single bucket.
    await db.execute('''
      CREATE UNIQUE INDEX idx_ci_coll_manga
      ON collection_items(collection_id, media_type, external_id, COALESCE(source, 'anilist'))
      WHERE collection_id IS NOT NULL AND media_type = 'manga'
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX idx_ci_coll_other
      ON collection_items(collection_id, media_type, external_id)
      WHERE collection_id IS NOT NULL AND media_type NOT IN ('game', 'manga')
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX idx_ci_uncat_game
      ON collection_items(media_type, external_id, platform_id)
      WHERE collection_id IS NULL AND media_type = 'game'
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX idx_ci_uncat_manga
      ON collection_items(media_type, external_id, COALESCE(source, 'anilist'))
      WHERE collection_id IS NULL AND media_type = 'manga'
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX idx_ci_uncat_other
      ON collection_items(media_type, external_id)
      WHERE collection_id IS NULL AND media_type NOT IN ('game', 'manga')
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

  static Future<void> createWishlistTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS wishlist (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        media_type_hint TEXT,
        note TEXT,
        is_resolved INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        resolved_at INTEGER,
        tag TEXT
      )
    ''');
  }

  static Future<void> createIgdbGenresTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS igdb_genres (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');
  }

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

  static Future<void> createVndbTagsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vndb_tags (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');
  }

  static Future<void> createMangaCacheTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS manga_cache (
        id INTEGER NOT NULL,
        source TEXT NOT NULL DEFAULT 'anilist',
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
        tags TEXT,
        authors TEXT,
        external_url TEXT,
        banner_url TEXT,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (id, source)
      )
    ''');
  }

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
        tags TEXT,
        studios TEXT,
        next_airing_episode INTEGER,
        next_airing_at INTEGER,
        external_url TEXT,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  static Future<void> createAniListTagsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS anilist_tags (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        category TEXT,
        description TEXT,
        is_adult INTEGER NOT NULL DEFAULT 0,
        is_general_spoiler INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_anilist_tags_category
      ON anilist_tags(category)
    ''');
  }

  /// MangaBaka genres — a fixed enum (no API endpoint), seeded as static
  /// lookup data. `key` is the API filter value (e.g. `fantasy`).
  static Future<void> createMangaBakaGenresTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mangabaka_genres (
        key TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        is_adult INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL
      )
    ''');
  }

  /// MangaBaka tag catalog (`/v1/tags`) — hierarchical, refreshed on demand.
  static Future<void> createMangaBakaTagsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mangabaka_tags (
        id INTEGER PRIMARY KEY,
        parent_id INTEGER,
        name TEXT NOT NULL,
        name_path TEXT,
        description TEXT,
        is_spoiler INTEGER NOT NULL DEFAULT 0,
        is_genre INTEGER NOT NULL DEFAULT 0,
        content_rating TEXT,
        series_count INTEGER NOT NULL DEFAULT 0,
        level INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_mangabaka_tags_parent
      ON mangabaka_tags(parent_id)
    ''');
  }

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

  static Future<void> createTrackerGameDataTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tracker_game_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tracker_type TEXT NOT NULL,
        game_id INTEGER NOT NULL,
        platform_id INTEGER,
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
      ON tracker_game_data(tracker_type, game_id, COALESCE(platform_id, -1))
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_tracker_game_data_game
      ON tracker_game_data(game_id)
    ''');
  }

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

  static Future<void> createMoodGridsTable(Database db) async {
    await db.execute('''
      CREATE TABLE mood_grids (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        rows INTEGER NOT NULL DEFAULT 1,
        cols INTEGER NOT NULL DEFAULT 5,
        caption_template TEXT,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
        updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now'))
      )
    ''');
  }

  /// No UNIQUE on `(grid_id, media_type, external_id)` — the same item
  /// can occupy several cells. No FK to `collection_items` — a cell
  /// stands alone, regardless of whether the item is in any collection.
  static Future<void> createMoodGridCellsTable(Database db) async {
    await db.execute('''
      CREATE TABLE mood_grid_cells (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        grid_id INTEGER NOT NULL,
        position INTEGER NOT NULL,
        label TEXT,
        media_type TEXT,
        external_id INTEGER,
        platform_id INTEGER,
        source TEXT,
        FOREIGN KEY (grid_id) REFERENCES mood_grids(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX idx_mood_grid_cell_pos
      ON mood_grid_cells(grid_id, position)
    ''');
  }

}
