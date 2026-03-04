import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/search/filters/anilist_genre_filter.dart';
import 'package:xerabora/features/search/models/search_source.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('AniListGenreFilter', () {
    late AniListGenreFilter filter;

    setUp(() {
      filter = AniListGenreFilter();
    });

    test('key is "genre"', () {
      expect(filter.key, 'genre');
    });

    test('cacheKey is "genre_anilist"', () {
      expect(filter.cacheKey, 'genre_anilist');
    });

    test('allOption has id "any" and null value', () {
      final FilterOption all = filter.allOption;

      expect(all.id, 'any');
      expect(all.label, 'All');
      expect(all.value, isNull);
    });

    test('options returns 18 genres', () async {
      final MockWidgetRef ref = MockWidgetRef();
      final MockS mockL = MockS();
      final List<FilterOption> options = await filter.options(ref, mockL);

      expect(options, hasLength(18));
    });

    test('first option is Action', () async {
      final MockWidgetRef ref = MockWidgetRef();
      final MockS mockL = MockS();
      final List<FilterOption> options = await filter.options(ref, mockL);

      expect(options[0].id, 'action');
      expect(options[0].label, 'Action');
      expect(options[0].value, 'Action');
    });

    test('option id is lowercase with underscores', () async {
      final MockWidgetRef ref = MockWidgetRef();
      final MockS mockL = MockS();
      final List<FilterOption> options = await filter.options(ref, mockL);

      // "Mahou Shoujo" => "mahou_shoujo"
      final FilterOption mahouShoujo =
          options.firstWhere((FilterOption o) => o.label == 'Mahou Shoujo');
      expect(mahouShoujo.id, 'mahou_shoujo');

      // "Sci-Fi" => "sci-fi"
      final FilterOption sciFi =
          options.firstWhere((FilterOption o) => o.label == 'Sci-Fi');
      expect(sciFi.id, 'sci-fi');

      // "Slice of Life" => "slice_of_life"
      final FilterOption sliceOfLife =
          options.firstWhere((FilterOption o) => o.label == 'Slice of Life');
      expect(sliceOfLife.id, 'slice_of_life');
    });

    test('option value matches label', () async {
      final MockWidgetRef ref = MockWidgetRef();
      final MockS mockL = MockS();
      final List<FilterOption> options = await filter.options(ref, mockL);

      for (final FilterOption option in options) {
        expect(option.value, option.label);
      }
    });

    test('options returns same length on multiple calls', () async {
      final MockWidgetRef ref = MockWidgetRef();
      final MockS mockL = MockS();
      final List<FilterOption> first = await filter.options(ref, mockL);
      final List<FilterOption> second = await filter.options(ref, mockL);

      expect(first.length, second.length);
      for (int i = 0; i < first.length; i++) {
        expect(first[i].id, second[i].id);
      }
    });
  });
}
