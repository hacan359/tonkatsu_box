import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tonkatsu_box/core/database/migrations/migration_v50.dart';

void main() {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;

  /// Pre-v50 `collection_items`: a minimal shape without the `is_favorite`
  /// column.
  Future<Database> openOldDb() async {
    return factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 49,
        onCreate: (Database db, int _) async {
          await db.execute('''
            CREATE TABLE collection_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              collection_id INTEGER,
              media_type TEXT NOT NULL DEFAULT 'game',
              external_id INTEGER NOT NULL,
              status TEXT DEFAULT 'not_started',
              added_at INTEGER NOT NULL
            )
          ''');
        },
      ),
    );
  }

  Future<bool> hasFavoriteColumn(Database db) async {
    final List<Map<String, Object?>> columns =
        await db.rawQuery('PRAGMA table_info(collection_items)');
    return columns.any((Map<String, Object?> c) => c['name'] == 'is_favorite');
  }

  group('MigrationV50', () {
    late Database db;

    setUp(() async {
      db = await openOldDb();
      await db.insert('collection_items', <String, Object?>{
        'collection_id': 1,
        'media_type': 'game',
        'external_id': 1942,
        'status': 'completed',
        'added_at': 1700000000,
      });
      await MigrationV50().migrate(db);
    });

    tearDown(() async => db.close());

    test('adds the is_favorite column', () async {
      expect(await hasFavoriteColumn(db), isTrue);
    });

    test('existing rows default to 0 (not favorite)', () async {
      final List<Map<String, Object?>> rows =
          await db.query('collection_items');
      expect(rows.single['is_favorite'], 0);
    });

    test('is idempotent — re-running does not throw', () async {
      await MigrationV50().migrate(db);
      expect(await hasFavoriteColumn(db), isTrue);
    });

    test('new rows can store is_favorite = 1', () async {
      await db.insert('collection_items', <String, Object?>{
        'collection_id': 1,
        'media_type': 'game',
        'external_id': 1943,
        'status': 'not_started',
        'added_at': 1700000001,
        'is_favorite': 1,
      });
      final List<Map<String, Object?>> rows = await db.query(
        'collection_items',
        where: 'external_id = ?',
        whereArgs: <Object?>[1943],
      );
      expect(rows.single['is_favorite'], 1);
    });
  });
}
