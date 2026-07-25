import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../schema.dart';
import 'migration.dart';

class MigrationV42 extends Migration {
  @override
  int get version => 42;

  @override
  String get description => 'Add anilist_tags catalog table';

  @override
  Future<void> migrate(Database db) async {
    await DatabaseSchema.createAniListTagsTable(db);
  }
}
