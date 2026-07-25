import 'package:core/database/migrations/migration_v56.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;

  /// A pre-v56 database with the v54-shaped `item_tags` (no position).
  Future<Database> openOldDb() async {
    return factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 55,
        onCreate: (Database db, int _) async {
          await db.execute('''
            CREATE TABLE item_tags (
              item_id INTEGER NOT NULL,
              tag_id INTEGER NOT NULL,
              PRIMARY KEY (item_id, tag_id)
            )
          ''');
        },
      ),
    );
  }

  Future<List<Map<String, Object?>>> columns(Database db) =>
      db.rawQuery('PRAGMA table_info(item_tags)');

  group('MigrationV56', () {
    late Database db;

    setUp(() async => db = await openOldDb());

    tearDown(() async => db.close());

    test('adds a nullable position column', () async {
      await MigrationV56().migrate(db);

      final Map<String, Object?> column = (await columns(db)).firstWhere(
        (Map<String, Object?> c) => c['name'] == 'position',
      );
      expect(column['type'], 'INTEGER');
      expect(column['notnull'], 0);
      expect(column['dflt_value'], isNull);
    });

    test('existing links keep NULL (global-order fallback)', () async {
      await db.insert('item_tags', <String, Object?>{
        'item_id': 1,
        'tag_id': 10,
      });
      await MigrationV56().migrate(db);

      final List<Map<String, Object?>> rows = await db.query('item_tags');
      expect(rows.single['position'], isNull);
    });

    test('re-run is a no-op', () async {
      await MigrationV56().migrate(db);
      await MigrationV56().migrate(db);

      final Iterable<Object?> names =
          (await columns(db)).map((Map<String, Object?> c) => c['name']);
      expect(names.where((Object? n) => n == 'position'), hasLength(1));
    });
  });
}
