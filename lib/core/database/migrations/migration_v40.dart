import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

class MigrationV40 extends Migration {
  @override
  int get version => 40;

  @override
  String get description => 'Add tag column to wishlist';

  @override
  Future<void> migrate(Database db) async {
    await db.execute('''
      ALTER TABLE wishlist ADD COLUMN tag TEXT
    ''');
  }
}
