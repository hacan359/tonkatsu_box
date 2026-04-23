import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/features/search/filters/manga_format_filter.dart';
import 'package:xerabora/features/search/models/search_source.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('MangaFormatFilter', () {
    late MangaFormatFilter filter;
    late MockS mockL;

    setUp(() {
      filter = MangaFormatFilter();
      mockL = MockS();
      when(() => mockL.mangaFormatManga).thenReturn('Manga');
      when(() => mockL.mangaFormatOneShot).thenReturn('One-shot');
      when(() => mockL.mangaFormatNovel).thenReturn('Novel');
    });

    test('key is "format"', () {
      expect(filter.key, 'format');
    });

    test('cacheKey defaults to key', () {
      expect(filter.cacheKey, 'format');
    });

    test('allOption has id "any" and null value', () {
      final FilterOption all = filter.allOption;

      expect(all.id, 'any');
      expect(all.label, 'All');
      expect(all.value, isNull);
    });

    test('options returns only valid AniList MediaFormat values', () async {
      final MockWidgetRef ref = MockWidgetRef();
      final List<FilterOption> options = await filter.options(ref, mockL);

      expect(
        options.map((FilterOption o) => o.value).toList(),
        <String>['MANGA', 'NOVEL', 'ONE_SHOT'],
      );
    });

    test('first option is Manga', () async {
      final MockWidgetRef ref = MockWidgetRef();
      final List<FilterOption> options = await filter.options(ref, mockL);

      expect(options[0].id, 'manga');
      expect(options[0].value, 'MANGA');
    });

    test('options returns same values on multiple calls', () async {
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
