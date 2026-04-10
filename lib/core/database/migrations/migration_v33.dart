// Миграция v33: создание таблицы anime_cache.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../schema.dart';
import 'migration.dart';

/// Миграция v33: добавляет таблицу кэша аниме из AniList.
class MigrationV33 extends Migration {
  @override
  int get version => 33;

  @override
  String get description => 'Add anime_cache table';

  @override
  Future<void> migrate(Database db) async {
    await DatabaseSchema.createAnimeCacheTable(db);
  }
}
