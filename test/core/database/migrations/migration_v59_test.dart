import 'package:core/database/migrations/migration_v59.dart';
import 'package:flutter_test/flutter_test.dart';
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

  group('MigrationV59', () {
    test('creates mangadex_tags with the UUID id and tag_group columns',
        () async {
      final Database db = await openDb();
      addTearDown(() async => db.close());

      await MigrationV59().migrate(db);

      final List<Map<String, Object?>> cols =
          await db.rawQuery('PRAGMA table_info(mangadex_tags)');
      expect(
        cols.map((Map<String, Object?> c) => c['name']),
        containsAll(<String>['id', 'name', 'tag_group', 'updated_at']),
      );
      final Map<String, Object?> id = cols.firstWhere(
        (Map<String, Object?> c) => c['name'] == 'id',
      );
      expect(id['type'], 'TEXT');
      expect(id['pk'], 1);
    });

    test('is idempotent and keeps cached rows', () async {
      final Database db = await openDb();
      addTearDown(() async => db.close());
      await MigrationV59().migrate(db);
      await db.insert('mangadex_tags', <String, Object?>{
        'id': '391b0423-d847-456f-aff0-8b0cfc03066b',
        'name': 'Action',
        'tag_group': 'genre',
        'updated_at': 1,
      });

      await expectLater(MigrationV59().migrate(db), completes);

      final List<Map<String, Object?>> rows = await db.query('mangadex_tags');
      expect(rows.single['name'], 'Action');
    });
  });
}
