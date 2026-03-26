// Миграция v27: добавление таблицы custom_items.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../schema.dart';
import 'migration.dart';

/// Миграция v27 — создание таблицы custom_items для кастомных элементов.
class MigrationV27 extends Migration {
  @override
  int get version => 27;

  @override
  String get description => 'Add custom_items table';

  @override
  Future<void> migrate(Database db) async {
    await DatabaseSchema.createCustomItemsTable(db);

    // Если таблица уже существовала без display_type — добавляем колонку.
    try {
      await db.execute(
        'ALTER TABLE custom_items ADD COLUMN display_type TEXT',
      );
    } on DatabaseException {
      // Колонка уже существует (таблица создана с ней) — игнорируем.
    }
  }
}
