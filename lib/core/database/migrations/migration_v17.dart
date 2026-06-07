import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// SQLite has no `ALTER COLUMN`, so dropping the `NOT NULL` constraint on
/// `collection_id` requires a full table rebuild (copy → drop → rename) plus
/// rebuilding the unique indexes.
class MigrationV17 extends Migration {
  @override
  int get version => 17;

  @override
  String get description =>
      'Recreate collection_items with nullable collection_id';

  @override
  Future<void> migrate(Database db) async {
    await db.execute('''
      CREATE TABLE collection_items_new (
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
        FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      INSERT INTO collection_items_new
      SELECT * FROM collection_items
    ''');

    await db.execute('DROP TABLE collection_items');
    await db.execute(
      'ALTER TABLE collection_items_new RENAME TO collection_items',
    );

    // Split unique constraints: items in a collection vs. uncategorised items
    // (collection_id IS NULL). COALESCE(platform_id, -1) buckets NULL so
    // multi-platform installs of the same external_id keep distinct rows.
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_ci_coll
      ON collection_items(
        collection_id, media_type, external_id, COALESCE(platform_id, -1)
      )
      WHERE collection_id IS NOT NULL
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_ci_uncat
      ON collection_items(media_type, external_id, COALESCE(platform_id, -1))
      WHERE collection_id IS NULL
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_collection_items_collection
      ON collection_items(collection_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_collection_items_type
      ON collection_items(media_type)
    ''');
  }
}
