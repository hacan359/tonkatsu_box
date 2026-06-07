import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

class MigrationV21 extends Migration {
  @override
  int get version => 21;

  @override
  String get description => 'Add external_url to games, movies, tv_shows';

  @override
  Future<void> migrate(Database db) async {
    await Migration.addColumnIfAbsent(
      db,
      'games',
      'external_url',
      'external_url TEXT',
    );
    await Migration.addColumnIfAbsent(
      db,
      'movies_cache',
      'external_url',
      'external_url TEXT',
    );
    await Migration.addColumnIfAbsent(
      db,
      'tv_shows_cache',
      'external_url',
      'external_url TEXT',
    );
  }
}
