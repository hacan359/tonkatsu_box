import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/data/repositories/collection_repository.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/shared/models/collection_game.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  group('CollectionStats', () {
    group('constructor', () {
      test('должен создавать экземпляр с обязательными полями 2', () {
        const CollectionStats stats = CollectionStats(
          total: 10,
          completed: 3,
          playing: 2,
          notStarted: 4,
          dropped: 1,
          planned: 0,
        );

        expect(stats.total, 10);
        expect(stats.completed, 3);
        expect(stats.playing, 2);
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
          playing: 2,
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
          playing: 0,
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
          playing: 0,
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
          playing: 1,
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
          playing: 5,
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
          playing: 2,
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
        expect(CollectionStats.empty.playing, 0);
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

    CollectionGame createTestCollectionGame({
      int id = 1,
      int collectionId = 1,
      int igdbId = 100,
      int platformId = 18,
      GameStatus status = GameStatus.notStarted,
      String? authorComment,
    }) {
      return CollectionGame(
        id: id,
        collectionId: collectionId,
        igdbId: igdbId,
        platformId: platformId,
        status: status,
        addedAt: testDate,
        authorComment: authorComment,
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

    group('getGames', () {
      test('должен возвращать игры коллекции', () async {
        final List<CollectionGame> games = <CollectionGame>[
          createTestCollectionGame(id: 1, igdbId: 100),
          createTestCollectionGame(id: 2, igdbId: 200),
        ];

        when(() => mockDb.getCollectionGames(1))
            .thenAnswer((_) async => games);

        final List<CollectionGame> result = await repository.getGames(1);

        expect(result, equals(games));
        verify(() => mockDb.getCollectionGames(1)).called(1);
      });
    });

    group('getGamesWithData', () {
      test('должен возвращать игры с подгруженными данными', () async {
        final List<CollectionGame> games = <CollectionGame>[
          createTestCollectionGame(id: 1),
        ];

        when(() => mockDb.getCollectionGamesWithData(1))
            .thenAnswer((_) async => games);

        final List<CollectionGame> result = await repository.getGamesWithData(1);

        expect(result, equals(games));
        verify(() => mockDb.getCollectionGamesWithData(1)).called(1);
      });
    });

    group('addGame', () {
      test('должен добавлять игру в коллекцию', () async {
        when(() => mockDb.addGameToCollection(
              collectionId: 1,
              igdbId: 100,
              platformId: 18,
              authorComment: 'Great game!',
            )).thenAnswer((_) async => 42);

        final int? id = await repository.addGame(
          collectionId: 1,
          igdbId: 100,
          platformId: 18,
          authorComment: 'Great game!',
        );

        expect(id, 42);
        verify(() => mockDb.addGameToCollection(
              collectionId: 1,
              igdbId: 100,
              platformId: 18,
              authorComment: 'Great game!',
            )).called(1);
      });

      test('должен возвращать null при дубликате', () async {
        when(() => mockDb.addGameToCollection(
              collectionId: any(named: 'collectionId'),
              igdbId: any(named: 'igdbId'),
              platformId: any(named: 'platformId'),
              authorComment: any(named: 'authorComment'),
            )).thenAnswer((_) async => null);

        final int? id = await repository.addGame(
          collectionId: 1,
          igdbId: 100,
          platformId: 18,
        );

        expect(id, isNull);
      });
    });

    group('removeGame', () {
      test('должен удалять игру из коллекции', () async {
        when(() => mockDb.removeGameFromCollection(42))
            .thenAnswer((_) async {});

        await repository.removeGame(42);

        verify(() => mockDb.removeGameFromCollection(42)).called(1);
      });
    });

    group('updateGameStatus', () {
      test('должен обновлять статус игры', () async {
        when(() => mockDb.updateGameStatus(1, GameStatus.completed))
            .thenAnswer((_) async {});

        await repository.updateGameStatus(1, GameStatus.completed);

        verify(() => mockDb.updateGameStatus(1, GameStatus.completed)).called(1);
      });
    });

    group('updateAuthorComment', () {
      test('должен обновлять комментарий автора', () async {
        when(() => mockDb.updateAuthorComment(1, 'New comment'))
            .thenAnswer((_) async {});

        await repository.updateAuthorComment(1, 'New comment');

        verify(() => mockDb.updateAuthorComment(1, 'New comment')).called(1);
      });

      test('должен обрабатывать null комментарий', () async {
        when(() => mockDb.updateAuthorComment(1, null))
            .thenAnswer((_) async {});

        await repository.updateAuthorComment(1, null);

        verify(() => mockDb.updateAuthorComment(1, null)).called(1);
      });
    });

    group('updateUserComment', () {
      test('должен обновлять личный комментарий', () async {
        when(() => mockDb.updateUserComment(1, 'My notes'))
            .thenAnswer((_) async {});

        await repository.updateUserComment(1, 'My notes');

        verify(() => mockDb.updateUserComment(1, 'My notes')).called(1);
      });
    });

    group('getStats', () {
      test('должен возвращать статистику коллекции', () async {
        when(() => mockDb.getCollectionStats(1)).thenAnswer(
          (_) async => <String, int>{
            'total': 10,
            'completed': 5,
            'playing': 2,
            'notStarted': 2,
            'dropped': 1,
            'planned': 0,
          },
        );

        final CollectionStats stats = await repository.getStats(1);

        expect(stats.total, 10);
        expect(stats.completed, 5);
        expect(stats.playing, 2);
        expect(stats.notStarted, 2);
        expect(stats.dropped, 1);
        expect(stats.planned, 0);
      });

      test('должен обрабатывать пустую статистику', () async {
        when(() => mockDb.getCollectionStats(1)).thenAnswer(
          (_) async => <String, int>{},
        );

        final CollectionStats stats = await repository.getStats(1);

        expect(stats.total, 0);
        expect(stats.completed, 0);
      });
    });

    group('fork', () {
      test('должен создавать форк коллекции', () async {
        final Collection original = createTestCollection(
          id: 1,
          name: 'Original',
          author: 'Original Author',
        );
        final List<CollectionGame> games = <CollectionGame>[
          createTestCollectionGame(
            id: 1,
            collectionId: 1,
            igdbId: 100,
            platformId: 18,
            authorComment: 'Comment',
          ),
        ];
        final Collection forked = Collection(
          id: 2,
          name: 'Original (copy)',
          author: 'New Author',
          type: CollectionType.fork,
          createdAt: testDate,
          forkedFromAuthor: 'Original Author',
          forkedFromName: 'Original',
        );

        when(() => mockDb.getCollectionById(1))
            .thenAnswer((_) async => original);
        when(() => mockDb.getCollectionGames(1))
            .thenAnswer((_) async => games);
        when(() => mockDb.createCollection(
              name: any(named: 'name'),
              author: any(named: 'author'),
              type: CollectionType.fork,
              originalSnapshot: any(named: 'originalSnapshot'),
              forkedFromAuthor: any(named: 'forkedFromAuthor'),
              forkedFromName: any(named: 'forkedFromName'),
            )).thenAnswer((_) async => forked);
        when(() => mockDb.addGameToCollection(
              collectionId: any(named: 'collectionId'),
              igdbId: any(named: 'igdbId'),
              platformId: any(named: 'platformId'),
              authorComment: any(named: 'authorComment'),
            )).thenAnswer((_) async => 10);

        final Collection result = await repository.fork(1, 'New Author');

        expect(result.type, CollectionType.fork);
        expect(result.name, 'Original (copy)');
        verify(() => mockDb.addGameToCollection(
              collectionId: 2,
              igdbId: 100,
              platformId: 18,
              authorComment: 'Comment',
            )).called(1);
      });

      test('должен выбрасывать ошибку для несуществующей коллекции', () async {
        when(() => mockDb.getCollectionById(999))
            .thenAnswer((_) async => null);

        expect(
          () => repository.fork(999, 'Author'),
          throwsArgumentError,
        );
      });
    });

    group('revertToOriginal', () {
      test('должен откатывать форк к оригиналу', () async {
        final Collection fork = Collection(
          id: 2,
          name: 'Forked',
          author: 'Author',
          type: CollectionType.fork,
          createdAt: testDate,
          originalSnapshot:
              '{"name":"Original","author":"Author","games":[{"igdb_id":100,"platform_id":18,"author_comment":"Comment"}]}',
        );

        when(() => mockDb.getCollectionById(2)).thenAnswer((_) async => fork);
        when(() => mockDb.clearCollectionGames(2)).thenAnswer((_) async {});
        when(() => mockDb.addGameToCollection(
              collectionId: any(named: 'collectionId'),
              igdbId: any(named: 'igdbId'),
              platformId: any(named: 'platformId'),
              authorComment: any(named: 'authorComment'),
            )).thenAnswer((_) async => 10);

        await repository.revertToOriginal(2);

        verify(() => mockDb.clearCollectionGames(2)).called(1);
        verify(() => mockDb.addGameToCollection(
              collectionId: 2,
              igdbId: 100,
              platformId: 18,
              authorComment: 'Comment',
            )).called(1);
      });

      test('должен выбрасывать ошибку для несуществующей коллекции', () async {
        when(() => mockDb.getCollectionById(999))
            .thenAnswer((_) async => null);

        expect(
          () => repository.revertToOriginal(999),
          throwsArgumentError,
        );
      });

      test('должен выбрасывать ошибку при отсутствии snapshot', () async {
        final Collection collection = createTestCollection();

        when(() => mockDb.getCollectionById(1))
            .thenAnswer((_) async => collection);

        expect(
          () => repository.revertToOriginal(1),
          throwsStateError,
        );
      });
    });
  });
}
