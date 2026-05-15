import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Cache tables (games/movies/...) stay canonical with API titles; the
/// per-item rename is stored here so a re-fetch of the API row can't wipe it.
class MigrationV39 extends Migration {
  @override
  int get version => 39;

  @override
  String get description =>
      'Add override_name column to collection_items';

  @override
  Future<void> migrate(Database db) async {
    await db.execute('''
      ALTER TABLE collection_items ADD COLUMN override_name TEXT
    ''');
  }
}
