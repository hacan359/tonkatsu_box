import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Ensures `collection_items.user_rating` exists.
class MigrationV16 extends Migration {
  @override
  int get version => 16;

  @override
  String get description => 'Ensure collection_items.user_rating column';

  @override
  Future<void> migrate(Database db) async {
    await Migration.addColumnIfAbsent(
      db,
      'collection_items',
      'user_rating',
      'user_rating INTEGER',
    );
  }
}
