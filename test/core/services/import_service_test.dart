import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/api/igdb_api.dart';
import 'package:xerabora/core/api/tmdb_api.dart';
import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/core/services/image_cache_service.dart';
import 'package:xerabora/core/services/import_service.dart';
import 'package:xerabora/core/services/xcoll_file.dart';
import 'package:xerabora/data/repositories/canvas_repository.dart';
import 'package:xerabora/data/repositories/collection_repository.dart';
import 'package:xerabora/shared/models/canvas_connection.dart';
import 'package:xerabora/shared/models/canvas_item.dart';
import 'package:xerabora/shared/models/canvas_viewport.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/shared/models/game.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/movie.dart';
import 'package:xerabora/shared/models/platform.dart';
import 'package:xerabora/shared/models/tv_episode.dart';
import 'package:xerabora/shared/models/tv_season.dart';
import 'package:xerabora/shared/models/tv_show.dart';

class MockCollectionRepository extends Mock implements CollectionRepository {}

class MockIgdbApi extends Mock implements IgdbApi {}

class MockTmdbApi extends Mock implements TmdbApi {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockCanvasRepository extends Mock implements CanvasRepository {}

class MockImageCacheService extends Mock implements ImageCacheService {}

void main() {
  final DateTime testDate = DateTime(2024, 1, 15, 12, 0, 0);

  setUpAll(() {
    registerFallbackValue(const Game(id: 0, name: 'fallback'));
    registerFallbackValue(const Movie(tmdbId: 0, title: 'fallback'));
    registerFallbackValue(const TvShow(tmdbId: 0, title: 'fallback'));
    registerFallbackValue(const <Game>[]);
    registerFallbackValue(const <Movie>[]);
    registerFallbackValue(const <TvShow>[]);
    registerFallbackValue(const <TvSeason>[]);
    registerFallbackValue(const <TvEpisode>[]);
    registerFallbackValue(const <Platform>[]);
    registerFallbackValue(CollectionType.own);
    registerFallbackValue(MediaType.game);
    registerFallbackValue(const CanvasViewport(collectionId: 0));
    registerFallbackValue(CanvasItem(
      id: 0,
      collectionId: 0,
      itemType: CanvasItemType.game,
      x: 0,
      y: 0,
      createdAt: DateTime.now(),
    ));
    registerFallbackValue(CanvasConnection(
      id: 0,
      collectionId: 0,
      fromItemId: 0,
      toItemId: 0,
      createdAt: DateTime.now(),
    ));
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(ImageType.gameCover);
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
      expect(result.itemsImported, equals(10));
      expect(result.error, isNull);
      expect(result.isCancelled, isFalse);
    });

    test('ImportResult.failure должен создать неуспешный результат', () {
      const ImportResult result = ImportResult.failure('Error occurred');

      expect(result.success, isFalse);
      expect(result.collection, isNull);
      expect(result.itemsImported, isNull);
      expect(result.error, equals('Error occurred'));
      expect(result.isCancelled, isFalse);
    });

    test('ImportResult.cancelled должен создать отменённый результат', () {
      const ImportResult result = ImportResult.cancelled();

      expect(result.success, isFalse);
      expect(result.collection, isNull);
      expect(result.itemsImported, isNull);
      expect(result.error, isNull);
      expect(result.isCancelled, isTrue);
    });
  });

  group('ImportProgress', () {
    test('progress должен вычисляться корректно', () {
      const ImportProgress progress = ImportProgress(
        stage: ImportStage.addingItems,
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
      for (final ImportStage stage in ImportStage.values) {
        expect(stage.description, isNotEmpty, reason: 'Stage $stage');
      }
    });

    test('должен иметь все новые v2 этапы', () {
      expect(ImportStage.values, contains(ImportStage.fetchingMovies));
      expect(ImportStage.values, contains(ImportStage.fetchingTvShows));
      expect(ImportStage.values, contains(ImportStage.cachingMedia));
      expect(ImportStage.values, contains(ImportStage.addingItems));
      expect(ImportStage.values, contains(ImportStage.importingCanvas));
      expect(ImportStage.values, contains(ImportStage.importingImages));
    });
  });

  group('ImportService', () {
    late ImportService sut;
    late MockCollectionRepository mockRepo;
    late MockIgdbApi mockApi;
    late MockTmdbApi mockTmdb;
    late MockDatabaseService mockDb;
    late MockCanvasRepository mockCanvas;

    setUp(() {
      mockRepo = MockCollectionRepository();
      mockApi = MockIgdbApi();
      mockTmdb = MockTmdbApi();
      mockDb = MockDatabaseService();
      mockCanvas = MockCanvasRepository();
      sut = ImportService(
        repository: mockRepo,
        igdbApi: mockApi,
        database: mockDb,
      );
    });

    group('parseFile', () {
      test('должен выбросить FormatException для v1 файла', () async {
        final Directory tempDir =
            Directory.systemTemp.createTempSync('xcoll_test');
        final File testFile = File('${tempDir.path}/test.xcoll');
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
          await expectLater(
            () => sut.parseFile(testFile),
            throwsA(isA<FormatException>()),
          );
        } finally {
          await testFile.delete();
          await tempDir.delete();
        }
      });

      test('должен парсить валидный .xcoll файл (v2)', () async {
        final Directory tempDir =
            Directory.systemTemp.createTempSync('xcoll_test');
        final File testFile = File('${tempDir.path}/test.xcoll');
        await testFile.writeAsString('''
{
  "version": 2,
  "format": "light",
  "name": "V2 Collection",
  "author": "Author",
  "created": "2024-01-15T12:00:00.000Z",
  "items": [
    {"media_type": "game", "external_id": 100}
  ]
}
''');

        try {
          final XcollFile result = await sut.parseFile(testFile);

          expect(result.name, equals('V2 Collection'));
          expect(result.version, equals(2));
          expect(result.items.length, equals(1));
        } finally {
          await testFile.delete();
          await tempDir.delete();
        }
      });

      test('должен выбросить исключение если файл не существует', () async {
        final File nonExistentFile = File('/non/existent/file.xcoll');

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
        final Directory tempDir =
            Directory.systemTemp.createTempSync('xcoll_test');
        final File testFile = File('${tempDir.path}/invalid.xcoll');
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

    // ==================== v2 Light Import (.xcoll) ====================

    group('importFromXcoll (v2 light)', () {
      late ImportService sutV2;

      setUp(() {
        sutV2 = ImportService(
          repository: mockRepo,
          igdbApi: mockApi,
          tmdbApi: mockTmdb,
          database: mockDb,
          canvasRepository: mockCanvas,
        );
      });

      test('должен успешно импортировать v2 с играми', () async {
        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.light,
          name: 'V2 Games',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[
            <String, dynamic>{
              'media_type': 'game',
              'external_id': 100,
              'platform_id': 48,
              'comment': 'Great game',
            },
            <String, dynamic>{
              'media_type': 'game',
              'external_id': 200,
            },
          ],
        );

        final Collection createdCollection = Collection(
          id: 10,
          name: 'V2 Games',
          author: 'Author',
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
        when(() => mockRepo.addItem(
              collectionId: any(named: 'collectionId'),
              mediaType: any(named: 'mediaType'),
              externalId: any(named: 'externalId'),
              platformId: any(named: 'platformId'),
              authorComment: any(named: 'authorComment'),
            )).thenAnswer((_) async => 1);

        final ImportResult result = await sutV2.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        expect(result.itemsImported, equals(2));
        expect(result.collection?.name, equals('V2 Games'));

        verify(() => mockApi.getGamesByIds(<int>[100, 200])).called(1);
        verify(() => mockDb.upsertGame(any())).called(2);
        verify(() => mockRepo.addItem(
              collectionId: 10,
              mediaType: MediaType.game,
              externalId: 100,
              platformId: 48,
              authorComment: 'Great game',
            )).called(1);
        verify(() => mockRepo.addItem(
              collectionId: 10,
              mediaType: MediaType.game,
              externalId: 200,
              platformId: null,
              authorComment: null,
            )).called(1);
      });

      test('должен успешно импортировать v2 с фильмами', () async {
        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.light,
          name: 'V2 Movies',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[
            <String, dynamic>{
              'media_type': 'movie',
              'external_id': 550,
            },
          ],
        );

        final Collection createdCollection = Collection(
          id: 11,
          name: 'V2 Movies',
          author: 'Author',
          type: CollectionType.imported,
          createdAt: testDate,
        );

        const Movie fetchedMovie = Movie(tmdbId: 550, title: 'Fight Club');

        when(() => mockTmdb.getMovie(550))
            .thenAnswer((_) async => fetchedMovie);
        when(() => mockDb.upsertMovies(any())).thenAnswer((_) async {});
        when(() => mockRepo.create(
              name: any(named: 'name'),
              author: any(named: 'author'),
              type: any(named: 'type'),
            )).thenAnswer((_) async => createdCollection);
        when(() => mockRepo.addItem(
              collectionId: any(named: 'collectionId'),
              mediaType: any(named: 'mediaType'),
              externalId: any(named: 'externalId'),
              platformId: any(named: 'platformId'),
              authorComment: any(named: 'authorComment'),
            )).thenAnswer((_) async => 1);

        final ImportResult result = await sutV2.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        expect(result.itemsImported, equals(1));

        verify(() => mockTmdb.getMovie(550)).called(1);
        verify(() => mockDb.upsertMovies(any())).called(1);
      });

      test('должен успешно импортировать v2 с сериалами', () async {
        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.light,
          name: 'V2 TV Shows',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[
            <String, dynamic>{
              'media_type': 'tv_show',
              'external_id': 1399,
              'current_season': 3,
              'current_episode': 5,
            },
          ],
        );

        final Collection createdCollection = Collection(
          id: 12,
          name: 'V2 TV Shows',
          author: 'Author',
          type: CollectionType.imported,
          createdAt: testDate,
        );

        const TvShow fetchedTvShow =
            TvShow(tmdbId: 1399, title: 'Breaking Bad');

        when(() => mockTmdb.getTvShow(1399))
            .thenAnswer((_) async => fetchedTvShow);
        when(() => mockDb.upsertTvShows(any())).thenAnswer((_) async {});
        when(() => mockRepo.create(
              name: any(named: 'name'),
              author: any(named: 'author'),
              type: any(named: 'type'),
            )).thenAnswer((_) async => createdCollection);
        when(() => mockRepo.addItem(
              collectionId: any(named: 'collectionId'),
              mediaType: any(named: 'mediaType'),
              externalId: any(named: 'externalId'),
              platformId: any(named: 'platformId'),
              authorComment: any(named: 'authorComment'),
            )).thenAnswer((_) async => 1);

        final ImportResult result = await sutV2.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        expect(result.itemsImported, equals(1));

        verify(() => mockTmdb.getTvShow(1399)).called(1);
        verify(() => mockDb.upsertTvShows(any())).called(1);
      });

      test('должен импортировать смешанные типы медиа', () async {
        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.light,
          name: 'Mixed Collection',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[
            <String, dynamic>{
              'media_type': 'game',
              'external_id': 100,
            },
            <String, dynamic>{
              'media_type': 'movie',
              'external_id': 550,
            },
            <String, dynamic>{
              'media_type': 'tv_show',
              'external_id': 1399,
            },
          ],
        );

        final Collection createdCollection = Collection(
          id: 15,
          name: 'Mixed Collection',
          author: 'Author',
          type: CollectionType.imported,
          createdAt: testDate,
        );

        when(() => mockApi.getGamesByIds(any()))
            .thenAnswer((_) async => const <Game>[Game(id: 100, name: 'G1')]);
        when(() => mockTmdb.getMovie(550))
            .thenAnswer((_) async => const Movie(tmdbId: 550, title: 'M1'));
        when(() => mockTmdb.getTvShow(1399))
            .thenAnswer((_) async => const TvShow(tmdbId: 1399, title: 'T1'));
        when(() => mockDb.upsertGame(any())).thenAnswer((_) async {});
        when(() => mockDb.upsertMovies(any())).thenAnswer((_) async {});
        when(() => mockDb.upsertTvShows(any())).thenAnswer((_) async {});
        when(() => mockRepo.create(
              name: any(named: 'name'),
              author: any(named: 'author'),
              type: any(named: 'type'),
            )).thenAnswer((_) async => createdCollection);
        when(() => mockRepo.addItem(
              collectionId: any(named: 'collectionId'),
              mediaType: any(named: 'mediaType'),
              externalId: any(named: 'externalId'),
              platformId: any(named: 'platformId'),
              authorComment: any(named: 'authorComment'),
            )).thenAnswer((_) async => 1);

        final ImportResult result = await sutV2.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        expect(result.itemsImported, equals(3));

        verify(() => mockApi.getGamesByIds(<int>[100])).called(1);
        verify(() => mockTmdb.getMovie(550)).called(1);
        verify(() => mockTmdb.getTvShow(1399)).called(1);
      });

      test('должен пропускать недоступные фильмы из TMDB', () async {
        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.light,
          name: 'TMDB Error',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[
            <String, dynamic>{
              'media_type': 'movie',
              'external_id': 550,
            },
            <String, dynamic>{
              'media_type': 'movie',
              'external_id': 999,
            },
          ],
        );

        final Collection createdCollection = Collection(
          id: 16,
          name: 'TMDB Error',
          author: 'Author',
          type: CollectionType.imported,
          createdAt: testDate,
        );

        when(() => mockTmdb.getMovie(550))
            .thenAnswer((_) async => const Movie(tmdbId: 550, title: 'M1'));
        when(() => mockTmdb.getMovie(999))
            .thenThrow(const TmdbApiException('Not found', statusCode: 404));
        when(() => mockDb.upsertMovies(any())).thenAnswer((_) async {});
        when(() => mockRepo.create(
              name: any(named: 'name'),
              author: any(named: 'author'),
              type: any(named: 'type'),
            )).thenAnswer((_) async => createdCollection);
        when(() => mockRepo.addItem(
              collectionId: any(named: 'collectionId'),
              mediaType: any(named: 'mediaType'),
              externalId: any(named: 'externalId'),
              platformId: any(named: 'platformId'),
              authorComment: any(named: 'authorComment'),
            )).thenAnswer((_) async => 1);

        final ImportResult result = await sutV2.importFromXcoll(xcoll);

        // Импорт не падает, просто пропускает недоступный фильм
        expect(result.success, isTrue);
        expect(result.itemsImported, equals(2));
      });

      test('должен пропускать недоступные сериалы из TMDB', () async {
        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.light,
          name: 'TV Error',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[
            <String, dynamic>{
              'media_type': 'tv_show',
              'external_id': 1399,
            },
          ],
        );

        final Collection createdCollection = Collection(
          id: 17,
          name: 'TV Error',
          author: 'Author',
          type: CollectionType.imported,
          createdAt: testDate,
        );

        when(() => mockTmdb.getTvShow(1399))
            .thenThrow(const TmdbApiException('Error'));
        when(() => mockRepo.create(
              name: any(named: 'name'),
              author: any(named: 'author'),
              type: any(named: 'type'),
            )).thenAnswer((_) async => createdCollection);
        when(() => mockRepo.addItem(
              collectionId: any(named: 'collectionId'),
              mediaType: any(named: 'mediaType'),
              externalId: any(named: 'externalId'),
              platformId: any(named: 'platformId'),
              authorComment: any(named: 'authorComment'),
            )).thenAnswer((_) async => 1);

        final ImportResult result = await sutV2.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        expect(result.itemsImported, equals(1));
      });

      test('должен вернуть ошибку при сбое IGDB API в v2', () async {
        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.light,
          name: 'IGDB Error',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[
            <String, dynamic>{
              'media_type': 'game',
              'external_id': 100,
            },
          ],
        );

        when(() => mockApi.getGamesByIds(any()))
            .thenThrow(const IgdbApiException('API Error'));

        final ImportResult result = await sutV2.importFromXcoll(xcoll);

        expect(result.success, isFalse);
        expect(result.error, contains('Failed to fetch games from IGDB'));
      });

      test('должен импортировать v2 без TMDB API (tmdbApi = null)', () async {
        // Сервис без tmdbApi — фильмы/сериалы не фетчатся, но элементы добавляются
        final ImportService sutNoTmdb = ImportService(
          repository: mockRepo,
          igdbApi: mockApi,
          database: mockDb,
        );

        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.light,
          name: 'No TMDB',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[
            <String, dynamic>{
              'media_type': 'movie',
              'external_id': 550,
            },
          ],
        );

        final Collection createdCollection = Collection(
          id: 20,
          name: 'No TMDB',
          author: 'Author',
          type: CollectionType.imported,
          createdAt: testDate,
        );

        when(() => mockRepo.create(
              name: any(named: 'name'),
              author: any(named: 'author'),
              type: any(named: 'type'),
            )).thenAnswer((_) async => createdCollection);
        when(() => mockRepo.addItem(
              collectionId: any(named: 'collectionId'),
              mediaType: any(named: 'mediaType'),
              externalId: any(named: 'externalId'),
              platformId: any(named: 'platformId'),
              authorComment: any(named: 'authorComment'),
            )).thenAnswer((_) async => 1);

        final ImportResult result = await sutNoTmdb.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        expect(result.itemsImported, equals(1));
        // TMDB не вызывается
        verifyNever(() => mockTmdb.getMovie(any()));
      });

      test('должен импортировать пустую v2 коллекцию', () async {
        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.light,
          name: 'Empty V2',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[],
        );

        final Collection createdCollection = Collection(
          id: 21,
          name: 'Empty V2',
          author: 'Author',
          type: CollectionType.imported,
          createdAt: testDate,
        );

        when(() => mockRepo.create(
              name: any(named: 'name'),
              author: any(named: 'author'),
              type: any(named: 'type'),
            )).thenAnswer((_) async => createdCollection);

        final ImportResult result = await sutV2.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        expect(result.itemsImported, equals(0));
      });

      test('должен отслеживать прогресс v2', () async {
        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.light,
          name: 'Progress V2',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[
            <String, dynamic>{
              'media_type': 'game',
              'external_id': 100,
            },
            <String, dynamic>{
              'media_type': 'movie',
              'external_id': 550,
            },
          ],
        );

        final Collection createdCollection = Collection(
          id: 22,
          name: 'Progress V2',
          author: 'Author',
          type: CollectionType.imported,
          createdAt: testDate,
        );

        when(() => mockApi.getGamesByIds(any()))
            .thenAnswer((_) async => const <Game>[Game(id: 100, name: 'G1')]);
        when(() => mockTmdb.getMovie(550))
            .thenAnswer((_) async => const Movie(tmdbId: 550, title: 'M1'));
        when(() => mockDb.upsertGame(any())).thenAnswer((_) async {});
        when(() => mockDb.upsertMovies(any())).thenAnswer((_) async {});
        when(() => mockRepo.create(
              name: any(named: 'name'),
              author: any(named: 'author'),
              type: any(named: 'type'),
            )).thenAnswer((_) async => createdCollection);
        when(() => mockRepo.addItem(
              collectionId: any(named: 'collectionId'),
              mediaType: any(named: 'mediaType'),
              externalId: any(named: 'externalId'),
              platformId: any(named: 'platformId'),
              authorComment: any(named: 'authorComment'),
            )).thenAnswer((_) async => 1);

        final List<ImportStage> stages = <ImportStage>[];
        await sutV2.importFromXcoll(
          xcoll,
          onProgress: (ImportProgress progress) {
            stages.add(progress.stage);
          },
        );

        expect(stages, contains(ImportStage.fetchingGames));
        expect(stages, contains(ImportStage.fetchingMovies));
        expect(stages, contains(ImportStage.cachingMedia));
        expect(stages, contains(ImportStage.creatingCollection));
        expect(stages, contains(ImportStage.addingItems));
        expect(stages, contains(ImportStage.completed));
      });

      test('должен корректно считать дубликаты в v2', () async {
        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.light,
          name: 'V2 Dup',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[
            <String, dynamic>{
              'media_type': 'game',
              'external_id': 100,
            },
            <String, dynamic>{
              'media_type': 'game',
              'external_id': 200,
            },
          ],
        );

        final Collection createdCollection = Collection(
          id: 23,
          name: 'V2 Dup',
          author: 'Author',
          type: CollectionType.imported,
          createdAt: testDate,
        );

        when(() => mockApi.getGamesByIds(any()))
            .thenAnswer((_) async => const <Game>[]);
        when(() => mockRepo.create(
              name: any(named: 'name'),
              author: any(named: 'author'),
              type: any(named: 'type'),
            )).thenAnswer((_) async => createdCollection);

        int callCount = 0;
        when(() => mockRepo.addItem(
              collectionId: any(named: 'collectionId'),
              mediaType: any(named: 'mediaType'),
              externalId: any(named: 'externalId'),
              platformId: any(named: 'platformId'),
              authorComment: any(named: 'authorComment'),
            )).thenAnswer((_) async {
          callCount++;
          return callCount == 1 ? 1 : null;
        });

        final ImportResult result = await sutV2.importFromXcoll(xcoll);

        expect(result.itemsImported, equals(1));
      });
    });

    // ==================== v2 Full Import (.xcollx) ====================

    group('importFromXcoll (v2 full с canvas)', () {
      late ImportService sutFull;

      setUp(() {
        sutFull = ImportService(
          repository: mockRepo,
          igdbApi: mockApi,
          tmdbApi: mockTmdb,
          database: mockDb,
          canvasRepository: mockCanvas,
        );
      });

      test('должен импортировать canvas с viewport', () async {
        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.full,
          name: 'Canvas Test',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[],
          canvas: const ExportCanvas(
            viewport: <String, dynamic>{
              'scale': 0.8,
              'offsetX': -100.0,
              'offsetY': -50.0,
            },
            items: <Map<String, dynamic>>[],
            connections: <Map<String, dynamic>>[],
          ),
        );

        final Collection createdCollection = Collection(
          id: 30,
          name: 'Canvas Test',
          author: 'Author',
          type: CollectionType.imported,
          createdAt: testDate,
        );

        when(() => mockRepo.create(
              name: any(named: 'name'),
              author: any(named: 'author'),
              type: any(named: 'type'),
            )).thenAnswer((_) async => createdCollection);
        when(() => mockCanvas.saveViewport(any())).thenAnswer((_) async {});

        final ImportResult result = await sutFull.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        verify(() => mockCanvas.saveViewport(any())).called(1);
      });

      test('должен импортировать canvas items с ID-ремаппингом', () async {
        // created_at — Unix timestamp в секундах (int)
        final int canvasTs = DateTime(2024, 3, 1).millisecondsSinceEpoch ~/ 1000;

        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.full,
          name: 'Canvas Items',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[],
          canvas: ExportCanvas(
            items: <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 10,
                'type': 'game',
                'x': 100.0,
                'y': 200.0,
                'created_at': canvasTs,
              },
              <String, dynamic>{
                'id': 20,
                'type': 'note',
                'x': 300.0,
                'y': 400.0,
                'created_at': canvasTs,
              },
            ],
            connections: const <Map<String, dynamic>>[],
          ),
        );

        final Collection createdCollection = Collection(
          id: 31,
          name: 'Canvas Items',
          author: 'Author',
          type: CollectionType.imported,
          createdAt: testDate,
        );

        when(() => mockRepo.create(
              name: any(named: 'name'),
              author: any(named: 'author'),
              type: any(named: 'type'),
            )).thenAnswer((_) async => createdCollection);

        // Мокаем createItem — возвращаем с новыми ID
        int nextId = 100;
        when(() => mockCanvas.createItem(any())).thenAnswer((Invocation inv) async {
          final CanvasItem inputItem =
              inv.positionalArguments[0] as CanvasItem;
          nextId++;
          return inputItem.copyWith(id: nextId);
        });

        final ImportResult result = await sutFull.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        verify(() => mockCanvas.createItem(any())).called(2);
      });

      test('должен импортировать connections с ID-ремаппингом', () async {
        final int canvasTs = DateTime(2024, 3, 1).millisecondsSinceEpoch ~/ 1000;

        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.full,
          name: 'Canvas Connections',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[],
          canvas: ExportCanvas(
            items: <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 10,
                'type': 'game',
                'x': 100.0,
                'y': 200.0,
                'created_at': canvasTs,
              },
              <String, dynamic>{
                'id': 20,
                'type': 'note',
                'x': 300.0,
                'y': 400.0,
                'created_at': canvasTs,
              },
            ],
            connections: <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 1,
                'from_item_id': 10,
                'to_item_id': 20,
                'created_at': canvasTs,
              },
            ],
          ),
        );

        final Collection createdCollection = Collection(
          id: 32,
          name: 'Canvas Connections',
          author: 'Author',
          type: CollectionType.imported,
          createdAt: testDate,
        );

        when(() => mockRepo.create(
              name: any(named: 'name'),
              author: any(named: 'author'),
              type: any(named: 'type'),
            )).thenAnswer((_) async => createdCollection);

        // createItem: export ID 10 → new ID 101, export ID 20 → new ID 102
        final Map<int, int> exportToNewId = <int, int>{};
        int nextItemId = 100;
        when(() => mockCanvas.createItem(any())).thenAnswer((Invocation inv) async {
          final CanvasItem inputItem =
              inv.positionalArguments[0] as CanvasItem;
          nextItemId++;
          // Через x мы определяем исходный export ID
          if (inputItem.x == 100.0) {
            exportToNewId[10] = nextItemId;
          } else {
            exportToNewId[20] = nextItemId;
          }
          return inputItem.copyWith(id: nextItemId);
        });

        when(() => mockCanvas.createConnection(any()))
            .thenAnswer((Invocation inv) async {
          final CanvasConnection inputConn =
              inv.positionalArguments[0] as CanvasConnection;
          return inputConn.copyWith(id: 1);
        });

        final ImportResult result = await sutFull.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        verify(() => mockCanvas.createItem(any())).called(2);

        // Проверяем что connection был создан с ремаппленными ID
        final CanvasConnection captured = verify(
          () => mockCanvas.createConnection(captureAny()),
        ).captured.first as CanvasConnection;

        expect(captured.fromItemId, equals(exportToNewId[10]));
        expect(captured.toItemId, equals(exportToNewId[20]));
        expect(captured.id, equals(0)); // ID сброшен для автоинкремента
      });

      test('должен пропускать connections с неремаппленными ID', () async {
        final int canvasTs = DateTime(2024, 3, 1).millisecondsSinceEpoch ~/ 1000;

        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.full,
          name: 'Skip Connection',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[],
          canvas: ExportCanvas(
            items: <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 10,
                'type': 'game',
                'x': 100.0,
                'y': 200.0,
                'created_at': canvasTs,
              },
            ],
            connections: <Map<String, dynamic>>[
              // Connection ссылается на несуществующий ID 999
              <String, dynamic>{
                'id': 1,
                'from_item_id': 10,
                'to_item_id': 999,
                'created_at': canvasTs,
              },
            ],
          ),
        );

        final Collection createdCollection = Collection(
          id: 33,
          name: 'Skip Connection',
          author: 'Author',
          type: CollectionType.imported,
          createdAt: testDate,
        );

        when(() => mockRepo.create(
              name: any(named: 'name'),
              author: any(named: 'author'),
              type: any(named: 'type'),
            )).thenAnswer((_) async => createdCollection);

        when(() => mockCanvas.createItem(any())).thenAnswer((Invocation inv) async {
          final CanvasItem inputItem =
              inv.positionalArguments[0] as CanvasItem;
          return inputItem.copyWith(id: 101);
        });

        final ImportResult result = await sutFull.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        // Connection пропущен, т.к. to_item_id 999 не ремаплится
        verifyNever(() => mockCanvas.createConnection(any()));
      });

      test('должен не импортировать canvas если canvas == null', () async {
        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.full,
          name: 'No Canvas',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[],
          canvas: null,
        );

        final Collection createdCollection = Collection(
          id: 34,
          name: 'No Canvas',
          author: 'Author',
          type: CollectionType.imported,
          createdAt: testDate,
        );

        when(() => mockRepo.create(
              name: any(named: 'name'),
              author: any(named: 'author'),
              type: any(named: 'type'),
            )).thenAnswer((_) async => createdCollection);

        final ImportResult result = await sutFull.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        verifyNever(() => mockCanvas.saveViewport(any()));
        verifyNever(() => mockCanvas.createItem(any()));
        verifyNever(() => mockCanvas.createConnection(any()));
      });

      test('должен не импортировать canvas в light mode', () async {
        // light format → isFull = false → canvas не импортируется
        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.light,
          name: 'Light No Canvas',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[],
          canvas: const ExportCanvas(
            viewport: <String, dynamic>{
              'scale': 1.0,
              'offsetX': 0.0,
              'offsetY': 0.0,
            },
          ),
        );

        final Collection createdCollection = Collection(
          id: 35,
          name: 'Light No Canvas',
          author: 'Author',
          type: CollectionType.imported,
          createdAt: testDate,
        );

        when(() => mockRepo.create(
              name: any(named: 'name'),
              author: any(named: 'author'),
              type: any(named: 'type'),
            )).thenAnswer((_) async => createdCollection);

        final ImportResult result = await sutFull.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        verifyNever(() => mockCanvas.saveViewport(any()));
        verifyNever(() => mockCanvas.createItem(any()));
      });

      test('должен отслеживать прогресс canvas импорта', () async {
        final int canvasTs = DateTime(2024, 3, 1).millisecondsSinceEpoch ~/ 1000;

        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.full,
          name: 'Canvas Progress',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[],
          canvas: ExportCanvas(
            viewport: const <String, dynamic>{
              'scale': 1.0,
              'offsetX': 0.0,
              'offsetY': 0.0,
            },
            items: <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 1,
                'type': 'game',
                'x': 0.0,
                'y': 0.0,
                'created_at': canvasTs,
              },
            ],
            connections: const <Map<String, dynamic>>[],
          ),
        );

        final Collection createdCollection = Collection(
          id: 36,
          name: 'Canvas Progress',
          author: 'Author',
          type: CollectionType.imported,
          createdAt: testDate,
        );

        when(() => mockRepo.create(
              name: any(named: 'name'),
              author: any(named: 'author'),
              type: any(named: 'type'),
            )).thenAnswer((_) async => createdCollection);
        when(() => mockCanvas.saveViewport(any())).thenAnswer((_) async {});
        when(() => mockCanvas.createItem(any())).thenAnswer((Invocation inv) async {
          final CanvasItem inputItem =
              inv.positionalArguments[0] as CanvasItem;
          return inputItem.copyWith(id: 1);
        });

        final List<ImportStage> stages = <ImportStage>[];
        await sutFull.importFromXcoll(
          xcoll,
          onProgress: (ImportProgress progress) {
            stages.add(progress.stage);
          },
        );

        expect(stages, contains(ImportStage.importingCanvas));
        expect(stages, contains(ImportStage.completed));
      });

      // ==================== Per-item canvas ====================

      test('должен импортировать per-item canvas viewport', () async {
        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.full,
          name: 'Per-Item Viewport',
          author: 'Author',
          created: testDate,
          items: <Map<String, dynamic>>[
            <String, dynamic>{
              'media_type': 'game',
              'external_id': 100,
              '_canvas': <String, dynamic>{
                'viewport': <String, dynamic>{
                  'scale': 0.5,
                  'offsetX': -200.0,
                  'offsetY': -100.0,
                },
                'items': <Map<String, dynamic>>[],
                'connections': <Map<String, dynamic>>[],
              },
            },
          ],
        );

        final Collection createdCollection = Collection(
          id: 40,
          name: 'Per-Item Viewport',
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
        when(() => mockRepo.addItem(
              collectionId: any(named: 'collectionId'),
              mediaType: any(named: 'mediaType'),
              externalId: any(named: 'externalId'),
              platformId: any(named: 'platformId'),
              authorComment: any(named: 'authorComment'),
            )).thenAnswer((_) async => 50); // collectionItemId = 50
        when(() => mockCanvas.saveGameCanvasViewport(any(), any()))
            .thenAnswer((_) async {});

        final ImportResult result = await sutFull.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        expect(result.itemsImported, equals(1));

        // Проверяем что saveGameCanvasViewport был вызван
        final List<dynamic> captured = verify(
          () => mockCanvas.saveGameCanvasViewport(captureAny(), captureAny()),
        ).captured;

        expect(captured[0], equals(50)); // collectionItemId
        final CanvasViewport savedViewport = captured[1] as CanvasViewport;
        expect(savedViewport.scale, equals(0.5));
        expect(savedViewport.offsetX, equals(-200.0));
        expect(savedViewport.offsetY, equals(-100.0));
      });

      test('должен импортировать per-item canvas items с ID-ремаппингом',
          () async {
        final int canvasTs = DateTime(2024, 3, 1).millisecondsSinceEpoch ~/ 1000;

        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.full,
          name: 'Per-Item Canvas Items',
          author: 'Author',
          created: testDate,
          items: <Map<String, dynamic>>[
            <String, dynamic>{
              'media_type': 'game',
              'external_id': 100,
              '_canvas': <String, dynamic>{
                'items': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'id': 5,
                    'type': 'image',
                    'x': 100.0,
                    'y': 200.0,
                    'created_at': canvasTs,
                    'data': <String, dynamic>{
                      'base64': 'iVBORw0KGgo=',
                      'mimeType': 'image/png',
                    },
                  },
                  <String, dynamic>{
                    'id': 6,
                    'type': 'text',
                    'x': 300.0,
                    'y': 400.0,
                    'created_at': canvasTs,
                    'data': <String, dynamic>{'text': 'My note'},
                  },
                ],
                'connections': <Map<String, dynamic>>[],
              },
            },
          ],
        );

        final Collection createdCollection = Collection(
          id: 41,
          name: 'Per-Item Canvas Items',
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
        when(() => mockRepo.addItem(
              collectionId: any(named: 'collectionId'),
              mediaType: any(named: 'mediaType'),
              externalId: any(named: 'externalId'),
              platformId: any(named: 'platformId'),
              authorComment: any(named: 'authorComment'),
            )).thenAnswer((_) async => 51);

        int nextCanvasId = 200;
        when(() => mockCanvas.createItem(any())).thenAnswer((Invocation inv) async {
          final CanvasItem inputItem =
              inv.positionalArguments[0] as CanvasItem;
          nextCanvasId++;
          return inputItem.copyWith(id: nextCanvasId);
        });

        final ImportResult result = await sutFull.importFromXcoll(xcoll);

        expect(result.success, isTrue);

        // Проверяем createItem вызван 2 раза с collectionItemId = 51
        final List<dynamic> captured = verify(
          () => mockCanvas.createItem(captureAny()),
        ).captured;

        expect(captured.length, equals(2));
        final CanvasItem first = captured[0] as CanvasItem;
        final CanvasItem second = captured[1] as CanvasItem;

        expect(first.collectionItemId, equals(51));
        expect(first.id, equals(0)); // Сброшен для автоинкремента
        expect(first.itemType, equals(CanvasItemType.image));
        expect(first.collectionId, equals(41));
        expect(first.data, isNotNull);
        expect(first.data!['base64'], equals('iVBORw0KGgo='));

        expect(second.collectionItemId, equals(51));
        expect(second.id, equals(0));
        expect(second.itemType, equals(CanvasItemType.text));
      });

      test('должен импортировать per-item canvas connections с ID-ремаппингом',
          () async {
        final int canvasTs = DateTime(2024, 3, 1).millisecondsSinceEpoch ~/ 1000;

        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.full,
          name: 'Per-Item Connections',
          author: 'Author',
          created: testDate,
          items: <Map<String, dynamic>>[
            <String, dynamic>{
              'media_type': 'game',
              'external_id': 100,
              '_canvas': <String, dynamic>{
                'items': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'id': 10,
                    'type': 'text',
                    'x': 100.0,
                    'y': 200.0,
                    'created_at': canvasTs,
                  },
                  <String, dynamic>{
                    'id': 20,
                    'type': 'image',
                    'x': 300.0,
                    'y': 400.0,
                    'created_at': canvasTs,
                  },
                ],
                'connections': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'id': 1,
                    'from_item_id': 10,
                    'to_item_id': 20,
                    'created_at': canvasTs,
                  },
                ],
              },
            },
          ],
        );

        final Collection createdCollection = Collection(
          id: 42,
          name: 'Per-Item Connections',
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
        when(() => mockRepo.addItem(
              collectionId: any(named: 'collectionId'),
              mediaType: any(named: 'mediaType'),
              externalId: any(named: 'externalId'),
              platformId: any(named: 'platformId'),
              authorComment: any(named: 'authorComment'),
            )).thenAnswer((_) async => 52);

        // createItem: export ID 10 → new ID 301, export ID 20 → new ID 302
        int nextId = 300;
        when(() => mockCanvas.createItem(any())).thenAnswer((Invocation inv) async {
          final CanvasItem inputItem =
              inv.positionalArguments[0] as CanvasItem;
          nextId++;
          return inputItem.copyWith(id: nextId);
        });

        when(() => mockCanvas.createConnection(any()))
            .thenAnswer((Invocation inv) async {
          final CanvasConnection inputConn =
              inv.positionalArguments[0] as CanvasConnection;
          return inputConn.copyWith(id: 1);
        });

        final ImportResult result = await sutFull.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        verify(() => mockCanvas.createItem(any())).called(2);

        // Проверяем connection создан с ремаппленными ID и collectionItemId
        final CanvasConnection captured = verify(
          () => mockCanvas.createConnection(captureAny()),
        ).captured.first as CanvasConnection;

        expect(captured.fromItemId, equals(301)); // remapped from 10
        expect(captured.toItemId, equals(302)); // remapped from 20
        expect(captured.collectionItemId, equals(52));
        expect(captured.collectionId, equals(42));
        expect(captured.id, equals(0)); // Сброшен для автоинкремента
      });

      test('должен пропускать per-item canvas при null _canvasRepository',
          () async {
        // Сервис без canvasRepository
        final ImportService sutNoCanvas = ImportService(
          repository: mockRepo,
          igdbApi: mockApi,
          tmdbApi: mockTmdb,
          database: mockDb,
        );

        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.full,
          name: 'No Canvas Repo',
          author: 'Author',
          created: testDate,
          items: <Map<String, dynamic>>[
            <String, dynamic>{
              'media_type': 'game',
              'external_id': 100,
              '_canvas': <String, dynamic>{
                'viewport': <String, dynamic>{
                  'scale': 0.5,
                  'offsetX': 0.0,
                  'offsetY': 0.0,
                },
                'items': <Map<String, dynamic>>[],
                'connections': <Map<String, dynamic>>[],
              },
            },
          ],
        );

        final Collection createdCollection = Collection(
          id: 43,
          name: 'No Canvas Repo',
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
        when(() => mockRepo.addItem(
              collectionId: any(named: 'collectionId'),
              mediaType: any(named: 'mediaType'),
              externalId: any(named: 'externalId'),
              platformId: any(named: 'platformId'),
              authorComment: any(named: 'authorComment'),
            )).thenAnswer((_) async => 1);

        final ImportResult result = await sutNoCanvas.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        expect(result.itemsImported, equals(1));
        // Canvas методы не должны вызываться
        verifyNever(() => mockCanvas.saveGameCanvasViewport(any(), any()));
        verifyNever(() => mockCanvas.createItem(any()));
        verifyNever(() => mockCanvas.createConnection(any()));
      });

      test('должен импортировать per-item canvas с изображениями (base64 data)',
          () async {
        final int canvasTs = DateTime(2024, 3, 1).millisecondsSinceEpoch ~/ 1000;

        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.full,
          name: 'Per-Item Images',
          author: 'Author',
          created: testDate,
          items: <Map<String, dynamic>>[
            <String, dynamic>{
              'media_type': 'game',
              'external_id': 100,
              '_canvas': <String, dynamic>{
                'items': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'id': 1,
                    'type': 'image',
                    'x': 50.0,
                    'y': 75.0,
                    'width': 320.0,
                    'height': 240.0,
                    'created_at': canvasTs,
                    'data': <String, dynamic>{
                      'base64': 'R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAA',
                      'mimeType': 'image/gif',
                    },
                  },
                ],
                'connections': <Map<String, dynamic>>[],
              },
            },
          ],
        );

        final Collection createdCollection = Collection(
          id: 44,
          name: 'Per-Item Images',
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
        when(() => mockRepo.addItem(
              collectionId: any(named: 'collectionId'),
              mediaType: any(named: 'mediaType'),
              externalId: any(named: 'externalId'),
              platformId: any(named: 'platformId'),
              authorComment: any(named: 'authorComment'),
            )).thenAnswer((_) async => 53);

        when(() => mockCanvas.createItem(any())).thenAnswer((Invocation inv) async {
          final CanvasItem inputItem =
              inv.positionalArguments[0] as CanvasItem;
          return inputItem.copyWith(id: 501);
        });

        final ImportResult result = await sutFull.importFromXcoll(xcoll);

        expect(result.success, isTrue);

        // Проверяем что изображение с base64 данными сохранено
        final CanvasItem captured = verify(
          () => mockCanvas.createItem(captureAny()),
        ).captured.first as CanvasItem;

        expect(captured.itemType, equals(CanvasItemType.image));
        expect(captured.collectionItemId, equals(53));
        expect(captured.data, isNotNull);
        expect(captured.data!['base64'],
            equals('R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAA'));
        expect(captured.data!['mimeType'], equals('image/gif'));
        expect(captured.x, equals(50.0));
        expect(captured.y, equals(75.0));
        expect(captured.width, equals(320.0));
        expect(captured.height, equals(240.0));
      });
    });

    // ==================== v2 Full Import Images ====================

    group('importFromXcoll (v2 full с images)', () {
      late MockImageCacheService mockImageCache;
      late ImportService sutImages;

      setUp(() {
        mockImageCache = MockImageCacheService();
        sutImages = ImportService(
          repository: mockRepo,
          igdbApi: mockApi,
          tmdbApi: mockTmdb,
          database: mockDb,
          canvasRepository: mockCanvas,
          imageCacheService: mockImageCache,
        );
      });

      /// Хелпер: создаёт XcollFile full с images и одним game item.
      XcollFile createFullXcollWithImages(Map<String, String> images) {
        return XcollFile(
          version: 2,
          format: ExportFormat.full,
          name: 'Images Test',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[
            <String, dynamic>{
              'media_type': 'game',
              'external_id': 100,
              'platform_id': 18,
            },
          ],
          images: images,
        );
      }

      /// Настраивает общие моки для успешного импорта v2.
      void setupDefaultMocks() {
        final Collection createdCollection = Collection(
          id: 50,
          name: 'Images Test',
          author: 'Author',
          type: CollectionType.imported,
          createdAt: testDate,
        );

        when(() => mockApi.getGamesByIds(any()))
            .thenAnswer((_) async => <Game>[
                  const Game(id: 100, name: 'Test Game'),
                ]);
        when(() => mockDb.upsertGame(any())).thenAnswer((_) async {});
        when(() => mockRepo.create(
              name: any(named: 'name'),
              author: any(named: 'author'),
              type: any(named: 'type'),
            )).thenAnswer((_) async => createdCollection);
        when(() => mockRepo.addItem(
              collectionId: any(named: 'collectionId'),
              mediaType: any(named: 'mediaType'),
              externalId: any(named: 'externalId'),
              platformId: any(named: 'platformId'),
              authorComment: any(named: 'authorComment'),
            )).thenAnswer((_) async => 10);
        when(() => mockCanvas.getGameCanvasItems(any()))
            .thenAnswer((_) async => <CanvasItem>[]);
      }

      test('должен восстановить game_covers изображение в кэш', () async {
        setupDefaultMocks();
        final Uint8List testBytes =
            Uint8List.fromList(<int>[137, 80, 78, 71, 13, 10, 26, 10]);
        final String base64Data = base64Encode(testBytes);

        when(() => mockImageCache.saveImageBytes(any(), any(), any()))
            .thenAnswer((_) async => true);

        final XcollFile xcoll = createFullXcollWithImages(
          <String, String>{'game_covers/100': base64Data},
        );

        final ImportResult result = await sutImages.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        final VerificationResult captured = verify(
          () => mockImageCache.saveImageBytes(
            captureAny(),
            captureAny(),
            captureAny(),
          ),
        );
        expect(captured.callCount, equals(1));

        final List<dynamic> capturedArgs = captured.captured;
        expect(capturedArgs[0], equals(ImageType.gameCover));
        expect(capturedArgs[1], equals('100'));
        expect(capturedArgs[2], equals(testBytes));
      });

      test('должен восстановить movie_posters изображение', () async {
        setupDefaultMocks();
        final Uint8List testBytes =
            Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF, 0xE0]);
        final String base64Data = base64Encode(testBytes);

        when(() => mockImageCache.saveImageBytes(any(), any(), any()))
            .thenAnswer((_) async => true);

        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.full,
          name: 'Movie Images',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[
            <String, dynamic>{
              'media_type': 'game',
              'external_id': 100,
              'platform_id': 18,
            },
          ],
          images: <String, String>{'movie_posters/550': base64Data},
        );

        await sutImages.importFromXcoll(xcoll);

        final VerificationResult captured = verify(
          () => mockImageCache.saveImageBytes(
            captureAny(),
            captureAny(),
            captureAny(),
          ),
        );
        final List<dynamic> capturedArgs = captured.captured;
        expect(capturedArgs[0], equals(ImageType.moviePoster));
        expect(capturedArgs[1], equals('550'));
        expect(capturedArgs[2], equals(testBytes));
      });

      test('должен пропустить невалидный ключ', () async {
        setupDefaultMocks();
        final String base64Data = base64Encode(<int>[1, 2, 3]);

        when(() => mockImageCache.saveImageBytes(any(), any(), any()))
            .thenAnswer((_) async => true);

        final XcollFile xcoll = createFullXcollWithImages(
          <String, String>{'invalid_key_no_slash': base64Data},
        );

        final ImportResult result = await sutImages.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        verifyNever(
          () => mockImageCache.saveImageBytes(any(), any(), any()),
        );
      });

      test('должен пропустить невалидный base64', () async {
        setupDefaultMocks();

        when(() => mockImageCache.saveImageBytes(any(), any(), any()))
            .thenAnswer((_) async => true);

        final XcollFile xcoll = createFullXcollWithImages(
          <String, String>{'game_covers/100': '!!!not-valid-base64!!!'},
        );

        // Не должен упасть
        final ImportResult result = await sutImages.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        verifyNever(
          () => mockImageCache.saveImageBytes(any(), any(), any()),
        );
      });

      test('без imageCacheService не должен вызывать saveImageBytes',
          () async {
        setupDefaultMocks();
        final String base64Data = base64Encode(<int>[1, 2, 3]);

        // sut без imageCacheService
        final ImportService sutNoCache = ImportService(
          repository: mockRepo,
          igdbApi: mockApi,
          tmdbApi: mockTmdb,
          database: mockDb,
          canvasRepository: mockCanvas,
        );

        final XcollFile xcoll = createFullXcollWithImages(
          <String, String>{'game_covers/100': base64Data},
        );

        final ImportResult result = await sutNoCache.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        verifyNever(
          () => mockImageCache.saveImageBytes(any(), any(), any()),
        );
      });

      test('должен пропустить images при format light', () async {
        setupDefaultMocks();
        final String base64Data = base64Encode(<int>[1, 2, 3]);

        when(() => mockImageCache.saveImageBytes(any(), any(), any()))
            .thenAnswer((_) async => true);

        // Light формат с images — images не должны восстанавливаться
        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.light,
          name: 'Light',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[
            <String, dynamic>{
              'media_type': 'game',
              'external_id': 100,
              'platform_id': 18,
            },
          ],
          images: <String, String>{'game_covers/100': base64Data},
        );

        final ImportResult result = await sutImages.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        verifyNever(
          () => mockImageCache.saveImageBytes(any(), any(), any()),
        );
      });

      test('должен отслеживать прогресс importingImages', () async {
        setupDefaultMocks();
        final String base64Data = base64Encode(<int>[1, 2, 3]);

        when(() => mockImageCache.saveImageBytes(any(), any(), any()))
            .thenAnswer((_) async => true);

        final XcollFile xcoll = createFullXcollWithImages(
          <String, String>{'game_covers/100': base64Data},
        );

        final List<ImportStage> stages = <ImportStage>[];
        await sutImages.importFromXcoll(
          xcoll,
          onProgress: (ImportProgress progress) {
            if (!stages.contains(progress.stage)) {
              stages.add(progress.stage);
            }
          },
        );

        expect(stages, contains(ImportStage.importingImages));
      });
    });

    // ==================== v2 full с embedded media ====================

    group('importFromXcoll (v2 full с embedded media)', () {
      late ImportService sutMedia;
      late MockCanvasRepository mockCanvas;
      late MockImageCacheService mockImageCache;

      setUp(() {
        mockCanvas = MockCanvasRepository();
        mockImageCache = MockImageCacheService();
        sutMedia = ImportService(
          repository: mockRepo,
          igdbApi: mockApi,
          tmdbApi: mockTmdb,
          database: mockDb,
          canvasRepository: mockCanvas,
          imageCacheService: mockImageCache,
        );
      });

      void setupDefaultMocksForMedia() {
        final Collection createdCollection = Collection(
          id: 10,
          name: 'Test',
          author: 'Author',
          type: CollectionType.imported,
          createdAt: testDate,
        );
        when(() => mockRepo.create(
              name: any(named: 'name'),
              author: any(named: 'author'),
              type: any(named: 'type'),
            )).thenAnswer((_) async => createdCollection);
        when(() => mockRepo.addItem(
              collectionId: any(named: 'collectionId'),
              mediaType: any(named: 'mediaType'),
              externalId: any(named: 'externalId'),
              platformId: any(named: 'platformId'),
              authorComment: any(named: 'authorComment'),
            )).thenAnswer((_) async => 1);
        when(() => mockDb.upsertGames(any())).thenAnswer((_) async {});
        when(() => mockDb.upsertMovies(any())).thenAnswer((_) async {});
        when(() => mockDb.upsertTvShows(any())).thenAnswer((_) async {});
        when(() => mockDb.upsertTvSeasons(any())).thenAnswer((_) async {});
        when(() => mockDb.upsertEpisodes(any())).thenAnswer((_) async {});
        when(() => mockDb.upsertPlatforms(any())).thenAnswer((_) async {});
        when(() => mockImageCache.saveImageBytes(any(), any(), any()))
            .thenAnswer((_) async => true);
      }

      test('должен восстановить games из embedded media', () async {
        setupDefaultMocksForMedia();

        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.full,
          name: 'With Media',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[
            <String, dynamic>{
              'media_type': 'game',
              'external_id': 42,
            },
          ],
          media: const <String, dynamic>{
            'games': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 42,
                'name': 'Offline Game',
                'summary': 'Test',
                'genres': 'Action|RPG',
              },
            ],
          },
        );

        final ImportResult result = await sutMedia.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        // Должен вызвать upsertGames, а НЕ igdb API
        verify(() => mockDb.upsertGames(any())).called(1);
        verifyNever(() => mockApi.getGamesByIds(any()));
      });

      test('должен восстановить movies из embedded media', () async {
        setupDefaultMocksForMedia();

        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.full,
          name: 'With Movies',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[
            <String, dynamic>{
              'media_type': 'movie',
              'external_id': 550,
            },
          ],
          media: const <String, dynamic>{
            'movies': <Map<String, dynamic>>[
              <String, dynamic>{
                'tmdb_id': 550,
                'title': 'Fight Club',
              },
            ],
          },
        );

        final ImportResult result = await sutMedia.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        verify(() => mockDb.upsertMovies(any())).called(1);
        verifyNever(() => mockTmdb.getMovie(any()));
      });

      test('должен восстановить tv_shows из embedded media', () async {
        setupDefaultMocksForMedia();

        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.full,
          name: 'With TV Shows',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[
            <String, dynamic>{
              'media_type': 'tv_show',
              'external_id': 1399,
            },
          ],
          media: const <String, dynamic>{
            'tv_shows': <Map<String, dynamic>>[
              <String, dynamic>{
                'tmdb_id': 1399,
                'title': 'Game of Thrones',
                'total_seasons': 8,
              },
            ],
          },
        );

        final ImportResult result = await sutMedia.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        verify(() => mockDb.upsertTvShows(any())).called(1);
        verifyNever(() => mockTmdb.getTvShow(any()));
      });

      test('должен восстановить все типы медиа из embedded', () async {
        setupDefaultMocksForMedia();

        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.full,
          name: 'All Types',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[
            <String, dynamic>{'media_type': 'game', 'external_id': 1},
            <String, dynamic>{'media_type': 'movie', 'external_id': 2},
            <String, dynamic>{'media_type': 'tv_show', 'external_id': 3},
          ],
          media: const <String, dynamic>{
            'games': <Map<String, dynamic>>[
              <String, dynamic>{'id': 1, 'name': 'G'},
            ],
            'movies': <Map<String, dynamic>>[
              <String, dynamic>{'tmdb_id': 2, 'title': 'M'},
            ],
            'tv_shows': <Map<String, dynamic>>[
              <String, dynamic>{'tmdb_id': 3, 'title': 'T'},
            ],
          },
        );

        final ImportResult result = await sutMedia.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        expect(result.itemsImported, equals(3));
        verify(() => mockDb.upsertGames(any())).called(1);
        verify(() => mockDb.upsertMovies(any())).called(1);
        verify(() => mockDb.upsertTvShows(any())).called(1);
        verifyNever(() => mockApi.getGamesByIds(any()));
        verifyNever(() => mockTmdb.getMovie(any()));
        verifyNever(() => mockTmdb.getTvShow(any()));
      });

      test('должен использовать API при пустом media', () async {
        setupDefaultMocksForMedia();
        when(() => mockApi.getGamesByIds(any()))
            .thenAnswer((_) async => const <Game>[Game(id: 42, name: 'G')]);
        when(() => mockDb.upsertGame(any())).thenAnswer((_) async {});

        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.light,
          name: 'No Media',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[
            <String, dynamic>{'media_type': 'game', 'external_id': 42},
          ],
          // media пуст — должен загрузить из API
        );

        final ImportResult result = await sutMedia.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        verify(() => mockApi.getGamesByIds(<int>[42])).called(1);
        verifyNever(() => mockDb.upsertGames(any()));
      });

      test('должен отслеживать прогресс restoringMedia', () async {
        setupDefaultMocksForMedia();

        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.full,
          name: 'Progress',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[
            <String, dynamic>{'media_type': 'game', 'external_id': 1},
          ],
          media: const <String, dynamic>{
            'games': <Map<String, dynamic>>[
              <String, dynamic>{'id': 1, 'name': 'G'},
            ],
          },
        );

        final List<ImportStage> stages = <ImportStage>[];
        await sutMedia.importFromXcoll(
          xcoll,
          onProgress: (ImportProgress progress) {
            if (!stages.contains(progress.stage)) {
              stages.add(progress.stage);
            }
          },
        );

        expect(stages, contains(ImportStage.restoringMedia));
        // Не должно быть этапов API-загрузки
        expect(stages, isNot(contains(ImportStage.fetchingGames)));
        expect(stages, isNot(contains(ImportStage.fetchingMovies)));
        expect(stages, isNot(contains(ImportStage.fetchingTvShows)));
      });

      test('должен пропустить пустые категории в embedded media', () async {
        setupDefaultMocksForMedia();

        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.full,
          name: 'Only Games',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[
            <String, dynamic>{'media_type': 'game', 'external_id': 1},
          ],
          media: const <String, dynamic>{
            'games': <Map<String, dynamic>>[
              <String, dynamic>{'id': 1, 'name': 'G'},
            ],
            // movies и tv_shows отсутствуют
          },
        );

        final ImportResult result = await sutMedia.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        verify(() => mockDb.upsertGames(any())).called(1);
        verifyNever(() => mockDb.upsertMovies(any()));
        verifyNever(() => mockDb.upsertTvShows(any()));
      });

      test('должен восстановить tv_seasons из embedded media', () async {
        setupDefaultMocksForMedia();

        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.full,
          name: 'With Seasons',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[
            <String, dynamic>{
              'media_type': 'tv_show',
              'external_id': 1399,
            },
          ],
          media: const <String, dynamic>{
            'tv_shows': <Map<String, dynamic>>[
              <String, dynamic>{
                'tmdb_id': 1399,
                'title': 'GoT',
                'total_seasons': 8,
              },
            ],
            'tv_seasons': <Map<String, dynamic>>[
              <String, dynamic>{
                'tmdb_show_id': 1399,
                'season_number': 1,
                'name': 'Season 1',
                'episode_count': 10,
                'air_date': '2011-04-17',
              },
              <String, dynamic>{
                'tmdb_show_id': 1399,
                'season_number': 2,
                'name': 'Season 2',
                'episode_count': 10,
              },
            ],
          },
        );

        final ImportResult result = await sutMedia.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        verify(() => mockDb.upsertTvShows(any())).called(1);
        verify(() => mockDb.upsertTvSeasons(any())).called(1);
      });

      test('не должен падать когда tv_seasons отсутствует в media', () async {
        setupDefaultMocksForMedia();

        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.full,
          name: 'No Seasons',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[
            <String, dynamic>{
              'media_type': 'tv_show',
              'external_id': 1399,
            },
          ],
          media: const <String, dynamic>{
            'tv_shows': <Map<String, dynamic>>[
              <String, dynamic>{
                'tmdb_id': 1399,
                'title': 'GoT',
              },
            ],
            // tv_seasons отсутствует
          },
        );

        final ImportResult result = await sutMedia.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        verify(() => mockDb.upsertTvShows(any())).called(1);
        verifyNever(() => mockDb.upsertTvSeasons(any()));
      });

      test('должен восстановить tv_episodes из embedded media', () async {
        setupDefaultMocksForMedia();

        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.full,
          name: 'With Episodes',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[
            <String, dynamic>{
              'media_type': 'tv_show',
              'external_id': 1399,
            },
          ],
          media: const <String, dynamic>{
            'tv_shows': <Map<String, dynamic>>[
              <String, dynamic>{
                'tmdb_id': 1399,
                'title': 'GoT',
              },
            ],
            'tv_episodes': <Map<String, dynamic>>[
              <String, dynamic>{
                'tmdb_show_id': 1399,
                'season_number': 1,
                'episode_number': 1,
                'name': 'Winter Is Coming',
                'overview': 'First episode',
                'air_date': '2011-04-17',
                'runtime': 62,
              },
              <String, dynamic>{
                'tmdb_show_id': 1399,
                'season_number': 1,
                'episode_number': 2,
                'name': 'The Kingsroad',
                'runtime': 56,
              },
            ],
          },
        );

        final ImportResult result = await sutMedia.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        verify(() => mockDb.upsertTvShows(any())).called(1);
        verify(() => mockDb.upsertEpisodes(any())).called(1);
      });

      test('не должен падать когда tv_episodes отсутствует в media', () async {
        setupDefaultMocksForMedia();

        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.full,
          name: 'No Episodes',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[
            <String, dynamic>{
              'media_type': 'tv_show',
              'external_id': 1399,
            },
          ],
          media: const <String, dynamic>{
            'tv_shows': <Map<String, dynamic>>[
              <String, dynamic>{
                'tmdb_id': 1399,
                'title': 'GoT',
              },
            ],
          },
        );

        final ImportResult result = await sutMedia.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        verify(() => mockDb.upsertTvShows(any())).called(1);
        verifyNever(() => mockDb.upsertEpisodes(any()));
      });

      test('должен восстановить platforms из embedded media', () async {
        setupDefaultMocksForMedia();

        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.full,
          name: 'With Platforms',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[
            <String, dynamic>{
              'media_type': 'game',
              'external_id': 42,
              'platform_id': 6,
            },
          ],
          media: const <String, dynamic>{
            'games': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 42,
                'name': 'Test Game',
              },
            ],
            'platforms': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 6,
                'name': 'PC (Microsoft Windows)',
                'abbreviation': 'PC',
                'logo_image_id': null,
                'synced_at': 1700000000,
              },
              <String, dynamic>{
                'id': 48,
                'name': 'PlayStation 4',
                'abbreviation': 'PS4',
                'logo_image_id': null,
                'synced_at': 1700000000,
              },
            ],
          },
        );

        final ImportResult result = await sutMedia.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        verify(() => mockDb.upsertPlatforms(any())).called(1);
        verify(() => mockDb.upsertGames(any())).called(1);
      });

      test('должен пропустить восстановление platforms без данных', () async {
        setupDefaultMocksForMedia();

        final XcollFile xcoll = XcollFile(
          version: 2,
          format: ExportFormat.full,
          name: 'No Platforms',
          author: 'Author',
          created: testDate,
          items: const <Map<String, dynamic>>[
            <String, dynamic>{
              'media_type': 'game',
              'external_id': 42,
            },
          ],
          media: const <String, dynamic>{
            'games': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 42,
                'name': 'Test Game',
              },
            ],
          },
        );

        final ImportResult result = await sutMedia.importFromXcoll(xcoll);

        expect(result.success, isTrue);
        verify(() => mockDb.upsertGames(any())).called(1);
        verifyNever(() => mockDb.upsertPlatforms(any()));
      });
    });
  });
}
