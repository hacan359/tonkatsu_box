import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Repair pass for v15: on some installs `createCollectionItemsTable` ran
/// without the new column, so the ALTER from v15 didn't fire. Retry it and
/// swallow the "duplicate column" error.
class MigrationV16 extends Migration {
  @override
  int get version => 16;

  @override
  String get description => 'Repair: ensure user_rating column exists';

  @override
  Future<void> migrate(Database db) async {
    try {
      await db.execute(
        'ALTER TABLE collection_items ADD COLUMN user_rating INTEGER',
      );
    } on DatabaseException catch (_) {
      // Column already present — repair was a no-op.
    }
  }
}
