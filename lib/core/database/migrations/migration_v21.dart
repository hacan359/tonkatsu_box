import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'migration.dart';

class MigrationV21 extends Migration {
  @override
  int get version => 21;

  @override
  String get description => 'Add external_url to games, movies, tv_shows';

  @override
  Future<void> migrate(Database db) async {
    await db.execute('ALTER TABLE games ADD COLUMN external_url TEXT');
    await db.execute('ALTER TABLE movies_cache ADD COLUMN external_url TEXT');
    await db.execute(
      'ALTER TABLE tv_shows_cache ADD COLUMN external_url TEXT',
    );
  }
}
