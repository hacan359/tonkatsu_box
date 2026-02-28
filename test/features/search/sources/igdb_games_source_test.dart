import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/search/filters/igdb_genre_filter.dart';
import 'package:xerabora/features/search/filters/igdb_platform_filter.dart';
import 'package:xerabora/features/search/filters/year_filter.dart';
import 'package:xerabora/features/search/models/search_source.dart';
import 'package:xerabora/features/search/sources/igdb_games_source.dart';

void main() {
  group('IgdbGamesSource', () {
    late IgdbGamesSource source;

    setUp(() {
      source = IgdbGamesSource();
    });

    group('properties', () {
      test('id is "games"', () {
        expect(source.id, 'games');
      });

      test('icon is videogame_asset_outlined', () {
        expect(source.icon, Icons.videogame_asset_outlined);
      });

      test('supportsBrowse is true', () {
        expect(source.supportsBrowse, isTrue);
      });
    });

    group('filters', () {
      test('has 3 filters', () {
        expect(source.filters, hasLength(3));
      });

      test('first filter is IgdbGenreFilter', () {
        expect(source.filters[0], isA<IgdbGenreFilter>());
      });

      test('second filter is IgdbPlatformFilter', () {
        expect(source.filters[1], isA<IgdbPlatformFilter>());
      });

      test('third filter is YearFilter', () {
        expect(source.filters[2], isA<YearFilter>());
      });
    });

    group('sortOptions', () {
      test('has 3 sort options', () {
        expect(source.sortOptions, hasLength(3));
      });

      test('first option is Top Rated', () {
        final BrowseSortOption first = source.sortOptions[0];
        expect(first.id, 'rating');
        // label is now a method: label(S l) — tested via widget tests
        expect(first.apiValue, 'rating desc');
      });

      test('second option is Newest', () {
        final BrowseSortOption second = source.sortOptions[1];
        expect(second.id, 'newest');
        expect(second.apiValue, 'first_release_date desc');
      });

      test('third option is Popular', () {
        final BrowseSortOption third = source.sortOptions[2];
        expect(third.id, 'popular');
        expect(third.apiValue, 'total_rating_count desc');
      });
    });

    group('defaultSort', () {
      test('returns first sort option (Top Rated)', () {
        expect(source.defaultSort.id, 'rating');
      });
    });
  });
}
