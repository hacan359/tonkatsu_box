// Миграция v34: добавление поля time_spent_minutes в collection_items.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Миграция v34: хранение потраченного времени (в минутах) на элемент коллекции.
class MigrationV34 extends Migration {
  @override
  int get version => 34;

  @override
  String get description => 'Add time_spent_minutes to collection_items';

  @override
  Future<void> migrate(Database db) async {
    await db.execute('''
      ALTER TABLE collection_items
      ADD COLUMN time_spent_minutes INTEGER NOT NULL DEFAULT 0
    ''');
  }
}
