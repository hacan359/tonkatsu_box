import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

class MigrationV12 extends Migration {
  @override
  int get version => 12;

  @override
  String get description => 'Add activity dates to collection_items';

  @override
  Future<void> migrate(Database db) async {
    await db.execute(
      'ALTER TABLE collection_items ADD COLUMN started_at INTEGER',
    );
    await db.execute(
      'ALTER TABLE collection_items ADD COLUMN completed_at INTEGER',
    );
    await db.execute(
      'ALTER TABLE collection_items ADD COLUMN last_activity_at INTEGER',
    );
    // Seed last_activity_at from added_at so existing rows aren't NULL.
    await db.execute(
      'UPDATE collection_items SET last_activity_at = added_at',
    );
  }
}
