import 'package:sqflite_common/sqlite_api.dart';

import 'migration.dart';

/// Anime identity becomes `(id, source)`; the old `source` column (source
/// material) becomes `source_material`.
class MigrationV60 extends Migration {
  @override
  int get version => 60;

  @override
  String get description =>
      'Anime (id, source) identity: anime_cache composite PK, source_material '
      'rename, collection_items anime indexes';

  @override
  Future<void> migrate(Database db) async {
    await _rebuildAnimeCache(db);
    await _addCollectionItemsSource(db);
    await _addMoodGridCellsSource(db);
  }

  // Rebuild for the composite PK; copy rows as source='anilist' and move the
  // old `source` (source material) into `source_material`.
  Future<void> _rebuildAnimeCache(Database db) async {
    await db.execute('ALTER TABLE anime_cache RENAME TO anime_cache_old');
    await db.execute('''
      CREATE TABLE anime_cache (
        id INTEGER NOT NULL,
        source TEXT NOT NULL DEFAULT 'anilist',
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
        source_material TEXT,
        genres TEXT,
        tags TEXT,
        studios TEXT,
        next_airing_episode INTEGER,
        next_airing_at INTEGER,
        external_url TEXT,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (id, source)
      )
    ''');
    await db.execute('''
      INSERT INTO anime_cache (
        id, source, title, title_english, title_native, description,
        cover_url, cover_url_medium, banner_url, average_score, mean_score,
        popularity, status, season, season_year, start_year, start_month,
        start_day, episodes, duration, format, source_material, genres, tags,
        studios, next_airing_episode, next_airing_at, external_url, updated_at
      )
      SELECT
        id, 'anilist', title, title_english, title_native, description,
        cover_url, cover_url_medium, banner_url, average_score, mean_score,
        popularity, status, season, season_year, start_year, start_month,
        start_day, episodes, duration, format, source, genres, tags,
        studios, next_airing_episode, next_airing_at, external_url, updated_at
      FROM anime_cache_old
    ''');
    await db.execute('DROP TABLE anime_cache_old');
  }

  Future<void> _addCollectionItemsSource(Database db) async {
    await db.execute(
      "UPDATE collection_items SET source = 'anilist' "
      "WHERE media_type = 'anime' AND source IS NULL",
    );

    await db.execute('DROP INDEX IF EXISTS idx_ci_coll_other');
    await db.execute('DROP INDEX IF EXISTS idx_ci_uncat_other');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_ci_coll_other
      ON collection_items(collection_id, media_type, external_id)
      WHERE collection_id IS NOT NULL
        AND media_type NOT IN ('game', 'manga', 'tv_show', 'book', 'anime')
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_ci_uncat_other
      ON collection_items(media_type, external_id)
      WHERE collection_id IS NULL
        AND media_type NOT IN ('game', 'manga', 'tv_show', 'book', 'anime')
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_ci_coll_anime
      ON collection_items(collection_id, media_type, external_id, COALESCE(source, 'anilist'))
      WHERE collection_id IS NOT NULL AND media_type = 'anime'
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_ci_uncat_anime
      ON collection_items(media_type, external_id, COALESCE(source, 'anilist'))
      WHERE collection_id IS NULL AND media_type = 'anime'
    ''');
  }

  Future<void> _addMoodGridCellsSource(Database db) async {
    await db.execute(
      "UPDATE mood_grid_cells SET source = 'anilist' "
      "WHERE media_type = 'anime' AND source IS NULL",
    );
  }
}
