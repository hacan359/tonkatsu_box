import 'package:core/database/migrations/migration.dart';
import 'package:core/database/migrations/migration_registry.dart';
import 'package:test/test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;

  Future<Database> openDb() {
    return factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 1),
    );
  }

  group('MigrationRegistry', () {
    test('should expose migrations in ascending, gapless version order', () {
      final List<int> versions = MigrationRegistry.all
          .map((Migration m) => m.version)
          .toList(growable: false);

      expect(
        versions,
        List<int>.generate(versions.length, (int i) => i + 1),
      );
    });

    test('should report the last migration as latestVersion', () {
      expect(MigrationRegistry.latestVersion, MigrationRegistry.all.last.version);
    });

    test('should return every migration above the given version as pending',
        () {
      final List<Migration> pending = MigrationRegistry.pending(
        MigrationRegistry.latestVersion - 1,
      );

      expect(pending, hasLength(1));
      expect(pending.single.version, MigrationRegistry.latestVersion);
    });

    test('should return nothing pending at the latest version', () {
      expect(MigrationRegistry.pending(MigrationRegistry.latestVersion),
          isEmpty);
    });
  });

  group('migration chain replay', () {
    test('should build the whole schema from an empty database', () async {
      final Database db = await openDb();
      addTearDown(() async => db.close());

      for (final Migration migration in MigrationRegistry.all) {
        await migration.migrate(db);
      }

      final List<Map<String, Object?>> tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%'",
      );

      // Every table the app queries must exist after a from-scratch replay;
      // a missing one means the chain no longer matches upgraded databases.
      final Set<String> names = tables
          .map((Map<String, Object?> r) => r['name'] as String)
          .toSet();
      expect(
        names,
        containsAll(<String>[
          'collections',
          'collection_items',
          'games',
          'platforms',
          'movies_cache',
          'tv_shows_cache',
          'anime_cache',
          'manga_cache',
          'books_cache',
          'visual_novels_cache',
          'custom_items',
          'canvas_items',
          'canvas_connections',
          'mood_grids',
          'mood_grid_cells',
          'tier_lists',
          'tier_list_entries',
          'tags',
          'item_tags',
          'collection_tags',
          'item_marks',
          'watched_episodes',
          'calendar_entries',
          'tracked_releases',
          'tracker_profiles',
          'wishlist',
        ]),
      );
    });
  });
}
