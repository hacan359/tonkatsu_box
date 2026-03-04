import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xerabora/core/database/dao/movie_dao.dart';
import 'package:xerabora/shared/models/movie.dart';

import '../../../helpers/mocks.dart';

void main() {
  late TransactionMockDatabase mockDb;
  late MockTransaction mockTxn;
  late MockBatch mockBatch;
  late MovieDao dao;

  setUp(() {
    mockDb = TransactionMockDatabase();
    mockTxn = MockTransaction();
    mockBatch = MockBatch();
    dao = MovieDao(() async => mockDb);
  });

  void stubTransaction() {
    mockDb.stubTransaction(mockTxn);
    when(() => mockTxn.batch()).thenReturn(mockBatch);
    when(
      () => mockBatch.insert(
        any(),
        any(),
        conflictAlgorithm: any(named: 'conflictAlgorithm'),
      ),
    ).thenReturn(null);
    when(() => mockBatch.commit(noResult: true))
        .thenAnswer((_) async => <Object?>[]);
  }

  group('MovieDao', () {
    group('getMovieByTmdbId', () {
      test('returns null when not found', () async {
        when(
          () => mockDb.query(
            'movies_cache',
            where: 'tmdb_id = ?',
            whereArgs: <Object?>[999],
            limit: 1,
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        expect(await dao.getMovieByTmdbId(999), isNull);
      });

      test('returns movie when found', () async {
        final Map<String, dynamic> row = <String, dynamic>{
          'tmdb_id': 550,
          'title': 'Fight Club',
          'original_title': null,
          'poster_url': null,
          'backdrop_url': null,
          'overview': null,
          'genres': null,
          'release_year': 1999,
          'rating': 8.4,
          'runtime': 139,
          'external_url': null,
          'cached_at': 1000,
        };
        when(
          () => mockDb.query(
            'movies_cache',
            where: 'tmdb_id = ?',
            whereArgs: <Object?>[550],
            limit: 1,
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[row]);

        final Movie? result = await dao.getMovieByTmdbId(550);

        expect(result, isNotNull);
        expect(result!.tmdbId, 550);
        expect(result.title, 'Fight Club');
      });
    });

    group('upsertMovie', () {
      test('inserts with replace', () async {
        const Movie movie = Movie(tmdbId: 1, title: 'Test');
        when(
          () => mockDb.insert(
            'movies_cache',
            any(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          ),
        ).thenAnswer((_) async => 1);

        await dao.upsertMovie(movie);

        verify(
          () => mockDb.insert(
            'movies_cache',
            movie.toDb(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          ),
        ).called(1);
      });
    });

    group('upsertMovies', () {
      test('skips when list is empty', () async {
        await dao.upsertMovies(<Movie>[]);

        verifyNever(() => mockTxn.batch());
      });

      test('uses transaction and batch', () async {
        stubTransaction();

        await dao.upsertMovies(const <Movie>[
          Movie(tmdbId: 1, title: 'M1'),
          Movie(tmdbId: 2, title: 'M2'),
        ]);

        verify(
          () => mockBatch.insert(
            'movies_cache',
            any(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          ),
        ).called(2);
        verify(() => mockBatch.commit(noResult: true)).called(1);
      });
    });

    group('getMoviesByTmdbIds', () {
      test('returns empty list for empty ids', () async {
        expect(await dao.getMoviesByTmdbIds(<int>[]), isEmpty);
      });

      test('queries with IN clause', () async {
        when(
          () => mockDb.query(
            'movies_cache',
            where: 'tmdb_id IN (?,?)',
            whereArgs: <Object?>[550, 680],
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        final List<Movie> result =
            await dao.getMoviesByTmdbIds(<int>[550, 680]);

        expect(result, isEmpty);
      });
    });

    group('clearMovies', () {
      test('deletes all movies', () async {
        when(() => mockDb.delete('movies_cache')).thenAnswer((_) async => 3);

        await dao.clearMovies();

        verify(() => mockDb.delete('movies_cache')).called(1);
      });
    });

    group('getTmdbGenreMap', () {
      test('returns genre map for movie type', () async {
        when(
          () => mockDb.query(
            'tmdb_genres',
            where: 'type = ? AND lang = ?',
            whereArgs: <Object?>['movie', 'en'],
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'id': 28, 'name': 'Action'},
            <String, dynamic>{'id': 12, 'name': 'Adventure'},
          ],
        );

        final Map<String, String> result = await dao.getTmdbGenreMap('movie');

        expect(result, <String, String>{'28': 'Action', '12': 'Adventure'});
      });

      test('respects lang parameter', () async {
        when(
          () => mockDb.query(
            'tmdb_genres',
            where: 'type = ? AND lang = ?',
            whereArgs: <Object?>['tv', 'ru'],
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        final Map<String, String> result =
            await dao.getTmdbGenreMap('tv', lang: 'ru');

        expect(result, isEmpty);
      });

      test('returns empty map when no genres cached', () async {
        when(
          () => mockDb.query(
            'tmdb_genres',
            where: 'type = ? AND lang = ?',
            whereArgs: <Object?>['movie', 'en'],
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        final Map<String, String> result = await dao.getTmdbGenreMap('movie');

        expect(result, isEmpty);
      });
    });
  });
}
