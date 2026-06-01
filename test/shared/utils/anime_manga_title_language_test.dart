import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/utils/anime_manga_title_language.dart';

void main() {
  group('AnimeMangaTitleLanguage', () {
    group('fromId', () {
      test('maps known ids to enum values', () {
        expect(AnimeMangaTitleLanguage.fromId('romaji'),
            AnimeMangaTitleLanguage.romaji);
        expect(AnimeMangaTitleLanguage.fromId('english'),
            AnimeMangaTitleLanguage.english);
        expect(AnimeMangaTitleLanguage.fromId('native'),
            AnimeMangaTitleLanguage.native);
      });

      test('unknown or null id defaults to romaji', () {
        expect(AnimeMangaTitleLanguage.fromId(null),
            AnimeMangaTitleLanguage.romaji);
        expect(AnimeMangaTitleLanguage.fromId('klingon'),
            AnimeMangaTitleLanguage.romaji);
        expect(AnimeMangaTitleLanguage.fromId(''),
            AnimeMangaTitleLanguage.romaji);
      });
    });
  });

  group('pickAnimeMangaTitle', () {
    test('romaji returns romaji', () {
      expect(
        pickAnimeMangaTitle(
          lang: 'romaji',
          romaji: 'R',
          english: 'E',
          native: 'N',
        ),
        'R',
      );
    });

    test('english returns english when present', () {
      expect(
        pickAnimeMangaTitle(
          lang: 'english',
          romaji: 'R',
          english: 'E',
          native: 'N',
        ),
        'E',
      );
    });

    test('native returns native when present', () {
      expect(
        pickAnimeMangaTitle(
          lang: 'native',
          romaji: 'R',
          english: 'E',
          native: 'N',
        ),
        'N',
      );
    });

    test('english falls back to romaji when english missing', () {
      expect(
        pickAnimeMangaTitle(
          lang: 'english',
          romaji: 'R',
          english: null,
          native: 'N',
        ),
        'R',
      );
    });

    test('native falls back to romaji when native missing', () {
      expect(
        pickAnimeMangaTitle(
          lang: 'native',
          romaji: 'R',
          english: 'E',
          native: null,
        ),
        'R',
      );
    });

    test('falls through full chain when primary and secondary missing', () {
      expect(
        pickAnimeMangaTitle(
          lang: 'english',
          romaji: null,
          english: null,
          native: 'N',
        ),
        'N',
      );
    });

    test('returns null when every variant is null', () {
      expect(
        pickAnimeMangaTitle(
          lang: 'romaji',
          romaji: null,
          english: null,
          native: null,
        ),
        isNull,
      );
    });

    test('empty strings are treated as missing', () {
      expect(
        pickAnimeMangaTitle(
          lang: 'english',
          romaji: 'R',
          english: '',
          native: 'N',
        ),
        'R',
      );
    });

    test('unknown lang code is treated as romaji', () {
      expect(
        pickAnimeMangaTitle(
          lang: 'klingon',
          romaji: 'R',
          english: 'E',
          native: 'N',
        ),
        'R',
      );
    });
  });
}
