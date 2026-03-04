import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xerabora/core/database/dao/tv_show_dao.dart';
import 'package:xerabora/shared/models/tv_episode.dart';
import 'package:xerabora/shared/models/tv_season.dart';
import 'package:xerabora/shared/models/tv_show.dart';

import '../../../helpers/mocks.dart';

void main() {
  late TransactionMockDatabase mockDb;
  late MockTransaction mockTxn;
  late MockBatch mockBatch;
  late TvShowDao dao;

  setUp(() {
    mockDb = TransactionMockDatabase();
    mockTxn = MockTransaction();
    mockBatch = MockBatch();
    dao = TvShowDao(() async => mockDb);
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

  group('TvShowDao', () {
    // ==================== TV Shows ====================

    group('getTvShowByTmdbId', () {
      test('returns null when not found', () async {
        when(
          () => mockDb.query(
            'tv_shows_cache',
            where: 'tmdb_id = ?',
            whereArgs: <Object?>[999],
            limit: 1,
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        expect(await dao.getTvShowByTmdbId(999), isNull);
      });

      test('returns tv show when found', () async {
        final Map<String, dynamic> row = <String, dynamic>{
          'tmdb_id': 200,
          'title': 'Breaking Bad',
          'original_title': null,
          'poster_url': null,
          'backdrop_url': null,
          'overview': null,
          'genres': null,
          'first_air_year': 2008,
          'total_seasons': 5,
          'total_episodes': 62,
          'rating': 9.5,
          'status': 'Ended',
          'external_url': null,
          'cached_at': 1000,
        };
        when(
          () => mockDb.query(
            'tv_shows_cache',
            where: 'tmdb_id = ?',
            whereArgs: <Object?>[200],
            limit: 1,
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[row]);

        final TvShow? result = await dao.getTvShowByTmdbId(200);

        expect(result, isNotNull);
        expect(result!.tmdbId, 200);
        expect(result.title, 'Breaking Bad');
      });
    });

    group('upsertTvShow', () {
      test('inserts with replace', () async {
        const TvShow show = TvShow(tmdbId: 1, title: 'Test');
        when(
          () => mockDb.insert(
            'tv_shows_cache',
            any(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          ),
        ).thenAnswer((_) async => 1);

        await dao.upsertTvShow(show);

        verify(
          () => mockDb.insert(
            'tv_shows_cache',
            show.toDb(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          ),
        ).called(1);
      });
    });

    group('upsertTvShows', () {
      test('skips when list is empty', () async {
        await dao.upsertTvShows(<TvShow>[]);

        verifyNever(() => mockTxn.batch());
      });

      test('uses transaction and batch', () async {
        stubTransaction();

        await dao.upsertTvShows(const <TvShow>[
          TvShow(tmdbId: 1, title: 'S1'),
          TvShow(tmdbId: 2, title: 'S2'),
        ]);

        verify(
          () => mockBatch.insert(
            'tv_shows_cache',
            any(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          ),
        ).called(2);
      });
    });

    group('getTvShowsByTmdbIds', () {
      test('returns empty list for empty ids', () async {
        expect(await dao.getTvShowsByTmdbIds(<int>[]), isEmpty);
      });

      test('queries with IN clause', () async {
        when(
          () => mockDb.query(
            'tv_shows_cache',
            where: 'tmdb_id IN (?,?)',
            whereArgs: <Object?>[100, 200],
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        final List<TvShow> result =
            await dao.getTvShowsByTmdbIds(<int>[100, 200]);

        expect(result, isEmpty);
      });
    });

    group('clearTvShows', () {
      test('deletes all tv shows', () async {
        when(() => mockDb.delete('tv_shows_cache'))
            .thenAnswer((_) async => 2);

        await dao.clearTvShows();

        verify(() => mockDb.delete('tv_shows_cache')).called(1);
      });
    });

    // ==================== TV Seasons ====================

    group('getTvSeasonsByShowId', () {
      test('returns seasons ordered by number', () async {
        when(
          () => mockDb.query(
            'tv_seasons_cache',
            where: 'tmdb_show_id = ?',
            whereArgs: <Object?>[200],
            orderBy: 'season_number ASC',
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{
              'tmdb_show_id': 200,
              'season_number': 1,
              'name': 'Season 1',
              'episode_count': 10,
              'poster_url': null,
              'air_date': null,
            },
          ],
        );

        final List<TvSeason> result = await dao.getTvSeasonsByShowId(200);

        expect(result.length, 1);
        expect(result.first.seasonNumber, 1);
      });
    });

    group('upsertTvSeasons', () {
      test('skips when list is empty', () async {
        await dao.upsertTvSeasons(<TvSeason>[]);

        verifyNever(() => mockTxn.batch());
      });

      test('uses transaction and batch', () async {
        stubTransaction();

        await dao.upsertTvSeasons(const <TvSeason>[
          TvSeason(tmdbShowId: 200, seasonNumber: 1),
          TvSeason(tmdbShowId: 200, seasonNumber: 2),
        ]);

        verify(
          () => mockBatch.insert(
            'tv_seasons_cache',
            any(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          ),
        ).called(2);
      });
    });

    group('clearTvSeasons', () {
      test('deletes all seasons', () async {
        when(() => mockDb.delete('tv_seasons_cache'))
            .thenAnswer((_) async => 3);

        await dao.clearTvSeasons();

        verify(() => mockDb.delete('tv_seasons_cache')).called(1);
      });
    });

    // ==================== TV Episodes ====================

    group('getEpisodesByShowId', () {
      test('returns episodes ordered by season and number', () async {
        when(
          () => mockDb.query(
            'tv_episodes_cache',
            where: 'tmdb_show_id = ?',
            whereArgs: <Object?>[200],
            orderBy: 'season_number ASC, episode_number ASC',
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{
              'tmdb_show_id': 200,
              'season_number': 1,
              'episode_number': 1,
              'name': 'Pilot',
              'overview': null,
              'air_date': null,
              'still_url': null,
              'runtime': null,
            },
          ],
        );

        final List<TvEpisode> result = await dao.getEpisodesByShowId(200);

        expect(result.length, 1);
        expect(result.first.name, 'Pilot');
      });
    });

    group('getEpisodesByShowAndSeason', () {
      test('returns episodes for specific season', () async {
        when(
          () => mockDb.query(
            'tv_episodes_cache',
            where: 'tmdb_show_id = ? AND season_number = ?',
            whereArgs: <Object?>[200, 2],
            orderBy: 'episode_number ASC',
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        final List<TvEpisode> result =
            await dao.getEpisodesByShowAndSeason(200, 2);

        expect(result, isEmpty);
      });
    });

    group('upsertEpisodes', () {
      test('skips when list is empty', () async {
        await dao.upsertEpisodes(<TvEpisode>[]);

        verifyNever(() => mockTxn.batch());
      });

      test('uses transaction and batch', () async {
        stubTransaction();

        await dao.upsertEpisodes(const <TvEpisode>[
          TvEpisode(
            tmdbShowId: 200,
            seasonNumber: 1,
            episodeNumber: 1,
            name: 'Ep1',
          ),
        ]);

        verify(
          () => mockBatch.insert(
            'tv_episodes_cache',
            any(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          ),
        ).called(1);
      });
    });

    group('clearEpisodesByShow', () {
      test('deletes episodes for show', () async {
        when(
          () => mockDb.delete(
            'tv_episodes_cache',
            where: 'tmdb_show_id = ?',
            whereArgs: <Object?>[200],
          ),
        ).thenAnswer((_) async => 10);

        await dao.clearEpisodesByShow(200);

        verify(
          () => mockDb.delete(
            'tv_episodes_cache',
            where: 'tmdb_show_id = ?',
            whereArgs: <Object?>[200],
          ),
        ).called(1);
      });
    });

    // ==================== Watched Episodes ====================

    group('getWatchedEpisodes', () {
      test('returns map of watched episodes', () async {
        when(
          () => mockDb.query(
            'watched_episodes',
            columns: <String>['season_number', 'episode_number', 'watched_at'],
            where: 'collection_id = ? AND show_id = ?',
            whereArgs: <Object?>[1, 200],
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{
              'season_number': 1,
              'episode_number': 1,
              'watched_at': 1705320000000,
            },
            <String, dynamic>{
              'season_number': 1,
              'episode_number': 2,
              'watched_at': null,
            },
          ],
        );

        final Map<(int, int), DateTime?> result =
            await dao.getWatchedEpisodes(1, 200);

        expect(result.length, 2);
        expect(result[(1, 1)], isNotNull);
        expect(result[(1, 2)], isNull);
      });
    });

    group('markEpisodeWatched', () {
      test('inserts with ignore conflict', () async {
        when(
          () => mockDb.insert(
            'watched_episodes',
            any(),
            conflictAlgorithm: ConflictAlgorithm.ignore,
          ),
        ).thenAnswer((_) async => 1);

        await dao.markEpisodeWatched(1, 200, 1, 3);

        final VerificationResult captured = verify(
          () => mockDb.insert(
            'watched_episodes',
            captureAny(),
            conflictAlgorithm: ConflictAlgorithm.ignore,
          ),
        );
        captured.called(1);

        final Map<String, dynamic> data =
            captured.captured.first as Map<String, dynamic>;
        expect(data['collection_id'], 1);
        expect(data['show_id'], 200);
        expect(data['season_number'], 1);
        expect(data['episode_number'], 3);
        expect(data['watched_at'], isA<int>());
      });
    });

    group('markEpisodeUnwatched', () {
      test('deletes specific episode record', () async {
        when(
          () => mockDb.delete(
            'watched_episodes',
            where: 'collection_id = ? AND show_id = ? '
                'AND season_number = ? AND episode_number = ?',
            whereArgs: <Object?>[1, 200, 1, 3],
          ),
        ).thenAnswer((_) async => 1);

        await dao.markEpisodeUnwatched(1, 200, 1, 3);

        verify(
          () => mockDb.delete(
            'watched_episodes',
            where: 'collection_id = ? AND show_id = ? '
                'AND season_number = ? AND episode_number = ?',
            whereArgs: <Object?>[1, 200, 1, 3],
          ),
        ).called(1);
      });
    });

    group('getWatchedEpisodeCount', () {
      test('returns count for show in collection', () async {
        when(
          () => mockDb.rawQuery(
            'SELECT COUNT(*) as cnt FROM watched_episodes '
            'WHERE collection_id = ? AND show_id = ?',
            <Object?>[1, 200],
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'cnt': 15},
          ],
        );

        expect(await dao.getWatchedEpisodeCount(1, 200), 15);
      });
    });

    group('markSeasonWatched', () {
      test('skips when episode list is empty', () async {
        await dao.markSeasonWatched(1, 200, 1, <int>[]);

        verifyNever(() => mockTxn.batch());
      });

      test('batch inserts episodes for season', () async {
        stubTransaction();

        await dao.markSeasonWatched(1, 200, 1, <int>[1, 2, 3]);

        verify(
          () => mockBatch.insert(
            'watched_episodes',
            any(),
            conflictAlgorithm: ConflictAlgorithm.ignore,
          ),
        ).called(3);
      });
    });

    group('unmarkSeasonWatched', () {
      test('deletes all episodes for season', () async {
        when(
          () => mockDb.delete(
            'watched_episodes',
            where: 'collection_id = ? AND show_id = ? AND season_number = ?',
            whereArgs: <Object?>[1, 200, 2],
          ),
        ).thenAnswer((_) async => 5);

        await dao.unmarkSeasonWatched(1, 200, 2);

        verify(
          () => mockDb.delete(
            'watched_episodes',
            where: 'collection_id = ? AND show_id = ? AND season_number = ?',
            whereArgs: <Object?>[1, 200, 2],
          ),
        ).called(1);
      });
    });
  });
}
