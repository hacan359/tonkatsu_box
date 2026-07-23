import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tonkatsu_box/core/database/migrations/migration_v60.dart';

/// Pre-v60 `anime_cache` (single-column PK, `source` holds source material).
const String _oldAnimeCacheDdl = '''
  CREATE TABLE anime_cache (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    title_english TEXT,
    title_native TEXT,
    description TEXT,
    cover_url TEXT,
    cover_url_medium TEXT,
    banner_url TEXT,
    average_score INTEGER,
    mean_score INTEGER,
    popularity INTEGER,
    status TEXT,
    season TEXT,
    season_year INTEGER,
    start_year INTEGER,
    start_month INTEGER,
    start_day INTEGER,
    episodes INTEGER,
    duration INTEGER,
    format TEXT,
    source TEXT,
    genres TEXT,
    tags TEXT,
    studios TEXT,
    next_airing_episode INTEGER,
    next_airing_at INTEGER,
    external_url TEXT,
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
        version: 59,
        onCreate: (Database db, int _) async {
          await db.execute(_oldAnimeCacheDdl);
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
            CREATE TABLE mood_grid_cells (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              media_type TEXT,
              external_id INTEGER,
              source TEXT
            )
          ''');
        },
      ),
    );
  }

  group('MigrationV60', () {
    late Database db;

    setUp(() async {
      db = await openOldDb();
      await db.insert('anime_cache', <String, Object?>{
        'id': 7442,
        'title': 'Frieren',
        'source': 'MANGA',
        'updated_at': 1000,
      });
      await db.insert('collection_items', <String, Object?>{
        'collection_id': 1,
        'media_type': 'anime',
        'external_id': 7442,
      });
      await db.insert('collection_items', <String, Object?>{
        'collection_id': 1,
        'media_type': 'game',
        'external_id': 42,
      });
      await db.insert('mood_grid_cells', <String, Object?>{
        'media_type': 'anime',
        'external_id': 7442,
      });
      await MigrationV60().migrate(db);
    });

    tearDown(() async => db.close());

    test('existing rows become source=anilist, material moves to '
        'source_material', () async {
      final List<Map<String, Object?>> rows = await db
          .query('anime_cache', where: 'id = ?', whereArgs: <Object?>[7442]);
      expect(rows, hasLength(1));
      expect(rows.first['source'], 'anilist');
      expect(rows.first['source_material'], 'MANGA');
      expect(rows.first['title'], 'Frieren');
    });

    test('allows same id from two sources (composite PK)', () async {
      await db.insert('anime_cache', <String, Object?>{
        'id': 7442,
        'source': 'kitsu',
        'title': 'Frieren (Kitsu)',
        'updated_at': 2000,
      });
      final List<Map<String, Object?>> rows = await db
          .query('anime_cache', where: 'id = ?', whereArgs: <Object?>[7442]);
      expect(rows, hasLength(2));
    });

    test('collection_items.source backfilled for anime only', () async {
      final List<Map<String, Object?>> anime = await db.query(
        'collection_items',
        where: 'media_type = ?',
        whereArgs: <Object?>['anime'],
      );
      expect(anime.first['source'], 'anilist');
      final List<Map<String, Object?>> game = await db.query(
        'collection_items',
        where: 'media_type = ?',
        whereArgs: <Object?>['game'],
      );
      expect(game.first['source'], isNull);
    });

    test('collection_items anime unique index includes source', () async {
      await db.insert('collection_items', <String, Object?>{
        'collection_id': 1,
        'media_type': 'anime',
        'external_id': 7442,
        'source': 'kitsu',
      });
      final List<Map<String, Object?>> rows = await db.query(
        'collection_items',
        where: 'media_type = ? AND external_id = ?',
        whereArgs: <Object?>['anime', 7442],
      );
      expect(rows, hasLength(2));
    });

    test('mood_grid_cells.source backfilled for anime', () async {
      final List<Map<String, Object?>> cells = await db.query(
        'mood_grid_cells',
        where: 'media_type = ?',
        whereArgs: <Object?>['anime'],
      );
      expect(cells.first['source'], 'anilist');
    });
  });
}
