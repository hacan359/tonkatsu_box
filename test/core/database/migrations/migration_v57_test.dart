import 'package:core/database/migrations/migration_v57.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;

  // Tables as they were before this migration: UNIQUE keys without `source`.
  Future<Database> openOldDb() async {
    return factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 56,
        onCreate: (Database db, int _) async {
          await db.execute('''
            CREATE TABLE collections (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE tv_shows_cache (
              tmdb_id INTEGER PRIMARY KEY,
              title TEXT NOT NULL,
              original_title TEXT,
              poster_url TEXT,
              backdrop_url TEXT,
              overview TEXT,
              genres TEXT,
              first_air_year INTEGER,
              total_seasons INTEGER,
              total_episodes INTEGER,
              rating REAL,
              status TEXT,
              external_url TEXT,
              cached_at INTEGER
            )
          ''');
          await db.execute('''
            CREATE TABLE collection_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              collection_id INTEGER,
              media_type TEXT NOT NULL,
              external_id INTEGER NOT NULL,
              source TEXT
            )
          ''');
          // Index shape as of v48..v56: book carved out into source-aware
          // indexes, excluded from the generic ones.
          await db.execute('''
            CREATE UNIQUE INDEX idx_ci_coll_other
            ON collection_items(collection_id, media_type, external_id)
            WHERE collection_id IS NOT NULL
              AND media_type NOT IN ('game', 'manga', 'book')
          ''');
          await db.execute('''
            CREATE UNIQUE INDEX idx_ci_uncat_other
            ON collection_items(media_type, external_id)
            WHERE collection_id IS NULL
              AND media_type NOT IN ('game', 'manga', 'book')
          ''');
          await db.execute('''
            CREATE UNIQUE INDEX idx_ci_coll_book
            ON collection_items(collection_id, media_type, external_id, COALESCE(source, 'openLibrary'))
            WHERE collection_id IS NOT NULL AND media_type = 'book'
          ''');
          await db.execute('''
            CREATE UNIQUE INDEX idx_ci_uncat_book
            ON collection_items(media_type, external_id, COALESCE(source, 'openLibrary'))
            WHERE collection_id IS NULL AND media_type = 'book'
          ''');
          await db.execute('''
            CREATE TABLE mood_grid_cells (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              media_type TEXT,
              external_id INTEGER,
              source TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE tv_seasons_cache (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              tmdb_show_id INTEGER NOT NULL,
              season_number INTEGER NOT NULL,
              name TEXT,
              episode_count INTEGER,
              poster_url TEXT,
              air_date TEXT,
              UNIQUE(tmdb_show_id, season_number)
            )
          ''');
          await db.execute('''
            CREATE TABLE tv_episodes_cache (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              tmdb_show_id INTEGER NOT NULL,
              season_number INTEGER NOT NULL,
              episode_number INTEGER NOT NULL,
              name TEXT,
              overview TEXT,
              air_date TEXT,
              still_url TEXT,
              runtime INTEGER,
              cached_at INTEGER,
              UNIQUE(tmdb_show_id, season_number, episode_number)
            )
          ''');
          await db.execute('''
            CREATE TABLE watched_episodes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              collection_id INTEGER NOT NULL,
              show_id INTEGER NOT NULL,
              season_number INTEGER NOT NULL,
              episode_number INTEGER NOT NULL,
              watched_at INTEGER,
              FOREIGN KEY (collection_id) REFERENCES collections(id)
                ON DELETE CASCADE,
              UNIQUE(collection_id, show_id, season_number, episode_number)
            )
          ''');
        },
      ),
    );
  }

  group('MigrationV57', () {
    late Database db;

    setUp(() async {
      db = await openOldDb();
      await db.insert('collections', <String, Object?>{'id': 1, 'name': 'TV'});
      await db.insert('tv_shows_cache', <String, Object?>{
        'tmdb_id': 100,
        'title': 'Show 100',
        'total_seasons': 2,
      });
      await db.insert('collection_items', <String, Object?>{
        'collection_id': 1,
        'media_type': 'tv_show',
        'external_id': 100,
      });
      await db.insert('collection_items', <String, Object?>{
        'collection_id': 1,
        'media_type': 'movie',
        'external_id': 42,
      });
      // Legal since v48: same numeric book id from two sources in one
      // collection. The rebuilt generic index must keep excluding 'book',
      // or this data aborts the whole upgrade.
      await db.insert('collection_items', <String, Object?>{
        'collection_id': 1,
        'media_type': 'book',
        'external_id': 777,
        'source': 'openLibrary',
      });
      await db.insert('collection_items', <String, Object?>{
        'collection_id': 1,
        'media_type': 'book',
        'external_id': 777,
        'source': 'googleBooks',
      });
      await db.insert('mood_grid_cells', <String, Object?>{
        'media_type': 'tv_show',
        'external_id': 100,
      });
      await db.insert('tv_seasons_cache', <String, Object?>{
        'tmdb_show_id': 100,
        'season_number': 1,
        'name': 'Season 1',
        'episode_count': 10,
      });
      await db.insert('tv_episodes_cache', <String, Object?>{
        'tmdb_show_id': 100,
        'season_number': 1,
        'episode_number': 3,
        'name': 'Pilot x3',
        'cached_at': 1000,
      });
      await db.insert('watched_episodes', <String, Object?>{
        'collection_id': 1,
        'show_id': 100,
        'season_number': 1,
        'episode_number': 3,
        'watched_at': 2000,
      });
      await MigrationV57().migrate(db);
    });

    tearDown(() async => db.close());

    test('existing rows backfilled as source=tmdb', () async {
      for (final String table in <String>[
        'tv_seasons_cache',
        'tv_episodes_cache',
        'watched_episodes',
      ]) {
        final List<Map<String, Object?>> rows = await db.query(table);
        expect(rows, hasLength(1), reason: table);
        expect(rows.first['source'], 'tmdb', reason: table);
      }
    });

    test('row data survives the rebuild', () async {
      final Map<String, Object?> season =
          (await db.query('tv_seasons_cache')).first;
      expect(season['name'], 'Season 1');
      expect(season['episode_count'], 10);

      final Map<String, Object?> episode =
          (await db.query('tv_episodes_cache')).first;
      expect(episode['name'], 'Pilot x3');
      expect(episode['cached_at'], 1000);

      final Map<String, Object?> watched =
          (await db.query('watched_episodes')).first;
      expect(watched['collection_id'], 1);
      expect(watched['watched_at'], 2000);
    });

    test('same show id from another source coexists in every table', () async {
      await db.insert('tv_seasons_cache', <String, Object?>{
        'tmdb_show_id': 100,
        'season_number': 1,
        'source': 'tvmaze',
      });
      await db.insert('tv_episodes_cache', <String, Object?>{
        'tmdb_show_id': 100,
        'season_number': 1,
        'episode_number': 3,
        'source': 'tvmaze',
      });
      await db.insert('watched_episodes', <String, Object?>{
        'collection_id': 1,
        'show_id': 100,
        'season_number': 1,
        'episode_number': 3,
        'source': 'tvmaze',
      });

      for (final String table in <String>[
        'tv_seasons_cache',
        'tv_episodes_cache',
        'watched_episodes',
      ]) {
        final List<Map<String, Object?>> rows = await db.query(table);
        expect(rows, hasLength(2), reason: table);
      }
    });

    test('UNIQUE still rejects a duplicate within one source', () async {
      await expectLater(
        db.insert('tv_episodes_cache', <String, Object?>{
          'tmdb_show_id': 100,
          'season_number': 1,
          'episode_number': 3,
          'source': 'tmdb',
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('source defaults to tmdb for inserts without the column', () async {
      await db.insert('tv_episodes_cache', <String, Object?>{
        'tmdb_show_id': 200,
        'season_number': 1,
        'episode_number': 1,
      });
      final List<Map<String, Object?>> rows = await db.query(
        'tv_episodes_cache',
        where: 'tmdb_show_id = ?',
        whereArgs: <Object?>[200],
      );
      expect(rows.first['source'], 'tmdb');
    });

    test('watched_episodes keeps the ON DELETE CASCADE to collections',
        () async {
      await db.execute('PRAGMA foreign_keys = ON');
      await db
          .delete('collections', where: 'id = ?', whereArgs: <Object?>[1]);
      final List<Map<String, Object?>> rows =
          await db.query('watched_episodes');
      expect(rows, isEmpty);
    });

    test('tv_shows_cache keeps existing rows as source=tmdb', () async {
      final List<Map<String, Object?>> rows = await db.query(
        'tv_shows_cache',
        where: 'tmdb_id = ?',
        whereArgs: <Object?>[100],
      );
      expect(rows, hasLength(1));
      expect(rows.first['source'], 'tmdb');
      expect(rows.first['title'], 'Show 100');
      expect(rows.first['total_seasons'], 2);
    });

    test('tv_shows_cache allows same id from two sources (composite PK)',
        () async {
      await db.insert('tv_shows_cache', <String, Object?>{
        'tmdb_id': 100,
        'source': 'tvmaze',
        'title': 'Show 100 (other)',
      });
      final List<Map<String, Object?>> rows = await db.query(
        'tv_shows_cache',
        where: 'tmdb_id = ?',
        whereArgs: <Object?>[100],
      );
      expect(rows, hasLength(2));
    });

    test('collection_items.source backfilled for tv_show only', () async {
      final List<Map<String, Object?>> tv = await db.query(
        'collection_items',
        where: 'media_type = ?',
        whereArgs: <Object?>['tv_show'],
      );
      expect(tv.first['source'], 'tmdb');
      final List<Map<String, Object?>> movie = await db.query(
        'collection_items',
        where: 'media_type = ?',
        whereArgs: <Object?>['movie'],
      );
      expect(movie.first['source'], isNull);
    });

    test('collection_items tv unique index includes source', () async {
      await db.insert('collection_items', <String, Object?>{
        'collection_id': 1,
        'media_type': 'tv_show',
        'external_id': 100,
        'source': 'tvmaze',
      });
      final List<Map<String, Object?>> rows = await db.query(
        'collection_items',
        where: 'media_type = ? AND external_id = ?',
        whereArgs: <Object?>['tv_show', 100],
      );
      expect(rows, hasLength(2));
    });

    test('collection_items tv duplicate within one source is rejected',
        () async {
      await expectLater(
        db.insert('collection_items', <String, Object?>{
          'collection_id': 1,
          'media_type': 'tv_show',
          'external_id': 100,
          'source': 'tmdb',
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('cross-source book duplicates survive the index rebuild', () async {
      final List<Map<String, Object?>> books = await db.query(
        'collection_items',
        where: 'media_type = ? AND external_id = ?',
        whereArgs: <Object?>['book', 777],
      );
      expect(books, hasLength(2));
      await expectLater(
        db.insert('collection_items', <String, Object?>{
          'collection_id': 1,
          'media_type': 'book',
          'external_id': 777,
          'source': 'openLibrary',
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('mood_grid_cells.source backfilled for tv_show', () async {
      final List<Map<String, Object?>> cells = await db.query(
        'mood_grid_cells',
        where: 'media_type = ?',
        whereArgs: <Object?>['tv_show'],
      );
      expect(cells.first['source'], 'tmdb');
    });
  });
}
