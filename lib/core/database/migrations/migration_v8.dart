import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../schema.dart';
import 'migration.dart';

/// Creates `collection_items` and folds the legacy `collection_games` table
/// (games-only) into it under `media_type = 'game'`.
class MigrationV8 extends Migration {
  @override
  int get version => 8;

  @override
  String get description =>
      'Create collection_items and migrate data from collection_games';

  @override
  Future<void> migrate(Database db) async {
    await DatabaseSchema.createCollectionItemsTable(db);
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
  }
}
