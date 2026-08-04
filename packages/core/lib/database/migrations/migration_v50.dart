import 'package:sqflite_common/sqlite_api.dart';

import 'migration.dart';

/// Adds `is_favorite`, per item and per collection — the same title in two
/// collections has independent flags.
class MigrationV50 extends Migration {
  @override
  int get version => 50;

  @override
  String get description => 'Collection items: is_favorite flag';

  @override
  Future<void> migrate(Database db) async {
    await Migration.addColumnIfAbsent(
      db,
      'collection_items',
      'is_favorite',
      'is_favorite INTEGER NOT NULL DEFAULT 0',
    );
  }
}
