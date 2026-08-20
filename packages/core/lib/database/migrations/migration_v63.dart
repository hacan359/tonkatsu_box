import 'package:sqflite_common/sqlite_api.dart';

import 'migration.dart';

/// Music in one step: album cache, track lists, listened-track marks. Album
/// `id` is fnv1a64 of the group MBID, so `.xcoll` links survive devices.
class MigrationV63 extends Migration {
  @override
  int get version => 63;

  @override
  String get description =>
      'Music: music_albums_cache, music_tracks_cache, listened_tracks';

  @override
  Future<void> migrate(Database db) async {
    await db.execute('''
      CREATE TABLE music_albums_cache (
        id INTEGER NOT NULL,
        source TEXT NOT NULL DEFAULT 'musicBrainz',
        mbid TEXT NOT NULL,
        title TEXT NOT NULL,
        artists TEXT,
        artist_mbids TEXT,
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
      CREATE UNIQUE INDEX IF NOT EXISTS idx_music_albums_mbid
      ON music_albums_cache(mbid, source)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_music_albums_title
      ON music_albums_cache(title)
    ''');

    // Track list of the picked release, keyed naturally like tv_episodes_cache
    // — the surrogate id is local-only and never exported.
    await db.execute('''
      CREATE TABLE music_tracks_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        album_id INTEGER NOT NULL,
        source TEXT NOT NULL DEFAULT 'musicBrainz',
        disc_number INTEGER NOT NULL,
        position INTEGER NOT NULL,
        title TEXT NOT NULL,
        recording_mbid TEXT,
        length_ms INTEGER,
        artists TEXT,
        cached_at INTEGER,
        UNIQUE(source, album_id, disc_number, position)
      )
    ''');

    await db.execute('''
      CREATE TABLE listened_tracks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        collection_id INTEGER NOT NULL,
        album_id INTEGER NOT NULL,
        source TEXT NOT NULL DEFAULT 'musicBrainz',
        disc_number INTEGER NOT NULL,
        track_number INTEGER NOT NULL,
        listened_at INTEGER,
        FOREIGN KEY (collection_id) REFERENCES collections(id)
          ON DELETE CASCADE,
        UNIQUE(collection_id, source, album_id, disc_number, track_number)
      )
    ''');
  }
}
