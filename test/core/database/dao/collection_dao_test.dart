import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/database/dao/collection_dao.dart';
import 'package:xerabora/shared/models/collected_item_info.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/cover_info.dart';
import 'package:xerabora/shared/models/game.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/movie.dart';
import 'package:xerabora/shared/models/platform.dart';
import 'package:xerabora/shared/models/tv_show.dart';
import 'package:xerabora/shared/models/visual_novel.dart';

import '../../../helpers/mocks.dart';

/// Минимальная строка collection_items для [CollectionItem.fromDb].
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
      customMediaDao: mockCustomMediaDao,
    );
  });

  group('CollectionDao', () {
    // ==================== Collections ====================

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

    // ==================== Collection Items ====================

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

      test('handles null collectionId for uncategorized', () async {
        when(
          () => mockDb.query(
            'collection_items',
            where:
                'collection_id IS NULL AND media_type = ? AND external_id = ?',
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
        // getNextSortOrder
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
            columns: <String>['started_at'],
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
            columns: <String>['started_at'],
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
            columns: <String>['started_at'],
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
            columns: <String>['started_at'],
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
      test('moves item and returns true', () async {
        // getNextSortOrder
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
          () => mockDb.update(
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
          () => mockDb.update(
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

    // ==================== Info ====================

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

    // ==================== Collection Covers ====================

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
  });
}
