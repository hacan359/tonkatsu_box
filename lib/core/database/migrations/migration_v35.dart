// Миграция v35: добавление полей hero_image_path и description в collections.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

/// Миграция v35: rich collection view — hero-изображение и описание.
class MigrationV35 extends Migration {
  @override
  int get version => 35;

  @override
  String get description =>
      'Add hero_image_path and description to collections';

  @override
  Future<void> migrate(Database db) async {
    await db.execute('''
      ALTER TABLE collections
      ADD COLUMN hero_image_path TEXT
    ''');
    await db.execute('''
      ALTER TABLE collections
      ADD COLUMN description TEXT
    ''');
  }
}
