// Миграция v3: создание таблиц collections и collection_games.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../schema.dart';
import 'migration.dart';

/// Миграция v3 — создание таблицы collections и legacy-таблицы
/// collection_games (нужна для миграции v8).
class MigrationV3 extends Migration {
  @override
  int get version => 3;

  @override
  String get description => 'Create collections and collection_games tables';

  @override
  Future<void> migrate(Database db) async {
    await DatabaseSchema.createCollectionsTable(db);

    // Legacy-таблица collection_games (нужна для миграции v8)
    await db.execute('''
      CREATE TABLE collection_games (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        collection_id INTEGER NOT NULL,
        igdb_id INTEGER NOT NULL,
        platform_id INTEGER NOT NULL,
        author_comment TEXT,
        user_comment TEXT,
        status TEXT DEFAULT 'not_started',
        added_at INTEGER NOT NULL,
        FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE,
        UNIQUE(collection_id, igdb_id, platform_id)
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_collection_games_collection
      ON collection_games(collection_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_collection_games_igdb
      ON collection_games(igdb_id)
    ''');
  }
}
