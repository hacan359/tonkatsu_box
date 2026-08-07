import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/search/models/search_source.dart';
import 'package:tonkatsu_box/features/search/sources/comicvine_source.dart';
import 'package:tonkatsu_box/shared/theme/app_assets.dart';

void main() {
  group('ComicVineSource', () {
    late ComicVineSource source;

    setUp(() {
      source = ComicVineSource();
    });

    group('properties', () {
      test('id is "comicvine"', () {
        expect(source.id, 'comicvine');
      });

      test('outputs MediaType.book', () {
        expect(source.outputMediaType, MediaType.book);
      });

      test('uses the ComicVine brand asset', () {
        expect(source.iconAsset, AppAssets.iconComicVineColor);
      });

      test('requires a query (no filter-only browse)', () {
        expect(source.supportsBrowse, isFalse);
        expect(source.filters, isEmpty);
      });

      test('sort stays active while a query is present', () {
        // The /volumes path paginates and reorders mid-query.
        expect(source.supportsSortDuringSearch, isTrue);
      });
    });

    group('sort options', () {
      test('defaults to relevance (the /search path)', () {
        expect(source.defaultSort.id, 'relevance');
        expect(source.defaultSort.apiValue, '');
      });

      test('exposes only the API-honoured /volumes orders', () {
        final Map<String, String> byId = <String, String>{
          for (final BrowseSortOption o in source.sortOptions)
            o.id: o.apiValue,
        };
        expect(byId, <String, String>{
          'relevance': '',
          'name_asc': 'name:asc',
          'name_desc': 'name:desc',
          'recently_updated': 'date_last_updated:desc',
          'recently_added': 'date_added:desc',
        });
      });
    });

    group('icons', () {
      test('tab icon is set', () {
        expect(source.icon, isA<IconData>());
      });
    });
  });
}
