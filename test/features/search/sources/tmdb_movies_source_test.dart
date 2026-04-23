import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/search/filters/min_rating_filter.dart';
import 'package:xerabora/features/search/filters/min_votes_filter.dart';
import 'package:xerabora/features/search/filters/tmdb_genre_filter.dart';
import 'package:xerabora/features/search/filters/tmdb_language_filter.dart';
import 'package:xerabora/features/search/filters/year_filter.dart';
import 'package:xerabora/features/search/models/search_source.dart';
import 'package:xerabora/features/search/sources/tmdb_movies_source.dart';

void main() {
  group('TmdbMoviesSource', () {
    late TmdbMoviesSource source;

    setUp(() {
      source = TmdbMoviesSource();
    });

    group('properties', () {
      test('id is "movies"', () {
        expect(source.id, 'movies');
      });

      test('icon is movie_outlined', () {
        expect(source.icon, Icons.movie_outlined);
      });

      test('supportsBrowse is true', () {
        expect(source.supportsBrowse, isTrue);
      });
    });

    group('filters', () {
      test('exposes genre (multi), year, min rating, min votes, language', () {
        expect(source.filters, hasLength(5));
      });

      test('first filter is TmdbGenreFilter with type movie (multi-select)',
          () {
        final SearchFilter first = source.filters[0];
        expect(first, isA<TmdbGenreFilter>());
        expect((first as TmdbGenreFilter).type, 'movie');
        expect(first.multiSelect, isTrue);
      });

      test('second filter is YearFilter', () {
        expect(source.filters[1], isA<YearFilter>());
      });

      test('third filter is MinRatingFilter', () {
        expect(source.filters[2], isA<MinRatingFilter>());
      });

      test('fourth filter is MinVotesFilter', () {
        expect(source.filters[3], isA<MinVotesFilter>());
      });

      test('fifth filter is TmdbLanguageFilter', () {
        expect(source.filters[4], isA<TmdbLanguageFilter>());
      });
    });

    group('sortOptions', () {
      test('has 3 sort options', () {
        expect(source.sortOptions, hasLength(3));
      });

      test('first option is Popular', () {
        final BrowseSortOption first = source.sortOptions[0];
        expect(first.id, 'popular');
        // label is now a method: label(S l) — tested via widget tests
        expect(first.apiValue, 'popularity.desc');
      });

      test('second option is Top Rated', () {
        final BrowseSortOption second = source.sortOptions[1];
        expect(second.id, 'top_rated');
        expect(second.apiValue, 'vote_average.desc');
      });

      test('third option is Newest', () {
        final BrowseSortOption third = source.sortOptions[2];
        expect(third.id, 'newest');
        expect(third.apiValue, 'primary_release_date.desc');
      });
    });

    group('defaultSort', () {
      test('returns first sort option (Popular)', () {
        expect(source.defaultSort.id, 'popular');
      });
    });

    group('buildDiscoverFeed', () {
      test('returns null', () {
        // Can't test with real context, but method should exist
        expect(source.buildDiscoverFeed, isNotNull);
      });
    });
  });
}
