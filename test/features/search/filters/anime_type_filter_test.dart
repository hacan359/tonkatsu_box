import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/features/search/filters/anime_type_filter.dart';
import 'package:xerabora/features/search/models/search_source.dart';
import 'package:xerabora/l10n/app_localizations.dart';

class MockWidgetRef extends Mock implements WidgetRef {}

class MockS extends Mock implements S {}

void main() {
  group('AnimeTypeFilter', () {
    late AnimeTypeFilter filter;
    late MockS mockL;

    setUp(() {
      filter = AnimeTypeFilter();
      mockL = MockS();
      when(() => mockL.browseAnimeTypeSeries).thenReturn('Series');
      when(() => mockL.browseAnimeTypeMovies).thenReturn('Movies');
    });

    test('key is "animeType"', () {
      expect(filter.key, 'animeType');
    });

    test('allOption has id "all" and null value', () {
      final FilterOption all = filter.allOption;

      expect(all.id, 'all');
      expect(all.label, 'All');
      expect(all.value, isNull);
    });

    test('options contains Series and Movies', () async {
      final MockWidgetRef ref = MockWidgetRef();
      final List<FilterOption> options = await filter.options(ref, mockL);

      expect(options, hasLength(2));
    });

    test('first option is Series', () async {
      final MockWidgetRef ref = MockWidgetRef();
      final List<FilterOption> options = await filter.options(ref, mockL);

      expect(options[0].id, 'series');
      expect(options[0].label, 'Series');
      expect(options[0].value, 'series');
    });

    test('second option is Movies', () async {
      final MockWidgetRef ref = MockWidgetRef();
      final List<FilterOption> options = await filter.options(ref, mockL);

      expect(options[1].id, 'movies');
      expect(options[1].label, 'Movies');
      expect(options[1].value, 'movies');
    });

    test('options returns same length on multiple calls', () async {
      final MockWidgetRef ref = MockWidgetRef();
      final List<FilterOption> first = await filter.options(ref, mockL);
      final List<FilterOption> second = await filter.options(ref, mockL);

      expect(first.length, second.length);
      for (int i = 0; i < first.length; i++) {
        expect(first[i].id, second[i].id);
      }
    });
  });
}
