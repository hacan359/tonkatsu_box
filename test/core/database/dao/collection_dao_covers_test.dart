import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tonkatsu_box/core/database/dao/anime_dao.dart';
import 'package:tonkatsu_box/core/database/dao/collection_dao.dart';
import 'package:tonkatsu_box/core/database/dao/custom_media_dao.dart';
import 'package:tonkatsu_box/core/database/dao/game_dao.dart';
import 'package:tonkatsu_box/core/database/dao/manga_dao.dart';
import 'package:tonkatsu_box/core/database/dao/movie_dao.dart';
import 'package:tonkatsu_box/core/database/dao/tv_show_dao.dart';
import 'package:tonkatsu_box/core/database/dao/visual_novel_dao.dart';
import 'package:tonkatsu_box/core/database/schema.dart';
import 'package:tonkatsu_box/shared/models/cover_info.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';

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
        version: 1,
        onCreate: (Database d, int _) async {
          await DatabaseSchema.createAll(d);
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
}
