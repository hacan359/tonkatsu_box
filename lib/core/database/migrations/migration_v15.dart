import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

class MigrationV15 extends Migration {
  @override
  int get version => 15;

  @override
  String get description => 'Add user_rating to collection_items';

  @override
  Future<void> migrate(Database db) async {
    await db.execute(
      'ALTER TABLE collection_items ADD COLUMN user_rating INTEGER',
    );
  }
}
