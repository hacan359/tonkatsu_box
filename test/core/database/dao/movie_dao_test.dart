import 'package:core/database/dao/movie_dao.dart';
import 'package:core/models/movie.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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
    when(() => mockBatch.rawInsert(any(), any())).thenReturn(null);
    when(() => mockBatch.commit(noResult: true))
        .thenAnswer((_) async => <Object?>[]);
  }

  group('MovieDao', () {
    group('getMovieByTmdbId', () {
      test('returns null when not found', () async {
        when(
          () => mockDb.query(
            'movies_cache',
            where: 'tmdb_id = ? AND source = ?',
            whereArgs: <Object?>[999, 'tmdb'],
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
            where: 'tmdb_id = ? AND source = ?',
            whereArgs: <Object?>[550, 'tmdb'],
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
      test('writes an upsert keyed by id and source', () async {
        const Movie movie = Movie(tmdbId: 1, title: 'Test');
        final List<String> sql = <String>[];
        when(() => mockDb.rawInsert(any(), any())).thenAnswer((Invocation i) {
          sql.add(i.positionalArguments.first as String);
          return Future<int>.value(1);
        });

        await dao.upsertMovie(movie);

        expect(sql.single, contains('INSERT OR REPLACE INTO movies_cache'));
        expect(sql.single, contains('source'));
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

        verify(() => mockBatch.rawInsert(any(), any())).called(2);
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

      test('capitalizes first letter of lowercase genre names', () async {
        when(
          () => mockDb.query(
            'tmdb_genres',
            where: 'type = ? AND lang = ?',
            whereArgs: <Object?>['movie', 'ru'],
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'id': 28, 'name': 'боевик'},
            <String, dynamic>{'id': 878, 'name': 'научная фантастика'},
          ],
        );

        final Map<String, String> result =
            await dao.getTmdbGenreMap('movie', lang: 'ru');

        expect(result, <String, String>{
          '28': 'Боевик',
          '878': 'Научная фантастика',
        });
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
