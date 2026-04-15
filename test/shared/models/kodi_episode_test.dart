// Тесты для KodiEpisode.fromJson.

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/kodi_episode.dart';

void main() {
  group('KodiEpisode.fromJson', () {
    test('полный ответ', () {
      final KodiEpisode ep = KodiEpisode.fromJson(<String, dynamic>{
        'episodeid': 123,
        'showtitle': 'Breaking Bad',
        'season': 1,
        'episode': 3,
        'playcount': 2,
        'lastplayed': '2026-04-05 20:15:00',
        'uniqueid': <String, dynamic>{'tvdb': 349232},
      });

      expect(ep.episodeId, 123);
      expect(ep.showTitle, 'Breaking Bad');
      expect(ep.season, 1);
      expect(ep.episode, 3);
      expect(ep.playcount, 2);
      expect(ep.lastPlayed, DateTime(2026, 4, 5, 20, 15));
      expect(ep.uniqueIds.tvdbId, 349232);
      expect(ep.isWatched, isTrue);
    });

    test('playcount = 0 → не просмотрен', () {
      final KodiEpisode ep = KodiEpisode.fromJson(<String, dynamic>{
        'episodeid': 1,
        'showtitle': 'Show',
        'season': 1,
        'episode': 1,
      });
      expect(ep.isWatched, isFalse);
    });

    test('показ специальных эпизодов (season = 0)', () {
      final KodiEpisode ep = KodiEpisode.fromJson(<String, dynamic>{
        'episodeid': 1,
        'showtitle': 'Show',
        'season': 0,
        'episode': 5,
      });
      expect(ep.season, 0);
    });

    test('отсутствуют season/episode → 0', () {
      final KodiEpisode ep = KodiEpisode.fromJson(<String, dynamic>{
        'episodeid': 1,
        'showtitle': 'Show',
      });
      expect(ep.season, 0);
      expect(ep.episode, 0);
    });
  });
}
