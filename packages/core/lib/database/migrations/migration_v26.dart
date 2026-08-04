import 'package:sqflite_common/sqlite_api.dart';

import '../schema.dart';
import 'migration.dart';

class MigrationV26 extends Migration {
  @override
  int get version => 26;

  @override
  String get description => 'Add tier lists tables';

  @override
  Future<void> migrate(Database db) async {
    await DatabaseSchema.createTierListsTable(db);
    await DatabaseSchema.createTierDefinitionsTable(db);
    await DatabaseSchema.createTierListEntriesTable(db);
  }
}
