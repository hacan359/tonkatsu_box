import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/search/models/search_source.dart';
import 'package:tonkatsu_box/features/search/sources/google_books_source.dart';
import 'package:tonkatsu_box/shared/theme/app_assets.dart';

void main() {
  group('GoogleBooksSource', () {
    late GoogleBooksSource source;

    setUp(() {
      source = GoogleBooksSource();
    });

    group('properties', () {
      test('id is "googlebooks"', () {
        expect(source.id, 'googlebooks');
      });

      test('outputs MediaType.book', () {
        expect(source.outputMediaType, MediaType.book);
      });

      test('uses the Google Books brand asset', () {
        expect(source.iconAsset, AppAssets.iconGoogleBooksColor);
      });

      test('requires a query but exposes print-type + language filters', () {
        expect(source.supportsBrowse, isFalse);
        expect(source.filters, hasLength(2));
        expect(
          source.filters.map((SearchFilter f) => f.key),
          containsAll(<String>['printType', 'language']),
        );
      });

      test('sort stays active while a query is present', () {
        expect(source.supportsSortDuringSearch, isTrue);
      });
    });

    group('sort options', () {
      test('defaults to relevance', () {
        expect(source.defaultSort.id, 'relevance');
      });

      test('exposes relevance + newest', () {
        final Map<String, String> byId = <String, String>{
          for (final BrowseSortOption o in source.sortOptions) o.id: o.apiValue,
        };
        expect(byId, <String, String>{
          'relevance': 'relevance',
          'newest': 'newest',
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
