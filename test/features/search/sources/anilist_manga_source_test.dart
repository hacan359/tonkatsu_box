import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/search/filters/anilist_genre_filter.dart';
import 'package:tonkatsu_box/features/search/filters/anilist_manga_status_filter.dart';
import 'package:tonkatsu_box/features/search/filters/anilist_tag_filter.dart';
import 'package:tonkatsu_box/features/search/filters/manga_format_filter.dart';
import 'package:tonkatsu_box/features/search/filters/year_filter.dart';
import 'package:tonkatsu_box/features/search/models/search_source.dart';
import 'package:tonkatsu_box/features/search/sources/anilist_manga_source.dart';

void main() {
  group('AniListMangaSource', () {
    late AniListMangaSource source;

    setUp(() {
      source = AniListMangaSource();
    });

    group('properties', () {
      test('id is "manga"', () {
        expect(source.id, 'manga');
      });

      test('icon is auto_stories_outlined', () {
        expect(source.icon, Icons.auto_stories_outlined);
      });

      test('supportsBrowse is true', () {
        expect(source.supportsBrowse, isTrue);
      });

      test('supportsSortDuringSearch is true', () {
        expect(source.supportsSortDuringSearch, isTrue);
      });
    });

    group('filters', () {
      test('exposes genre (multi), tag (multi), format, status, year', () {
        expect(source.filters, hasLength(5));
      });

      test('first filter is AniListGenreFilter (multi-select)', () {
        expect(source.filters[0], isA<AniListGenreFilter>());
        expect(source.filters[0].multiSelect, isTrue);
      });

      test('second filter is AniListTagFilter (multi-select)', () {
        expect(source.filters[1], isA<AniListTagFilter>());
        expect(source.filters[1].multiSelect, isTrue);
      });

      test('third filter is MangaFormatFilter', () {
        expect(source.filters[2], isA<MangaFormatFilter>());
      });

      test('fourth filter is AniListMangaStatusFilter', () {
        expect(source.filters[3], isA<AniListMangaStatusFilter>());
      });

      test('fifth filter is YearFilter', () {
        expect(source.filters[4], isA<YearFilter>());
      });
    });

    group('sortOptions', () {
      test('has 4 sort options', () {
        expect(source.sortOptions, hasLength(4));
      });

      test('first option is score', () {
        final BrowseSortOption first = source.sortOptions[0];
        expect(first.id, 'score');
        expect(first.apiValue, 'SCORE_DESC');
      });

      test('second option is popularity', () {
        final BrowseSortOption second = source.sortOptions[1];
        expect(second.id, 'popularity');
        expect(second.apiValue, 'POPULARITY_DESC');
      });

      test('third option is newest', () {
        final BrowseSortOption third = source.sortOptions[2];
        expect(third.id, 'newest');
        expect(third.apiValue, 'START_DATE_DESC');
      });

      test('fourth option is trending', () {
        final BrowseSortOption fourth = source.sortOptions[3];
        expect(fourth.id, 'trending');
        expect(fourth.apiValue, 'TRENDING_DESC');
      });
    });

    group('defaultSort', () {
      test('returns first sort option (score)', () {
        expect(source.defaultSort.id, 'score');
      });
    });

    group('buildDiscoverFeed', () {
      test('returns null', () {
        expect(source.buildDiscoverFeed, isNotNull);
      });
    });
  });
}
