import 'package:core/database/migrations/migration_v48.dart';
import 'package:test/test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;

  /// Pre-v48 `collection_items`: `source` exists (added in v44) but books still
  /// fall under the generic `*_other` indexes that key only on `external_id`.
  Future<Database> openOldDb() async {
    return factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 47,
        onCreate: (Database db, int _) async {
          await db.execute('''
            CREATE TABLE collection_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              collection_id INTEGER,
              media_type TEXT NOT NULL,
              external_id INTEGER NOT NULL,
              source TEXT
            )
          ''');
          await db.execute('''
            CREATE UNIQUE INDEX idx_ci_coll_other
            ON collection_items(collection_id, media_type, external_id)
            WHERE collection_id IS NOT NULL AND media_type NOT IN ('game', 'manga')
          ''');
          await db.execute('''
            CREATE UNIQUE INDEX idx_ci_uncat_other
            ON collection_items(media_type, external_id)
            WHERE collection_id IS NULL AND media_type NOT IN ('game', 'manga')
          ''');
        },
      ),
    );
  }

  group('MigrationV48', () {
    late Database db;

    setUp(() async {
      db = await openOldDb();
      // Legacy book row without a source (only OpenLibrary existed before).
      await db.insert('collection_items', <String, Object?>{
        'collection_id': 1,
        'media_type': 'book',
        'external_id': 3104,
      });
      await MigrationV48().migrate(db);
    });

    tearDown(() async => db.close());

    test('backfills null source to openLibrary for book rows', () async {
      final List<Map<String, Object?>> rows = await db.query(
        'collection_items',
        where: 'media_type = ? AND external_id = ?',
        whereArgs: <Object?>['book', 3104],
      );
      expect(rows, hasLength(1));
      expect(rows.first['source'], 'openLibrary');
    });

    test('OpenLibrary and Fantlab book with same id coexist in a collection',
        () async {
      await db.insert('collection_items', <String, Object?>{
        'collection_id': 2,
        'media_type': 'book',
        'external_id': 7777,
        'source': 'openLibrary',
      });
      await db.insert('collection_items', <String, Object?>{
        'collection_id': 2,
        'media_type': 'book',
        'external_id': 7777,
        'source': 'fantlab',
      });

      final List<Map<String, Object?>> rows = await db.query(
        'collection_items',
        where: 'collection_id = ? AND media_type = ? AND external_id = ?',
        whereArgs: <Object?>[2, 'book', 7777],
      );
      expect(rows, hasLength(2));
    });

    test('same book id + same source still rejected in one collection',
        () async {
      await db.insert('collection_items', <String, Object?>{
        'collection_id': 3,
        'media_type': 'book',
        'external_id': 555,
        'source': 'fantlab',
      });

      expect(
        () => db.insert('collection_items', <String, Object?>{
          'collection_id': 3,
          'media_type': 'book',
          'external_id': 555,
          'source': 'fantlab',
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('non-book type is still deduped by external_id', () async {
      await db.insert('collection_items', <String, Object?>{
        'collection_id': 4,
        'media_type': 'movie',
        'external_id': 42,
      });

      expect(
        () => db.insert('collection_items', <String, Object?>{
          'collection_id': 4,
          'media_type': 'movie',
          'external_id': 42,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}
