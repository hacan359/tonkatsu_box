// Тесты для KodiImportService — импорт библиотеки Kodi → TMDB фильмы.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/api/kodi_api.dart';
import 'package:xerabora/core/api/tmdb_api.dart';
import 'package:xerabora/core/services/kodi_import_service.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/kodi_movie.dart';
import 'package:xerabora/shared/models/kodi_unique_ids.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/movie.dart';
import 'package:xerabora/shared/models/tv_show.dart';

import '../../helpers/test_helpers.dart';

class _Default {
  const _Default();
}

void main() {
  setUpAll(registerAllFallbacks);

  late MockKodiApi mockKodiApi;
  late MockTmdbApi mockTmdbApi;
  late MockDatabaseService mockDb;
  late KodiImportService service;

  final List<KodiImportProgress> progressLog = <KodiImportProgress>[];

  setUp(() {
    mockKodiApi = MockKodiApi();
    mockTmdbApi = MockTmdbApi();
    mockDb = MockDatabaseService();
    service = KodiImportService(
      kodiApi: mockKodiApi,
      tmdbApi: mockTmdbApi,
      database: mockDb,
    );
    progressLog.clear();

    // Default stubs.
    when(() => mockDb.upsertMovie(any())).thenAnswer((_) async {});
    when(() => mockDb.updateItemUserComment(any(), any()))
        .thenAnswer((_) async {});
    when(() => mockDb.updateItemUserRating(any(), any()))
        .thenAnswer((_) async {});
    when(() => mockDb.updateItemActivityDates(
          any(),
          lastActivityAt: any(named: 'lastActivityAt'),
        )).thenAnswer((_) async {});
    when(() => mockDb.updateItemStatus(any(), any(), mediaType: any(named: 'mediaType')))
        .thenAnswer((_) async {});
  });

  KodiMovie _movie({
    int movieId = 1,
    String title = 'Test Movie',
    int? tmdbId = 100,
    String? imdbId,
    int year = 2020,
    int playcount = 1,
    Object? lastPlayed = const _Default(),
    int? userRating,
    String? set,
    DateTime? dateAdded,
    double? communityRating,
  }) {
    return KodiMovie(
      movieId: movieId,
      title: title,
      year: year,
      playcount: playcount,
      lastPlayed: lastPlayed is _Default ? DateTime(2026, 4, 15) : lastPlayed as DateTime?,
      userRating: userRating,
      set: set,
      dateAdded: dateAdded,
      communityRating: communityRating,
      uniqueIds: KodiUniqueIds(
        tmdbId: tmdbId,
        imdbId: imdbId,
      ),
    );
  }

  const Movie tmdbMovie = Movie(tmdbId: 100, title: 'Test Movie');

  void stubGetMovies(List<KodiMovie> movies) {
    when(() => mockKodiApi.getMovies(
          start: any(named: 'start'),
          end: any(named: 'end'),
        )).thenAnswer((_) async => movies);
  }

  void stubTmdbGetMovie({int tmdbId = 100}) {
    when(() => mockTmdbApi.getMovie(tmdbId))
        .thenAnswer((_) async => tmdbMovie);
  }

  void stubNoExistingItem() {
    when(() => mockDb.findCollectionItem(
          collectionId: any(named: 'collectionId'),
          mediaType: any(named: 'mediaType'),
          externalId: any(named: 'externalId'),
        )).thenAnswer((_) async => null);
  }

  void stubAddItem({int returnId = 1}) {
    when(() => mockDb.addItemToCollection(
          collectionId: any(named: 'collectionId'),
          mediaType: any(named: 'mediaType'),
          externalId: any(named: 'externalId'),
          platformId: any(named: 'platformId'),
          authorComment: any(named: 'authorComment'),
          status: any(named: 'status'),
        )).thenAnswer((_) async => returnId);
  }

  group('KodiImportService', () {
    group('importLibrary', () {
      test('imports watched movie as completed', () async {
        final KodiMovie movie = _movie(playcount: 2);
        stubGetMovies(<KodiMovie>[movie]);
        stubTmdbGetMovie();
        stubNoExistingItem();
        stubAddItem();

        final KodiImportResult result = await service.importLibrary(
          collectionId: 10,
          createSubCollections: false,
          importRatings: false,
          onProgress: progressLog.add,
        );

        expect(result.imported, 1);
        expect(result.total, 1);
        expect(result.collectionId, 10);

        verify(() => mockDb.addItemToCollection(
              collectionId: 10,
              mediaType: MediaType.movie,
              externalId: 100,
              status: ItemStatus.completed,
            )).called(1);
      });

      test('imports unwatched movie as planned', () async {
        final KodiMovie movie = _movie(
          playcount: 0,
          lastPlayed: null,
        );
        stubGetMovies(<KodiMovie>[movie]);
        stubTmdbGetMovie();
        stubNoExistingItem();
        stubAddItem();

        final KodiImportResult result = await service.importLibrary(
          collectionId: 10,
          createSubCollections: false,
          importRatings: false,
          onProgress: progressLog.add,
        );

        expect(result.imported, 1);

        verify(() => mockDb.addItemToCollection(
              collectionId: 10,
              mediaType: MediaType.movie,
              externalId: 100,
              status: ItemStatus.planned,
            )).called(1);
      });

      test('imports started but not finished movie as inProgress', () async {
        final KodiMovie movie = _movie(playcount: 0);
        stubGetMovies(<KodiMovie>[movie]);
        stubTmdbGetMovie();
        stubNoExistingItem();
        stubAddItem();

        await service.importLibrary(
          collectionId: 10,
          createSubCollections: false,
          importRatings: false,
          onProgress: progressLog.add,
        );

        verify(() => mockDb.addItemToCollection(
              collectionId: 10,
              mediaType: MediaType.movie,
              externalId: 100,
              status: ItemStatus.inProgress,
            )).called(1);
      });

      test('imports userRating when importRatings=true', () async {
        final KodiMovie movie = _movie(userRating: 8);
        stubGetMovies(<KodiMovie>[movie]);
        stubTmdbGetMovie();
        stubNoExistingItem();
        stubAddItem(returnId: 42);

        await service.importLibrary(
          collectionId: 10,
          createSubCollections: false,
          importRatings: true,
          onProgress: progressLog.add,
        );

        verify(() => mockDb.updateItemUserRating(42, 8)).called(1);
      });

      test('skips userRating when importRatings=false', () async {
        final KodiMovie movie = _movie(userRating: 8);
        stubGetMovies(<KodiMovie>[movie]);
        stubTmdbGetMovie();
        stubNoExistingItem();
        stubAddItem();

        await service.importLibrary(
          collectionId: 10,
          createSubCollections: false,
          importRatings: false,
          onProgress: progressLog.add,
        );

        verifyNever(() => mockDb.updateItemUserRating(any(), any()));
      });

      test('writes comment with metadata', () async {
        final KodiMovie movie = _movie(
          playcount: 3,
          lastPlayed: DateTime(2026, 4, 15),
          dateAdded: DateTime(2023, 12, 29),
          communityRating: 7.8,
        );
        stubGetMovies(<KodiMovie>[movie]);
        stubTmdbGetMovie();
        stubNoExistingItem();
        stubAddItem(returnId: 5);

        await service.importLibrary(
          collectionId: 10,
          createSubCollections: false,
          importRatings: false,
          onProgress: progressLog.add,
        );

        final String captured = verify(
          () => mockDb.updateItemUserComment(5, captureAny()),
        ).captured.single as String;

        expect(captured, contains('Watched 3 times'));
        expect(captured, contains('Last played: 2026-04-15'));
        expect(captured, contains('Added to Kodi: 2023-12-29'));
      });

      test('counts unmatched when no tmdb id', () async {
        final KodiMovie movie = _movie(tmdbId: null);
        stubGetMovies(<KodiMovie>[movie]);

        final KodiImportResult result = await service.importLibrary(
          collectionId: 10,
          createSubCollections: false,
          importRatings: false,
          onProgress: progressLog.add,
        );

        expect(result.unmatched, 1);
        expect(result.imported, 0);
      });

      test('resolves tmdb via imdb fallback', () async {
        final KodiMovie movie = _movie(tmdbId: null, imdbId: 'tt1234567');
        stubGetMovies(<KodiMovie>[movie]);
        when(() => mockTmdbApi.findByImdbId('tt1234567')).thenAnswer(
          (_) async => TmdbFindResult(
            movies: <Movie>[const Movie(tmdbId: 200, title: 'Found')],
            tvShows: <TvShow>[],
          ),
        );
        when(() => mockTmdbApi.getMovie(200))
            .thenAnswer((_) async => const Movie(tmdbId: 200, title: 'Found'));
        stubNoExistingItem();
        stubAddItem();

        final KodiImportResult result = await service.importLibrary(
          collectionId: 10,
          createSubCollections: false,
          importRatings: false,
          onProgress: progressLog.add,
        );

        expect(result.imported, 1);
        verify(() => mockDb.addItemToCollection(
              collectionId: 10,
              mediaType: MediaType.movie,
              externalId: 200,
              status: any(named: 'status'),
            )).called(1);
      });

      test('creates sub-collection from set', () async {
        final KodiMovie movie = _movie(set: 'Harry Potter Collection');
        stubGetMovies(<KodiMovie>[movie]);
        stubTmdbGetMovie();
        stubNoExistingItem();
        stubAddItem();

        when(() => mockDb.findCollectionByName(
              'Harry Potter Collection (kodi)',
            )).thenAnswer((_) async => null);
        when(() => mockDb.createCollection(
              name: 'Harry Potter Collection (kodi)',
              author: 'Kodi',
            )).thenAnswer((_) async => createTestCollection(
              id: 99,
              name: 'Harry Potter Collection (kodi)',
              author: 'Kodi',
            ));

        final KodiImportResult result = await service.importLibrary(
          collectionId: 10,
          createSubCollections: true,
          importRatings: false,
          onProgress: progressLog.add,
        );

        expect(result.collectionsCreated, 1);
        verify(() => mockDb.addItemToCollection(
              collectionId: 99,
              mediaType: MediaType.movie,
              externalId: 100,
              status: any(named: 'status'),
            )).called(1);
      });

      test('reuses existing sub-collection from set', () async {
        final KodiMovie movie = _movie(set: 'HP Collection');
        stubGetMovies(<KodiMovie>[movie]);
        stubTmdbGetMovie();
        stubNoExistingItem();
        stubAddItem();

        when(() => mockDb.findCollectionByName('HP Collection (kodi)'))
            .thenAnswer((_) async => createTestCollection(
                  id: 50,
                  name: 'HP Collection (kodi)',
                  author: 'Kodi',
                ));

        final KodiImportResult result = await service.importLibrary(
          collectionId: 10,
          createSubCollections: true,
          importRatings: false,
          onProgress: progressLog.add,
        );

        expect(result.collectionsCreated, 0);
        verifyNever(() => mockDb.createCollection(
              name: any(named: 'name'),
              author: any(named: 'author'),
            ));
        verify(() => mockDb.addItemToCollection(
              collectionId: 50,
              mediaType: MediaType.movie,
              externalId: 100,
              status: any(named: 'status'),
            )).called(1);
      });

      test('updates existing item instead of duplicating', () async {
        final KodiMovie movie = _movie(playcount: 2);
        stubGetMovies(<KodiMovie>[movie]);
        stubTmdbGetMovie();

        when(() => mockDb.findCollectionItem(
              collectionId: 10,
              mediaType: MediaType.movie,
              externalId: 100,
            )).thenAnswer((_) async => createTestCollectionItem(
              id: 77,
              collectionId: 10,
              mediaType: MediaType.movie,
              externalId: 100,
              status: ItemStatus.planned,
            ));

        final KodiImportResult result = await service.importLibrary(
          collectionId: 10,
          createSubCollections: false,
          importRatings: false,
          onProgress: progressLog.add,
        );

        expect(result.updated, 1);
        expect(result.imported, 0);
        verifyNever(() => mockDb.addItemToCollection(
              collectionId: any(named: 'collectionId'),
              mediaType: any(named: 'mediaType'),
              externalId: any(named: 'externalId'),
            ));
      });

      test('creates collection lazily via callback', () async {
        stubGetMovies(<KodiMovie>[_movie()]);
        stubTmdbGetMovie();
        stubNoExistingItem();
        stubAddItem();

        bool collectionCreated = false;

        await service.importLibrary(
          createCollection: () async {
            collectionCreated = true;
            return 42;
          },
          createSubCollections: false,
          importRatings: false,
          onProgress: progressLog.add,
        );

        expect(collectionCreated, isTrue);
      });

      test('throws on empty Kodi library', () async {
        stubGetMovies(<KodiMovie>[]);

        expect(
          () => service.importLibrary(
            collectionId: 10,
            createSubCollections: false,
            importRatings: false,
            onProgress: progressLog.add,
          ),
          throwsA(isA<KodiApiException>()),
        );
      });

      test('reports progress through all stages', () async {
        stubGetMovies(<KodiMovie>[_movie()]);
        stubTmdbGetMovie();
        stubNoExistingItem();
        stubAddItem();

        await service.importLibrary(
          collectionId: 10,
          createSubCollections: false,
          importRatings: false,
          onProgress: progressLog.add,
        );

        final List<KodiImportStage> stages =
            progressLog.map((KodiImportProgress p) => p.stage).toList();
        expect(stages.first, KodiImportStage.fetchingLibrary);
        expect(stages.last, KodiImportStage.completed);
        expect(stages, contains(KodiImportStage.matchingMovies));
      });
    });

    group('toUniversal', () {
      test('converts to UniversalImportResult', () {
        const KodiImportResult result = KodiImportResult(
          imported: 5,
          updated: 2,
          unmatched: 1,
          total: 8,
          collectionId: 10,
          collectionsCreated: 1,
        );

        final universal = result.toUniversal();
        expect(universal.sourceName, 'Kodi');
        expect(universal.success, isTrue);
        expect(universal.totalImported, 5);
        expect(universal.totalUpdated, 2);
        expect(universal.skipped, 1);
        expect(universal.collectionId, 10);
      });
    });
  });
}
