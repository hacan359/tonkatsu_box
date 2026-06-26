import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/import/rate_limited_retry.dart';
import 'package:tonkatsu_box/core/import/tmdb_matcher.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/models/movie.dart';
import 'package:tonkatsu_box/shared/models/tv_show.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late MockTmdbApi mockTmdb;
  late TmdbMatcher matcher;

  setUpAll(registerAllFallbacks);

  setUp(() {
    mockTmdb = MockTmdbApi();
    // Zero throttle/backoff so the matcher doesn't sleep during tests.
    matcher = TmdbMatcher(
      mockTmdb,
      retry: const RateLimitedRetry(baseDelay: Duration.zero),
      throttle: Duration.zero,
    );
  });

  group('TmdbMatcher', () {
    group('matchMovie', () {
      test('drops the server year filter, still verifies the result year',
          () async {
        // TMDB's `year=` filter is unreliable and can miss a correctly-dated
        // film. The matcher widens to a no-year search, but only accepts a
        // result whose actual release year matches the requested one.
        when(() => mockTmdb.searchMovies(any(), year: 1992))
            .thenAnswer((_) async => <Movie>[]);
        when(() => mockTmdb.searchMovies(any(), year: null)).thenAnswer(
            (_) async => <Movie>[createTestMovie(tmdbId: 88, releaseYear: 1992)]);

        final TmdbMatch? match =
            await matcher.matchMovie(primaryQuery: 'Naked Killer', year: 1992);

        expect(match, isNotNull);
        expect(match!.tmdbId, 88);
        expect(match.mediaType, MediaType.movie);
      });

      test('does not accept a wrong-year result from the no-year search',
          () async {
        // Regression guard: a popular same-title film of a different year must
        // not be substituted when the requested year has no match.
        when(() => mockTmdb.searchMovies(any(), year: 1997))
            .thenAnswer((_) async => <Movie>[]);
        when(() => mockTmdb.searchMovies(any(), year: null)).thenAnswer(
            (_) async => <Movie>[createTestMovie(tmdbId: 99, releaseYear: 2026)]);

        final TmdbMatch? match =
            await matcher.matchMovie(primaryQuery: 'The Odyssey', year: 1997);

        expect(match, isNull);
      });

      test('prefers the result whose year matches the requested year',
          () async {
        when(() => mockTmdb.searchMovies(any(), year: any(named: 'year')))
            .thenAnswer((_) async => <Movie>[
                  createTestMovie(tmdbId: 1, releaseYear: 2000),
                  createTestMovie(tmdbId: 2, releaseYear: 1999),
                ]);

        final TmdbMatch? match =
            await matcher.matchMovie(primaryQuery: 'X', year: 1999);

        expect(match!.tmdbId, 2);
      });

      test('classifies animation by genre', () async {
        when(() => mockTmdb.searchMovies(any(), year: any(named: 'year')))
            .thenAnswer((_) async => <Movie>[
                  createTestMovie(tmdbId: 9, genres: <String>['Animation']),
                ]);

        final TmdbMatch? match = await matcher.matchMovie(primaryQuery: 'X');

        expect(match!.mediaType, MediaType.animation);
        expect(match.platformId, AnimationSource.movie);
      });

      test('animationHint forces animation without an animation genre',
          () async {
        when(() => mockTmdb.searchMovies(any(), year: any(named: 'year')))
            .thenAnswer((_) async => <Movie>[
                  createTestMovie(tmdbId: 9, genres: <String>['Drama']),
                ]);

        final TmdbMatch? match =
            await matcher.matchMovie(primaryQuery: 'X', animationHint: true);

        expect(match!.mediaType, MediaType.animation);
      });

      test('returns null when no strategy yields a result', () async {
        when(() => mockTmdb.searchMovies(any(), year: any(named: 'year')))
            .thenAnswer((_) async => <Movie>[]);

        final TmdbMatch? match = await matcher.matchMovie(
          primaryQuery: 'Nope',
          fallbackQuery: 'Also nope',
          year: 2099,
        );

        expect(match, isNull);
      });
    });

    group('matchTvShow', () {
      test('resolves on the TV endpoint with the tv media type', () async {
        when(() => mockTmdb.searchTvShows(any(),
                firstAirDateYear: any(named: 'firstAirDateYear')))
            .thenAnswer((_) async => <TvShow>[createTestTvShow(tmdbId: 1396)]);

        final TmdbMatch? match = await matcher.matchTvShow(primaryQuery: 'BB');

        expect(match!.tmdbId, 1396);
        expect(match.mediaType, MediaType.tvShow);
      });
    });

    group('isAnimationByGenres', () {
      test('true for animation name or genre id 16', () {
        expect(TmdbMatcher.isAnimationByGenres(<String>['Animation']), isTrue);
        expect(TmdbMatcher.isAnimationByGenres(<String>['16']), isTrue);
      });

      test('false for other, empty, or null genres', () {
        expect(TmdbMatcher.isAnimationByGenres(<String>['Drama']), isFalse);
        expect(TmdbMatcher.isAnimationByGenres(<String>[]), isFalse);
        expect(TmdbMatcher.isAnimationByGenres(null), isFalse);
      });
    });
  });
}
