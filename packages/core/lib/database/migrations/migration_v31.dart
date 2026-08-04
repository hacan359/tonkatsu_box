import 'package:sqflite_common/sqlite_api.dart';

import '../schema.dart';
import 'migration.dart';

class MigrationV31 extends Migration {
  @override
  int get version => 31;

  @override
  String get description =>
      'Create tracker tables (profiles, game data, achievements)';

  @override
  Future<void> migrate(Database db) async {
    await DatabaseSchema.createTrackerProfilesTable(db);
    await DatabaseSchema.createTrackerGameDataTable(db);
    await DatabaseSchema.createTrackerAchievementsTable(db);
  }
}
