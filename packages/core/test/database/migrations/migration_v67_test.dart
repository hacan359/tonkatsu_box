import 'package:core/database/migrations/migration.dart';
import 'package:core/database/migrations/migration_registry.dart';
import 'package:core/database/migrations/migration_v67.dart';
import 'package:test/test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;

  const Map<String, List<String>> added = <String, List<String>>{
    'movies_cache': <String>['directors', 'studios'],
    'tv_shows_cache': <String>['creators', 'studios'],
    'games': <String>['developers', 'publishers'],
    'custom_items': <String>['authors'],
  };

  group('MigrationV67', () {
    late Database db;

    setUp(() async {
      db = await factory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 66,
          onCreate: (Database d, int _) async {
            for (final Migration m in MigrationRegistry.all) {
              if (m.version < 67) await m.migrate(d);
            }
          },
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    Future<List<String>> columns(String table) async {
      final List<Map<String, Object?>> rows =
          await db.rawQuery('PRAGMA table_info($table)');
      return rows.map((Map<String, Object?> r) => r['name'] as String).toList();
    }

    test('should add the creator columns', () async {
      for (final MapEntry<String, List<String>> e in added.entries) {
        expect(await columns(e.key), isNot(containsAll(e.value)));
      }

      await MigrationV67().migrate(db);

      for (final MapEntry<String, List<String>> e in added.entries) {
        expect(await columns(e.key), containsAll(e.value), reason: e.key);
      }
    });

    test('should be a no-op when run twice', () async {
      await MigrationV67().migrate(db);
      await MigrationV67().migrate(db);

      for (final MapEntry<String, List<String>> e in added.entries) {
        for (final String column in e.value) {
          expect(
            (await columns(e.key)).where((String c) => c == column),
            hasLength(1),
          );
        }
      }
    });

    test('should leave existing rows without creators', () async {
      await db.insert('custom_items', <String, Object?>{
        'id': 1,
        'title': 'Card',
        'cached_at': 0,
      });

      await MigrationV67().migrate(db);

      final List<Map<String, Object?>> rows = await db.query('custom_items');
      expect(rows.single['authors'], isNull);
    });
  });
}
