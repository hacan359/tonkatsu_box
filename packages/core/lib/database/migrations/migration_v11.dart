import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

class MigrationV11 extends Migration {
  @override
  int get version => 11;

  @override
  String get description => 'Add sort_order to collection_items';

  @override
  Future<void> migrate(Database db) async {
    await Migration.addColumnIfAbsent(
      db,
      'collection_items',
      'sort_order',
      'sort_order INTEGER NOT NULL DEFAULT 0',
    );
    // Seed sort_order to match existing visual order (newest first by added_at).
    await db.execute('''
      UPDATE collection_items SET sort_order = (
        SELECT COUNT(*) FROM collection_items AS ci2
        WHERE ci2.collection_id = collection_items.collection_id
          AND ci2.added_at > collection_items.added_at
      )
    ''');
  }
}
