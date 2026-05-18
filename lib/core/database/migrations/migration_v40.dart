import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Adds an optional `tag` to wishlist entries so bulk-imported items
/// (MAL, AniList) can be grouped and removed together; existing rows
/// stay untagged (NULL).
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
