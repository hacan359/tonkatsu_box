import 'package:core/database/migrations/migration.dart';
import 'package:core/database/migrations/migration_registry.dart';
import 'package:core/models/cover_info.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tonkatsu_box/core/database/dao/anime_dao.dart';
import 'package:tonkatsu_box/core/database/dao/book_dao.dart';
import 'package:tonkatsu_box/core/database/dao/collection_dao.dart';
import 'package:tonkatsu_box/core/database/dao/custom_media_dao.dart';
import 'package:tonkatsu_box/core/database/dao/game_dao.dart';
import 'package:tonkatsu_box/core/database/dao/manga_dao.dart';
import 'package:tonkatsu_box/core/database/dao/movie_dao.dart';
import 'package:tonkatsu_box/core/database/dao/tv_show_dao.dart';
import 'package:tonkatsu_box/core/database/dao/visual_novel_dao.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late CollectionDao dao;

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: MigrationRegistry.all.last.version,
        onCreate: (Database d, int _) async {
          for (final Migration m in MigrationRegistry.all) {
            await m.migrate(d);
          }
        },
      ),
    );
    Future<Database> getDb() async => db;
    dao = CollectionDao(
      getDb,
      gameDao: GameDao(getDb),
      movieDao: MovieDao(getDb),
      tvShowDao: TvShowDao(getDb),
      visualNovelDao: VisualNovelDao(getDb),
      animeDao: AnimeDao(getDb),
      mangaDao: MangaDao(getDb),
      bookDao: BookDao(getDb),
      customMediaDao: CustomMediaDao(getDb),
    );

    await db.insert('collections', <String, Object?>{
      'id': 1,
      'name': 'Mixed',
      'author': 'tester',
      'created_at': 1700000000,
    });
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertCustom({
    required int id,
    required int collectionItemId,
    required String coverUrl,
  }) async {
    await db.insert('custom_items', <String, Object?>{
      'id': id,
      'title': 'Custom $id',
      'cover_url': coverUrl,
      'cached_at': 1700000000,
    });
    await db.insert('collection_items', <String, Object?>{
      'id': collectionItemId,
      'collection_id': 1,
      'media_type': 'custom',
      'external_id': id,
      'status': 'not_started',
      'sort_order': collectionItemId,
      'added_at': 1700000000,
    });
  }

  group('CollectionDao.getCollectionCovers — custom items', () {
    test('returns custom items with cover_url', () async {
      await insertCustom(
        id: 100,
        collectionItemId: 1,
        coverUrl: 'https://example.com/poster.jpg',
      );

      final List<CoverInfo> covers = await dao.getCollectionCovers(1);

      expect(covers, hasLength(1));
      expect(covers.first.mediaType, MediaType.custom);
      expect(covers.first.externalId, 100);
      expect(covers.first.thumbnailUrl, 'https://example.com/poster.jpg');
    });

    test('returns local-marker cover_url as-is', () async {
      await insertCustom(
        id: 200,
        collectionItemId: 2,
        coverUrl: 'local://cover',
      );

      final List<CoverInfo> covers = await dao.getCollectionCovers(1);

      expect(covers, hasLength(1));
      expect(covers.first.thumbnailUrl, 'local://cover');
    });

    test('skips custom items whose cover_url is null', () async {
      await db.insert('custom_items', <String, Object?>{
        'id': 300,
        'title': 'No cover',
        'cached_at': 1700000000,
      });
      await db.insert('collection_items', <String, Object?>{
        'id': 3,
        'collection_id': 1,
        'media_type': 'custom',
        'external_id': 300,
        'status': 'not_started',
        'sort_order': 3,
        'added_at': 1700000000,
      });

      final List<CoverInfo> covers = await dao.getCollectionCovers(1);

      expect(covers, isEmpty);
    });

    test('respects the limit and includes custom alongside other types',
        () async {
      await insertCustom(
        id: 100,
        collectionItemId: 1,
        coverUrl: 'https://x.test/a.jpg',
      );
      await db.insert('games', <String, Object?>{
        'id': 500,
        'name': 'A Game',
        'cover_url': 'https://x.test/game.jpg',
        'cached_at': 1700000000,
      });
      await db.insert('collection_items', <String, Object?>{
        'id': 5,
        'collection_id': 1,
        'media_type': 'game',
        'external_id': 500,
        'status': 'completed',
        'sort_order': 0,
        'added_at': 1700000000,
      });

      final List<CoverInfo> covers = await dao.getCollectionCovers(1, limit: 10);

      expect(covers, hasLength(2));
      expect(
        covers.map((CoverInfo c) => c.mediaType).toSet(),
        <MediaType>{MediaType.custom, MediaType.game},
      );
    });
  });

  group('CollectionDao.getCollectionCovers — tv show source', () {
    Future<void> insertTvShow({
      required int tmdbId,
      required String source,
      required String posterUrl,
    }) async {
      await db.insert('tv_shows_cache', <String, Object?>{
        'tmdb_id': tmdbId,
        'source': source,
        'title': 'Show $source',
        'poster_url': posterUrl,
        'cached_at': 1700000000,
      });
    }

    test('should not duplicate a cover when two sources share a show id',
        () async {
      await insertTvShow(
        tmdbId: 700,
        source: 'tmdb',
        posterUrl: 'https://x.test/tmdb.jpg',
      );
      await insertTvShow(
        tmdbId: 700,
        source: 'anilist',
        posterUrl: 'https://x.test/anilist.jpg',
      );
      await db.insert('collection_items', <String, Object?>{
        'id': 10,
        'collection_id': 1,
        'media_type': 'tv_show',
        'external_id': 700,
        'source': 'tmdb',
        'status': 'not_started',
        'sort_order': 0,
        'added_at': 1700000000,
      });

      final List<CoverInfo> covers = await dao.getCollectionCovers(1);

      expect(covers, hasLength(1));
      expect(covers.first.thumbnailUrl, 'https://x.test/tmdb.jpg');
    });

    test('should match a NULL item source to the tmdb row', () async {
      await insertTvShow(
        tmdbId: 701,
        source: 'anilist',
        posterUrl: 'https://x.test/anilist.jpg',
      );
      await insertTvShow(
        tmdbId: 701,
        source: 'tmdb',
        posterUrl: 'https://x.test/tmdb.jpg',
      );
      await db.insert('collection_items', <String, Object?>{
        'id': 11,
        'collection_id': 1,
        'media_type': 'tv_show',
        'external_id': 701,
        'status': 'not_started',
        'sort_order': 0,
        'added_at': 1700000000,
      });

      final List<CoverInfo> covers = await dao.getCollectionCovers(1);

      expect(covers, hasLength(1));
      expect(covers.first.thumbnailUrl, 'https://x.test/tmdb.jpg');
    });
  });
}
