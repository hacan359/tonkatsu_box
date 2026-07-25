import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../schema.dart';
import 'migration.dart';

class MigrationV2 extends Migration {
  @override
  int get version => 2;

  @override
  String get description => 'Create games table';

  @override
  Future<void> migrate(Database db) async {
    await DatabaseSchema.createGamesTable(db);
  }
}
