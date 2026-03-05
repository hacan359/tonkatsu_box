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
      when(() => mockL.mangaFormatManhwa).thenReturn('Manhwa');
      when(() => mockL.mangaFormatManhua).thenReturn('Manhua');
      when(() => mockL.mangaFormatOneShot).thenReturn('One-shot');
      when(() => mockL.mangaFormatNovel).thenReturn('Novel');
      when(() => mockL.mangaFormatLightNovel).thenReturn('Light Novel');
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

    test('options returns 6 formats', () async {
      final MockWidgetRef ref = MockWidgetRef();
      final List<FilterOption> options = await filter.options(ref, mockL);

      expect(options, hasLength(6));
    });

    test('first option is Manga', () async {
      final MockWidgetRef ref = MockWidgetRef();
      final List<FilterOption> options = await filter.options(ref, mockL);

      expect(options[0].id, 'manga');
      expect(options[0].label, 'Manga');
      expect(options[0].value, 'MANGA');
    });

    test('second option is Manhwa', () async {
      final MockWidgetRef ref = MockWidgetRef();
      final List<FilterOption> options = await filter.options(ref, mockL);

      expect(options[1].id, 'manhwa');
      expect(options[1].label, 'Manhwa');
      expect(options[1].value, 'MANHWA');
    });

    test('third option is Manhua', () async {
      final MockWidgetRef ref = MockWidgetRef();
      final List<FilterOption> options = await filter.options(ref, mockL);

      expect(options[2].id, 'manhua');
      expect(options[2].label, 'Manhua');
      expect(options[2].value, 'MANHUA');
    });

    test('fourth option is One-shot', () async {
      final MockWidgetRef ref = MockWidgetRef();
      final List<FilterOption> options = await filter.options(ref, mockL);

      expect(options[3].id, 'one_shot');
      expect(options[3].label, 'One-shot');
      expect(options[3].value, 'ONE_SHOT');
    });

    test('fifth option is Novel', () async {
      final MockWidgetRef ref = MockWidgetRef();
      final List<FilterOption> options = await filter.options(ref, mockL);

      expect(options[4].id, 'novel');
      expect(options[4].label, 'Novel');
      expect(options[4].value, 'NOVEL');
    });

    test('sixth option is Light Novel', () async {
      final MockWidgetRef ref = MockWidgetRef();
      final List<FilterOption> options = await filter.options(ref, mockL);

      expect(options[5].id, 'light_novel');
      expect(options[5].label, 'Light Novel');
      expect(options[5].value, 'LIGHT_NOVEL');
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
