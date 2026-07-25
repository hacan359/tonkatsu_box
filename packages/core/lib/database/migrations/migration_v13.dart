import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../schema.dart';
import 'migration.dart';

class MigrationV13 extends Migration {
  @override
  int get version => 13;

  @override
  String get description => 'Create tmdb_genres table';

  @override
  Future<void> migrate(Database db) async {
    await DatabaseSchema.createTmdbGenresTable(db);
  }
}
