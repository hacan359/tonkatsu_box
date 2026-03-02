// Миграция v16: repair — повторное добавление user_rating.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Миграция v16 — repair: повторная попытка добавить user_rating
/// (v15 могла не включить колонку при createCollectionItemsTable).
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
      // Колонка уже существует — ничего делать не нужно.
    }
  }
}
