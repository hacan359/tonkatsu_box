import 'package:core/database/migrations/migration.dart';
import 'package:core/database/migrations/migration_registry.dart';
import 'package:core/database/migrations/migration_v65.dart';
import 'package:test/test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;

  group('MigrationV65', () {
    late Database db;

    setUp(() async {
      db = await factory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 64,
          onCreate: (Database d, int _) async {
            for (final Migration m in MigrationRegistry.all) {
              if (m.version < 65) await m.migrate(d);
            }
          },
        ),
      );
      await db.insert('collections', <String, Object?>{
        'id': 1,
        'name': 'C',
        'author': 'tester',
        'created_at': 0,
      });
      for (final int id in <int>[1, 2, 3, 4, 5]) {
        await db.insert('custom_items', <String, Object?>{
          'id': id,
          'title': 'Card $id',
          'cached_at': 0,
        });
      }
      await db.insert('collection_items', <String, Object?>{
        'collection_id': 1,
        'media_type': 'custom',
        'external_id': 1,
        'added_at': 0,
      });
      await db.insert('canvas_items', <String, Object?>{
        'collection_id': 1,
        'item_type': 'custom',
        'item_ref_id': 2,
        'created_at': 0,
      });
      final int gridId =
          await db.insert('mood_grids', <String, Object?>{'name': 'G'});
      await db.insert('mood_grid_cells', <String, Object?>{
        'grid_id': gridId,
        'position': 0,
        'media_type': 'custom',
        'external_id': 3,
      });
      // A non-custom item with a matching id must not keep card 4 alive.
      await db.insert('collection_items', <String, Object?>{
        'collection_id': 1,
        'media_type': 'game',
        'external_id': 4,
        'added_at': 0,
      });
    });

    tearDown(() async {
      await db.close();
    });

    Future<Set<int>> cardIds() async => <int>{
          for (final Map<String, Object?> row
              in await db.query('custom_items', columns: <String>['id']))
            row['id']! as int,
        };

    test('deletes cards nothing points at, keeps the referenced ones',
        () async {
      await MigrationV65().migrate(db);

      expect(await cardIds(), <int>{1, 2, 3});
    });

    test('is a no-op on a second run', () async {
      await MigrationV65().migrate(db);
      await MigrationV65().migrate(db);

      expect(await cardIds(), <int>{1, 2, 3});
    });
  });
}
