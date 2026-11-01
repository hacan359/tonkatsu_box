import 'package:sqflite_common/sqlite_api.dart';

import 'migration.dart';

// JSON string lists; rows cached before this version stay null until the next
// fetch. Studios sit apart from creators so a network never reads as a person.
class MigrationV67 extends Migration {
  @override
  int get version => 67;

  @override
  String get description =>
      'Add creator and studio columns to movies, tv shows, games and custom '
      'items';

  @override
  Future<void> migrate(Database db) async {
    await Migration.addColumnIfAbsent(
      db,
      'movies_cache',
      'directors',
      'directors TEXT',
    );
    await Migration.addColumnIfAbsent(
      db,
      'movies_cache',
      'studios',
      'studios TEXT',
    );
    await Migration.addColumnIfAbsent(
      db,
      'tv_shows_cache',
      'creators',
      'creators TEXT',
    );
    await Migration.addColumnIfAbsent(
      db,
      'tv_shows_cache',
      'studios',
      'studios TEXT',
    );
    await Migration.addColumnIfAbsent(
      db,
      'games',
      'developers',
      'developers TEXT',
    );
    await Migration.addColumnIfAbsent(
      db,
      'games',
      'publishers',
      'publishers TEXT',
    );
    await Migration.addColumnIfAbsent(
      db,
      'custom_items',
      'authors',
      'authors TEXT',
    );
  }
}
