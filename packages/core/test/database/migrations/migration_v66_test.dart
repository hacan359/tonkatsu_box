import 'package:core/database/migrations/migration.dart';
import 'package:core/database/migrations/migration_registry.dart';
import 'package:core/database/migrations/migration_v66.dart';
import 'package:test/test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;

  group('MigrationV66', () {
    late Database db;

    setUp(() async {
      db = await factory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 65,
          onCreate: (Database d, int _) async {
            for (final Migration m in MigrationRegistry.all) {
              if (m.version < 66) await m.migrate(d);
            }
          },
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    Future<List<String>> columns() async {
      final List<Map<String, Object?>> rows =
          await db.rawQuery('PRAGMA table_info(collection_items)');
      return rows.map((Map<String, Object?> r) => r['name'] as String).toList();
    }

    test('should add override_cover_url to collection_items', () async {
      expect(await columns(), isNot(contains('override_cover_url')));

      await MigrationV66().migrate(db);

      expect(await columns(), contains('override_cover_url'));
    });

    test('should be a no-op when run twice', () async {
      await MigrationV66().migrate(db);
      await MigrationV66().migrate(db);

      expect(
        (await columns()).where((String c) => c == 'override_cover_url'),
        hasLength(1),
      );
    });

    test('should leave existing rows without an override', () async {
      await db.insert('collections', <String, Object?>{
        'id': 1,
        'name': 'C',
        'author': 'tester',
        'created_at': 0,
      });
      await db.insert('collection_items', <String, Object?>{
        'collection_id': 1,
        'media_type': 'game',
        'external_id': 7,
        'added_at': 0,
      });

      await MigrationV66().migrate(db);

      final List<Map<String, Object?>> rows =
          await db.query('collection_items');
      expect(rows.single['override_cover_url'], isNull);
    });
  });
}
