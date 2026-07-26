import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../schema.dart';
import 'migration.dart';

class MigrationV10 extends Migration {
  @override
  int get version => 10;

  @override
  String get description =>
      'Create tv_episodes_cache and watched_episodes tables';

  @override
  Future<void> migrate(Database db) async {
    await DatabaseSchema.createTvEpisodesCacheTable(db);
    await DatabaseSchema.createWatchedEpisodesTable(db);
  }
}
