import 'package:sqflite_common/sqlite_api.dart';

import 'migration.dart';

/// Movie identity becomes `(source, movie id)` — provider id spaces overlap, so
/// a TheTVDB movie would otherwise replace the TMDB movie with the same number.
class MigrationV62 extends Migration {
  @override
  int get version => 62;

  @override
  String get description =>
      'Movie source: (tmdb_id, source) PK on movies_cache, '
      'collection_items movie indexes';

  @override
  Future<void> migrate(Database db) async {
    await _rebuildMoviesCache(db);
    await _addCollectionItemsMovieSource(db);
  }

  Future<void> _rebuildMoviesCache(Database db) async {
    await db.execute('ALTER TABLE movies_cache RENAME TO movies_cache_old');
    await db.execute('''
      CREATE TABLE movies_cache (
        tmdb_id INTEGER NOT NULL,
        source TEXT NOT NULL DEFAULT 'tmdb',
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
        cached_at INTEGER,
        PRIMARY KEY (tmdb_id, source)
      )
    ''');
    await db.execute('''
      INSERT INTO movies_cache (
        tmdb_id, source, title, original_title, poster_url, backdrop_url,
        overview, genres, release_year, rating, runtime, external_url, cached_at
      )
      SELECT
        tmdb_id, 'tmdb', title, original_title, poster_url, backdrop_url,
        overview, genres, release_year, rating, runtime, external_url, cached_at
      FROM movies_cache_old
    ''');
    await db.execute('DROP TABLE movies_cache_old');
  }

  Future<void> _addCollectionItemsMovieSource(Database db) async {
    await db.execute(
      "UPDATE collection_items SET source = 'tmdb' "
      "WHERE media_type = 'movie' AND source IS NULL",
    );
    await db.execute(
      "UPDATE mood_grid_cells SET source = 'tmdb' "
      "WHERE media_type = 'movie' AND source IS NULL",
    );

    // Re-scope the generic index off movie; a movie now needs source in the key
    // so the same title from two providers can coexist.
    await db.execute('DROP INDEX IF EXISTS idx_ci_coll_other');
    await db.execute('DROP INDEX IF EXISTS idx_ci_uncat_other');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_ci_coll_other
      ON collection_items(collection_id, media_type, external_id)
      WHERE collection_id IS NOT NULL
        AND media_type NOT IN ('game', 'manga', 'tv_show', 'book', 'anime', 'movie')
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_ci_uncat_other
      ON collection_items(media_type, external_id)
      WHERE collection_id IS NULL
        AND media_type NOT IN ('game', 'manga', 'tv_show', 'book', 'anime', 'movie')
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_ci_coll_movie
      ON collection_items(collection_id, media_type, external_id, COALESCE(source, 'tmdb'))
      WHERE collection_id IS NOT NULL AND media_type = 'movie'
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_ci_uncat_movie
      ON collection_items(media_type, external_id, COALESCE(source, 'tmdb'))
      WHERE collection_id IS NULL AND media_type = 'movie'
    ''');
  }
}
