// Тесты для KodiTvShow.fromJson.

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/kodi_tv_show.dart';

void main() {
  group('KodiTvShow.fromJson', () {
    test('полный ответ', () {
      final KodiTvShow show = KodiTvShow.fromJson(<String, dynamic>{
        'tvshowid': 7,
        'title': 'Breaking Bad',
        'year': 2008,
        'playcount': 0,
        'lastplayed': '2026-04-01 19:00:00',
        'userrating': 10,
        'uniqueid': <String, dynamic>{
          'tmdb': '1396',
          'tvdb': 81189,
        },
      });

      expect(show.tvShowId, 7);
      expect(show.title, 'Breaking Bad');
      expect(show.year, 2008);
      expect(show.playcount, 0);
      expect(show.lastPlayed, DateTime(2026, 4, 1, 19));
      expect(show.userRating, 10);
      expect(show.uniqueIds.tmdbId, 1396);
      expect(show.uniqueIds.tvdbId, 81189);
    });

    test('title отсутствует → пустая строка', () {
      final KodiTvShow show =
          KodiTvShow.fromJson(<String, dynamic>{'tvshowid': 1});
      expect(show.title, isEmpty);
    });

    test('без uniqueid', () {
      final KodiTvShow show = KodiTvShow.fromJson(<String, dynamic>{
        'tvshowid': 1,
        'title': 'Test',
      });
      expect(show.uniqueIds.hasAny, isFalse);
    });
  });
}
