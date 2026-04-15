// Тесты для KodiMovie.fromJson.

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/kodi_movie.dart';

void main() {
  group('KodiMovie.fromJson', () {
    test('полный ответ', () {
      final KodiMovie movie = KodiMovie.fromJson(<String, dynamic>{
        'movieid': 42,
        'title': 'Inception',
        'year': 2010,
        'playcount': 1,
        'lastplayed': '2026-04-12 22:30:11',
        'userrating': 9,
        'uniqueid': <String, dynamic>{
          'imdb': 'tt1375666',
          'tmdb': '27205',
        },
      });

      expect(movie.movieId, 42);
      expect(movie.title, 'Inception');
      expect(movie.year, 2010);
      expect(movie.playcount, 1);
      expect(movie.lastPlayed, DateTime(2026, 4, 12, 22, 30, 11));
      expect(movie.userRating, 9);
      expect(movie.uniqueIds.tmdbId, 27205);
      expect(movie.uniqueIds.imdbId, 'tt1375666');
      expect(movie.isWatched, isTrue);
    });

    test('без uniqueid → пустой блок', () {
      final KodiMovie movie = KodiMovie.fromJson(<String, dynamic>{
        'movieid': 1,
        'title': 'Test',
      });
      expect(movie.uniqueIds.hasAny, isFalse);
    });

    test('пустой uniqueid объект', () {
      final KodiMovie movie = KodiMovie.fromJson(<String, dynamic>{
        'movieid': 1,
        'title': 'Test',
        'uniqueid': <String, dynamic>{},
      });
      expect(movie.uniqueIds.hasAny, isFalse);
    });

    test('playcount отсутствует → 0', () {
      final KodiMovie movie = KodiMovie.fromJson(<String, dynamic>{
        'movieid': 1,
        'title': 'Test',
      });
      expect(movie.playcount, 0);
      expect(movie.isWatched, isFalse);
    });

    test('lastplayed пустая строка → null', () {
      final KodiMovie movie = KodiMovie.fromJson(<String, dynamic>{
        'movieid': 1,
        'title': 'Test',
        'lastplayed': '',
      });
      expect(movie.lastPlayed, isNull);
    });

    test('title отсутствует → пустая строка', () {
      final KodiMovie movie =
          KodiMovie.fromJson(<String, dynamic>{'movieid': 1});
      expect(movie.title, isEmpty);
    });

    test('year = 0 → null', () {
      final KodiMovie movie = KodiMovie.fromJson(<String, dynamic>{
        'movieid': 1,
        'title': 'Test',
        'year': 0,
      });
      expect(movie.year, isNull);
    });

    test('userrating = 0 → null (не выставлен)', () {
      final KodiMovie movie = KodiMovie.fromJson(<String, dynamic>{
        'movieid': 1,
        'title': 'Test',
        'userrating': 0,
      });
      expect(movie.userRating, isNull);
    });

    test('userrating как double округляется', () {
      final KodiMovie movie = KodiMovie.fromJson(<String, dynamic>{
        'movieid': 1,
        'title': 'Test',
        'userrating': 8.6,
      });
      expect(movie.userRating, 9);
    });
  });
}
