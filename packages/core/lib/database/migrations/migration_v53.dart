import 'package:sqflite_common/sqlite_api.dart';

import 'migration.dart';

/// Per-unit marks (like and/or note) in a dedicated table, anchored on
/// `collection_items.id` with `ON DELETE CASCADE`.
class MigrationV53 extends Migration {
  @override
  int get version => 53;

  @override
  String get description => 'item_marks: per-unit likes and notes';

  @override
  Future<void> migrate(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS item_marks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        unit_type TEXT NOT NULL,
        parent_number INTEGER NOT NULL DEFAULT 0,
        unit_number INTEGER NOT NULL DEFAULT 0,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        user_comment TEXT,
        liked_at INTEGER,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (item_id) REFERENCES collection_items(id) ON DELETE CASCADE,
        UNIQUE(item_id, unit_type, parent_number, unit_number)
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_item_marks_item '
      'ON item_marks(item_id)',
    );
  }
}
