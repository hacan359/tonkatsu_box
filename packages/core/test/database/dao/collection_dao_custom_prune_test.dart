import 'package:core/database/dao/audio_dao.dart';
import 'package:core/database/dao/anime_dao.dart';
import 'package:core/database/dao/book_dao.dart';
import 'package:core/database/dao/collection_dao.dart';
import 'package:core/database/dao/custom_media_dao.dart';
import 'package:core/database/dao/game_dao.dart';
import 'package:core/database/dao/manga_dao.dart';
import 'package:core/database/dao/movie_dao.dart';
import 'package:core/database/dao/tv_show_dao.dart';
import 'package:core/database/dao/visual_novel_dao.dart';
import 'package:core/database/migrations/migration.dart';
import 'package:core/database/migrations/migration_registry.dart';
import 'package:test/test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
        onConfigure: (Database d) => d.execute('PRAGMA foreign_keys = ON'),
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
      audioDao: AudioDao(getDb),
      customMediaDao: CustomMediaDao(getDb),
    );
    for (final int id in <int>[1, 2]) {
      await db.insert('collections', <String, Object?>{
        'id': id,
        'name': 'C$id',
        'author': 'tester',
        'created_at': 0,
      });
    }
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertCard(int id) => db.insert('custom_items', <String, Object?>{
        'id': id,
        'title': 'Card $id',
        'cached_at': 0,
      });

  Future<int> insertItem(int collectionId, int cardId) =>
      db.insert('collection_items', <String, Object?>{
        'collection_id': collectionId,
        'media_type': 'custom',
        'external_id': cardId,
        'added_at': 0,
      });

  Future<Set<int>> cardIds() async => <int>{
        for (final Map<String, Object?> row
            in await db.query('custom_items', columns: <String>['id']))
          row['id']! as int,
      };

  group('CollectionDao custom card pruning', () {
    group('removeItemFromCollection', () {
      test('deletes the card with its last item', () async {
        await insertCard(7);
        final int itemId = await insertItem(1, 7);

        await dao.removeItemFromCollection(itemId);

        expect(await cardIds(), isEmpty);
      });

      test('leaves cards the removed item never pointed at', () async {
        await insertCard(9);
        final int gameItem = await db.insert(
          'collection_items',
          <String, Object?>{
            'collection_id': 1,
            'media_type': 'game',
            'external_id': 9,
            'added_at': 0,
          },
        );

        await dao.removeItemFromCollection(gameItem);

        expect(await cardIds(), <int>{9});
      });

      test('keeps a card another collection still holds', () async {
        await insertCard(7);
        final int itemId = await insertItem(1, 7);
        await insertItem(2, 7);

        await dao.removeItemFromCollection(itemId);

        expect(await cardIds(), <int>{7});
      });

      test('keeps a card a board still shows', () async {
        await insertCard(7);
        final int itemId = await insertItem(1, 7);
        await db.insert('canvas_items', <String, Object?>{
          'collection_id': 2,
          'item_type': 'custom',
          'item_ref_id': 7,
          'created_at': 0,
        });

        await dao.removeItemFromCollection(itemId);

        expect(await cardIds(), <int>{7});
      });

      test('keeps a card a mood grid cell still shows', () async {
        await insertCard(7);
        final int itemId = await insertItem(1, 7);
        final int gridId =
            await db.insert('mood_grids', <String, Object?>{'name': 'G'});
        await db.insert('mood_grid_cells', <String, Object?>{
          'grid_id': gridId,
          'position': 0,
          'media_type': 'custom',
          'external_id': 7,
        });

        await dao.removeItemFromCollection(itemId);

        expect(await cardIds(), <int>{7});
      });
    });

    group('deleteCollection', () {
      test('deletes only the cards left without items', () async {
        await insertCard(7);
        await insertCard(8);
        await insertItem(1, 7);
        await insertItem(1, 8);
        await insertItem(2, 8);

        await dao.deleteCollection(1);

        expect(await cardIds(), <int>{8});
      });
    });

    group('clearCollectionItems', () {
      test('deletes the cards of the cleared collection', () async {
        await insertCard(7);
        await insertCard(8);
        await insertItem(1, 7);
        await insertItem(2, 8);

        await dao.clearCollectionItems(1);

        expect(await cardIds(), <int>{8});
      });
    });
  });
}
