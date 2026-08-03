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
import 'package:core/models/collection.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/custom_media.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/platform.dart';
import 'package:core/models/visual_novel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/test_helpers.dart';

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
        // Mirrors openAppDatabase — without it FK cascades silently no-op.
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
      customMediaDao: CustomMediaDao(getDb),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> newCollection(String name) async {
    final Collection c = await dao.createCollection(name: name, author: 'me');
    return c.id;
  }

  group('CollectionDao collections', () {
    group('createCollection', () {
      test('returns the row with its generated id', () async {
        final Collection c =
            await dao.createCollection(name: 'Backlog', author: 'me');

        expect(c.id, greaterThan(0));
        expect((await dao.getCollectionById(c.id))?.name, 'Backlog');
      });

      test('defaults to the own type', () async {
        final Collection c =
            await dao.createCollection(name: 'Backlog', author: 'me');

        expect(c.type, CollectionType.own);
      });

      test('keeps the supplied createdAt instead of now', () async {
        final DateTime when = DateTime.fromMillisecondsSinceEpoch(
          1600000000 * 1000,
        );

        final Collection c = await dao.createCollection(
          name: 'Restored',
          author: 'me',
          createdAt: when,
        );

        expect(c.createdAt, when);
        expect((await dao.getCollectionById(c.id))?.createdAt, when);
      });

      test('persists fork provenance', () async {
        final Collection c = await dao.createCollection(
          name: 'Fork',
          author: 'me',
          type: CollectionType.fork,
          forkedFromAuthor: 'someone',
          forkedFromName: 'Original',
        );

        final Collection? stored = await dao.getCollectionById(c.id);
        expect(stored?.type, CollectionType.fork);
        expect(stored?.forkedFromAuthor, 'someone');
        expect(stored?.forkedFromName, 'Original');
      });
    });

    group('findCollectionByName', () {
      test('returns null when no collection carries the name', () async {
        expect(await dao.findCollectionByName('Nope'), isNull);
      });

      test('finds an existing collection by exact name', () async {
        final int id = await newCollection('Backlog');

        expect((await dao.findCollectionByName('Backlog'))?.id, id);
      });

      test('does not match a different case', () async {
        await newCollection('Backlog');

        expect(await dao.findCollectionByName('backlog'), isNull);
      });
    });

    group('getCollectionsByType', () {
      test('returns only collections of the requested type', () async {
        await dao.createCollection(name: 'Mine', author: 'me');
        await dao.createCollection(
          name: 'Theirs',
          author: 'them',
          type: CollectionType.imported,
        );

        expect(await dao.getCollectionsByType(CollectionType.own), hasLength(1));
        expect(
          (await dao.getCollectionsByType(CollectionType.imported)).single.name,
          'Theirs',
        );
      });
    });

    group('getAllCollections', () {
      test('sorts by created_at descending', () async {
        await dao.createCollection(
          name: 'Older',
          author: 'me',
          createdAt: DateTime.fromMillisecondsSinceEpoch(1000 * 1000),
        );
        await dao.createCollection(
          name: 'Newer',
          author: 'me',
          createdAt: DateTime.fromMillisecondsSinceEpoch(2000 * 1000),
        );

        expect(
          (await dao.getAllCollections()).map((Collection c) => c.name),
          <String>['Newer', 'Older'],
        );
      });
    });

    group('updateCollection', () {
      test('writes only the fields that were passed', () async {
        final int id = await newCollection('Before');
        await dao.updateCollection(id, description: 'desc');

        await dao.updateCollection(id, name: 'After');

        final Collection? stored = await dao.getCollectionById(id);
        expect(stored?.name, 'After');
        expect(stored?.description, 'desc');
      });

      test('clears the hero image only on the explicit clear flag', () async {
        final int id = await newCollection('C');
        await dao.updateCollection(id, heroImagePath: '/covers/hero.png');

        await dao.updateCollection(id, name: 'Renamed');
        expect(
          (await dao.getCollectionById(id))?.heroImagePath,
          '/covers/hero.png',
        );

        await dao.updateCollection(id, clearHeroImage: true);
        expect((await dao.getCollectionById(id))?.heroImagePath, isNull);
      });

      test('clears the description only on the explicit clear flag', () async {
        final int id = await newCollection('C');
        await dao.updateCollection(id, description: 'desc');

        await dao.updateCollection(id, clearDescription: true);

        expect((await dao.getCollectionById(id))?.description, isNull);
      });

      test('is a no-op when nothing was passed', () async {
        final int id = await newCollection('Untouched');

        await dao.updateCollection(id);

        expect((await dao.getCollectionById(id))?.name, 'Untouched');
      });
    });

    group('deleteCollection', () {
      test('cascades to its items', () async {
        final int id = await newCollection('Doomed');
        await dao.addItemToCollection(
          collectionId: id,
          mediaType: MediaType.game,
          externalId: 1,
        );

        await dao.deleteCollection(id);

        expect(await dao.getCollectionById(id), isNull);
        expect(await dao.getCollectionItems(id), isEmpty);
      });
    });

    group('getCollectionCount', () {
      test('is zero on an empty database', () async {
        expect(await dao.getCollectionCount(), 0);
      });

      test('counts every collection regardless of type', () async {
        await newCollection('A');
        await dao.createCollection(
          name: 'B',
          author: 'me',
          type: CollectionType.imported,
        );

        expect(await dao.getCollectionCount(), 2);
      });
    });
  });

  group('CollectionDao items', () {
    group('addItemToCollection', () {
      test('returns the new row id', () async {
        final int id = await newCollection('C');

        final int? itemId = await dao.addItemToCollection(
          collectionId: id,
          mediaType: MediaType.game,
          externalId: 42,
        );

        expect(itemId, isNotNull);
        expect((await dao.getCollectionItemById(itemId!))?.externalId, 42);
      });

      test('returns null on a UNIQUE conflict instead of throwing', () async {
        final int id = await newCollection('C');
        await dao.addItemToCollection(
          collectionId: id,
          mediaType: MediaType.movie,
          externalId: 7,
        );

        final int? second = await dao.addItemToCollection(
          collectionId: id,
          mediaType: MediaType.movie,
          externalId: 7,
        );

        expect(second, isNull);
      });

      test('adds uncategorized items when collectionId is null', () async {
        final int? itemId = await dao.addItemToCollection(
          collectionId: null,
          mediaType: MediaType.game,
          externalId: 5,
        );

        expect(itemId, isNotNull);
        expect(await dao.getCollectionItems(null), hasLength(1));
      });

      test('appends an increasing sort order within a collection', () async {
        final int id = await newCollection('C');

        final int? first = await dao.addItemToCollection(
          collectionId: id,
          mediaType: MediaType.game,
          externalId: 1,
        );
        final int? second = await dao.addItemToCollection(
          collectionId: id,
          mediaType: MediaType.game,
          externalId: 2,
        );

        final CollectionItem? a = await dao.getCollectionItemById(first!);
        final CollectionItem? b = await dao.getCollectionItemById(second!);
        expect(b!.sortOrder, greaterThan(a!.sortOrder));
      });

      test('keeps the supplied addedAt', () async {
        final int id = await newCollection('C');

        final int? itemId = await dao.addItemToCollection(
          collectionId: id,
          mediaType: MediaType.game,
          externalId: 1,
          addedAt: DateTime.fromMillisecondsSinceEpoch(1600000000 * 1000),
        );

        expect(
          (await dao.getCollectionItemById(itemId!))?.addedAt,
          DateTime.fromMillisecondsSinceEpoch(1600000000 * 1000),
        );
      });
    });

    group('findCollectionItem', () {
      test('returns null when nothing matches', () async {
        expect(
          await dao.findCollectionItem(
            collectionId: null,
            mediaType: MediaType.game,
            externalId: 1,
          ),
          isNull,
        );
      });

      test('searches across collections when collectionId is null', () async {
        final int id = await newCollection('C');
        await dao.addItemToCollection(
          collectionId: id,
          mediaType: MediaType.game,
          externalId: 42,
        );

        final CollectionItem? found = await dao.findCollectionItem(
          collectionId: null,
          mediaType: MediaType.game,
          externalId: 42,
        );

        expect(found?.collectionId, id);
      });

      test('disambiguates games by platform', () async {
        final int id = await newCollection('C');
        await dao.addItemToCollection(
          collectionId: id,
          mediaType: MediaType.game,
          externalId: 42,
          platformId: 6,
        );

        expect(
          await dao.findCollectionItem(
            collectionId: id,
            mediaType: MediaType.game,
            externalId: 42,
            platformId: 48,
          ),
          isNull,
        );
        expect(
          await dao.findCollectionItem(
            collectionId: id,
            mediaType: MediaType.game,
            externalId: 42,
            platformId: 6,
          ),
          isNotNull,
        );
      });

      test('treats a null stored source as the media default', () async {
        final int id = await newCollection('C');
        await dao.addItemToCollection(
          collectionId: id,
          mediaType: MediaType.anime,
          externalId: 9,
        );

        expect(
          await dao.findCollectionItem(
            collectionId: id,
            mediaType: MediaType.anime,
            externalId: 9,
            source: MediaType.anime.defaultSource,
          ),
          isNotNull,
        );
        expect(
          await dao.findCollectionItem(
            collectionId: id,
            mediaType: MediaType.anime,
            externalId: 9,
            source: DataSource.kitsu,
          ),
          isNull,
        );
      });
    });

    group('findCollectionItemWithData', () {
      test('returns null when nothing matches', () async {
        expect(
          await dao.findCollectionItemWithData(
            collectionId: null,
            mediaType: MediaType.game,
            externalId: 1,
          ),
          isNull,
        );
      });

      test('hydrates the joined media model', () async {
        final int id = await newCollection('C');
        await db.insert('games', <String, Object?>{
          'id': 42,
          'name': 'Hollow Knight',
          'cached_at': 1700000000,
        });
        await dao.addItemToCollection(
          collectionId: id,
          mediaType: MediaType.game,
          externalId: 42,
        );

        final CollectionItem? found = await dao.findCollectionItemWithData(
          collectionId: id,
          mediaType: MediaType.game,
          externalId: 42,
        );

        expect(found?.game?.name, 'Hollow Knight');
      });
    });

    group('findAllCollectionItems', () {
      test('returns every collection holding the same media', () async {
        final int a = await newCollection('A');
        final int b = await newCollection('B');
        await dao.addItemToCollection(
          collectionId: a,
          mediaType: MediaType.movie,
          externalId: 7,
        );
        await dao.addItemToCollection(
          collectionId: b,
          mediaType: MediaType.movie,
          externalId: 7,
        );

        final List<CollectionItem> found = await dao.findAllCollectionItems(
          mediaType: MediaType.movie,
          externalId: 7,
        );

        expect(
          found.map((CollectionItem i) => i.collectionId).toSet(),
          <int?>{a, b},
        );
      });

      test('returns empty when the media is not collected', () async {
        expect(
          await dao.findAllCollectionItems(
            mediaType: MediaType.movie,
            externalId: 999,
          ),
          isEmpty,
        );
      });

      test('filters by source, defaulting null rows to the media default',
          () async {
        final int a = await newCollection('A');
        await dao.addItemToCollection(
          collectionId: a,
          mediaType: MediaType.anime,
          externalId: 9,
        );

        expect(
          await dao.findAllCollectionItems(
            mediaType: MediaType.anime,
            externalId: 9,
            source: MediaType.anime.defaultSource,
          ),
          hasLength(1),
        );
        expect(
          await dao.findAllCollectionItems(
            mediaType: MediaType.anime,
            externalId: 9,
            source: DataSource.kitsu,
          ),
          isEmpty,
        );
      });
    });

    group('getItemsWithDataByRowIds', () {
      test('returns empty for an empty id list', () async {
        expect(await dao.getItemsWithDataByRowIds(const <int>[]), isEmpty);
      });

      test('skips row ids with no item', () async {
        final int id = await newCollection('C');
        final int? itemId = await dao.addItemToCollection(
          collectionId: id,
          mediaType: MediaType.game,
          externalId: 1,
        );

        final List<CollectionItem> found =
            await dao.getItemsWithDataByRowIds(<int>[itemId!, itemId + 999]);

        expect(found, hasLength(1));
        expect(found.single.id, itemId);
      });

      test('hydrates the joined media model', () async {
        final int id = await newCollection('C');
        await db.insert('games', <String, Object?>{
          'id': 42,
          'name': 'Celeste',
          'cached_at': 1700000000,
        });
        final int? itemId = await dao.addItemToCollection(
          collectionId: id,
          mediaType: MediaType.game,
          externalId: 42,
        );

        final List<CollectionItem> found =
            await dao.getItemsWithDataByRowIds(<int>[itemId!]);

        expect(found.single.game?.name, 'Celeste');
      });

      test('spans more ids than one IN-clause chunk holds', () async {
        final int id = await newCollection('C');
        final List<int> itemIds = <int>[];
        for (int i = 0; i < 1100; i++) {
          itemIds.add((await dao.addItemToCollection(
            collectionId: id,
            mediaType: MediaType.game,
            externalId: i,
          ))!);
        }

        expect(await dao.getItemsWithDataByRowIds(itemIds), hasLength(1100));
      });
    });

    group('getAllCollectionItemsWithData', () {
      test('returns empty on an empty database', () async {
        expect(await dao.getAllCollectionItemsWithData(), isEmpty);
      });

      test('filters by media type', () async {
        final int id = await newCollection('C');
        await dao.addItemToCollection(
          collectionId: id,
          mediaType: MediaType.game,
          externalId: 1,
        );
        await dao.addItemToCollection(
          collectionId: id,
          mediaType: MediaType.movie,
          externalId: 2,
        );

        expect(
          await dao.getAllCollectionItemsWithData(mediaType: MediaType.game),
          hasLength(1),
        );
      });

      test('spans collections and uncategorized items', () async {
        final int id = await newCollection('C');
        await dao.addItemToCollection(
          collectionId: id,
          mediaType: MediaType.game,
          externalId: 1,
        );
        await dao.addItemToCollection(
          collectionId: null,
          mediaType: MediaType.game,
          externalId: 2,
        );

        expect(await dao.getAllCollectionItemsWithData(), hasLength(2));
      });
    });

    group('updateItemTimeSpent', () {
      test('stores the total minutes', () async {
        final int id = await newCollection('C');
        final int? itemId = await dao.addItemToCollection(
          collectionId: id,
          mediaType: MediaType.game,
          externalId: 1,
        );

        await dao.updateItemTimeSpent(itemId!, 125);

        expect(
          (await dao.getCollectionItemById(itemId))?.timeSpentMinutes,
          125,
        );
      });

      test('overwrites rather than accumulates', () async {
        final int id = await newCollection('C');
        final int? itemId = await dao.addItemToCollection(
          collectionId: id,
          mediaType: MediaType.game,
          externalId: 1,
        );

        await dao.updateItemTimeSpent(itemId!, 60);
        await dao.updateItemTimeSpent(itemId, 90);

        expect((await dao.getCollectionItemById(itemId))?.timeSpentMinutes, 90);
      });
    });

    group('setItemFavorite', () {
      test('flips the flag on and back off', () async {
        final int id = await newCollection('C');
        final int? itemId = await dao.addItemToCollection(
          collectionId: id,
          mediaType: MediaType.game,
          externalId: 1,
        );

        await dao.setItemFavorite(itemId!, isFavorite: true);
        expect((await dao.getCollectionItemById(itemId))?.isFavorite, isTrue);

        await dao.setItemFavorite(itemId, isFavorite: false);
        expect((await dao.getCollectionItemById(itemId))?.isFavorite, isFalse);
      });
    });

    group('getCollectionIdsWithStatus', () {
      test('is empty when no item carries the status', () async {
        expect(
          await dao.getCollectionIdsWithStatus(ItemStatus.completed),
          isEmpty,
        );
      });

      test('includes null for matching uncategorized items', () async {
        await dao.addItemToCollection(
          collectionId: null,
          mediaType: MediaType.game,
          externalId: 1,
          status: ItemStatus.completed,
        );

        expect(
          await dao.getCollectionIdsWithStatus(ItemStatus.completed),
          <int?>{null},
        );
      });

      test('deduplicates collections holding several matches', () async {
        final int id = await newCollection('C');
        await dao.addItemToCollection(
          collectionId: id,
          mediaType: MediaType.game,
          externalId: 1,
          status: ItemStatus.completed,
        );
        await dao.addItemToCollection(
          collectionId: id,
          mediaType: MediaType.game,
          externalId: 2,
          status: ItemStatus.completed,
        );
        await dao.addItemToCollection(
          collectionId: id,
          mediaType: MediaType.game,
          externalId: 3,
          status: ItemStatus.dropped,
        );

        expect(
          await dao.getCollectionIdsWithStatus(ItemStatus.completed),
          <int?>{id},
        );
      });
    });

    group('getItemIdsByExternalId', () {
      test('matches across collections', () async {
        final int a = await newCollection('A');
        final int b = await newCollection('B');
        await dao.addItemToCollection(
          collectionId: a,
          mediaType: MediaType.game,
          externalId: 42,
        );
        await dao.addItemToCollection(
          collectionId: b,
          mediaType: MediaType.game,
          externalId: 42,
        );

        final List<({int id, int? collectionId, int? platformId})> found =
            await dao.getItemIdsByExternalId(42, 'game');

        expect(
          found.map((({int id, int? collectionId, int? platformId}) r) =>
              r.collectionId).toSet(),
          <int?>{a, b},
        );
      });

      test('ignores platform unless filterByPlatform is set', () async {
        final int a = await newCollection('A');
        await dao.addItemToCollection(
          collectionId: a,
          mediaType: MediaType.game,
          externalId: 42,
          platformId: 6,
        );

        expect(
          await dao.getItemIdsByExternalId(42, 'game', platformId: 48),
          hasLength(1),
        );
        expect(
          await dao.getItemIdsByExternalId(
            42,
            'game',
            platformId: 48,
            filterByPlatform: true,
          ),
          isEmpty,
        );
      });

      test('a null platform with filterByPlatform matches only NULL rows',
          () async {
        final int a = await newCollection('A');
        await dao.addItemToCollection(
          collectionId: a,
          mediaType: MediaType.game,
          externalId: 42,
          platformId: 6,
        );
        await dao.addItemToCollection(
          collectionId: a,
          mediaType: MediaType.game,
          externalId: 42,
        );

        final List<({int id, int? collectionId, int? platformId})> found =
            await dao.getItemIdsByExternalId(
          42,
          'game',
          filterByPlatform: true,
        );

        expect(found, hasLength(1));
        expect(found.single.platformId, isNull);
      });

      test('returns empty for an uncollected external id', () async {
        expect(await dao.getItemIdsByExternalId(999, 'game'), isEmpty);
      });
    });

    group('clearAllData', () {
      test('truncates collections, items and media caches', () async {
        final int id = await newCollection('C');
        await db.insert('games', <String, Object?>{
          'id': 42,
          'name': 'Celeste',
          'cached_at': 1700000000,
        });
        await dao.addItemToCollection(
          collectionId: id,
          mediaType: MediaType.game,
          externalId: 42,
        );

        await dao.clearAllData();

        expect(await dao.getAllCollections(), isEmpty);
        expect(await dao.getAllCollectionItemsWithData(), isEmpty);
        expect(await db.query('games'), isEmpty);
      });

      test('keeps the static reference tables seeded by migrations', () async {
        final int before = (await db.query('platforms')).length;

        await dao.clearAllData();

        expect((await db.query('platforms')).length, before);
        expect(before, greaterThan(0));
      });

      test('is a no-op on an already empty database', () async {
        await dao.clearAllData();

        expect(await dao.getCollectionCount(), 0);
      });
    });
  });

  // _loadJoinedData fans out one query per media type and re-attaches the
  // results; each branch needs its own cached row to be exercised.
  group('CollectionDao hydration', () {
    late int collectionId;

    setUp(() async {
      collectionId = await newCollection('Mixed');
    });

    Future<CollectionItem> hydrateOne({
      required MediaType mediaType,
      required int externalId,
      int? platformId,
    }) async {
      final int? itemId = await dao.addItemToCollection(
        collectionId: collectionId,
        mediaType: mediaType,
        externalId: externalId,
        platformId: platformId,
      );
      final List<CollectionItem> items =
          await dao.getItemsWithDataByRowIds(<int>[itemId!]);
      return items.single;
    }

    test('attaches a game and its platform', () async {
      await GameDao(() async => db).upsertGame(
        createTestGame(id: 42, name: 'Hollow Knight'),
      );
      final Platform? platform =
          await GameDao(() async => db).getPlatformById(6);

      final CollectionItem item = await hydrateOne(
        mediaType: MediaType.game,
        externalId: 42,
        platformId: platform?.id,
      );

      expect(item.game?.name, 'Hollow Knight');
      expect(item.platform?.id, platform?.id);
    });

    test('leaves the platform null for a game without one', () async {
      await GameDao(() async => db).upsertGame(createTestGame(id: 42));

      final CollectionItem item =
          await hydrateOne(mediaType: MediaType.game, externalId: 42);

      expect(item.game, isNotNull);
      expect(item.platform, isNull);
    });

    test('attaches a movie', () async {
      await MovieDao(() async => db).upsertMovie(
        createTestMovie(tmdbId: 100, title: 'Arrival'),
      );

      final CollectionItem item =
          await hydrateOne(mediaType: MediaType.movie, externalId: 100);

      expect(item.movie?.title, 'Arrival');
    });

    test('attaches a tv show', () async {
      await TvShowDao(() async => db).upsertTvShow(
        createTestTvShow(tmdbId: 200, title: 'Severance'),
      );

      final CollectionItem item =
          await hydrateOne(mediaType: MediaType.tvShow, externalId: 200);

      expect(item.tvShow?.title, 'Severance');
    });

    test('attaches a visual novel', () async {
      final VisualNovel vn =
          createTestVisualNovel(id: 'v500', title: 'Steins;Gate');
      await VisualNovelDao(() async => db).upsertVisualNovel(vn);

      final CollectionItem item = await hydrateOne(
        mediaType: MediaType.visualNovel,
        externalId: vn.numericId,
      );

      expect(item.visualNovel?.title, 'Steins;Gate');
    });

    test('attaches an anime', () async {
      await AnimeDao(() async => db).upsertAnime(
        createTestAnime(id: 300, title: 'Cowboy Bebop'),
      );

      final CollectionItem item =
          await hydrateOne(mediaType: MediaType.anime, externalId: 300);

      expect(item.anime?.title, 'Cowboy Bebop');
    });

    test('attaches a manga', () async {
      await MangaDao(() async => db).upsertManga(
        createTestManga(id: 400, title: 'Berserk'),
      );

      final CollectionItem item =
          await hydrateOne(mediaType: MediaType.manga, externalId: 400);

      expect(item.manga?.title, 'Berserk');
    });

    test('attaches a book', () async {
      await BookDao(() async => db).upsertBook(
        createTestBook(id: '500', title: 'Dune'),
      );

      final CollectionItem item =
          await hydrateOne(mediaType: MediaType.book, externalId: 500);

      expect(item.book?.title, 'Dune');
    });

    test('attaches a custom card', () async {
      await CustomMediaDao(() async => db).upsert(
        const CustomMedia(id: 600, title: 'My card'),
      );

      final CollectionItem item =
          await hydrateOne(mediaType: MediaType.custom, externalId: 600);

      expect(item.customMedia?.title, 'My card');
    });

    test('resolves the platform a custom card carries itself', () async {
      final Platform? platform =
          await GameDao(() async => db).getPlatformById(6);
      await CustomMediaDao(() async => db).upsert(
        CustomMedia(id: 600, title: 'My card', platformId: platform?.id),
      );

      final CollectionItem item =
          await hydrateOne(mediaType: MediaType.custom, externalId: 600);

      expect(item.platform?.id, platform?.id);
    });

    test('animation reads the tv cache for the tvShow platform', () async {
      await TvShowDao(() async => db).upsertTvShow(
        createTestTvShow(tmdbId: 700, title: 'Arcane'),
      );

      final CollectionItem item = await hydrateOne(
        mediaType: MediaType.animation,
        externalId: 700,
        platformId: AnimationSource.tvShow,
      );

      expect(item.tvShow?.title, 'Arcane');
      expect(item.movie, isNull);
    });

    test('animation reads the movie cache otherwise', () async {
      await MovieDao(() async => db).upsertMovie(
        createTestMovie(tmdbId: 800, title: 'Spirited Away'),
      );

      final CollectionItem item = await hydrateOne(
        mediaType: MediaType.animation,
        externalId: 800,
      );

      expect(item.movie?.title, 'Spirited Away');
      expect(item.tvShow, isNull);
    });

    test('hydrates a mixed batch in one pass', () async {
      await GameDao(() async => db)
          .upsertGame(createTestGame(id: 42, name: 'Game'));
      await MovieDao(() async => db)
          .upsertMovie(createTestMovie(tmdbId: 100, title: 'Movie'));
      await AnimeDao(() async => db)
          .upsertAnime(createTestAnime(id: 300, title: 'Anime'));
      await MangaDao(() async => db)
          .upsertManga(createTestManga(id: 400, title: 'Manga'));

      final List<int> ids = <int>[
        (await dao.addItemToCollection(
          collectionId: collectionId,
          mediaType: MediaType.game,
          externalId: 42,
        ))!,
        (await dao.addItemToCollection(
          collectionId: collectionId,
          mediaType: MediaType.movie,
          externalId: 100,
        ))!,
        (await dao.addItemToCollection(
          collectionId: collectionId,
          mediaType: MediaType.anime,
          externalId: 300,
        ))!,
        (await dao.addItemToCollection(
          collectionId: collectionId,
          mediaType: MediaType.manga,
          externalId: 400,
        ))!,
      ];

      final List<CollectionItem> items =
          await dao.getItemsWithDataByRowIds(ids);

      expect(
        items.map((CollectionItem i) => i.itemName).toSet(),
        <String>{'Game', 'Movie', 'Anime', 'Manga'},
      );
    });

    test('leaves the join null when the cache row is missing', () async {
      final CollectionItem item =
          await hydrateOne(mediaType: MediaType.anime, externalId: 999);

      expect(item.anime, isNull);
    });
  });
}
