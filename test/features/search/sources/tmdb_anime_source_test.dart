import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/search/filters/anime_type_filter.dart';
import 'package:xerabora/features/search/filters/tmdb_genre_filter.dart';
import 'package:xerabora/features/search/filters/year_filter.dart';
import 'package:xerabora/features/search/models/search_source.dart';
import 'package:xerabora/features/search/sources/tmdb_anime_source.dart';

void main() {
  group('TmdbAnimeSource', () {
    late TmdbAnimeSource source;

    setUp(() {
      source = TmdbAnimeSource();
    });

    group('properties', () {
      test('id is "anime"', () {
        expect(source.id, 'anime');
      });

      test('icon is animation_outlined', () {
        expect(source.icon, Icons.animation_outlined);
      });

      test('supportsBrowse is true', () {
        expect(source.supportsBrowse, isTrue);
      });
    });

    group('filters', () {
      test('has 3 filters', () {
        expect(source.filters, hasLength(3));
      });

      test('first filter is TmdbGenreFilter with type tv', () {
        final SearchFilter first = source.filters[0];
        expect(first, isA<TmdbGenreFilter>());
        expect((first as TmdbGenreFilter).type, 'tv');
      });

      test('second filter is YearFilter', () {
        expect(source.filters[1], isA<YearFilter>());
      });

      test('third filter is AnimeTypeFilter', () {
        expect(source.filters[2], isA<AnimeTypeFilter>());
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
