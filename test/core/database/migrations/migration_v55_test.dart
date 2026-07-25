import 'package:core/database/migrations/migration_v55.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;

  /// A pre-v55 database with a minimal `collection_items` (no rewatch_count).
  Future<Database> openOldDb() async {
    return factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 54,
        onCreate: (Database db, int _) async {
          await db.execute('''
            CREATE TABLE collection_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              media_type TEXT NOT NULL,
              external_id INTEGER NOT NULL,
              status TEXT DEFAULT 'not_started'
            )
          ''');
        },
      ),
    );
  }

  Future<List<Map<String, Object?>>> columns(Database db) =>
      db.rawQuery('PRAGMA table_info(collection_items)');

  group('MigrationV55', () {
    late Database db;

    setUp(() async => db = await openOldDb());

    tearDown(() async => db.close());

    test('adds a nullable rewatch_count column', () async {
      await MigrationV55().migrate(db);

      final Map<String, Object?> column = (await columns(db)).firstWhere(
        (Map<String, Object?> c) => c['name'] == 'rewatch_count',
      );
      expect(column['type'], 'INTEGER');
      expect(column['notnull'], 0);
      expect(column['dflt_value'], isNull);
    });

    test('existing rows keep NULL (never completed / not tracked)', () async {
      await db.insert('collection_items', <String, Object?>{
        'id': 1,
        'media_type': 'game',
        'external_id': 100,
        'status': 'completed',
      });
      await MigrationV55().migrate(db);

      final List<Map<String, Object?>> rows =
          await db.query('collection_items');
      expect(rows.single['rewatch_count'], isNull);
    });

    test('re-run is a no-op', () async {
      await MigrationV55().migrate(db);
      await MigrationV55().migrate(db);

      final Iterable<Object?> names =
          (await columns(db)).map((Map<String, Object?> c) => c['name']);
      expect(
        names.where((Object? n) => n == 'rewatch_count'),
        hasLength(1),
      );
    });
  });
}
