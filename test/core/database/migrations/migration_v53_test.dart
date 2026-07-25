import 'package:core/database/migrations/migration_v53.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;

  /// A pre-v53 database with only a minimal `collection_items` table so the
  /// new table's foreign key has a target.
  Future<Database> openOldDb() async {
    return factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 52,
        onCreate: (Database db, int _) async {
          await db.execute('''
            CREATE TABLE collection_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              media_type TEXT NOT NULL,
              external_id INTEGER NOT NULL
            )
          ''');
        },
      ),
    );
  }

  Future<bool> hasTable(Database db, String table) async {
    final List<Map<String, Object?>> rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      <Object?>[table],
    );
    return rows.isNotEmpty;
  }

  Future<bool> hasIndex(Database db, String index) async {
    final List<Map<String, Object?>> rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='index' AND name=?",
      <Object?>[index],
    );
    return rows.isNotEmpty;
  }

  group('MigrationV53', () {
    late Database db;

    setUp(() async {
      db = await openOldDb();
      await MigrationV53().migrate(db);
    });

    tearDown(() async => db.close());

    test('creates the item_marks table and its index', () async {
      expect(await hasTable(db, 'item_marks'), isTrue);
      expect(await hasIndex(db, 'idx_item_marks_item'), isTrue);
    });

    test('is idempotent — re-running does not throw', () async {
      await MigrationV53().migrate(db);
      expect(await hasTable(db, 'item_marks'), isTrue);
    });

    test('enforces the unique unit key', () async {
      await db.insert('item_marks', <String, Object?>{
        'item_id': 1,
        'unit_type': 'episode',
        'parent_number': 1,
        'unit_number': 3,
        'is_favorite': 1,
        'updated_at': 1700000000000,
      });
      expect(
        () => db.insert('item_marks', <String, Object?>{
          'item_id': 1,
          'unit_type': 'episode',
          'parent_number': 1,
          'unit_number': 3,
          'is_favorite': 0,
          'updated_at': 1700000001000,
        }, conflictAlgorithm: ConflictAlgorithm.fail),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('cascades deletes from collection_items', () async {
      await db.execute('PRAGMA foreign_keys = ON');
      await db.insert('collection_items', <String, Object?>{
        'id': 1,
        'media_type': 'tv_show',
        'external_id': 100,
      });
      await db.insert('item_marks', <String, Object?>{
        'item_id': 1,
        'unit_type': 'episode',
        'parent_number': 1,
        'unit_number': 3,
        'is_favorite': 1,
        'updated_at': 1700000000000,
      });
      await db.delete('collection_items', where: 'id = ?', whereArgs: <Object?>[1]);
      final List<Map<String, Object?>> marks = await db.query('item_marks');
      expect(marks, isEmpty);
    });
  });
}
