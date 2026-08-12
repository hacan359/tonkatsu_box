import 'package:core/models/collection.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/data/repositories/collection_repository.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    registerAllFallbacks();
    registerFallbackValue(<Map<String, dynamic>>[]);
    registerFallbackValue(<(int, Map<String, dynamic>)>[]);
  });

  group('CollectionStats', () {
    group('constructor', () {
      test('should create экземпляр с обязательными полями 2', () {
        const CollectionStats stats = CollectionStats(
          total: 10,
          completed: 3,
          inProgress: 2,
          notStarted: 4,
          dropped: 1,
          planned: 0,
        );

        expect(stats.total, 10);
        expect(stats.completed, 3);
        expect(stats.inProgress, 2);
        expect(stats.notStarted, 4);
        expect(stats.dropped, 1);
        expect(stats.planned, 0);
      });
    });

    group('completionPercent', () {
      test('should return правильный процент', () {
        const CollectionStats stats = CollectionStats(
          total: 10,
          completed: 5,
          inProgress: 2,
          notStarted: 3,
          dropped: 0,
          planned: 0,
        );

        expect(stats.completionPercent, 50.0);
      });

      test('should return 0 при пустой коллекции', () {
        const CollectionStats stats = CollectionStats(
          total: 0,
          completed: 0,
          inProgress: 0,
          notStarted: 0,
          dropped: 0,
          planned: 0,
        );

        expect(stats.completionPercent, 0.0);
      });

      test('should return 100 при полном прохождении', () {
        const CollectionStats stats = CollectionStats(
          total: 5,
          completed: 5,
          inProgress: 0,
          notStarted: 0,
          dropped: 0,
          planned: 0,
        );

        expect(stats.completionPercent, 100.0);
      });

      test('should handle дробные проценты', () {
        const CollectionStats stats = CollectionStats(
          total: 3,
          completed: 1,
          inProgress: 1,
          notStarted: 1,
          dropped: 0,
          planned: 0,
        );

        expect(stats.completionPercent, closeTo(33.33, 0.01));
      });
    });

    group('completionPercentFormatted', () {
      test('should return форматированный процент', () {
        const CollectionStats stats = CollectionStats(
          total: 10,
          completed: 5,
          inProgress: 5,
          notStarted: 0,
          dropped: 0,
          planned: 0,
        );

        expect(stats.completionPercentFormatted, '50%');
      });

      test('должен округлять дробный процент', () {
        const CollectionStats stats = CollectionStats(
          total: 3,
          completed: 1,
          inProgress: 2,
          notStarted: 0,
          dropped: 0,
          planned: 0,
        );

        expect(stats.completionPercentFormatted, '33%');
      });

      test('should return 0% для пустой коллекции', () {
        expect(CollectionStats.empty.completionPercentFormatted, '0%');
      });
    });

    group('mediaTypeCounts', () {
      test('should map every media type to its count field', () {
        const CollectionStats stats = CollectionStats(
          total: 6,
          completed: 0,
          inProgress: 0,
          notStarted: 6,
          dropped: 0,
          planned: 0,
          gameCount: 1,
          movieCount: 2,
          tvShowCount: 3,
          animationCount: 4,
          visualNovelCount: 5,
          mangaCount: 6,
          animeCount: 7,
          bookCount: 8,
          musicCount: 10,
          customCount: 9,
        );

        expect(stats.mediaTypeCounts, <MediaType, int>{
          MediaType.game: 1,
          MediaType.movie: 2,
          MediaType.tvShow: 3,
          MediaType.animation: 4,
          MediaType.visualNovel: 5,
          MediaType.manga: 6,
          MediaType.anime: 7,
          MediaType.book: 8,
          MediaType.music: 10,
          MediaType.custom: 9,
        });
      });

      test('should cover all MediaType values', () {
        expect(
          CollectionStats.empty.mediaTypeCounts.keys,
          containsAll(MediaType.values),
        );
      });
    });

    group('presentMediaTypes', () {
      test('should return empty list when no items', () {
        expect(CollectionStats.empty.presentMediaTypes, isEmpty);
      });

      test('should order dominant type first', () {
        const CollectionStats stats = CollectionStats(
          total: 10,
          completed: 0,
          inProgress: 0,
          notStarted: 10,
          dropped: 0,
          planned: 0,
          gameCount: 2,
          bookCount: 7,
          movieCount: 1,
        );

        expect(stats.presentMediaTypes, <MediaType>[
          MediaType.book,
          MediaType.game,
          MediaType.movie,
        ]);
      });

      test('should skip types with zero items', () {
        const CollectionStats stats = CollectionStats(
          total: 3,
          completed: 0,
          inProgress: 0,
          notStarted: 3,
          dropped: 0,
          planned: 0,
          animeCount: 3,
        );

        expect(stats.presentMediaTypes, <MediaType>[MediaType.anime]);
      });

      test('should break count ties by enum order', () {
        const CollectionStats stats = CollectionStats(
          total: 4,
          completed: 0,
          inProgress: 0,
          notStarted: 4,
          dropped: 0,
          planned: 0,
          mangaCount: 2,
          movieCount: 2,
        );

        // movie precedes manga in the MediaType declaration order.
        expect(stats.presentMediaTypes, <MediaType>[
          MediaType.movie,
          MediaType.manga,
        ]);
      });
    });

    group('empty', () {
      test('должен иметь все нулевые значения', () {
        expect(CollectionStats.empty.total, 0);
        expect(CollectionStats.empty.completed, 0);
        expect(CollectionStats.empty.inProgress, 0);
        expect(CollectionStats.empty.notStarted, 0);
        expect(CollectionStats.empty.dropped, 0);
        expect(CollectionStats.empty.planned, 0);
      });
    });
  });

  group('CollectionRepository', () {
    late MockDatabaseService mockDb;
    late CollectionRepository repository;

    setUp(() {
      mockDb = MockDatabaseService();
      repository = CollectionRepository(db: mockDb);
    });

    group('getAll', () {
      test('должен делегировать в DatabaseService', () async {
        final List<Collection> collections = <Collection>[
          createTestCollection(id: 1, name: 'Collection 1'),
          createTestCollection(id: 2, name: 'Collection 2'),
        ];

        when(() => mockDb.getAllCollections())
            .thenAnswer((_) async => collections);

        final List<Collection> result = await repository.getAll();

        expect(result, equals(collections));
        verify(() => mockDb.getAllCollections()).called(1);
      });

      test('should return пустой список когда нет коллекций', () async {
        when(() => mockDb.getAllCollections())
            .thenAnswer((_) async => <Collection>[]);

        final List<Collection> result = await repository.getAll();

        expect(result, isEmpty);
      });
    });

    group('addItemsBatch', () {
      test('delegates to CollectionDao.addItemsBatch', () async {
        final MockCollectionDao dao = MockCollectionDao();
        when(() => mockDb.collectionDao).thenReturn(dao);
        when(() => dao.addItemsBatch(any(), any())).thenAnswer((_) async => 3);

        final int inserted = await repository.addItemsBatch(
          1,
          <Map<String, dynamic>>[
            <String, dynamic>{'external_id': 1},
          ],
        );

        expect(inserted, 3);
        verify(() => dao.addItemsBatch(1, any())).called(1);
      });

      test('addItemsBatchReturningIds delegates to CollectionDao', () async {
        final MockCollectionDao dao = MockCollectionDao();
        when(() => mockDb.collectionDao).thenReturn(dao);
        when(() => dao.addItemsBatchReturningIds(any(), any()))
            .thenAnswer((_) async => <int?>[7, null]);

        final List<int?> ids = await repository.addItemsBatchReturningIds(
          1,
          <Map<String, dynamic>>[
            <String, dynamic>{'external_id': 1},
            <String, dynamic>{'external_id': 2},
          ],
        );

        expect(ids, <int?>[7, null]);
        verify(() => dao.addItemsBatchReturningIds(1, any())).called(1);
      });
    });

    group('updateItemFieldsBatch', () {
      test('delegates to CollectionDao.updateItemFieldsBatch', () async {
        final MockCollectionDao dao = MockCollectionDao();
        when(() => mockDb.collectionDao).thenReturn(dao);
        when(() => dao.updateItemFieldsBatch(any())).thenAnswer((_) async {});

        await repository.updateItemFieldsBatch(
          <(int, Map<String, dynamic>)>[
            (7, <String, dynamic>{'user_rating': 9.0}),
          ],
        );

        verify(() => dao.updateItemFieldsBatch(any())).called(1);
      });
    });

    group('getByType', () {
      test('should return коллекции указанного типа', () async {
        final List<Collection> ownCollections = <Collection>[
          createTestCollection(id: 1, type: CollectionType.own),
        ];

        when(() => mockDb.getCollectionsByType(CollectionType.own))
            .thenAnswer((_) async => ownCollections);

        final List<Collection> result =
            await repository.getByType(CollectionType.own);

        expect(result, equals(ownCollections));
        verify(() => mockDb.getCollectionsByType(CollectionType.own)).called(1);
      });

      test('should return пустой список для типа без коллекций', () async {
        when(() => mockDb.getCollectionsByType(CollectionType.imported))
            .thenAnswer((_) async => <Collection>[]);

        final List<Collection> result =
            await repository.getByType(CollectionType.imported);

        expect(result, isEmpty);
      });
    });

    group('getById', () {
      test('should return коллекцию по ID', () async {
        final Collection collection = createTestCollection(id: 42);

        when(() => mockDb.getCollectionById(42))
            .thenAnswer((_) async => collection);

        final Collection? result = await repository.getById(42);

        expect(result, equals(collection));
        verify(() => mockDb.getCollectionById(42)).called(1);
      });

      test('should return null для несуществующего ID', () async {
        when(() => mockDb.getCollectionById(999))
            .thenAnswer((_) async => null);

        final Collection? result = await repository.getById(999);

        expect(result, isNull);
      });
    });

    group('create', () {
      test('should create коллекцию с переданными параметрами', () async {
        final Collection newCollection = createTestCollection(
          id: 1,
          name: 'New Collection',
          author: 'Author',
        );

        when(() => mockDb.createCollection(
              name: 'New Collection',
              author: 'Author',
              type: CollectionType.own,
            )).thenAnswer((_) async => newCollection);

        final Collection result = await repository.create(
          name: 'New Collection',
          author: 'Author',
        );

        expect(result, equals(newCollection));
        verify(() => mockDb.createCollection(
              name: 'New Collection',
              author: 'Author',
              type: CollectionType.own,
            )).called(1);
      });

      test('должен передавать кастомный тип', () async {
        final Collection forkCollection = createTestCollection(
          type: CollectionType.fork,
        );

        when(() => mockDb.createCollection(
              name: any(named: 'name'),
              author: any(named: 'author'),
              type: CollectionType.fork,
            )).thenAnswer((_) async => forkCollection);

        await repository.create(
          name: 'Fork',
          author: 'Author',
          type: CollectionType.fork,
        );

        verify(() => mockDb.createCollection(
              name: 'Fork',
              author: 'Author',
              type: CollectionType.fork,
            )).called(1);
      });
    });

    group('updateName', () {
      test('should update название коллекции', () async {
        when(() => mockDb.updateCollection(1, name: 'New Name'))
            .thenAnswer((_) async {});

        await repository.updateName(1, 'New Name');

        verify(() => mockDb.updateCollection(1, name: 'New Name')).called(1);
      });
    });

    group('delete', () {
      test('should delete коллекцию', () async {
        when(() => mockDb.deleteCollection(1)).thenAnswer((_) async {});

        await repository.delete(1);

        verify(() => mockDb.deleteCollection(1)).called(1);
      });
    });

    group('getCount', () {
      test('should return количество коллекций', () async {
        when(() => mockDb.getCollectionCount()).thenAnswer((_) async => 5);

        final int count = await repository.getCount();

        expect(count, 5);
        verify(() => mockDb.getCollectionCount()).called(1);
      });
    });

    group('getStats', () {
      test('should return статистику коллекции', () async {
        when(() => mockDb.getCollectionItemStats(1)).thenAnswer(
          (_) async => <String, int>{
            'total': 10,
            'completed': 5,
            'inProgress': 2,
            'notStarted': 2,
            'dropped': 1,
            'planned': 0,
            'gameCount': 8,
            'movieCount': 1,
            'tvShowCount': 1,
          },
        );

        final CollectionStats stats = await repository.getStats(1);

        expect(stats.total, 10);
        expect(stats.completed, 5);
        expect(stats.inProgress, 2);
        expect(stats.notStarted, 2);
        expect(stats.dropped, 1);
        expect(stats.planned, 0);
      });

      test('should handle пустую статистику', () async {
        when(() => mockDb.getCollectionItemStats(1)).thenAnswer(
          (_) async => <String, int>{},
        );

        final CollectionStats stats = await repository.getStats(1);

        expect(stats.total, 0);
        expect(stats.completed, 0);
      });
    });

    group('moveItemToCollection', () {
      test('should return true при успешном перемещении', () async {
        when(() => mockDb.updateItemCollectionId(10, 5))
            .thenAnswer((_) async => true);

        final bool result = await repository.moveItemToCollection(10, 5);

        expect(result, isTrue);
        verify(() => mockDb.updateItemCollectionId(10, 5)).called(1);
      });

      test('should return true при перемещении в uncategorized (null)',
          () async {
        when(() => mockDb.updateItemCollectionId(10, null))
            .thenAnswer((_) async => true);

        final bool result = await repository.moveItemToCollection(10, null);

        expect(result, isTrue);
        verify(() => mockDb.updateItemCollectionId(10, null)).called(1);
      });

      test('should return false при дубликате (UNIQUE constraint)',
          () async {
        when(() => mockDb.updateItemCollectionId(10, 5))
            .thenAnswer((_) async => false);

        final bool result = await repository.moveItemToCollection(10, 5);

        expect(result, isFalse);
        verify(() => mockDb.updateItemCollectionId(10, 5)).called(1);
      });

      test('должен делегировать вызов в DatabaseService', () async {
        when(() => mockDb.updateItemCollectionId(any(), any()))
            .thenAnswer((_) async => true);

        await repository.moveItemToCollection(42, 7);

        verify(() => mockDb.updateItemCollectionId(42, 7)).called(1);
      });
    });

    group('cloneItemToCollection', () {
      test('should return ID нового элемента on success', () async {
        when(() => mockDb.cloneItemToCollection(10, 5))
            .thenAnswer((_) async => 99);

        final int? result = await repository.cloneItemToCollection(10, 5);

        expect(result, 99);
        verify(() => mockDb.cloneItemToCollection(10, 5)).called(1);
      });

      test('should return null при дубликате', () async {
        when(() => mockDb.cloneItemToCollection(10, 5))
            .thenAnswer((_) async => null);

        final int? result = await repository.cloneItemToCollection(10, 5);

        expect(result, isNull);
        verify(() => mockDb.cloneItemToCollection(10, 5)).called(1);
      });

      test('должен делегировать вызов в DatabaseService', () async {
        when(() => mockDb.cloneItemToCollection(any(), any()))
            .thenAnswer((_) async => 42);

        await repository.cloneItemToCollection(7, 3);

        verify(() => mockDb.cloneItemToCollection(7, 3)).called(1);
      });
    });

  });
}
