import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Creates `collection_items`, folds the legacy `collection_games` table
/// (games-only) into it under `media_type = 'game'`, then drops the old table.
class MigrationV8 extends Migration {
  @override
  int get version => 8;

  @override
  String get description =>
      'Create collection_items and migrate data from collection_games';

  @override
  Future<void> migrate(Database db) async {
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
    await _migrateCollectionGamesToItems(db);
  }

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
    await db.execute('DROP TABLE collection_games');
  }
}
