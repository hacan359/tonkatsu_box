import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../schema.dart';
import 'migration.dart';

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
