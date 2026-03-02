// Миграция v4: добавление logo_image_id в platforms.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Миграция v4 — добавление колонки logo_image_id в таблицу platforms.
class MigrationV4 extends Migration {
  @override
  int get version => 4;

  @override
  String get description => 'Add logo_image_id to platforms';

  @override
  Future<void> migrate(Database db) async {
    await db.execute('ALTER TABLE platforms ADD COLUMN logo_image_id TEXT');
  }
}
