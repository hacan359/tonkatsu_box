import 'package:core/database/migrations/migration.dart';
import 'package:core/database/migrations/migration_registry.dart';
import 'package:core/database/migrations/migration_v69.dart';
import 'package:test/test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;

  group('MigrationV69', () {
    late Database db;

    setUp(() async {
      db = await factory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 68,
          onCreate: (Database d, int _) async {
            for (final Migration m in MigrationRegistry.all) {
              if (m.version < 69) await m.migrate(d);
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
          await db.rawQuery('PRAGMA table_info(item_marks)');
      return rows.map((Map<String, Object?> r) => r['name'] as String).toList();
    }

    test('should add item_marks.user_rating', () async {
      expect(await columns(), isNot(contains('user_rating')));

      await MigrationV69().migrate(db);

      expect(await columns(), contains('user_rating'));
    });

    test('should be a no-op when run twice', () async {
      await MigrationV69().migrate(db);
      await MigrationV69().migrate(db);

      expect(
        (await columns()).where((String c) => c == 'user_rating'),
        hasLength(1),
      );
    });

    test('should leave existing marks unrated', () async {
      await db.insert('item_marks', <String, Object?>{
        'item_id': 1,
        'unit_type': 'season',
        'parent_number': 2,
        'unit_number': 0,
        'is_favorite': 1,
        'updated_at': 0,
      });

      await MigrationV69().migrate(db);

      final List<Map<String, Object?>> rows = await db.query('item_marks');
      expect(rows.single['user_rating'], isNull);
    });

    test('should be the last migration in the registry', () {
      expect(MigrationRegistry.all.last, isA<MigrationV69>());
      expect(MigrationRegistry.latestVersion, 69);
    });
  });
}
