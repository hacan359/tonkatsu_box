import 'package:core/database/dao/audio_dao.dart';
import 'package:core/database/dao/anime_dao.dart';
import 'package:core/database/dao/book_dao.dart';
import 'package:core/database/dao/canvas_dao.dart';
import 'package:core/database/dao/collection_dao.dart';
import 'package:core/database/dao/custom_media_dao.dart';
import 'package:core/database/dao/game_dao.dart';
import 'package:core/database/dao/manga_dao.dart';
import 'package:core/database/dao/movie_dao.dart';
import 'package:core/database/dao/tv_show_dao.dart';
import 'package:core/database/dao/visual_novel_dao.dart';
import 'package:core/database/migrations/migration.dart';
import 'package:core/database/migrations/migration_registry.dart';
import 'package:core/models/canvas_item.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/cover_info.dart';
import 'package:core/models/game.dart';
import 'package:core/models/image_type.dart';
import 'package:test/test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  const String override = 'https://example.com/mine.png';
  const String apiCover = 'https://images.igdb.com/igdb/image/upload/t_cover_big/co1.jpg';

  late Database db;
  late CollectionDao dao;
  late GameDao gameDao;
  late CanvasDao canvasDao;

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
    gameDao = GameDao(getDb);
    canvasDao = CanvasDao(getDb);
    dao = CollectionDao(
      getDb,
      gameDao: gameDao,
      movieDao: MovieDao(getDb),
      tvShowDao: TvShowDao(getDb),
      visualNovelDao: VisualNovelDao(getDb),
      animeDao: AnimeDao(getDb),
      mangaDao: MangaDao(getDb),
      bookDao: BookDao(getDb),
      audioDao: AudioDao(getDb),
      customMediaDao: CustomMediaDao(getDb),
    );

    await db.insert('collections', <String, Object?>{
      'id': 1,
      'name': 'C',
      'author': 'tester',
      'created_at': 0,
    });
    await gameDao.upsertGame(const Game(id: 10, name: 'G', coverUrl: apiCover));
    for (final int id in <int>[1, 2]) {
      await db.insert('collection_items', <String, Object?>{
        'id': id,
        'collection_id': id == 1 ? 1 : null,
        'media_type': 'game',
        'external_id': 10,
        'status': 'not_started',
        'added_at': 0,
      });
    }
  });

  tearDown(() async {
    await db.close();
  });

  Future<CollectionItem> item(int id) async =>
      (await dao.getItemsWithDataByRowIds(<int>[id])).single;

  group('CollectionDao', () {
    group('setItemOverrideCoverUrl', () {
      test('should store the override and expose it through the getters',
          () async {
        await dao.setItemOverrideCoverUrl(1, override);

        final CollectionItem stored = await item(1);
        expect(stored.overrideCoverUrl, override);
        expect(stored.coverUrl, override);
        expect(stored.cachedCoverUrl, apiCover);
        expect(stored.imageType, ImageType.coverOverride);
      });

      test('should clear the override when given null', () async {
        await dao.setItemOverrideCoverUrl(1, override);
        await dao.setItemOverrideCoverUrl(1, null);

        final CollectionItem stored = await item(1);
        expect(stored.overrideCoverUrl, isNull);
        expect(stored.coverUrl, apiCover);
      });

      test('should survive an API refetch replacing the game row', () async {
        await dao.setItemOverrideCoverUrl(1, override);

        await gameDao.upsertGame(
          const Game(id: 10, name: 'G', coverUrl: 'https://new/cover.jpg'),
        );

        final CollectionItem stored = await item(1);
        expect(stored.overrideCoverUrl, override);
        expect(stored.cachedCoverUrl, 'https://new/cover.jpg');
      });

      test('should touch only the given row', () async {
        await dao.setItemOverrideCoverUrl(1, override);

        expect((await item(2)).overrideCoverUrl, isNull);
      });
    });

    group('countItemsWithOverrideCover', () {
      test('should count every row showing the same override', () async {
        expect(await dao.countItemsWithOverrideCover(override), 0);

        await dao.setItemOverrideCoverUrl(1, override);
        expect(await dao.countItemsWithOverrideCover(override), 1);

        await dao.setItemOverrideCoverUrl(2, override);
        expect(await dao.countItemsWithOverrideCover(override), 2);
      });
    });

    group('getCollectionCovers', () {
      test('should carry the override next to the API cover', () async {
        await dao.setItemOverrideCoverUrl(1, override);

        final CoverInfo cover = (await dao.getCollectionCovers(1)).single;
        expect(cover.overrideCoverUrl, override);
        expect(cover.displayUrl, override);
        expect(cover.imageType, ImageType.coverOverride);
      });

      test('should include an item whose only cover is the override',
          () async {
        await gameDao.upsertGame(const Game(id: 10, name: 'G'));
        expect(await dao.getCollectionCovers(1), isEmpty);

        await dao.setItemOverrideCoverUrl(1, override);

        expect(await dao.getCollectionCovers(1), hasLength(1));
      });
    });
  });

  group('CanvasDao', () {
    group('getCanvasItems', () {
      test('should join the override of the matching collection item',
          () async {
        await dao.setItemOverrideCoverUrl(1, override);
        await db.insert('canvas_items', <String, Object?>{
          'collection_id': 1,
          'item_type': 'game',
          'item_ref_id': 10,
          'x': 0,
          'y': 0,
          'created_at': 0,
        });

        final List<Map<String, dynamic>> rows =
            await canvasDao.getCanvasItems(1);
        final CanvasItem card = CanvasItem.fromDb(rows.single);
        expect(card.overrideCoverUrl, override);
        expect(card.mediaImageType, ImageType.coverOverride);
      });
    });
  });
}
