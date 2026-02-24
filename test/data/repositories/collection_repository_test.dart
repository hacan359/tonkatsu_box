import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/data/repositories/collection_repository.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  setUpAll(() {
    registerFallbackValue(MediaType.game);
    registerFallbackValue(ItemStatus.notStarted);
  });

  group('CollectionStats', () {
    group('constructor', () {
      test('должен создавать экземпляр с обязательными полями 2', () {
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
      test('должен возвращать правильный процент', () {
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

      test('должен возвращать 0 при пустой коллекции', () {
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

      test('должен возвращать 100 при полном прохождении', () {
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

      test('должен обрабатывать дробные проценты', () {
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
      test('должен возвращать форматированный процент', () {
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

      test('должен возвращать 0% для пустой коллекции', () {
        expect(CollectionStats.empty.completionPercentFormatted, '0%');
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

    final DateTime testDate = DateTime(2024, 1, 15, 12, 0, 0);

    Collection createTestCollection({
      int id = 1,
      String name = 'Test Collection',
      String author = 'Test Author',
      CollectionType type = CollectionType.own,
    }) {
      return Collection(
        id: id,
        name: name,
        author: author,
        type: type,
        createdAt: testDate,
      );
    }

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

      test('должен возвращать пустой список когда нет коллекций', () async {
        when(() => mockDb.getAllCollections())
            .thenAnswer((_) async => <Collection>[]);

        final List<Collection> result = await repository.getAll();

        expect(result, isEmpty);
      });
    });

    group('getByType', () {
      test('должен возвращать коллекции указанного типа', () async {
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

      test('должен возвращать пустой список для типа без коллекций', () async {
        when(() => mockDb.getCollectionsByType(CollectionType.imported))
            .thenAnswer((_) async => <Collection>[]);

        final List<Collection> result =
            await repository.getByType(CollectionType.imported);

        expect(result, isEmpty);
      });
    });

    group('getById', () {
      test('должен возвращать коллекцию по ID', () async {
        final Collection collection = createTestCollection(id: 42);

        when(() => mockDb.getCollectionById(42))
            .thenAnswer((_) async => collection);

        final Collection? result = await repository.getById(42);

        expect(result, equals(collection));
        verify(() => mockDb.getCollectionById(42)).called(1);
      });

      test('должен возвращать null для несуществующего ID', () async {
        when(() => mockDb.getCollectionById(999))
            .thenAnswer((_) async => null);

        final Collection? result = await repository.getById(999);

        expect(result, isNull);
      });
    });

    group('create', () {
      test('должен создавать коллекцию с переданными параметрами', () async {
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
      test('должен обновлять название коллекции', () async {
        when(() => mockDb.updateCollection(1, name: 'New Name'))
            .thenAnswer((_) async {});

        await repository.updateName(1, 'New Name');

        verify(() => mockDb.updateCollection(1, name: 'New Name')).called(1);
      });
    });

    group('delete', () {
      test('должен удалять коллекцию', () async {
        when(() => mockDb.deleteCollection(1)).thenAnswer((_) async {});

        await repository.delete(1);

        verify(() => mockDb.deleteCollection(1)).called(1);
      });
    });

    group('getCount', () {
      test('должен возвращать количество коллекций', () async {
        when(() => mockDb.getCollectionCount()).thenAnswer((_) async => 5);

        final int count = await repository.getCount();

        expect(count, 5);
        verify(() => mockDb.getCollectionCount()).called(1);
      });
    });

    group('getStats', () {
      test('должен возвращать статистику коллекции', () async {
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

      test('должен обрабатывать пустую статистику', () async {
        when(() => mockDb.getCollectionItemStats(1)).thenAnswer(
          (_) async => <String, int>{},
        );

        final CollectionStats stats = await repository.getStats(1);

        expect(stats.total, 0);
        expect(stats.completed, 0);
      });
    });

    group('moveItemToCollection', () {
      test('должен возвращать true при успешном перемещении', () async {
        when(() => mockDb.updateItemCollectionId(10, 5))
            .thenAnswer((_) async => true);

        final bool result = await repository.moveItemToCollection(10, 5);

        expect(result, isTrue);
        verify(() => mockDb.updateItemCollectionId(10, 5)).called(1);
      });

      test('должен возвращать true при перемещении в uncategorized (null)',
          () async {
        when(() => mockDb.updateItemCollectionId(10, null))
            .thenAnswer((_) async => true);

        final bool result = await repository.moveItemToCollection(10, null);

        expect(result, isTrue);
        verify(() => mockDb.updateItemCollectionId(10, null)).called(1);
      });

      test('должен возвращать false при дубликате (UNIQUE constraint)',
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

  });
}
