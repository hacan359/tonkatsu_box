import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../schema.dart';
import 'migration.dart';

/// Adds MangaBaka as a second manga provider.
///
/// Manga identity becomes `(external_id, source)`:
/// - `manga_cache` is rebuilt with a composite primary key `(id, source)` so
///   an AniList and a MangaBaka entry sharing a numeric id coexist;
/// - `collection_items` gains a nullable `source` column (filled only for
///   manga) and manga-specific unique indexes that include it.
///
/// Also creates the MangaBaka genre / tag catalog tables and seeds the fixed
/// genre enum.
class MigrationV44 extends Migration {
  @override
  int get version => 44;

  @override
  String get description =>
      'MangaBaka source: manga_cache (id, source) PK, collection_items.source, catalogs';

  @override
  Future<void> migrate(Database db) async {
    await _rebuildMangaCache(db);
    await _addCollectionItemsSource(db);
    await _addMoodGridCellsSource(db);
    await DatabaseSchema.createMangaBakaGenresTable(db);
    await DatabaseSchema.createMangaBakaTagsTable(db);
    await seedGenres(db);
  }

  /// SQLite can't change a primary key in place — rebuild the table with the
  /// composite PK and copy existing rows as `source = 'anilist'`.
  Future<void> _rebuildMangaCache(Database db) async {
    await db.execute('ALTER TABLE manga_cache RENAME TO manga_cache_old');
    await DatabaseSchema.createMangaCacheTable(db);
    await db.execute('''
      INSERT INTO manga_cache (
        id, source, title, title_english, title_native, description,
        cover_url, cover_url_medium, average_score, mean_score, popularity,
        status, start_year, start_month, start_day, chapters, volumes,
        format, country_of_origin, genres, tags, authors, external_url,
        banner_url, updated_at
      )
      SELECT
        id, 'anilist', title, title_english, title_native, description,
        cover_url, cover_url_medium, average_score, mean_score, popularity,
        status, start_year, start_month, start_day, chapters, volumes,
        format, country_of_origin, genres, tags, authors, external_url,
        banner_url, updated_at
      FROM manga_cache_old
    ''');
    await db.execute('DROP TABLE manga_cache_old');
  }

