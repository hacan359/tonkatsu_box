// Тесты для модели TvEpisode.

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/tv_episode.dart';

void main() {
  group('TvEpisode', () {
    group('fromJson', () {
      test('должен создать из полного JSON', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'episode_number': 1,
          'name': 'Pilot',
          'overview': 'Walter White, a struggling chemistry teacher...',
          'air_date': '2008-01-20',
          'still_path': '/ydlY3iPfeOAvu8gVqrxPoMvzNCn.jpg',
          'runtime': 58,
        };

        final TvEpisode episode =
            TvEpisode.fromJson(json, showId: 1396, season: 1);

        expect(episode.tmdbShowId, 1396);
        expect(episode.seasonNumber, 1);
        expect(episode.episodeNumber, 1);
        expect(episode.name, 'Pilot');
        expect(episode.overview,
            'Walter White, a struggling chemistry teacher...');
        expect(episode.airDate, '2008-01-20');
        expect(episode.stillUrl,
            'https://image.tmdb.org/t/p/w300/ydlY3iPfeOAvu8gVqrxPoMvzNCn.jpg');
        expect(episode.runtime, 58);
      });

      test('должен создать из минимального JSON', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'episode_number': 1,
        };

        final TvEpisode episode =
            TvEpisode.fromJson(json, showId: 1396, season: 1);

        expect(episode.tmdbShowId, 1396);
        expect(episode.seasonNumber, 1);
        expect(episode.episodeNumber, 1);
        expect(episode.name, '');
        expect(episode.overview, isNull);
        expect(episode.airDate, isNull);
        expect(episode.stillUrl, isNull);
        expect(episode.runtime, isNull);
      });

      test('должен обработать null still_path', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'episode_number': 2,
          'name': 'Cat\'s in the Bag...',
          'still_path': null,
        };

        final TvEpisode episode =
            TvEpisode.fromJson(json, showId: 1396, season: 1);

        expect(episode.stillUrl, isNull);
      });

      test('должен обработать отсутствующий still_path', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'episode_number': 3,
          'name': '...And the Bag\'s in the River',
        };

        final TvEpisode episode =
            TvEpisode.fromJson(json, showId: 1396, season: 1);

        expect(episode.stillUrl, isNull);
      });

      test('должен обработать null name (использовать пустую строку)', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'episode_number': 1,
          'name': null,
        };

        final TvEpisode episode =
            TvEpisode.fromJson(json, showId: 100, season: 1);

        expect(episode.name, '');
      });

      test('должен обработать отсутствующий name (использовать пустую строку)',
          () {
        final Map<String, dynamic> json = <String, dynamic>{
          'episode_number': 1,
        };

        final TvEpisode episode =
            TvEpisode.fromJson(json, showId: 100, season: 1);

        expect(episode.name, '');
      });

      test('должен обработать null overview', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'episode_number': 1,
          'overview': null,
        };

        final TvEpisode episode =
            TvEpisode.fromJson(json, showId: 100, season: 1);

        expect(episode.overview, isNull);
      });

      test('должен обработать null air_date', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'episode_number': 1,
          'air_date': null,
        };

        final TvEpisode episode =
            TvEpisode.fromJson(json, showId: 100, season: 1);

        expect(episode.airDate, isNull);
      });

      test('должен обработать null runtime', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'episode_number': 1,
          'runtime': null,
        };

        final TvEpisode episode =
            TvEpisode.fromJson(json, showId: 100, season: 1);

        expect(episode.runtime, isNull);
      });

      test('должен построить still_url из still_path', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'episode_number': 5,
          'still_path': '/abc123.jpg',
        };

        final TvEpisode episode =
            TvEpisode.fromJson(json, showId: 1396, season: 2);

        expect(episode.stillUrl, 'https://image.tmdb.org/t/p/w300/abc123.jpg');
      });

      test('должен обработать эпизод 0', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'episode_number': 0,
          'name': 'Special Episode',
          'overview': 'A special behind-the-scenes episode',
          'air_date': '2009-02-17',
          'still_path': '/special.jpg',
          'runtime': 30,
        };

        final TvEpisode episode =
            TvEpisode.fromJson(json, showId: 1396, season: 0);

        expect(episode.seasonNumber, 0);
        expect(episode.episodeNumber, 0);
        expect(episode.name, 'Special Episode');
        expect(episode.overview, 'A special behind-the-scenes episode');
        expect(episode.stillUrl,
            'https://image.tmdb.org/t/p/w300/special.jpg');
        expect(episode.runtime, 30);
      });

      test('должен использовать переданные showId и season', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'episode_number': 7,
        };

        final TvEpisode episode1 =
            TvEpisode.fromJson(json, showId: 100, season: 1);
        final TvEpisode episode2 =
            TvEpisode.fromJson(json, showId: 200, season: 5);

        expect(episode1.tmdbShowId, 100);
        expect(episode1.seasonNumber, 1);
        expect(episode2.tmdbShowId, 200);
        expect(episode2.seasonNumber, 5);
      });

      test('должен обработать большой номер эпизода', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'episode_number': 999,
          'name': 'Episode 999',
        };

        final TvEpisode episode =
            TvEpisode.fromJson(json, showId: 1, season: 10);

        expect(episode.episodeNumber, 999);
      });

      test('должен обработать длинный overview', () {
        final String longOverview = 'A' * 1000;
        final Map<String, dynamic> json = <String, dynamic>{
          'episode_number': 1,
          'overview': longOverview,
        };

        final TvEpisode episode =
            TvEpisode.fromJson(json, showId: 1, season: 1);

        expect(episode.overview, longOverview);
      });
    });

    group('fromDb', () {
      test('должен создать из полной записи БД', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'tmdb_show_id': 1396,
          'season_number': 1,
          'episode_number': 1,
          'name': 'Pilot',
          'overview': 'Walter White, a struggling chemistry teacher...',
          'air_date': '2008-01-20',
          'still_url': 'https://image.tmdb.org/t/p/w300/still.jpg',
          'runtime': 58,
        };

        final TvEpisode episode = TvEpisode.fromDb(row);

        expect(episode.tmdbShowId, 1396);
        expect(episode.seasonNumber, 1);
        expect(episode.episodeNumber, 1);
        expect(episode.name, 'Pilot');
        expect(episode.overview,
            'Walter White, a struggling chemistry teacher...');
        expect(episode.airDate, '2008-01-20');
        expect(episode.stillUrl, 'https://image.tmdb.org/t/p/w300/still.jpg');
        expect(episode.runtime, 58);
      });

      test('должен создать из минимальной записи БД', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'tmdb_show_id': 1396,
          'season_number': 1,
          'episode_number': 1,
        };

        final TvEpisode episode = TvEpisode.fromDb(row);

        expect(episode.tmdbShowId, 1396);
        expect(episode.seasonNumber, 1);
        expect(episode.episodeNumber, 1);
        expect(episode.name, '');
        expect(episode.overview, isNull);
        expect(episode.airDate, isNull);
        expect(episode.stillUrl, isNull);
        expect(episode.runtime, isNull);
      });

      test('должен обработать null значения', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'tmdb_show_id': 1396,
          'season_number': 2,
          'episode_number': 5,
          'name': null,
          'overview': null,
          'air_date': null,
          'still_url': null,
          'runtime': null,
        };

        final TvEpisode episode = TvEpisode.fromDb(row);

        expect(episode.tmdbShowId, 1396);
        expect(episode.seasonNumber, 2);
        expect(episode.episodeNumber, 5);
        expect(episode.name, '');
        expect(episode.overview, isNull);
        expect(episode.airDate, isNull);
        expect(episode.stillUrl, isNull);
        expect(episode.runtime, isNull);
      });

      test('должен обработать эпизод 0 из БД', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'tmdb_show_id': 1396,
          'season_number': 0,
          'episode_number': 0,
          'name': 'Special',
        };

        final TvEpisode episode = TvEpisode.fromDb(row);

        expect(episode.seasonNumber, 0);
        expect(episode.episodeNumber, 0);
        expect(episode.name, 'Special');
      });
    });

    group('toDb', () {
      test('должен преобразовать в Map для БД', () {
        const TvEpisode episode = TvEpisode(
          tmdbShowId: 1396,
          seasonNumber: 1,
          episodeNumber: 1,
          name: 'Pilot',
          overview: 'Walter White, a struggling chemistry teacher...',
          airDate: '2008-01-20',
          stillUrl: 'https://image.tmdb.org/t/p/w300/still.jpg',
          runtime: 58,
        );

        final Map<String, dynamic> db = episode.toDb();

        expect(db['tmdb_show_id'], 1396);
        expect(db['season_number'], 1);
        expect(db['episode_number'], 1);
        expect(db['name'], 'Pilot');
        expect(db['overview'], 'Walter White, a struggling chemistry teacher...');
        expect(db['air_date'], '2008-01-20');
        expect(db['still_url'], 'https://image.tmdb.org/t/p/w300/still.jpg');
        expect(db['runtime'], 58);
        expect(db['cached_at'], isA<int>());
      });

      test('должен обработать null значения', () {
        const TvEpisode episode = TvEpisode(
          tmdbShowId: 1396,
          seasonNumber: 1,
          episodeNumber: 1,
          name: '',
        );

        final Map<String, dynamic> db = episode.toDb();

        expect(db['tmdb_show_id'], 1396);
        expect(db['season_number'], 1);
        expect(db['episode_number'], 1);
        expect(db['name'], '');
        expect(db['overview'], isNull);
        expect(db['air_date'], isNull);
        expect(db['still_url'], isNull);
        expect(db['runtime'], isNull);
        expect(db['cached_at'], isA<int>());
      });

      test('должен включить cached_at с текущим временем', () {
        const TvEpisode episode = TvEpisode(
          tmdbShowId: 1396,
          seasonNumber: 1,
          episodeNumber: 1,
          name: 'Test',
        );

        final int before = DateTime.now().millisecondsSinceEpoch;
        final Map<String, dynamic> db = episode.toDb();
        final int after = DateTime.now().millisecondsSinceEpoch;

        expect(db['cached_at'], isA<int>());
        final int cachedAt = db['cached_at'] as int;
        expect(cachedAt, greaterThanOrEqualTo(before));
        expect(cachedAt, lessThanOrEqualTo(after));
      });

      test('должен обработать эпизод 0', () {
        const TvEpisode episode = TvEpisode(
          tmdbShowId: 1396,
          seasonNumber: 0,
          episodeNumber: 0,
          name: 'Special',
        );

        final Map<String, dynamic> db = episode.toDb();

        expect(db['season_number'], 0);
        expect(db['episode_number'], 0);
      });
    });

    group('toDb/fromDb round-trip', () {
      test('должен сохранить и восстановить все данные', () {
        const TvEpisode original = TvEpisode(
          tmdbShowId: 1396,
          seasonNumber: 3,
          episodeNumber: 7,
          name: 'One Minute',
          overview: 'Hank\'s increasing volatility forces a confrontation...',
          airDate: '2010-05-02',
          stillUrl: 'https://image.tmdb.org/t/p/w300/episode.jpg',
          runtime: 47,
        );

        final Map<String, dynamic> db = original.toDb();
        final TvEpisode restored = TvEpisode.fromDb(db);

        expect(restored.tmdbShowId, original.tmdbShowId);
        expect(restored.seasonNumber, original.seasonNumber);
        expect(restored.episodeNumber, original.episodeNumber);
        expect(restored.name, original.name);
        expect(restored.overview, original.overview);
        expect(restored.airDate, original.airDate);
        expect(restored.stillUrl, original.stillUrl);
        expect(restored.runtime, original.runtime);
      });

      test('должен сохранить и восстановить минимальные данные', () {
        const TvEpisode original = TvEpisode(
          tmdbShowId: 1396,
          seasonNumber: 1,
          episodeNumber: 1,
          name: '',
        );

        final Map<String, dynamic> db = original.toDb();
        final TvEpisode restored = TvEpisode.fromDb(db);

        expect(restored.tmdbShowId, original.tmdbShowId);
        expect(restored.seasonNumber, original.seasonNumber);
        expect(restored.episodeNumber, original.episodeNumber);
        expect(restored.name, original.name);
        expect(restored.overview, isNull);
        expect(restored.airDate, isNull);
        expect(restored.stillUrl, isNull);
        expect(restored.runtime, isNull);
      });

      test('должен сохранить и восстановить эпизод 0', () {
        const TvEpisode original = TvEpisode(
          tmdbShowId: 1396,
          seasonNumber: 0,
          episodeNumber: 0,
          name: 'Special',
          overview: 'Behind the scenes',
          runtime: 30,
        );

        final Map<String, dynamic> db = original.toDb();
        final TvEpisode restored = TvEpisode.fromDb(db);

        expect(restored.tmdbShowId, original.tmdbShowId);
        expect(restored.seasonNumber, original.seasonNumber);
        expect(restored.episodeNumber, original.episodeNumber);
        expect(restored.name, original.name);
        expect(restored.overview, original.overview);
        expect(restored.runtime, original.runtime);
      });
    });

    group('copyWith', () {
      test('должен создать копию с изменёнными полями', () {
        const TvEpisode original = TvEpisode(
          tmdbShowId: 1396,
          seasonNumber: 1,
          episodeNumber: 1,
          name: 'Pilot',
          runtime: 58,
        );

        final TvEpisode copy = original.copyWith(
          name: 'Pilot (Extended)',
          runtime: 65,
        );

        expect(copy.tmdbShowId, 1396);
        expect(copy.seasonNumber, 1);
        expect(copy.episodeNumber, 1);
        expect(copy.name, 'Pilot (Extended)');
        expect(copy.runtime, 65);
      });

      test('должен сохранить неизменённые поля', () {
        const TvEpisode original = TvEpisode(
          tmdbShowId: 1396,
          seasonNumber: 1,
          episodeNumber: 1,
          name: 'Pilot',
          overview: 'Original overview',
          airDate: '2008-01-20',
          stillUrl: 'https://example.com/still.jpg',
          runtime: 58,
        );

        final TvEpisode copy = original.copyWith(name: 'Updated');

        expect(copy.tmdbShowId, 1396);
        expect(copy.seasonNumber, 1);
        expect(copy.episodeNumber, 1);
        expect(copy.overview, 'Original overview');
        expect(copy.airDate, '2008-01-20');
        expect(copy.stillUrl, 'https://example.com/still.jpg');
        expect(copy.runtime, 58);
      });

      test('должен позволить изменить все поля', () {
        const TvEpisode original = TvEpisode(
          tmdbShowId: 1,
          seasonNumber: 1,
          episodeNumber: 1,
          name: 'Old',
        );

        final TvEpisode copy = original.copyWith(
          tmdbShowId: 2,
          seasonNumber: 5,
          episodeNumber: 10,
          name: 'New Name',
          overview: 'New overview',
          airDate: '2025-01-01',
          stillUrl: 'new_still',
          runtime: 42,
        );

        expect(copy.tmdbShowId, 2);
        expect(copy.seasonNumber, 5);
        expect(copy.episodeNumber, 10);
        expect(copy.name, 'New Name');
        expect(copy.overview, 'New overview');
        expect(copy.airDate, '2025-01-01');
        expect(copy.stillUrl, 'new_still');
        expect(copy.runtime, 42);
      });

      test('должен позволить изменить tmdbShowId', () {
        const TvEpisode original = TvEpisode(
          tmdbShowId: 1396,
          seasonNumber: 1,
          episodeNumber: 1,
          name: 'Test',
        );

        final TvEpisode copy = original.copyWith(tmdbShowId: 9999);

        expect(copy.tmdbShowId, 9999);
      });

      test('должен позволить изменить seasonNumber', () {
        const TvEpisode original = TvEpisode(
          tmdbShowId: 1396,
          seasonNumber: 1,
          episodeNumber: 1,
          name: 'Test',
        );

        final TvEpisode copy = original.copyWith(seasonNumber: 5);

        expect(copy.seasonNumber, 5);
      });

      test('должен позволить изменить episodeNumber', () {
        const TvEpisode original = TvEpisode(
          tmdbShowId: 1396,
          seasonNumber: 1,
          episodeNumber: 1,
          name: 'Test',
        );

        final TvEpisode copy = original.copyWith(episodeNumber: 13);

        expect(copy.episodeNumber, 13);
      });

      test('должен позволить изменить overview', () {
        const TvEpisode original = TvEpisode(
          tmdbShowId: 1396,
          seasonNumber: 1,
          episodeNumber: 1,
          name: 'Test',
          overview: 'Old',
        );

        final TvEpisode copy = original.copyWith(overview: 'New overview');

        expect(copy.overview, 'New overview');
      });

      test('должен позволить изменить airDate', () {
        const TvEpisode original = TvEpisode(
          tmdbShowId: 1396,
          seasonNumber: 1,
          episodeNumber: 1,
          name: 'Test',
          airDate: '2020-01-01',
        );

        final TvEpisode copy = original.copyWith(airDate: '2025-12-31');

        expect(copy.airDate, '2025-12-31');
      });

      test('должен позволить изменить stillUrl', () {
        const TvEpisode original = TvEpisode(
          tmdbShowId: 1396,
          seasonNumber: 1,
          episodeNumber: 1,
          name: 'Test',
          stillUrl: 'old_url',
        );

        final TvEpisode copy = original.copyWith(stillUrl: 'new_url');

        expect(copy.stillUrl, 'new_url');
      });

      test('должен позволить изменить runtime', () {
        const TvEpisode original = TvEpisode(
          tmdbShowId: 1396,
          seasonNumber: 1,
          episodeNumber: 1,
          name: 'Test',
          runtime: 45,
        );

        final TvEpisode copy = original.copyWith(runtime: 90);

        expect(copy.runtime, 90);
      });
    });

    group('equality', () {
      test(
          'эпизоды с одинаковым showId, season и episode должны быть равны',
          () {
        const TvEpisode episode1 = TvEpisode(
          tmdbShowId: 1396,
          seasonNumber: 1,
          episodeNumber: 1,
          name: 'Pilot',
        );
        const TvEpisode episode2 = TvEpisode(
          tmdbShowId: 1396,
          seasonNumber: 1,
          episodeNumber: 1,
          name: 'Different Name',
        );

        expect(episode1, equals(episode2));
        expect(episode1.hashCode, equals(episode2.hashCode));
      });

      test('эпизоды с разными showId не должны быть равны', () {
        const TvEpisode episode1 = TvEpisode(
          tmdbShowId: 1396,
          seasonNumber: 1,
          episodeNumber: 1,
          name: 'Test',
        );
        const TvEpisode episode2 = TvEpisode(
          tmdbShowId: 1399,
          seasonNumber: 1,
          episodeNumber: 1,
          name: 'Test',
        );

        expect(episode1, isNot(equals(episode2)));
      });

      test('эпизоды с разными seasonNumber не должны быть равны', () {
        const TvEpisode episode1 = TvEpisode(
          tmdbShowId: 1396,
          seasonNumber: 1,
          episodeNumber: 1,
          name: 'Test',
        );
        const TvEpisode episode2 = TvEpisode(
          tmdbShowId: 1396,
          seasonNumber: 2,
          episodeNumber: 1,
          name: 'Test',
        );

        expect(episode1, isNot(equals(episode2)));
      });

      test('эпизоды с разными episodeNumber не должны быть равны', () {
        const TvEpisode episode1 = TvEpisode(
          tmdbShowId: 1396,
          seasonNumber: 1,
          episodeNumber: 1,
          name: 'Test',
        );
        const TvEpisode episode2 = TvEpisode(
          tmdbShowId: 1396,
          seasonNumber: 1,
          episodeNumber: 2,
          name: 'Test',
        );

        expect(episode1, isNot(equals(episode2)));
      });

      test('идентичные объекты должны быть равны', () {
        const TvEpisode episode = TvEpisode(
          tmdbShowId: 1396,
          seasonNumber: 1,
          episodeNumber: 1,
          name: 'Test',
        );

        expect(episode, equals(episode));
      });

      test('сравнение с другим типом не должно быть равно', () {
        const TvEpisode episode = TvEpisode(
          tmdbShowId: 1396,
          seasonNumber: 1,
          episodeNumber: 1,
          name: 'Test',
        );

        // ignore: unrelated_type_equality_checks
        expect(episode == 'not an episode', isFalse);
      });

      test('эпизоды с разными полями (не ключевыми) должны быть равны', () {
        const TvEpisode episode1 = TvEpisode(
          tmdbShowId: 1396,
          seasonNumber: 1,
          episodeNumber: 1,
          name: 'Name 1',
          overview: 'Overview 1',
          runtime: 45,
        );
        const TvEpisode episode2 = TvEpisode(
          tmdbShowId: 1396,
          seasonNumber: 1,
          episodeNumber: 1,
          name: 'Name 2',
          overview: 'Overview 2',
          runtime: 60,
        );

        expect(episode1, equals(episode2));
        expect(episode1.hashCode, equals(episode2.hashCode));
      });
    });

    test('toString должен вернуть читаемое представление', () {
      const TvEpisode episode = TvEpisode(
        tmdbShowId: 1396,
        seasonNumber: 3,
        episodeNumber: 7,
        name: 'One Minute',
      );

      expect(episode.toString(),
          'TvEpisode(showId: 1396, S3E7: One Minute)');
    });

    test('toString должен работать с эпизодом 0', () {
      const TvEpisode episode = TvEpisode(
        tmdbShowId: 1396,
        seasonNumber: 0,
        episodeNumber: 0,
        name: 'Special',
      );

      expect(episode.toString(), 'TvEpisode(showId: 1396, S0E0: Special)');
    });

    test('toString должен работать с пустым name', () {
      const TvEpisode episode = TvEpisode(
        tmdbShowId: 1396,
        seasonNumber: 1,
        episodeNumber: 1,
        name: '',
      );

      expect(episode.toString(), 'TvEpisode(showId: 1396, S1E1: )');
    });

    test('toString должен работать с большими номерами', () {
      const TvEpisode episode = TvEpisode(
        tmdbShowId: 99999,
        seasonNumber: 15,
        episodeNumber: 23,
        name: 'Finale',
      );

      expect(episode.toString(), 'TvEpisode(showId: 99999, S15E23: Finale)');
    });
  });
}
