import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/features/search/filters/tmdb_language_filter.dart';
import 'package:xerabora/features/search/models/search_source.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('TmdbLanguageFilter', () {
    late TmdbLanguageFilter filter;
    late MockS mockL;

    setUp(() {
      filter = TmdbLanguageFilter();
      mockL = MockS();
      when(() => mockL.browseFilterLanguage).thenReturn('Language');
      when(() => mockL.languageEnglish).thenReturn('English');
      when(() => mockL.languageJapanese).thenReturn('Japanese');
      when(() => mockL.languageKorean).thenReturn('Korean');
      when(() => mockL.languageChinese).thenReturn('Chinese');
      when(() => mockL.languageFrench).thenReturn('French');
      when(() => mockL.languageSpanish).thenReturn('Spanish');
      when(() => mockL.languageGerman).thenReturn('German');
      when(() => mockL.languageRussian).thenReturn('Russian');
      when(() => mockL.languageItalian).thenReturn('Italian');
      when(() => mockL.languagePortuguese).thenReturn('Portuguese');
    });

    test('key is "originalLanguage" — binds to TMDB with_original_language', () {
      expect(filter.key, 'originalLanguage');
    });

    test('searchable — long list, popover should expose a search box', () {
      expect(filter.searchable, isTrue);
    });

    test('allOption clears the filter', () {
      expect(filter.allOption.value, isNull);
    });

    test('options are ISO 639-1 codes, not names', () async {
      final MockWidgetRef ref = MockWidgetRef();
      final List<FilterOption> opts = await filter.options(ref, mockL);

      expect(opts.map((FilterOption o) => o.value).toList(), <String>[
        'en',
        'ja',
        'ko',
        'zh',
        'fr',
        'es',
        'de',
        'ru',
        'it',
        'pt',
      ]);
    });
  });
}