  Future<void> _addCollectionItemsSource(Database db) async {
    await Migration.addColumnIfAbsent(
      db,
      'collection_items',
      'source',
      'source TEXT',
    );
    await db.execute(
      "UPDATE collection_items SET source = 'anilist' WHERE media_type = 'manga'",
    );

    // Re-scope the generic non-game indexes off manga, add manga-specific
    // unique indexes that include source.
    await db.execute('DROP INDEX IF EXISTS idx_ci_coll_other');
    await db.execute('DROP INDEX IF EXISTS idx_ci_uncat_other');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_ci_coll_other
      ON collection_items(collection_id, media_type, external_id)
      WHERE collection_id IS NOT NULL AND media_type NOT IN ('game', 'manga')
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_ci_uncat_other
      ON collection_items(media_type, external_id)
      WHERE collection_id IS NULL AND media_type NOT IN ('game', 'manga')
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_ci_coll_manga
      ON collection_items(collection_id, media_type, external_id, COALESCE(source, 'anilist'))
      WHERE collection_id IS NOT NULL AND media_type = 'manga'
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_ci_uncat_manga
      ON collection_items(media_type, external_id, COALESCE(source, 'anilist'))
      WHERE collection_id IS NULL AND media_type = 'manga'
    ''');
  }

  Future<void> _addMoodGridCellsSource(Database db) async {
    await Migration.addColumnIfAbsent(
      db,
      'mood_grid_cells',
      'source',
      'source TEXT',
    );
    await db.execute(
      "UPDATE mood_grid_cells SET source = 'anilist' WHERE media_type = 'manga'",
    );
  }

  /// Seeds the fixed MangaBaka genre enum. Called from both the migration and
  /// `_onCreate` (fresh installs), so the catalog is populated either way.
  static Future<void> seedGenres(Database db) async {
    await db.execute('DELETE FROM mangabaka_genres');
    final Batch batch = db.batch();
    for (int i = 0; i < _mangaBakaGenres.length; i++) {
      final ({String key, String name, bool adult}) g = _mangaBakaGenres[i];
      batch.insert('mangabaka_genres', <String, Object?>{
        'key': g.key,
        'name': g.name,
        'is_adult': g.adult ? 1 : 0,
        'sort_order': i,
      });
    }
    await batch.commit(noResult: true);
  }
}

/// MangaBaka's fixed `genre` filter enum (from the API validation error). The
/// API endpoint has no genre list, so this is seeded statically.
const List<({String key, String name, bool adult})> _mangaBakaGenres =
    <({String key, String name, bool adult})>[
  (key: 'action', name: 'Action', adult: false),
  (key: 'adult', name: 'Adult', adult: true),
  (key: 'adventure', name: 'Adventure', adult: false),
  (key: 'avant_garde', name: 'Avant Garde', adult: false),
  (key: 'award_winning', name: 'Award Winning', adult: false),
  (key: 'boys_love', name: "Boys' Love", adult: false),
  (key: 'comedy', name: 'Comedy', adult: false),
  (key: 'doujinshi', name: 'Doujinshi', adult: false),
  (key: 'drama', name: 'Drama', adult: false),
  (key: 'ecchi', name: 'Ecchi', adult: false),
  (key: 'erotica', name: 'Erotica', adult: true),
  (key: 'fantasy', name: 'Fantasy', adult: false),
  (key: 'gender_bender', name: 'Gender Bender', adult: false),
  (key: 'girls_love', name: "Girls' Love", adult: false),
  (key: 'gourmet', name: 'Gourmet', adult: false),
  (key: 'harem', name: 'Harem', adult: false),
  (key: 'hentai', name: 'Hentai', adult: true),
  (key: 'historical', name: 'Historical', adult: false),
  (key: 'horror', name: 'Horror', adult: false),
  (key: 'josei', name: 'Josei', adult: false),
  (key: 'lolicon', name: 'Lolicon', adult: true),
  (key: 'mahou_shoujo', name: 'Mahou Shoujo', adult: false),
  (key: 'martial_arts', name: 'Martial Arts', adult: false),
  (key: 'mature', name: 'Mature', adult: true),
  (key: 'mecha', name: 'Mecha', adult: false),
  (key: 'music', name: 'Music', adult: false),
  (key: 'mystery', name: 'Mystery', adult: false),
  (key: 'psychological', name: 'Psychological', adult: false),
  (key: 'romance', name: 'Romance', adult: false),
  (key: 'school_life', name: 'School Life', adult: false),
  (key: 'sci-fi', name: 'Sci-Fi', adult: false),
  (key: 'seinen', name: 'Seinen', adult: false),
  (key: 'shotacon', name: 'Shotacon', adult: true),
  (key: 'shoujo', name: 'Shoujo', adult: false),
  (key: 'shoujo_ai', name: 'Shoujo Ai', adult: false),
  (key: 'shounen', name: 'Shounen', adult: false),
  (key: 'shounen_ai', name: 'Shounen Ai', adult: false),
  (key: 'slice_of_life', name: 'Slice of Life', adult: false),
  (key: 'smut', name: 'Smut', adult: true),
  (key: 'sports', name: 'Sports', adult: false),
  (key: 'supernatural', name: 'Supernatural', adult: false),
  (key: 'suspense', name: 'Suspense', adult: false),
  (key: 'thriller', name: 'Thriller', adult: false),
  (key: 'tragedy', name: 'Tragedy', adult: false),
  (key: 'yaoi', name: 'Yaoi', adult: true),
  (key: 'yuri', name: 'Yuri', adult: false),
];
