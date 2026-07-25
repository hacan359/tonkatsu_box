import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

class MigrationV33 extends Migration {
  @override
  int get version => 33;

  @override
  String get description => 'Add anime_cache table';

  @override
  Future<void> migrate(Database db) async {
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
}
