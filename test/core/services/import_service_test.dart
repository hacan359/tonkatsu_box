import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/api/igdb_api.dart';
import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/core/services/import_service.dart';
import 'package:xerabora/core/services/rcoll_file.dart';
import 'package:xerabora/data/repositories/collection_repository.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/shared/models/game.dart';

class MockCollectionRepository extends Mock implements CollectionRepository {}

class MockIgdbApi extends Mock implements IgdbApi {}

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  final DateTime testDate = DateTime(2024, 1, 15, 12, 0, 0);

  setUpAll(() {
    registerFallbackValue(const Game(id: 0, name: 'fallback'));
    registerFallbackValue(CollectionType.own);
  });

  group('ImportResult', () {
    test('ImportResult.success должен создать успешный результат', () {
      final Collection collection = Collection(
        id: 1,
        name: 'Test',
        author: 'Author',
        type: CollectionType.imported,
        createdAt: testDate,
      );

      final ImportResult result = ImportResult.success(collection, 10);

      expect(result.success, isTrue);
      expect(result.collection, equals(collection));
      expect(result.gamesImported, equals(10));
      expect(result.error, isNull);
      expect(result.isCancelled, isFalse);
    });

    test('ImportResult.failure должен создать неуспешный результат', () {
      const ImportResult result = ImportResult.failure('Error occurred');

      expect(result.success, isFalse);
      expect(result.collection, isNull);
      expect(result.gamesImported, isNull);
      expect(result.error, equals('Error occurred'));
      expect(result.isCancelled, isFalse);
    });

    test('ImportResult.cancelled должен создать отменённый результат', () {
      const ImportResult result = ImportResult.cancelled();

      expect(result.success, isFalse);
      expect(result.collection, isNull);
      expect(result.gamesImported, isNull);
      expect(result.error, isNull);
      expect(result.isCancelled, isTrue);
    });
  });

  group('ImportProgress', () {
    test('progress должен вычисляться корректно', () {
      const ImportProgress progress = ImportProgress(
        stage: ImportStage.addingGames,
        current: 5,
        total: 10,
      );

      expect(progress.progress, equals(0.5));
    });

    test('progress должен быть 0 при total=0', () {
      const ImportProgress progress = ImportProgress(
        stage: ImportStage.reading,
        current: 0,
        total: 0,
      );

      expect(progress.progress, equals(0.0));
    });

    test('должен хранить message', () {
      const ImportProgress progress = ImportProgress(
        stage: ImportStage.fetchingGames,
        current: 2,
        total: 5,
        message: 'Fetching games...',
      );

      expect(progress.message, equals('Fetching games...'));
    });
  });

  group('ImportStage', () {
    test('должен иметь description для каждого этапа', () {
      expect(ImportStage.reading.description, isNotEmpty);
      expect(ImportStage.fetchingGames.description, isNotEmpty);
      expect(ImportStage.cachingGames.description, isNotEmpty);
      expect(ImportStage.creatingCollection.description, isNotEmpty);
      expect(ImportStage.addingGames.description, isNotEmpty);
      expect(ImportStage.completed.description, isNotEmpty);
    });
  });

  group('ImportService', () {
    late ImportService sut;
    late MockCollectionRepository mockRepo;
    late MockIgdbApi mockApi;
    late MockDatabaseService mockDb;

    setUp(() {
      mockRepo = MockCollectionRepository();
      mockApi = MockIgdbApi();
      mockDb = MockDatabaseService();
      sut = ImportService(
        repository: mockRepo,
        igdbApi: mockApi,
        database: mockDb,
      );
    });

    group('parseFile', () {
      test('должен парсить валидный .rcoll файл', () async {
        final Directory tempDir = Directory.systemTemp.createTempSync('rcoll_test');
        final File testFile = File('${tempDir.path}/test.rcoll');
        await testFile.writeAsString('''
{
  "version": 1,
  "name": "Test Collection",
  "author": "Author",
  "created": "2024-01-15T12:00:00.000Z",
  "games": [
    {"igdb_id": 100, "platform_id": 18}
  ]
}
''');

        try {
          final RcollFile result = await sut.parseFile(testFile);

          expect(result.name, equals('Test Collection'));
          expect(result.author, equals('Author'));
          expect(result.games.length, equals(1));
          expect(result.games[0].igdbId, equals(100));
        } finally {
          await testFile.delete();
          await tempDir.delete();
        }
      });

      test('должен выбросить исключение если файл не существует', () async {
        final File nonExistentFile = File('/non/existent/file.rcoll');

        expect(
          () => sut.parseFile(nonExistentFile),
          throwsA(isA<FormatException>().having(
            (FormatException e) => e.message,
            'message',
            contains('does not exist'),
          )),
        );
      });

      test('должен выбросить исключение при невалидном JSON', () async {
        final Directory tempDir = Directory.systemTemp.createTempSync('rcoll_test');
        final File testFile = File('${tempDir.path}/invalid.rcoll');
        await testFile.writeAsString('not valid json');

        try {
          await expectLater(
            () => sut.parseFile(testFile),
            throwsA(isA<FormatException>()),
          );
        } finally {
          await testFile.delete();
          await tempDir.delete();
        }
      });
    });

    group('importFromRcoll', () {
      test('должен успешно импортировать коллекцию без игр', () async {
        final RcollFile rcoll = RcollFile(
          version: 1,
          name: 'Empty Collection',
          author: 'Author',
          created: testDate,
          games: const <RcollGame>[],
        );

        final Collection createdCollection = Collection(
          id: 1,
          name: 'Empty Collection',
          author: 'Author',
          type: CollectionType.imported,
          createdAt: testDate,
        );

        when(() => mockRepo.create(
              name: any(named: 'name'),
              author: any(named: 'author'),
              type: any(named: 'type'),
            )).thenAnswer((_) async => createdCollection);

        final ImportResult result = await sut.importFromRcoll(rcoll);

        expect(result.success, isTrue);
        expect(result.collection?.name, equals('Empty Collection'));
        expect(result.gamesImported, equals(0));

        verify(() => mockRepo.create(
              name: 'Empty Collection',
              author: 'Author',
              type: CollectionType.imported,
            )).called(1);
      });

      test('должен успешно импортировать коллекцию с играми', () async {
        final RcollFile rcoll = RcollFile(
          version: 1,
          name: 'Game Collection',
          author: 'Gamer',
          created: testDate,
          games: const <RcollGame>[
            RcollGame(igdbId: 100, platformId: 18, comment: 'Great'),
            RcollGame(igdbId: 200, platformId: 19),
          ],
        );

        final Collection createdCollection = Collection(
          id: 5,
          name: 'Game Collection',
          author: 'Gamer',
          type: CollectionType.imported,
          createdAt: testDate,
        );

        const List<Game> fetchedGames = <Game>[
          Game(id: 100, name: 'Game 1'),
          Game(id: 200, name: 'Game 2'),
        ];

        when(() => mockApi.getGamesByIds(any()))
            .thenAnswer((_) async => fetchedGames);
        when(() => mockDb.upsertGame(any())).thenAnswer((_) async {});
        when(() => mockRepo.create(
              name: any(named: 'name'),
              author: any(named: 'author'),
              type: any(named: 'type'),
            )).thenAnswer((_) async => createdCollection);
        when(() => mockRepo.addGame(
              collectionId: any(named: 'collectionId'),
              igdbId: any(named: 'igdbId'),
              platformId: any(named: 'platformId'),
              authorComment: any(named: 'authorComment'),
            )).thenAnswer((_) async => 1);

        final ImportResult result = await sut.importFromRcoll(rcoll);

        expect(result.success, isTrue);
        expect(result.gamesImported, equals(2));

        verify(() => mockApi.getGamesByIds(<int>[100, 200])).called(1);
        verify(() => mockDb.upsertGame(any())).called(2);
        verify(() => mockRepo.addGame(
              collectionId: 5,
              igdbId: 100,
              platformId: 18,
              authorComment: 'Great',
            )).called(1);
        verify(() => mockRepo.addGame(
              collectionId: 5,
              igdbId: 200,
              platformId: 19,
              authorComment: null,
            )).called(1);
      });

      test('должен вернуть ошибку при сбое IGDB API', () async {
        final RcollFile rcoll = RcollFile(
          version: 1,
          name: 'Test',
          author: 'Author',
          created: testDate,
          games: const <RcollGame>[
            RcollGame(igdbId: 100, platformId: 18),
          ],
        );

        when(() => mockApi.getGamesByIds(any()))
            .thenThrow(const IgdbApiException('API Error'));

        final ImportResult result = await sut.importFromRcoll(rcoll);

        expect(result.success, isFalse);
        expect(result.error, contains('Failed to fetch games from IGDB'));
      });

      test('должен отслеживать прогресс', () async {
        final RcollFile rcoll = RcollFile(
          version: 1,
          name: 'Progress Test',
          author: 'Author',
          created: testDate,
          games: const <RcollGame>[
            RcollGame(igdbId: 100, platformId: 18),
          ],
        );

        final Collection createdCollection = Collection(
          id: 1,
          name: 'Progress Test',
          author: 'Author',
          type: CollectionType.imported,
          createdAt: testDate,
        );

        const List<Game> fetchedGames = <Game>[
          Game(id: 100, name: 'Game 1'),
        ];

        when(() => mockApi.getGamesByIds(any()))
            .thenAnswer((_) async => fetchedGames);
        when(() => mockDb.upsertGame(any())).thenAnswer((_) async {});
        when(() => mockRepo.create(
              name: any(named: 'name'),
              author: any(named: 'author'),
              type: any(named: 'type'),
            )).thenAnswer((_) async => createdCollection);
        when(() => mockRepo.addGame(
              collectionId: any(named: 'collectionId'),
              igdbId: any(named: 'igdbId'),
              platformId: any(named: 'platformId'),
              authorComment: any(named: 'authorComment'),
            )).thenAnswer((_) async => 1);

        final List<ImportStage> stages = <ImportStage>[];
        await sut.importFromRcoll(
          rcoll,
          onProgress: (ImportProgress progress) {
            stages.add(progress.stage);
          },
        );

        // Проверяем что все этапы были пройдены
        expect(stages, contains(ImportStage.fetchingGames));
        expect(stages, contains(ImportStage.cachingGames));
        expect(stages, contains(ImportStage.creatingCollection));
        expect(stages, contains(ImportStage.addingGames));
        expect(stages, contains(ImportStage.completed));
      });

      test('должен корректно считать добавленные игры при дубликатах', () async {
        final RcollFile rcoll = RcollFile(
          version: 1,
          name: 'Dup Test',
          author: 'Author',
          created: testDate,
          games: const <RcollGame>[
            RcollGame(igdbId: 100, platformId: 18),
            RcollGame(igdbId: 200, platformId: 19),
          ],
        );

        final Collection createdCollection = Collection(
          id: 1,
          name: 'Dup Test',
          author: 'Author',
          type: CollectionType.imported,
          createdAt: testDate,
        );

        when(() => mockApi.getGamesByIds(any()))
            .thenAnswer((_) async => <Game>[]);
        when(() => mockDb.upsertGame(any())).thenAnswer((_) async {});
        when(() => mockRepo.create(
              name: any(named: 'name'),
              author: any(named: 'author'),
              type: any(named: 'type'),
            )).thenAnswer((_) async => createdCollection);

        // Первая игра добавлена успешно, вторая - дубликат (возвращает null)
        int callCount = 0;
        when(() => mockRepo.addGame(
              collectionId: any(named: 'collectionId'),
              igdbId: any(named: 'igdbId'),
              platformId: any(named: 'platformId'),
              authorComment: any(named: 'authorComment'),
            )).thenAnswer((_) async {
          callCount++;
          return callCount == 1 ? 1 : null; // Первый вызов успешен, второй - дубликат
        });

        final ImportResult result = await sut.importFromRcoll(rcoll);

        expect(result.gamesImported, equals(1)); // Только одна игра добавлена
      });
    });
  });
}
