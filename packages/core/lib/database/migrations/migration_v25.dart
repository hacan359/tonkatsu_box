import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../schema.dart';
import 'migration.dart';

class MigrationV25 extends Migration {
  @override
  int get version => 25;

  @override
  String get description => 'Add manga cache table';

  @override
  Future<void> migrate(Database db) async {
    await DatabaseSchema.createMangaCacheTable(db);
  }
}
