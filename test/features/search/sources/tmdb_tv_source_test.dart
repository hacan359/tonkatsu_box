import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/search/filters/tmdb_genre_filter.dart';
import 'package:xerabora/features/search/filters/year_filter.dart';
import 'package:xerabora/features/search/models/search_source.dart';
import 'package:xerabora/features/search/sources/tmdb_tv_source.dart';

void main() {
  group('TmdbTvSource', () {
    late TmdbTvSource source;

    setUp(() {
      source = TmdbTvSource();
    });

    group('properties', () {
      test('id is "tv"', () {
        expect(source.id, 'tv');
      });

      test('icon is tv_outlined', () {
        expect(source.icon, Icons.tv_outlined);
      });

      test('supportsBrowse is true', () {
        expect(source.supportsBrowse, isTrue);
      });
    });

    group('filters', () {
      test('has 2 filters', () {
        expect(source.filters, hasLength(2));
      });

      test('first filter is TmdbGenreFilter with type tv', () {
        final SearchFilter first = source.filters[0];
        expect(first, isA<TmdbGenreFilter>());
        expect((first as TmdbGenreFilter).type, 'tv');
      });

      test('second filter is YearFilter', () {
        expect(source.filters[1], isA<YearFilter>());
      });
    });

    group('sortOptions', () {
      test('has 3 sort options', () {
        expect(source.sortOptions, hasLength(3));
      });

      test('first option is Popular', () {
        final BrowseSortOption first = source.sortOptions[0];
        expect(first.id, 'popular');
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
        expect(third.apiValue, 'first_air_date.desc');
      });
    });

    group('defaultSort', () {
      test('returns first sort option (Popular)', () {
        expect(source.defaultSort.id, 'popular');
      });
    });
  });
}
