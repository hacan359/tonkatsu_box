// Миграция v11: добавление sort_order в collection_items.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Миграция v11 — добавление колонки sort_order для ручной сортировки
/// элементов коллекции.
class MigrationV11 extends Migration {
  @override
  int get version => 11;

  @override
  String get description => 'Add sort_order to collection_items';

  @override
  Future<void> migrate(Database db) async {
    await db.execute(
      'ALTER TABLE collection_items '
      'ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0',
    );
    // Присвоить начальные значения по текущему порядку added_at DESC
    await db.execute('''
      UPDATE collection_items SET sort_order = (
        SELECT COUNT(*) FROM collection_items AS ci2
        WHERE ci2.collection_id = collection_items.collection_id
          AND ci2.added_at > collection_items.added_at
      )
    ''');
  }
}
