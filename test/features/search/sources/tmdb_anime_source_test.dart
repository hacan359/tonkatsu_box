import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/search/filters/anime_type_filter.dart';
import 'package:xerabora/features/search/filters/min_rating_filter.dart';
import 'package:xerabora/features/search/filters/min_votes_filter.dart';
import 'package:xerabora/features/search/filters/tmdb_genre_filter.dart';
import 'package:xerabora/features/search/filters/tmdb_language_filter.dart';
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
      test(
          'exposes genre (multi), year, anime type, min rating, min votes, language',
          () {
        expect(source.filters, hasLength(6));
      });

      test('first filter is TmdbGenreFilter with type tv (multi-select)', () {
        final SearchFilter first = source.filters[0];
        expect(first, isA<TmdbGenreFilter>());
        expect((first as TmdbGenreFilter).type, 'tv');
        expect(first.multiSelect, isTrue);
      });

      test('second filter is YearFilter', () {
        expect(source.filters[1], isA<YearFilter>());
      });

      test('third filter is AnimeTypeFilter', () {
        expect(source.filters[2], isA<AnimeTypeFilter>());
      });

      test('fourth filter is MinRatingFilter', () {
        expect(source.filters[3], isA<MinRatingFilter>());
      });

      test('fifth filter is MinVotesFilter', () {
        expect(source.filters[4], isA<MinVotesFilter>());
      });

      test('sixth filter is TmdbLanguageFilter', () {
        expect(source.filters[5], isA<TmdbLanguageFilter>());
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
