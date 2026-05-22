import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

// override_name lives on collection_items (not cache tables) so an API refetch
// of the canonical title can't wipe the user's rename.
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
