import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// TV show identity becomes `(source, show id)`. SQLite can't alter constraints
/// in place, so the four tv tables are rebuilt and backfilled as `tmdb`.
class MigrationV57 extends Migration {
  @override
  int get version => 57;

  @override
  String get description =>
      'Show source: (tmdb_id, source) PK on tv_shows_cache, source column on '
      'tv_seasons_cache/tv_episodes_cache/watched_episodes, '
      'collection_items tv indexes';

  @override
  Future<void> migrate(Database db) async {
    await _rebuildTvShowsCache(db);
    await _rebuildTvSeasonsCache(db);
    await _rebuildTvEpisodesCache(db);
    await _rebuildWatchedEpisodes(db);
    await _addCollectionItemsTvSource(db);
    await _addMoodGridCellsTvSource(db);
  }

  Future<void> _rebuildTvShowsCache(Database db) async {
    await db.execute('ALTER TABLE tv_shows_cache RENAME TO tv_shows_cache_old');
    await db.execute('''
      CREATE TABLE tv_shows_cache (
        tmdb_id INTEGER NOT NULL,
        source TEXT NOT NULL DEFAULT 'tmdb',
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
        cached_at INTEGER,
        PRIMARY KEY (tmdb_id, source)
      )
    ''');
    await db.execute('''
      INSERT INTO tv_shows_cache (
        tmdb_id, source, title, original_title, poster_url, backdrop_url,
        overview, genres, first_air_year, total_seasons, total_episodes,
        rating, status, external_url, cached_at
      )
      SELECT
        tmdb_id, 'tmdb', title, original_title, poster_url, backdrop_url,
        overview, genres, first_air_year, total_seasons, total_episodes,
        rating, status, external_url, cached_at
      FROM tv_shows_cache_old
    ''');
    await db.execute('DROP TABLE tv_shows_cache_old');
  }

  Future<void> _addCollectionItemsTvSource(Database db) async {
    await db.execute(
      "UPDATE collection_items SET source = 'tmdb' "
      "WHERE media_type = 'tv_show' AND source IS NULL",
    );

    // Re-scope the generic non-game indexes off tv_show, add tv-specific
    // unique indexes that include source.
    await db.execute('DROP INDEX IF EXISTS idx_ci_coll_other');
    await db.execute('DROP INDEX IF EXISTS idx_ci_uncat_other');
    // 'book' stays excluded (source-aware since v48); re-including it would make
    // this index throw on legal cross-source duplicates and roll the upgrade back.
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_ci_coll_other
      ON collection_items(collection_id, media_type, external_id)
      WHERE collection_id IS NOT NULL
        AND media_type NOT IN ('game', 'manga', 'book', 'tv_show')
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_ci_uncat_other
      ON collection_items(media_type, external_id)
      WHERE collection_id IS NULL
        AND media_type NOT IN ('game', 'manga', 'book', 'tv_show')
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_ci_coll_tv
      ON collection_items(collection_id, media_type, external_id, COALESCE(source, 'tmdb'))
      WHERE collection_id IS NOT NULL AND media_type = 'tv_show'
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_ci_uncat_tv
      ON collection_items(media_type, external_id, COALESCE(source, 'tmdb'))
      WHERE collection_id IS NULL AND media_type = 'tv_show'
    ''');
  }

  Future<void> _addMoodGridCellsTvSource(Database db) async {
    await db.execute(
      "UPDATE mood_grid_cells SET source = 'tmdb' "
      "WHERE media_type = 'tv_show' AND source IS NULL",
    );
  }

  Future<void> _rebuildTvSeasonsCache(Database db) async {
    await db
        .execute('ALTER TABLE tv_seasons_cache RENAME TO tv_seasons_cache_old');
    await db.execute('''
      CREATE TABLE tv_seasons_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tmdb_show_id INTEGER NOT NULL,
        season_number INTEGER NOT NULL,
        name TEXT,
        episode_count INTEGER,
        poster_url TEXT,
        air_date TEXT,
        source TEXT NOT NULL DEFAULT 'tmdb',
        UNIQUE(source, tmdb_show_id, season_number)
      )
    ''');
    await db.execute('''
      INSERT INTO tv_seasons_cache (
        id, tmdb_show_id, season_number, name, episode_count, poster_url,
        air_date, source
      )
      SELECT
        id, tmdb_show_id, season_number, name, episode_count, poster_url,
        air_date, 'tmdb'
      FROM tv_seasons_cache_old
    ''');
    await db.execute('DROP TABLE tv_seasons_cache_old');
  }

  Future<void> _rebuildTvEpisodesCache(Database db) async {
    await db.execute(
        'ALTER TABLE tv_episodes_cache RENAME TO tv_episodes_cache_old');
    await db.execute('''
      CREATE TABLE tv_episodes_cache (
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
        source TEXT NOT NULL DEFAULT 'tmdb',
        UNIQUE(source, tmdb_show_id, season_number, episode_number)
      )
    ''');
    await db.execute('''
      INSERT INTO tv_episodes_cache (
        id, tmdb_show_id, season_number, episode_number, name, overview,
        air_date, still_url, runtime, cached_at, source
      )
      SELECT
        id, tmdb_show_id, season_number, episode_number, name, overview,
        air_date, still_url, runtime, cached_at, 'tmdb'
      FROM tv_episodes_cache_old
    ''');
    await db.execute('DROP TABLE tv_episodes_cache_old');
  }

  Future<void> _rebuildWatchedEpisodes(Database db) async {
    // With `PRAGMA foreign_keys = ON` a row pointing at a deleted collection would
    // fail the rebuild insert on every launch. Such rows are unreachable anyway.
    await db.execute(
      'DELETE FROM watched_episodes WHERE NOT EXISTS ('
      'SELECT 1 FROM collections WHERE collections.id = '
      'watched_episodes.collection_id)',
    );
    await db.execute(
        'ALTER TABLE watched_episodes RENAME TO watched_episodes_old');
    await db.execute('''
      CREATE TABLE watched_episodes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        collection_id INTEGER NOT NULL,
        show_id INTEGER NOT NULL,
        season_number INTEGER NOT NULL,
        episode_number INTEGER NOT NULL,
        watched_at INTEGER,
        source TEXT NOT NULL DEFAULT 'tmdb',
        FOREIGN KEY (collection_id) REFERENCES collections(id)
          ON DELETE CASCADE,
        UNIQUE(collection_id, source, show_id, season_number, episode_number)
      )
    ''');
    await db.execute('''
      INSERT INTO watched_episodes (
        id, collection_id, show_id, season_number, episode_number,
        watched_at, source
      )
      SELECT
        id, collection_id, show_id, season_number, episode_number,
        watched_at, 'tmdb'
      FROM watched_episodes_old
    ''');
    await db.execute('DROP TABLE watched_episodes_old');
  }
}
