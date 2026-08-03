import 'package:core/database/migrations/migration_v49.dart';
import 'package:test/test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;

  /// Pre-v49 `books_cache`: the v47 shape without the `kind` column.
  Future<Database> openOldDb() async {
    return factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 48,
        onCreate: (Database db, int _) async {
          await db.execute('''
            CREATE TABLE books_cache (
              id TEXT NOT NULL,
              source TEXT NOT NULL,
              title TEXT NOT NULL,
              cached_at INTEGER NOT NULL,
              PRIMARY KEY (id, source)
            )
          ''');
        },
      ),
    );
  }

  Future<bool> hasKindColumn(Database db) async {
    final List<Map<String, Object?>> columns =
        await db.rawQuery('PRAGMA table_info(books_cache)');
    return columns.any((Map<String, Object?> c) => c['name'] == 'kind');
  }

  group('MigrationV49', () {
    late Database db;

    setUp(() async {
      db = await openOldDb();
      await db.insert('books_cache', <String, Object?>{
        'id': '796',
        'source': 'comicVine',
        'title': 'Batman',
        'cached_at': 1700000000,
      });
      await MigrationV49().migrate(db);
    });

    tearDown(() async => db.close());

    test('adds the kind column', () async {
      expect(await hasKindColumn(db), isTrue);
    });

    test('existing rows default to book', () async {
      final List<Map<String, Object?>> rows = await db.query('books_cache');
      expect(rows.single['kind'], 'book');
    });

    test('is idempotent — re-running does not throw', () async {
      await MigrationV49().migrate(db);
      expect(await hasKindColumn(db), isTrue);
    });

    test('new comic rows can store kind = comic', () async {
      await db.insert('books_cache', <String, Object?>{
        'id': '42721',
        'source': 'comicVine',
        'title': 'Batman Volume 2',
        'cached_at': 1700000001,
        'kind': 'comic',
      });
      final List<Map<String, Object?>> rows = await db.query(
        'books_cache',
        where: 'id = ?',
        whereArgs: <Object?>['42721'],
      );
      expect(rows.single['kind'], 'comic');
    });
  });
}
