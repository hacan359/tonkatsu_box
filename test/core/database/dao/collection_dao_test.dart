import 'package:core/database/dao/collection_dao.dart';
import 'package:core/models/collected_item_info.dart';
import 'package:core/models/collection.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/cover_info.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/game.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/movie.dart';
import 'package:core/models/platform.dart';
import 'package:core/models/tv_show.dart';
import 'package:core/models/visual_novel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

Map<String, dynamic> _itemRow({
  int id = 1,
  int? collectionId = 1,
  String mediaType = 'game',
  int externalId = 100,
  int? platformId,
  String status = 'not_started',
  int sortOrder = 0,
  int addedAt = 1705320000,
}) =>
    <String, dynamic>{
      'id': id,
      'collection_id': collectionId,
      'media_type': mediaType,
      'external_id': externalId,
      'platform_id': platformId,
      'current_season': 0,
      'current_episode': 0,
      'status': status,
      'author_comment': null,
      'user_comment': null,
      'user_rating': null,
      'added_at': addedAt,
      'sort_order': sortOrder,
      'started_at': null,
      'completed_at': null,
      'last_activity_at': null,
    };

void main() {
  late TransactionMockDatabase mockDb;
  late MockTransaction mockTxn;
  late MockGameDao mockGameDao;
  late MockMovieDao mockMovieDao;
  late MockTvShowDao mockTvShowDao;
  late MockVisualNovelDao mockVisualNovelDao;
  late MockMangaDao mockMangaDao;
  late MockBookDao mockBookDao;
  late MockAlbumDao mockAlbumDao;
  late MockAnimeDao mockAnimeDao;
  late MockCustomMediaDao mockCustomMediaDao;
  late CollectionDao dao;

  setUp(() {
    mockDb = TransactionMockDatabase();
    mockTxn = MockTransaction();
    mockGameDao = MockGameDao();
    mockMovieDao = MockMovieDao();
    mockTvShowDao = MockTvShowDao();
    mockVisualNovelDao = MockVisualNovelDao();
    mockMangaDao = MockMangaDao();
    mockBookDao = MockBookDao();
    mockAlbumDao = MockAlbumDao();
    mockAnimeDao = MockAnimeDao();
    mockCustomMediaDao = MockCustomMediaDao();
    dao = CollectionDao(
      () async => mockDb,
      gameDao: mockGameDao,
      movieDao: mockMovieDao,
      tvShowDao: mockTvShowDao,
      visualNovelDao: mockVisualNovelDao,
      animeDao: mockAnimeDao,
      mangaDao: mockMangaDao,
      bookDao: mockBookDao,
      albumDao: mockAlbumDao,
      customMediaDao: mockCustomMediaDao,
    );
  });

  group('CollectionDao', () {
    group('getAllCollections', () {
      test('returns collections ordered by created_at DESC', () async {
        when(() => mockDb.query('collections', orderBy: 'created_at DESC'))
            .thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 1,
              'name': 'My Games',
              'author': 'User',
              'type': 'own',
              'created_at': 1705320000,
              'original_snapshot': null,
              'forked_from_author': null,
              'forked_from_name': null,
            },
          ],
        );

        final List<Collection> result = await dao.getAllCollections();

        expect(result.length, 1);
        expect(result.first.name, 'My Games');
      });
    });

    group('getCollectionsByType', () {
      test('filters by type', () async {
        when(
          () => mockDb.query(
            'collections',
            where: 'type = ?',
            whereArgs: <Object?>['own'],
            orderBy: 'created_at DESC',
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        final List<Collection> result =
            await dao.getCollectionsByType(CollectionType.own);

        expect(result, isEmpty);
      });
    });

    group('getCollectionById', () {
      test('returns null when not found', () async {
        when(
          () => mockDb.query(
            'collections',
            where: 'id = ?',
            whereArgs: <Object?>[999],
            limit: 1,
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        expect(await dao.getCollectionById(999), isNull);
      });

      test('returns collection when found', () async {
        when(
          () => mockDb.query(
            'collections',
            where: 'id = ?',
            whereArgs: <Object?>[1],
            limit: 1,
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 1,
              'name': 'Test',
              'author': 'User',
              'type': 'own',
              'created_at': 1705320000,
              'original_snapshot': null,
              'forked_from_author': null,
              'forked_from_name': null,
            },
          ],
        );

        final Collection? result = await dao.getCollectionById(1);

        expect(result, isNotNull);
        expect(result!.id, 1);
      });
    });

    group('createCollection', () {
      test('inserts and returns collection with id', () async {
        when(() => mockDb.insert('collections', any()))
            .thenAnswer((_) async => 5);

        final Collection result = await dao.createCollection(
          name: 'New Collection',
          author: 'Author',
        );

        expect(result.id, 5);
        expect(result.name, 'New Collection');
        expect(result.author, 'Author');
        expect(result.type, CollectionType.own);
      });

      test('passes optional fields', () async {
        when(() => mockDb.insert('collections', any()))
            .thenAnswer((_) async => 1);

        final Collection result = await dao.createCollection(
          name: 'Fork',
          author: 'Me',
          type: CollectionType.fork,
          forkedFromAuthor: 'Original',
          forkedFromName: 'Source',
        );

        expect(result.type, CollectionType.fork);
        expect(result.forkedFromAuthor, 'Original');
      });
    });

    group('updateCollection', () {
      test('updates name', () async {
        when(
          () => mockDb.update(
            'collections',
            <String, dynamic>{'name': 'Renamed'},
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 1);

        await dao.updateCollection(1, name: 'Renamed');

        verify(
          () => mockDb.update(
            'collections',
            <String, dynamic>{'name': 'Renamed'},
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).called(1);
      });

      test('skips when name is null', () async {
        await dao.updateCollection(1);

        verifyNever(
          () => mockDb.update(
            any(),
            any(),
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
          ),
        );
      });
    });

    group('deleteCollection', () {
      test('deletes by id', () async {
        when(
          () => mockDb.delete(
            'collections',
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 1);

        await dao.deleteCollection(1);

        verify(
          () => mockDb.delete(
            'collections',
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).called(1);
      });
    });

    group('getCollectionCount', () {
      test('returns count', () async {
        when(() => mockDb.rawQuery('SELECT COUNT(*) as count FROM collections'))
            .thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'count': 3},
          ],
        );

        expect(await dao.getCollectionCount(), 3);
      });
    });

    group('getCollectionItems', () {
      test('queries by collection_id', () async {
        when(
          () => mockDb.query(
            'collection_items',
            where: 'collection_id = ?',
            whereArgs: <Object?>[1],
            orderBy: 'sort_order ASC',
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[_itemRow()],
        );

        final List<CollectionItem> result = await dao.getCollectionItems(1);

        expect(result.length, 1);
      });

      test('queries uncategorized when collectionId is null', () async {
        when(
          () => mockDb.query(
            'collection_items',
            where: 'collection_id IS NULL',
            whereArgs: <Object?>[],
            orderBy: 'sort_order ASC',
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        final List<CollectionItem> result = await dao.getCollectionItems(null);

        expect(result, isEmpty);
      });

      test('filters by mediaType', () async {
        when(
          () => mockDb.query(
            'collection_items',
            where: 'collection_id = ? AND media_type = ?',
            whereArgs: <Object?>[1, 'game'],
            orderBy: 'sort_order ASC',
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        await dao.getCollectionItems(1, mediaType: MediaType.game);

        verify(
          () => mockDb.query(
            'collection_items',
            where: 'collection_id = ? AND media_type = ?',
            whereArgs: <Object?>[1, 'game'],
            orderBy: 'sort_order ASC',
          ),
        ).called(1);
      });
    });

    group('getCollectionItemsWithData', () {
      test('returns empty list for empty items', () async {
        when(
          () => mockDb.query(
            'collection_items',
            where: 'collection_id = ?',
            whereArgs: <Object?>[1],
            orderBy: 'sort_order ASC',
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        final List<CollectionItem> result =
            await dao.getCollectionItemsWithData(1);

        expect(result, isEmpty);
      });

      test('loads joined data for game items', () async {
        when(
          () => mockDb.query(
            'collection_items',
            where: 'collection_id = ?',
            whereArgs: <Object?>[1],
            orderBy: 'sort_order ASC',
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            _itemRow(id: 1, externalId: 100),
          ],
        );

        when(() => mockGameDao.getGamesByIds(<int>[100])).thenAnswer(
          (_) async => <Game>[const Game(id: 100, name: 'Zelda')],
        );
        when(() => mockGameDao.getPlatformsByIds(any()))
            .thenAnswer((_) async => <Platform>[]);

        final List<CollectionItem> result =
            await dao.getCollectionItemsWithData(1);

        expect(result.length, 1);
        expect(result.first.game, isNotNull);
        expect(result.first.game!.name, 'Zelda');
      });

      test('loads joined data for movie items', () async {
        when(
          () => mockDb.query(
            'collection_items',
            where: 'collection_id = ?',
            whereArgs: <Object?>[1],
            orderBy: 'sort_order ASC',
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            _itemRow(id: 1, mediaType: 'movie', externalId: 550),
          ],
        );

        when(() => mockMovieDao.getMoviesByTmdbIds(<int>[550])).thenAnswer(
          (_) async => <Movie>[const Movie(tmdbId: 550, title: 'Fight Club')],
        );
        when(() => mockMovieDao.getTmdbGenreMap('movie'))
            .thenAnswer((_) async => <String, String>{});

        final List<CollectionItem> result =
            await dao.getCollectionItemsWithData(1);

        expect(result.length, 1);
        expect(result.first.movie, isNotNull);
        expect(result.first.movie!.title, 'Fight Club');
      });

      test('loads joined data for tv show items', () async {
        when(
          () => mockDb.query(
            'collection_items',
            where: 'collection_id = ?',
            whereArgs: <Object?>[1],
            orderBy: 'sort_order ASC',
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            _itemRow(id: 1, mediaType: 'tv_show', externalId: 200),
          ],
        );

        when(() => mockTvShowDao.getTvShowsByTmdbIds(<int>[200])).thenAnswer(
          (_) async => <TvShow>[
            const TvShow(tmdbId: 200, title: 'Breaking Bad'),
          ],
        );
        when(() => mockMovieDao.getTmdbGenreMap('tv'))
            .thenAnswer((_) async => <String, String>{});

        final List<CollectionItem> result =
            await dao.getCollectionItemsWithData(1);

        expect(result.length, 1);
        expect(result.first.tvShow, isNotNull);
      });

      test('loads joined data for visual novel items', () async {
        when(
          () => mockDb.query(
            'collection_items',
            where: 'collection_id = ?',
            whereArgs: <Object?>[1],
            orderBy: 'sort_order ASC',
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            _itemRow(id: 1, mediaType: 'visual_novel', externalId: 500),
          ],
        );

        when(() => mockVisualNovelDao.getVisualNovelsByNumericIds(<int>[500]))
            .thenAnswer(
          (_) async => <VisualNovel>[
            const VisualNovel(id: 'v500', title: 'Steins;Gate'),
          ],
        );

        final List<CollectionItem> result =
            await dao.getCollectionItemsWithData(1);

        expect(result.length, 1);
        expect(result.first.visualNovel, isNotNull);
      });

      test('resolves numeric genre ids', () async {
        when(
          () => mockDb.query(
            'collection_items',
            where: 'collection_id = ?',
            whereArgs: <Object?>[1],
            orderBy: 'sort_order ASC',
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            _itemRow(id: 1, mediaType: 'movie', externalId: 550),
          ],
        );

        when(() => mockMovieDao.getMoviesByTmdbIds(<int>[550])).thenAnswer(
          (_) async => <Movie>[
            const Movie(
              tmdbId: 550,
              title: 'Fight Club',
              genres: <String>['28', '18'],
            ),
          ],
        );
        when(() => mockMovieDao.getTmdbGenreMap('movie')).thenAnswer(
          (_) async => <String, String>{'28': 'Action', '18': 'Drama'},
        );

        final List<CollectionItem> result =
            await dao.getCollectionItemsWithData(1);

        expect(result.first.movie!.genres, <String>['Action', 'Drama']);
      });
    });

    group('getAllCollectionItems', () {
      test('returns all items ordered by added_at', () async {
        when(
          () => mockDb.query(
            'collection_items',
            where: null,
            whereArgs: null,
            orderBy: 'added_at DESC',
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        final List<CollectionItem> result = await dao.getAllCollectionItems();

        expect(result, isEmpty);
      });

      test('filters by mediaType', () async {
        when(
          () => mockDb.query(
            'collection_items',
            where: 'media_type = ?',
            whereArgs: <Object?>['movie'],
            orderBy: 'added_at DESC',
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        await dao.getAllCollectionItems(mediaType: MediaType.movie);

        verify(
          () => mockDb.query(
            'collection_items',
            where: 'media_type = ?',
            whereArgs: <Object?>['movie'],
            orderBy: 'added_at DESC',
          ),
        ).called(1);
      });
    });

    group('getCollectionItemById', () {
      test('returns null when not found', () async {
        when(
          () => mockDb.query(
            'collection_items',
            where: 'id = ?',
            whereArgs: <Object?>[999],
            limit: 1,
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        expect(await dao.getCollectionItemById(999), isNull);
      });

      test('returns item when found', () async {
        when(
          () => mockDb.query(
            'collection_items',
            where: 'id = ?',
            whereArgs: <Object?>[1],
            limit: 1,
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[_itemRow()]);

        final CollectionItem? result = await dao.getCollectionItemById(1);

        expect(result, isNotNull);
        expect(result!.id, 1);
      });
    });

    group('findCollectionItem', () {
      test('finds by collection, mediaType and externalId', () async {
        when(
          () => mockDb.query(
            'collection_items',
            where: 'collection_id = ? AND media_type = ? AND external_id = ?',
            whereArgs: <Object?>[1, 'game', 100],
            limit: 1,
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[_itemRow()]);

        final CollectionItem? result = await dao.findCollectionItem(
          collectionId: 1,
          mediaType: MediaType.game,
          externalId: 100,
        );

        expect(result, isNotNull);
      });

      test('handles null collectionId — searches all collections', () async {
        when(
          () => mockDb.query(
            'collection_items',
            where: 'media_type = ? AND external_id = ?',
            whereArgs: <Object?>['game', 100],
            limit: 1,
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        final CollectionItem? result = await dao.findCollectionItem(
          collectionId: null,
          mediaType: MediaType.game,
          externalId: 100,
        );

        expect(result, isNull);
      });
    });

    group('addItemToCollection', () {
      test('inserts item and returns id', () async {
        when(
          () => mockDb.rawQuery(
            'SELECT MAX(sort_order) AS max_sort FROM collection_items '
            'WHERE collection_id = ?',
            <Object?>[1],
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'max_sort': 2},
          ],
        );
        when(() => mockDb.insert('collection_items', any()))
            .thenAnswer((_) async => 10);

        final int? id = await dao.addItemToCollection(
          collectionId: 1,
          mediaType: MediaType.game,
          externalId: 100,
        );

        expect(id, 10);
      });

      test('returns null on unique constraint violation', () async {
        when(
          () => mockDb.rawQuery(
            'SELECT MAX(sort_order) AS max_sort FROM collection_items '
            'WHERE collection_id = ?',
            <Object?>[1],
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'max_sort': 0},
          ],
        );
        when(() => mockDb.insert('collection_items', any()))
            .thenThrow(FakeDatabaseException());

        final int? id = await dao.addItemToCollection(
          collectionId: 1,
          mediaType: MediaType.game,
          externalId: 100,
        );

        expect(id, isNull);
      });
    });

    group('getNextSortOrder', () {
      test('returns max + 1 for collection', () async {
        when(
          () => mockDb.rawQuery(
            'SELECT MAX(sort_order) AS max_sort FROM collection_items '
            'WHERE collection_id = ?',
            <Object?>[1],
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'max_sort': 5},
          ],
        );

        expect(await dao.getNextSortOrder(1), 6);
      });

      test('returns 0 when collection is empty', () async {
        when(
          () => mockDb.rawQuery(
            'SELECT MAX(sort_order) AS max_sort FROM collection_items '
            'WHERE collection_id = ?',
            <Object?>[1],
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'max_sort': null},
          ],
        );

        expect(await dao.getNextSortOrder(1), 0);
      });

      test('handles null collectionId for uncategorized', () async {
        when(
          () => mockDb.rawQuery(
            'SELECT MAX(sort_order) AS max_sort FROM collection_items '
            'WHERE collection_id IS NULL',
            <Object?>[],
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'max_sort': null},
          ],
        );

        expect(await dao.getNextSortOrder(null), 0);
      });
    });

    group('reorderItems', () {
      test('does nothing for empty list', () async {
        await dao.reorderItems(1, <int>[]);

        verifyNever(() => mockTxn.batch());
      });

      test('updates sort_order in batch transaction', () async {
        final MockBatch mockBatch = MockBatch();
        mockDb.stubTransaction(mockTxn);
        when(() => mockTxn.batch()).thenReturn(mockBatch);
        when(
          () => mockBatch.update(
            any(),
            any(),
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
          ),
        ).thenReturn(null);
        when(() => mockBatch.commit(noResult: true))
            .thenAnswer((_) async => <Object?>[]);

        await dao.reorderItems(1, <int>[30, 20, 10]);

        verify(
          () => mockBatch.update(
            'collection_items',
            <String, dynamic>{'sort_order': 0},
            where: 'id = ?',
            whereArgs: <Object?>[30],
          ),
        ).called(1);
        verify(
          () => mockBatch.update(
            'collection_items',
            <String, dynamic>{'sort_order': 1},
            where: 'id = ?',
            whereArgs: <Object?>[20],
          ),
        ).called(1);
        verify(
          () => mockBatch.update(
            'collection_items',
            <String, dynamic>{'sort_order': 2},
            where: 'id = ?',
            whereArgs: <Object?>[10],
          ),
        ).called(1);
        verify(() => mockBatch.commit(noResult: true)).called(1);
      });
    });

    group('addItemsBatch', () {
      test('returns 0 and skips the transaction for empty rows', () async {
        final int inserted =
            await dao.addItemsBatch(1, <Map<String, dynamic>>[]);

        expect(inserted, 0);
        verifyNever(() => mockTxn.batch());
      });

      test('counts inserts, treating zero results as ignored conflicts',
          () async {
        final MockBatch mockBatch = MockBatch();
        when(() => mockDb.rawQuery(any(), any())).thenAnswer(
          (_) async =>
              <Map<String, dynamic>>[<String, dynamic>{'max_sort': 4}],
        );
        mockDb.stubTransaction(mockTxn);
        when(() => mockTxn.batch()).thenReturn(mockBatch);
        when(() => mockBatch.insert(any(), any(),
                conflictAlgorithm: any(named: 'conflictAlgorithm')))
            .thenReturn(null);
        when(() => mockBatch.commit())
            .thenAnswer((_) async => <Object?>[10, 0, 11]);

        final int inserted = await dao.addItemsBatch(7, <Map<String, dynamic>>[
          <String, dynamic>{'media_type': 'movie', 'external_id': 1},
          <String, dynamic>{'media_type': 'movie', 'external_id': 2},
          <String, dynamic>{'media_type': 'movie', 'external_id': 3},
        ]);

        expect(inserted, 2,
            reason: 'two ids > 0; the 0 is an ignored unique conflict');
      });

      test(
          'addItemsBatchReturningIds fills collection id and sort order, '
          'aligns ids with rows (null for ignored)', () async {
        final MockBatch mockBatch = MockBatch();
        when(() => mockDb.rawQuery(any(), any())).thenAnswer(
          (_) async =>
              <Map<String, dynamic>>[<String, dynamic>{'max_sort': 4}],
        );
        mockDb.stubTransaction(mockTxn);
        when(() => mockTxn.batch()).thenReturn(mockBatch);
        when(() => mockBatch.insert(any(), any(),
                conflictAlgorithm: any(named: 'conflictAlgorithm')))
            .thenReturn(null);
        when(() => mockBatch.commit())
            .thenAnswer((_) async => <Object?>[10, 0, 11]);

        final List<int?> ids =
            await dao.addItemsBatchReturningIds(7, <Map<String, dynamic>>[
          <String, dynamic>{'media_type': 'movie', 'external_id': 1},
          <String, dynamic>{'media_type': 'movie', 'external_id': 2},
          <String, dynamic>{'media_type': 'movie', 'external_id': 3},
        ]);

        expect(ids, <int?>[10, null, 11]);
        final List<dynamic> rows = verify(
          () => mockBatch.insert('collection_items', captureAny(),
              conflictAlgorithm: any(named: 'conflictAlgorithm')),
        ).captured;
        expect(rows, hasLength(3));
        final Map<String, dynamic> first = rows.first as Map<String, dynamic>;
        expect(first['collection_id'], 7);
        expect(first['external_id'], 1);
        expect(first['sort_order'], 5, reason: 'max_sort 4 → first is 5');
        expect((rows[1] as Map<String, dynamic>)['sort_order'], 6);
        expect((rows[2] as Map<String, dynamic>)['sort_order'], 7);
      });

      test('keeps added_at from the row, fills it only when absent', () async {
        final MockBatch mockBatch = MockBatch();
        when(() => mockDb.rawQuery(any(), any())).thenAnswer(
          (_) async =>
              <Map<String, dynamic>>[<String, dynamic>{'max_sort': 0}],
        );
        mockDb.stubTransaction(mockTxn);
        when(() => mockTxn.batch()).thenReturn(mockBatch);
        when(() => mockBatch.insert(any(), any(),
                conflictAlgorithm: any(named: 'conflictAlgorithm')))
            .thenReturn(null);
        when(() => mockBatch.commit())
            .thenAnswer((_) async => <Object?>[10, 11]);

        await dao.addItemsBatch(7, <Map<String, dynamic>>[
          <String, dynamic>{
            'media_type': 'book',
            'external_id': 1,
            'added_at': 1600000000,
          },
          <String, dynamic>{'media_type': 'book', 'external_id': 2},
        ]);

        final List<dynamic> rows = verify(
          () => mockBatch.insert('collection_items', captureAny(),
              conflictAlgorithm: any(named: 'conflictAlgorithm')),
        ).captured;
        expect((rows[0] as Map<String, dynamic>)['added_at'], 1600000000);
        final Object? filled = (rows[1] as Map<String, dynamic>)['added_at'];
        expect(filled, isA<int>());
        expect(filled, isNot(1600000000));
      });
    });

    group('updateItemFieldsBatch', () {
      test('does nothing for empty updates', () async {
        await dao.updateItemFieldsBatch(<(int, Map<String, dynamic>)>[]);

        verifyNever(() => mockTxn.batch());
      });

      test('updates only entries with non-empty field maps', () async {
        final MockBatch mockBatch = MockBatch();
        mockDb.stubTransaction(mockTxn);
        when(() => mockTxn.batch()).thenReturn(mockBatch);
        when(() => mockBatch.update(any(), any(),
                where: any(named: 'where'), whereArgs: any(named: 'whereArgs')))
            .thenReturn(null);
        when(() => mockBatch.commit(noResult: true))
            .thenAnswer((_) async => <Object?>[]);

        await dao.updateItemFieldsBatch(<(int, Map<String, dynamic>)>[
          (42, <String, dynamic>{'user_rating': 9.0}),
          (43, <String, dynamic>{}),
        ]);

        verify(() => mockBatch.update(
              'collection_items',
              <String, dynamic>{'user_rating': 9.0},
              where: 'id = ?',
              whereArgs: <Object?>[42],
            )).called(1);
        verifyNever(() => mockBatch.update(any(), any(),
            where: any(named: 'where'), whereArgs: <Object?>[43]));
        verify(() => mockBatch.commit(noResult: true)).called(1);
      });
    });

    group('removeItemFromCollection', () {
      test('deletes by id', () async {
        when(
          () => mockDb.delete(
            'collection_items',
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 1);

        await dao.removeItemFromCollection(1);

        verify(
          () => mockDb.delete(
            'collection_items',
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).called(1);
      });
    });

    group('updateItemStatus', () {
      test('sets notStarted — clears dates', () async {
        when(
          () => mockDb.query(
            'collection_items',
            columns: <String>['started_at', 'status', 'rewatch_count'],
            where: 'id = ?',
            whereArgs: <Object?>[1],
            limit: 1,
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'started_at': 1705320000},
          ],
        );
        when(
          () => mockDb.update(
            'collection_items',
            any(),
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 1);

        await dao.updateItemStatus(
          1,
          ItemStatus.notStarted,
          mediaType: MediaType.game,
        );

        final VerificationResult captured = verify(
          () => mockDb.update(
            'collection_items',
            captureAny(),
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        );
        captured.called(1);

        final Map<String, dynamic> data =
            captured.captured.first as Map<String, dynamic>;
        expect(data['status'], 'not_started');
        expect(data['started_at'], isNull);
        expect(data['completed_at'], isNull);
      });

      test('sets inProgress — sets started_at when not set', () async {
        when(
          () => mockDb.query(
            'collection_items',
            columns: <String>['started_at', 'status', 'rewatch_count'],
            where: 'id = ?',
            whereArgs: <Object?>[1],
            limit: 1,
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'started_at': null},
          ],
        );
        when(
          () => mockDb.update(
            'collection_items',
            any(),
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 1);

        await dao.updateItemStatus(
          1,
          ItemStatus.inProgress,
          mediaType: MediaType.game,
        );

        final VerificationResult captured = verify(
          () => mockDb.update(
            'collection_items',
            captureAny(),
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        );

        final Map<String, dynamic> data =
            captured.captured.first as Map<String, dynamic>;
        expect(data['status'], 'in_progress');
        expect(data['started_at'], isA<int>());
        expect(data['completed_at'], isNull);
      });

      test('sets completed — sets both dates when not started', () async {
        when(
          () => mockDb.query(
            'collection_items',
            columns: <String>['started_at', 'status', 'rewatch_count'],
            where: 'id = ?',
            whereArgs: <Object?>[1],
            limit: 1,
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'started_at': null},
          ],
        );
        when(
          () => mockDb.update(
            'collection_items',
            any(),
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 1);

        await dao.updateItemStatus(
          1,
          ItemStatus.completed,
          mediaType: MediaType.game,
        );

        final VerificationResult captured = verify(
          () => mockDb.update(
            'collection_items',
            captureAny(),
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        );

        final Map<String, dynamic> data =
            captured.captured.first as Map<String, dynamic>;
        expect(data['status'], 'completed');
        expect(data['started_at'], isA<int>());
        expect(data['completed_at'], isA<int>());
      });

      test('sets completed — keeps existing started_at', () async {
        when(
          () => mockDb.query(
            'collection_items',
            columns: <String>['started_at', 'status', 'rewatch_count'],
            where: 'id = ?',
            whereArgs: <Object?>[1],
            limit: 1,
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'started_at': 1705320000},
          ],
        );
        when(
          () => mockDb.update(
            'collection_items',
            any(),
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 1);

        await dao.updateItemStatus(
          1,
          ItemStatus.completed,
          mediaType: MediaType.game,
        );

        final VerificationResult captured = verify(
          () => mockDb.update(
            'collection_items',
            captureAny(),
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        );

        final Map<String, dynamic> data =
            captured.captured.first as Map<String, dynamic>;
        expect(data.containsKey('started_at'), false);
        expect(data['completed_at'], isA<int>());
      });

      Future<Map<String, dynamic>> runStatusUpdate({
        required ItemStatus newStatus,
        required String currentStatus,
        required int? currentCount,
      }) async {
        when(
          () => mockDb.query(
            'collection_items',
            columns: <String>['started_at', 'status', 'rewatch_count'],
            where: 'id = ?',
            whereArgs: <Object?>[1],
            limit: 1,
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{
              'started_at': 1705320000,
              'status': currentStatus,
              'rewatch_count': currentCount,
            },
          ],
        );
        when(
          () => mockDb.update(
            'collection_items',
            any(),
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 1);

        await dao.updateItemStatus(1, newStatus, mediaType: MediaType.game);

        final VerificationResult captured = verify(
          () => mockDb.update(
            'collection_items',
            captureAny(),
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        );
        return captured.captured.first as Map<String, dynamic>;
      }

      test('first transition to completed: rewatch_count null → 0', () async {
        final Map<String, dynamic> data = await runStatusUpdate(
          newStatus: ItemStatus.completed,
          currentStatus: 'in_progress',
          currentCount: null,
        );
        expect(data['rewatch_count'], 0);
      });

      test('replaying → completed bumps rewatch_count', () async {
        final Map<String, dynamic> data = await runStatusUpdate(
          newStatus: ItemStatus.completed,
          currentStatus: 'replaying',
          currentCount: 2,
        );
        expect(data['rewatch_count'], 3);
      });

      test('completed → completed keeps rewatch_count untouched', () async {
        final Map<String, dynamic> data = await runStatusUpdate(
          newStatus: ItemStatus.completed,
          currentStatus: 'completed',
          currentCount: 2,
        );
        expect(data.containsKey('rewatch_count'), isFalse);
      });

      test('sets replaying — bare status, no dates or counter', () async {
        final Map<String, dynamic> data = await runStatusUpdate(
          newStatus: ItemStatus.replaying,
          currentStatus: 'completed',
          currentCount: 1,
        );
        expect(data['status'], 'replaying');
        expect(data['last_activity_at'], isA<int>());
        expect(data.containsKey('started_at'), isFalse);
        expect(data.containsKey('completed_at'), isFalse);
        expect(data.containsKey('rewatch_count'), isFalse);
      });
    });

    group('updateItemRewatchCount', () {
      test('writes the value verbatim, null included', () async {
        when(
          () => mockDb.update(
            'collection_items',
            any(),
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 1);

        await dao.updateItemRewatchCount(1, 5);
        await dao.updateItemRewatchCount(1, null);

        final VerificationResult captured = verify(
          () => mockDb.update(
            'collection_items',
            captureAny(),
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        );
        captured.called(2);
        expect(
          captured.captured.first,
          <String, dynamic>{'rewatch_count': 5},
        );
        expect(
          captured.captured.last,
          <String, dynamic>{'rewatch_count': null},
        );
      });
    });

    group('updateItemActivityDates', () {
      test('updates provided dates', () async {
        final DateTime date = DateTime(2024, 6, 15);
        when(
          () => mockDb.update(
            'collection_items',
            any(),
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 1);

        await dao.updateItemActivityDates(1, startedAt: date);

        verify(
          () => mockDb.update(
            'collection_items',
            <String, dynamic>{
              'started_at': date.millisecondsSinceEpoch ~/ 1000,
            },
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).called(1);
      });

      test('skips when no dates provided', () async {
        await dao.updateItemActivityDates(1);

        verifyNever(
          () => mockDb.update(
            any(),
            any(),
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
          ),
        );
      });

      test('writes explicit NULLs when the clear flags are set', () async {
        when(
          () => mockDb.update(
            'collection_items',
            any(),
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 1);

        await dao.updateItemActivityDates(
          1,
          clearStartedAt: true,
          clearCompletedAt: true,
        );

        verify(
          () => mockDb.update(
            'collection_items',
            <String, dynamic>{
              'started_at': null,
              'completed_at': null,
            },
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).called(1);
      });

      test('clear flag wins over a supplied date for the same field', () async {
        when(
          () => mockDb.update(
            'collection_items',
            any(),
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 1);

        await dao.updateItemActivityDates(
          1,
          completedAt: DateTime(2024, 6, 15),
          clearCompletedAt: true,
        );

        verify(
          () => mockDb.update(
            'collection_items',
            <String, dynamic>{'completed_at': null},
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).called(1);
      });
    });

    group('updateItemProgress', () {
      test('updates season and episode', () async {
        when(
          () => mockDb.update(
            'collection_items',
            any(),
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 1);

        await dao.updateItemProgress(1, currentSeason: 3, currentEpisode: 5);

        verify(
          () => mockDb.update(
            'collection_items',
            <String, dynamic>{'current_season': 3, 'current_episode': 5},
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).called(1);
      });

      test('skips when no progress provided', () async {
        await dao.updateItemProgress(1);

        verifyNever(
          () => mockDb.update(
            any(),
            any(),
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
          ),
        );
      });
    });

    group('updateItemAuthorComment', () {
      test('updates comment', () async {
        when(
          () => mockDb.update(
            'collection_items',
            <String, dynamic>{'author_comment': 'Nice'},
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 1);

        await dao.updateItemAuthorComment(1, 'Nice');

        verify(
          () => mockDb.update(
            'collection_items',
            <String, dynamic>{'author_comment': 'Nice'},
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).called(1);
      });
    });

    group('updateItemUserComment', () {
      test('updates comment', () async {
        when(
          () => mockDb.update(
            'collection_items',
            <String, dynamic>{'user_comment': 'My note'},
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 1);

        await dao.updateItemUserComment(1, 'My note');

        verify(
          () => mockDb.update(
            'collection_items',
            <String, dynamic>{'user_comment': 'My note'},
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).called(1);
      });
    });

    group('updateItemUserRating', () {
      test('updates rating', () async {
        when(
          () => mockDb.update(
            'collection_items',
            <String, dynamic>{'user_rating': 9},
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 1);

        await dao.updateItemUserRating(1, 9);

        verify(
          () => mockDb.update(
            'collection_items',
            <String, dynamic>{'user_rating': 9},
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).called(1);
      });

      test('clears rating with null', () async {
        when(
          () => mockDb.update(
            'collection_items',
            <String, dynamic>{'user_rating': null},
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 1);

        await dao.updateItemUserRating(1, null);

        verify(
          () => mockDb.update(
            'collection_items',
            <String, dynamic>{'user_rating': null},
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).called(1);
      });
    });

    group('updateItemCollectionId', () {
      void stubItemLookup() {
        mockDb.stubTransaction(mockTxn);
        when(
          () => mockTxn.query(
            'collection_items',
            columns: <String>[
              'collection_id',
              'media_type',
              'external_id',
              'source',
              'platform_id',
            ],
            where: 'id = ?',
            whereArgs: <Object?>[1],
            limit: 1,
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);
      }

      test('moves item and returns true', () async {
        stubItemLookup();
        when(
          () => mockDb.rawQuery(
            'SELECT MAX(sort_order) AS max_sort FROM collection_items '
            'WHERE collection_id = ?',
            <Object?>[2],
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'max_sort': 3},
          ],
        );
        when(
          () => mockTxn.update(
            'collection_items',
            any(),
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 1);

        final bool result = await dao.updateItemCollectionId(1, 2);

        expect(result, true);
      });

      test('returns false on unique constraint violation', () async {
        stubItemLookup();
        when(
          () => mockDb.rawQuery(
            'SELECT MAX(sort_order) AS max_sort FROM collection_items '
            'WHERE collection_id = ?',
            <Object?>[2],
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'max_sort': 0},
          ],
        );
        when(
          () => mockTxn.update(
            'collection_items',
            any(),
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenThrow(FakeDatabaseException());

        final bool result = await dao.updateItemCollectionId(1, 2);

        expect(result, false);
      });
    });

    group('getUniquePlatformIds', () {
      test('returns platform ids from all collections', () async {
        when(() => mockDb.rawQuery(any(), any())).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'platform_id': 1},
            <String, dynamic>{'platform_id': 2},
          ],
        );

        final List<int> result = await dao.getUniquePlatformIds();

        expect(result, <int>[1, 2]);
      });

      test('filters by collectionId', () async {
        when(() => mockDb.rawQuery(any(), any())).thenAnswer(
          (_) async => <Map<String, dynamic>>[],
        );

        await dao.getUniquePlatformIds(collectionId: 1);

        verify(() => mockDb.rawQuery(any(), <Object?>[1])).called(1);
      });
    });

    group('getCollectionItemCount', () {
      test('counts by collectionId', () async {
        when(() => mockDb.rawQuery(any(), any())).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'count': 10},
          ],
        );

        expect(await dao.getCollectionItemCount(1), 10);
      });

      test('counts uncategorized when null', () async {
        when(() => mockDb.rawQuery(any(), any())).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'count': 2},
          ],
        );

        expect(await dao.getCollectionItemCount(null), 2);
      });
    });

    group('getCollectionItemStats', () {
      test('aggregates stats by type and status', () async {
        when(() => mockDb.rawQuery(any(), any())).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{
              'media_type': 'game',
              'status': 'completed',
              'count': 3,
            },
            <String, dynamic>{
              'media_type': 'movie',
              'status': 'in_progress',
              'count': 2,
            },
          ],
        );

        final Map<String, int> stats = await dao.getCollectionItemStats(1);

        expect(stats['total'], 5);
        expect(stats['completed'], 3);
        expect(stats['inProgress'], 2);
        expect(stats['gameCount'], 3);
        expect(stats['movieCount'], 2);
      });

      test('returns zero stats for empty collection', () async {
        when(() => mockDb.rawQuery(any(), any())).thenAnswer(
          (_) async => <Map<String, dynamic>>[],
        );

        final Map<String, int> stats = await dao.getCollectionItemStats(1);

        expect(stats['total'], 0);
        expect(stats['completed'], 0);
      });
    });

    group('clearCollectionItems', () {
      test('clears by collectionId', () async {
        when(
          () => mockDb.delete(
            'collection_items',
            where: 'collection_id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 5);

        await dao.clearCollectionItems(1);

        verify(
          () => mockDb.delete(
            'collection_items',
            where: 'collection_id = ?',
            whereArgs: <Object?>[1],
          ),
        ).called(1);
      });

      test('clears uncategorized when null', () async {
        when(
          () => mockDb.delete(
            'collection_items',
            where: 'collection_id IS NULL',
          ),
        ).thenAnswer((_) async => 2);

        await dao.clearCollectionItems(null);

        verify(
          () => mockDb.delete(
            'collection_items',
            where: 'collection_id IS NULL',
          ),
        ).called(1);
      });
    });

    group('getCollectedItemInfos', () {
      test('returns grouped infos by external_id', () async {
        when(() => mockDb.rawQuery(any(), any())).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 1,
              'external_id': 100,
              'collection_id': 1,
              'name': 'My Games',
            },
            <String, dynamic>{
              'id': 2,
              'external_id': 100,
              'collection_id': 2,
              'name': 'Favorites',
            },
            <String, dynamic>{
              'id': 3,
              'external_id': 200,
              'collection_id': 1,
              'name': 'My Games',
            },
          ],
        );

        final Map<int, List<CollectedItemInfo>> result =
            await dao.getCollectedItemInfos(MediaType.game);

        expect(result.keys.length, 2);
        expect(result[100]!.length, 2);
        expect(result[200]!.length, 1);
      });

      test('defaults a null source to the media type default, not tmdb',
          () async {
        when(() => mockDb.rawQuery(any(), any())).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 1,
              'external_id': 100,
              'collection_id': 1,
              'name': 'My Manga',
            },
          ],
        );

        final Map<int, List<CollectedItemInfo>> result =
            await dao.getCollectedItemInfos(MediaType.manga);

        expect(result[100]!.single.source, DataSource.anilist);
      });

      test('keeps the stored source when present', () async {
        when(() => mockDb.rawQuery(any(), any())).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 1,
              'external_id': 100,
              'collection_id': 1,
              'name': 'Shows',
              'source': 'tvmaze',
            },
          ],
        );

        final Map<int, List<CollectedItemInfo>> result =
            await dao.getCollectedItemInfos(MediaType.tvShow);

        expect(result[100]!.single.source, DataSource.tvmaze);
      });
    });

    group('getUncategorizedItemCount', () {
      test('returns count of uncategorized items', () async {
        when(
          () => mockDb.rawQuery(
            'SELECT COUNT(*) as count FROM collection_items '
            'WHERE collection_id IS NULL',
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'count': 4},
          ],
        );

        expect(await dao.getUncategorizedItemCount(), 4);
      });
    });

    group('getCollectionCovers', () {
      test('returns covers for collection', () async {
        when(() => mockDb.rawQuery(any(), any())).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{
              'external_id': 100,
              'media_type': 'game',
              'platform_id': null,
              'thumbnail_url': 'https://example.com/cover.jpg',
            },
          ],
        );

        final List<CoverInfo> result = await dao.getCollectionCovers(1);

        expect(result.length, 1);
        expect(result.first.externalId, 100);
        expect(result.first.thumbnailUrl, 'https://example.com/cover.jpg');
      });

      test('returns covers for uncategorized', () async {
        when(() => mockDb.rawQuery(any(), any())).thenAnswer(
          (_) async => <Map<String, dynamic>>[],
        );

        final List<CoverInfo> result = await dao.getCollectionCovers(null);

        expect(result, isEmpty);
      });
    });

    group('cloneItemToCollection', () {
      test('nulls tag_id in clone (source tag belongs to source collection)',
          () async {
        when(
          () => mockDb.query(
            'collection_items',
            where: 'id = ?',
            whereArgs: <Object?>[1],
            limit: 1,
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{
              ..._itemRow(),
              'tag_id': 77,
            },
          ],
        );
        when(
          () => mockDb.rawQuery(
            'SELECT MAX(sort_order) AS max_sort FROM collection_items '
            'WHERE collection_id = ?',
            <Object?>[2],
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'max_sort': null},
          ],
        );
        when(() => mockDb.insert('collection_items', any()))
            .thenAnswer((_) async => 101);

        final int? newId = await dao.cloneItemToCollection(1, 2);

        expect(newId, 101);
        final Map<String, dynamic> inserted = verify(
          () => mockDb.insert('collection_items', captureAny()),
        ).captured.single as Map<String, dynamic>;
        expect(inserted['tag_id'], isNull);
        expect(inserted['collection_id'], 2);
        expect(inserted.containsKey('id'), isFalse);
      });

      test('returns null when source item does not exist', () async {
        when(
          () => mockDb.query(
            'collection_items',
            where: 'id = ?',
            whereArgs: <Object?>[1],
            limit: 1,
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        expect(await dao.cloneItemToCollection(1, 2), isNull);
      });
    });

    group('setItemOverrideName', () {
      test('writes the trimmed override on a non-empty input', () async {
        when(
          () => mockDb.update(
            'collection_items',
            any(),
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 1);

        await dao.setItemOverrideName(1, '  FF7R  ');

        verify(
          () => mockDb.update(
            'collection_items',
            <String, dynamic>{'override_name': 'FF7R'},
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).called(1);
      });

      test('clears the override on an empty input', () async {
        when(
          () => mockDb.update(
            'collection_items',
            any(),
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 1);

        await dao.setItemOverrideName(1, '');

        verify(
          () => mockDb.update(
            'collection_items',
            <String, dynamic>{'override_name': null},
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).called(1);
      });

      test('clears the override on a whitespace-only input', () async {
        when(
          () => mockDb.update(
            'collection_items',
            any(),
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 1);

        await dao.setItemOverrideName(1, '   ');

        verify(
          () => mockDb.update(
            'collection_items',
            <String, dynamic>{'override_name': null},
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).called(1);
      });

      test('clears the override on null input', () async {
        when(
          () => mockDb.update(
            'collection_items',
            any(),
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 1);

        await dao.setItemOverrideName(1, null);

        verify(
          () => mockDb.update(
            'collection_items',
            <String, dynamic>{'override_name': null},
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).called(1);
      });
    });

    group('resolveCardLink', () {
      void stubGameHydration() {
        when(() => mockGameDao.getGamesByIds(any()))
            .thenAnswer((_) async => <Game>[const Game(id: 100, name: 'Zelda')]);
        when(() => mockGameDao.getPlatformsByIds(any()))
            .thenAnswer((_) async => <Platform>[]);
      }

      void stubQuery(List<Map<String, dynamic>> rows) {
        when(
          () => mockDb.query(
            'collection_items',
            where: 'media_type = ? AND external_id = ?',
            whereArgs: <Object?>['game', 100],
          ),
        ).thenAnswer((_) async => rows);
      }

      test('returns empty when nothing matches', () async {
        stubQuery(<Map<String, dynamic>>[]);

        final List<CollectionItem> result = await dao.resolveCardLink(
          mediaType: MediaType.game,
          externalId: 100,
        );

        expect(result, isEmpty);
      });

      test('prefers the hinted collection when it matches', () async {
        stubQuery(<Map<String, dynamic>>[
          _itemRow(id: 1, collectionId: 1, externalId: 100),
          _itemRow(id: 2, collectionId: 2, externalId: 100),
        ]);
        stubGameHydration();

        final List<CollectionItem> result = await dao.resolveCardLink(
          mediaType: MediaType.game,
          externalId: 100,
          collectionId: 2,
        );

        expect(result, hasLength(1));
        expect(result.first.collectionId, 2);
      });

      test('falls back to all collections when the hint does not match',
          () async {
        stubQuery(<Map<String, dynamic>>[
          _itemRow(id: 1, collectionId: 1, externalId: 100),
          _itemRow(id: 2, collectionId: 2, externalId: 100),
        ]);
        stubGameHydration();

        final List<CollectionItem> result = await dao.resolveCardLink(
          mediaType: MediaType.game,
          externalId: 100,
          collectionId: 99,
        );

        expect(result, hasLength(2));
      });

      test('narrows a multi-source type by source', () async {
        when(
          () => mockDb.query(
            'collection_items',
            where: 'media_type = ? AND external_id = ? '
                'AND COALESCE(source, ?) = ?',
            whereArgs: <Object?>['anime', 100, 'anilist', 'kitsu'],
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        final List<CollectionItem> result = await dao.resolveCardLink(
          mediaType: MediaType.anime,
          externalId: 100,
          source: DataSource.kitsu,
        );

        expect(result, isEmpty);
      });

      test('ignores source for a single-source type', () async {
        stubQuery(<Map<String, dynamic>>[
          _itemRow(id: 1, collectionId: 1, externalId: 100),
        ]);
        stubGameHydration();

        final List<CollectionItem> result = await dao.resolveCardLink(
          mediaType: MediaType.game,
          externalId: 100,
          source: DataSource.igdb,
        );

        expect(result, hasLength(1));
      });
    });
  });
}
