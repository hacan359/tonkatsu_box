// Тесты для KodiUniqueIds.

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/kodi_unique_ids.dart';

void main() {
  group('KodiUniqueIds.fromJson', () {
    test('null → пустой объект', () {
      final KodiUniqueIds ids = KodiUniqueIds.fromJson(null);
      expect(ids.tmdbId, isNull);
      expect(ids.imdbId, isNull);
      expect(ids.tvdbId, isNull);
      expect(ids.hasAny, isFalse);
    });

    test('{} → пустой объект', () {
      final KodiUniqueIds ids =
          KodiUniqueIds.fromJson(<String, dynamic>{});
      expect(ids.hasAny, isFalse);
    });

    test('tmdb как строка → int', () {
      final KodiUniqueIds ids = KodiUniqueIds.fromJson(<String, dynamic>{
        'tmdb': '27205',
      });
      expect(ids.tmdbId, 27205);
    });

    test('tmdb как int → сохраняется', () {
      final KodiUniqueIds ids = KodiUniqueIds.fromJson(<String, dynamic>{
        'tmdb': 27205,
      });
      expect(ids.tmdbId, 27205);
    });

    test('tmdb = 0 → null (в Kodi 0 == "нет")', () {
      final KodiUniqueIds ids = KodiUniqueIds.fromJson(<String, dynamic>{
        'tmdb': 0,
      });
      expect(ids.tmdbId, isNull);
    });

    test('tmdb = "0" → null', () {
      final KodiUniqueIds ids = KodiUniqueIds.fromJson(<String, dynamic>{
        'tmdb': '0',
      });
      expect(ids.tmdbId, isNull);
    });

    test('tmdb = "abc" → null', () {
      final KodiUniqueIds ids = KodiUniqueIds.fromJson(<String, dynamic>{
        'tmdb': 'abc',
      });
      expect(ids.tmdbId, isNull);
    });

    test('imdb сохраняет префикс tt', () {
      final KodiUniqueIds ids = KodiUniqueIds.fromJson(<String, dynamic>{
        'imdb': 'tt1375666',
      });
      expect(ids.imdbId, 'tt1375666');
    });

    test('imdb пустая строка → null', () {
      final KodiUniqueIds ids = KodiUniqueIds.fromJson(<String, dynamic>{
        'imdb': '',
      });
      expect(ids.imdbId, isNull);
    });

    test('imdb с пробелами по краям → trim', () {
      final KodiUniqueIds ids = KodiUniqueIds.fromJson(<String, dynamic>{
        'imdb': '  tt1375666  ',
      });
      expect(ids.imdbId, 'tt1375666');
    });

    test('tvdb как строка', () {
      final KodiUniqueIds ids = KodiUniqueIds.fromJson(<String, dynamic>{
        'tvdb': '12345',
      });
      expect(ids.tvdbId, 12345);
    });

    test('все три ID одновременно', () {
      final KodiUniqueIds ids = KodiUniqueIds.fromJson(<String, dynamic>{
        'tmdb': '27205',
        'imdb': 'tt1375666',
        'tvdb': 12345,
      });
      expect(ids.tmdbId, 27205);
      expect(ids.imdbId, 'tt1375666');
      expect(ids.tvdbId, 12345);
      expect(ids.hasAny, isTrue);
    });

    test('игнорирует неизвестные поля (anidb)', () {
      final KodiUniqueIds ids = KodiUniqueIds.fromJson(<String, dynamic>{
        'anidb': '99',
        'tmdb': '1',
      });
      expect(ids.tmdbId, 1);
    });
  });

  group('KodiUniqueIds equality', () {
    test('одинаковые значения → равны', () {
      const KodiUniqueIds a =
          KodiUniqueIds(tmdbId: 1, imdbId: 'tt1', tvdbId: 2);
      const KodiUniqueIds b =
          KodiUniqueIds(tmdbId: 1, imdbId: 'tt1', tvdbId: 2);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('разные значения → не равны', () {
      const KodiUniqueIds a = KodiUniqueIds(tmdbId: 1);
      const KodiUniqueIds b = KodiUniqueIds(tmdbId: 2);
      expect(a, isNot(b));
    });
  });
}
