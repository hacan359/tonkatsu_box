// Миграция v15: добавление user_rating в collection_items.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Миграция v15 — добавление колонки user_rating (1-10) в
/// collection_items.
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
