// Миграция v32: добавление artwork_url в таблицу games.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Миграция v32: добавляет колонку `artwork_url` в таблицу `games`.
///
/// Позволяет сохранять URL artwork из IGDB для отображения
/// в качестве backdrop на экране деталей.
class MigrationV32 extends Migration {
  @override
  int get version => 32;

  @override
  String get description => 'Add artwork_url column to games table';

  @override
  Future<void> migrate(Database db) async {
    await db.execute('ALTER TABLE games ADD COLUMN artwork_url TEXT');
  }
}
