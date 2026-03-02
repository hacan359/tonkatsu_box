// Миграция v23: создание таблиц visual_novels_cache и vndb_tags.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../schema.dart';
import 'migration.dart';

/// Миграция v23 — создание таблиц visual_novels_cache и vndb_tags
/// для интеграции с VNDB.
class MigrationV23 extends Migration {
  @override
  int get version => 23;

  @override
  String get description => 'Create visual_novels_cache and vndb_tags tables';

  @override
  Future<void> migrate(Database db) async {
    await DatabaseSchema.createVisualNovelsCacheTable(db);
    await DatabaseSchema.createVndbTagsTable(db);
  }
}
