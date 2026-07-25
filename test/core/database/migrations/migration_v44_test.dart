import 'package:core/database/migrations/migration_v44.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Minimal pre-v44 `manga_cache` (single-column PK, no `source`) — only the
/// columns the migration copies.
const String _oldMangaCacheDdl = '''
  CREATE TABLE manga_cache (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    title_english TEXT,
    title_native TEXT,
    description TEXT,
    cover_url TEXT,
    cover_url_medium TEXT,
    average_score INTEGER,
    mean_score INTEGER,
    popularity INTEGER,
    status TEXT,
    start_year INTEGER,
    start_month INTEGER,
    start_day INTEGER,
    chapters INTEGER,
    volumes INTEGER,
    format TEXT,
    country_of_origin TEXT,
    genres TEXT,
    tags TEXT,
    authors TEXT,
    external_url TEXT,
    banner_url TEXT,
    updated_at INTEGER NOT NULL
  )
''';

void main() {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;

  Future<Database> openOldDb() async {
    return factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 43,
        onCreate: (Database db, int _) async {
          await db.execute(_oldMangaCacheDdl);
          await db.execute('''
            CREATE TABLE collection_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              collection_id INTEGER,
              media_type TEXT NOT NULL,
              external_id INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE mood_grid_cells (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              media_type TEXT,
              external_id INTEGER
            )
          ''');
        },
      ),
    );
  }

  group('MigrationV44', () {
    late Database db;

    setUp(() async {
      db = await openOldDb();
      await db.insert('manga_cache', <String, Object?>{
        'id': 1995,
        'title': 'Frieren',
        'updated_at': 1000,
      });
      await db.insert('collection_items', <String, Object?>{
        'collection_id': 1,
        'media_type': 'manga',
        'external_id': 1995,
      });
      await db.insert('collection_items', <String, Object?>{
        'collection_id': 1,
        'media_type': 'game',
        'external_id': 42,
      });
      await db.insert('mood_grid_cells', <String, Object?>{
        'media_type': 'manga',
        'external_id': 1995,
      });
      await MigrationV44().migrate(db);
    });

    tearDown(() async => db.close());

    test('manga_cache keeps existing rows as source=anilist', () async {
      final List<Map<String, Object?>> rows =
          await db.query('manga_cache', where: 'id = ?', whereArgs: <Object?>[1995]);
      expect(rows, hasLength(1));
      expect(rows.first['source'], 'anilist');
      expect(rows.first['title'], 'Frieren');
    });

    test('manga_cache allows same id from two sources (composite PK)',
        () async {
      await db.insert('manga_cache', <String, Object?>{
        'id': 1995,
        'source': 'mangabaka',
        'title': 'Frieren (MangaBaka)',
        'updated_at': 2000,
      });
      final List<Map<String, Object?>> rows = await db
          .query('manga_cache', where: 'id = ?', whereArgs: <Object?>[1995]);
      expect(rows, hasLength(2));
    });

    test('collection_items.source backfilled for manga only', () async {
      final List<Map<String, Object?>> manga = await db.query(
        'collection_items',
        where: 'media_type = ?',
        whereArgs: <Object?>['manga'],
      );
      expect(manga.first['source'], 'anilist');
      final List<Map<String, Object?>> game = await db.query(
        'collection_items',
        where: 'media_type = ?',
        whereArgs: <Object?>['game'],
      );
      expect(game.first['source'], isNull);
    });

    test('collection_items manga unique index includes source', () async {
      // Same (collection, manga, external_id) but different source coexist.
      await db.insert('collection_items', <String, Object?>{
        'collection_id': 1,
        'media_type': 'manga',
        'external_id': 1995,
        'source': 'mangabaka',
      });
      final List<Map<String, Object?>> rows = await db.query(
        'collection_items',
        where: 'media_type = ? AND external_id = ?',
        whereArgs: <Object?>['manga', 1995],
      );
      expect(rows, hasLength(2));
    });

    test('mood_grid_cells.source backfilled for manga', () async {
      final List<Map<String, Object?>> cells = await db.query(
        'mood_grid_cells',
        where: 'media_type = ?',
        whereArgs: <Object?>['manga'],
      );
      expect(cells.first['source'], 'anilist');
    });

    test('mangabaka_genres seeded', () async {
      final List<Map<String, Object?>> rows =
          await db.rawQuery('SELECT COUNT(*) AS c FROM mangabaka_genres');
      expect(rows.first['c'], 46);
    });

    test('mangabaka_tags table created (empty)', () async {
      final List<Map<String, Object?>> rows =
          await db.rawQuery('SELECT COUNT(*) AS c FROM mangabaka_tags');
      expect(rows.first['c'], 0);
    });
  });
}
