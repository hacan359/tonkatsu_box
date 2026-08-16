import 'package:sqflite_common/sqlite_api.dart';

import 'migration.dart';

/// Podcasts join albums under one `kind`-discriminated cache. v63 never
/// shipped, so the music tables are dropped rather than migrated.
class MigrationV64 extends Migration {
  @override
  int get version => 64;

  @override
  String get description =>
      'Audio: drop music tables, create audio_cache / audio_tracks_cache / '
      'listened_tracks with the kind discriminator';

  @override
  Future<void> migrate(Database db) async {
    await db.execute('DROP TABLE IF EXISTS listened_tracks');
    await db.execute('DROP TABLE IF EXISTS music_tracks_cache');
    await db.execute('DROP TABLE IF EXISTS music_albums_cache');

    await db.execute('''
      CREATE TABLE audio_cache (
        id INTEGER NOT NULL,
        source TEXT NOT NULL,
        kind TEXT NOT NULL DEFAULT 'album',
        native_id TEXT NOT NULL,
        title TEXT NOT NULL,
        artists TEXT,
        artist_mbids TEXT,
        description TEXT,
        language TEXT,
        primary_type TEXT,
        secondary_types TEXT,
        release_year INTEGER,
        first_release_date TEXT,
        genres TEXT,
        tags TEXT,
        rating REAL,
        rating_count INTEGER,
        listen_count INTEGER,
        release_mbid TEXT,
        release_title TEXT,
        label TEXT,
        format TEXT,
        track_count INTEGER,
        disc_count INTEGER,
        total_length_ms INTEGER,
        cover_url TEXT,
        external_url TEXT,
        cached_at INTEGER,
        PRIMARY KEY (id, source)
      )
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_audio_native_id
      ON audio_cache(native_id, source)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_audio_title
      ON audio_cache(title)
    ''');

    // Keyed naturally like tv_episodes_cache; the surrogate id is local-only.
    // Podcast episodes store disc_number 0 and the episode id as position.
    await db.execute('''
      CREATE TABLE audio_tracks_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        audio_id INTEGER NOT NULL,
        source TEXT NOT NULL,
        disc_number INTEGER NOT NULL,
        position INTEGER NOT NULL,
        title TEXT NOT NULL,
        native_id TEXT,
        length_ms INTEGER,
        artists TEXT,
        date_published INTEGER,
        cached_at INTEGER,
        UNIQUE(source, audio_id, disc_number, position)
      )
    ''');

    await db.execute('''
      CREATE TABLE listened_tracks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        collection_id INTEGER NOT NULL,
        audio_id INTEGER NOT NULL,
        source TEXT NOT NULL,
        disc_number INTEGER NOT NULL,
        track_number INTEGER NOT NULL,
        listened_at INTEGER,
        FOREIGN KEY (collection_id) REFERENCES collections(id)
          ON DELETE CASCADE,
        UNIQUE(collection_id, source, audio_id, disc_number, track_number)
      )
    ''');
  }
}
