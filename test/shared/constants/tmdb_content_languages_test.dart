import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/constants/tmdb_content_languages.dart';

void main() {
  group('kTmdbContentLanguages', () {
    test('не пустой', () {
      expect(kTmdbContentLanguages, isNotEmpty);
    });

    test('содержит en-US и ru-RU', () {
      final Iterable<String> codes =
          kTmdbContentLanguages.map((TmdbContentLanguage l) => l.code);
      expect(codes, contains('en-US'));
      expect(codes, contains('ru-RU'));
    });

    test('коды уникальны', () {
      final List<String> codes = kTmdbContentLanguages
          .map((TmdbContentLanguage l) => l.code)
          .toList();
      expect(codes.length, codes.toSet().length);
    });

    test('у всех нативное имя не пустое', () {
      for (final TmdbContentLanguage lang in kTmdbContentLanguages) {
        expect(lang.nativeName, isNotEmpty,
            reason: 'Пустое nativeName у ${lang.code}');
      }
    });

    test('коды в формате xx-XX (IETF BCP 47)', () {
      final RegExp pattern = RegExp(r'^[a-z]{2}-[A-Z]{2}$');
      for (final TmdbContentLanguage lang in kTmdbContentLanguages) {
        expect(pattern.hasMatch(lang.code), isTrue,
            reason: 'Невалидный код: ${lang.code}');
      }
    });
  });

  group('defaultContentLanguageForUi', () {
    test('en → en-US', () {
      expect(defaultContentLanguageForUi('en'), 'en-US');
    });

    test('ru → ru-RU', () {
      expect(defaultContentLanguageForUi('ru'), 'ru-RU');
    });

    test('неизвестная локаль → en-US (fallback)', () {
      expect(defaultContentLanguageForUi('xx'), 'en-US');
      expect(defaultContentLanguageForUi(''), 'en-US');
    });

    test('возвращает код, который есть в kTmdbContentLanguages', () {
      final Set<String> available = kTmdbContentLanguages
          .map((TmdbContentLanguage l) => l.code)
          .toSet();
      for (final String ui in <String>['en', 'ru', 'unknown']) {
        expect(available, contains(defaultContentLanguageForUi(ui)));
      }
    });
  });
}
