// Тесты для модели TvSeason.

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/tv_season.dart';

void main() {
  group('TvSeason', () {
    group('fromJson', () {
      test('должен создать из полного JSON', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'season_number': 1,
          'name': 'Season 1',
          'episode_count': 7,
          'poster_path': '/1BP4xYv9ZG4ZVHkL7ocOziBbSYH.jpg',
          'air_date': '2008-01-20',
        };

        final TvSeason season = TvSeason.fromJson(json, showId: 1396);

        expect(season.tmdbShowId, 1396);
        expect(season.seasonNumber, 1);
        expect(season.name, 'Season 1');
        expect(season.episodeCount, 7);
        expect(season.posterUrl,
            'https://image.tmdb.org/t/p/w342/1BP4xYv9ZG4ZVHkL7ocOziBbSYH.jpg');
        expect(season.airDate, '2008-01-20');
      });

      test('должен создать из минимального JSON', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'season_number': 0,
        };

        final TvSeason season = TvSeason.fromJson(json, showId: 1396);

        expect(season.tmdbShowId, 1396);
        expect(season.seasonNumber, 0);
        expect(season.name, isNull);
        expect(season.episodeCount, isNull);
        expect(season.posterUrl, isNull);
        expect(season.airDate, isNull);
      });

      test('должен обработать null poster_path', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'season_number': 2,
          'name': 'Season 2',
          'poster_path': null,
        };

        final TvSeason season = TvSeason.fromJson(json, showId: 1396);

        expect(season.posterUrl, isNull);
      });

      test('должен обработать отсутствующий poster_path', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'season_number': 3,
          'name': 'Season 3',
        };

        final TvSeason season = TvSeason.fromJson(json, showId: 1396);

        expect(season.posterUrl, isNull);
      });

      test('должен обработать null name', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'season_number': 1,
          'name': null,
        };

        final TvSeason season = TvSeason.fromJson(json, showId: 100);

        expect(season.name, isNull);
      });

      test('должен обработать null episode_count', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'season_number': 1,
          'episode_count': null,
        };

        final TvSeason season = TvSeason.fromJson(json, showId: 100);

        expect(season.episodeCount, isNull);
      });

      test('должен обработать null air_date', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'season_number': 1,
          'air_date': null,
        };

        final TvSeason season = TvSeason.fromJson(json, showId: 100);

        expect(season.airDate, isNull);
      });

      test('должен обработать сезон 0 (спецвыпуски)', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'season_number': 0,
          'name': 'Specials',
          'episode_count': 3,
          'poster_path': '/specials.jpg',
          'air_date': '2009-02-17',
        };

        final TvSeason season = TvSeason.fromJson(json, showId: 1396);

        expect(season.seasonNumber, 0);
        expect(season.name, 'Specials');
        expect(season.episodeCount, 3);
        expect(season.posterUrl,
            'https://image.tmdb.org/t/p/w342/specials.jpg');
        expect(season.airDate, '2009-02-17');
      });

      test('должен использовать переданный showId', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'season_number': 1,
        };

        final TvSeason season1 = TvSeason.fromJson(json, showId: 100);
        final TvSeason season2 = TvSeason.fromJson(json, showId: 200);

        expect(season1.tmdbShowId, 100);
        expect(season2.tmdbShowId, 200);
      });
    });

    group('fromDb', () {
      test('должен создать из полной записи БД', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'tmdb_show_id': 1396,
          'season_number': 1,
          'name': 'Season 1',
          'episode_count': 7,
          'poster_url': 'https://image.tmdb.org/t/p/w500/poster.jpg',
          'air_date': '2008-01-20',
        };

        final TvSeason season = TvSeason.fromDb(row);

        expect(season.tmdbShowId, 1396);
        expect(season.seasonNumber, 1);
        expect(season.name, 'Season 1');
        expect(season.episodeCount, 7);
        expect(season.posterUrl, 'https://image.tmdb.org/t/p/w500/poster.jpg');
        expect(season.airDate, '2008-01-20');
      });

      test('должен обработать null значения', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'tmdb_show_id': 1396,
          'season_number': 1,
          'name': null,
          'episode_count': null,
          'poster_url': null,
          'air_date': null,
        };

        final TvSeason season = TvSeason.fromDb(row);

        expect(season.tmdbShowId, 1396);
        expect(season.seasonNumber, 1);
        expect(season.name, isNull);
        expect(season.episodeCount, isNull);
        expect(season.posterUrl, isNull);
        expect(season.airDate, isNull);
      });
    });

    group('toDb', () {
      test('должен преобразовать в Map для БД', () {
        const TvSeason season = TvSeason(
          tmdbShowId: 1396,
          seasonNumber: 1,
          name: 'Season 1',
          episodeCount: 7,
          posterUrl: 'https://image.tmdb.org/t/p/w500/poster.jpg',
          airDate: '2008-01-20',
        );

        final Map<String, dynamic> db = season.toDb();

        expect(db['tmdb_show_id'], 1396);
        expect(db['season_number'], 1);
        expect(db['name'], 'Season 1');
        expect(db['episode_count'], 7);
        expect(db['poster_url'], 'https://image.tmdb.org/t/p/w500/poster.jpg');
        expect(db['air_date'], '2008-01-20');
      });

      test('должен обработать null значения', () {
        const TvSeason season = TvSeason(
          tmdbShowId: 1396,
          seasonNumber: 1,
        );

        final Map<String, dynamic> db = season.toDb();

        expect(db['tmdb_show_id'], 1396);
        expect(db['season_number'], 1);
        expect(db['name'], isNull);
        expect(db['episode_count'], isNull);
        expect(db['poster_url'], isNull);
        expect(db['air_date'], isNull);
      });
    });

    group('toDb/fromDb round-trip', () {
      test('должен сохранить и восстановить все данные', () {
        const TvSeason original = TvSeason(
          tmdbShowId: 1396,
          seasonNumber: 3,
          name: 'Season 3',
          episodeCount: 13,
          posterUrl: 'https://image.tmdb.org/t/p/w500/season3.jpg',
          airDate: '2010-03-21',
        );

        final Map<String, dynamic> db = original.toDb();
        final TvSeason restored = TvSeason.fromDb(db);

        expect(restored.tmdbShowId, original.tmdbShowId);
        expect(restored.seasonNumber, original.seasonNumber);
        expect(restored.name, original.name);
        expect(restored.episodeCount, original.episodeCount);
        expect(restored.posterUrl, original.posterUrl);
        expect(restored.airDate, original.airDate);
      });

      test('должен сохранить и восстановить минимальные данные', () {
        const TvSeason original = TvSeason(
          tmdbShowId: 1396,
          seasonNumber: 0,
        );

        final Map<String, dynamic> db = original.toDb();
        final TvSeason restored = TvSeason.fromDb(db);

        expect(restored.tmdbShowId, original.tmdbShowId);
        expect(restored.seasonNumber, original.seasonNumber);
        expect(restored.name, isNull);
        expect(restored.episodeCount, isNull);
        expect(restored.posterUrl, isNull);
        expect(restored.airDate, isNull);
      });
    });

    group('copyWith', () {
      test('должен создать копию с изменёнными полями', () {
        const TvSeason original = TvSeason(
          tmdbShowId: 1396,
          seasonNumber: 1,
          name: 'Season 1',
          episodeCount: 7,
        );

        final TvSeason copy = original.copyWith(
          name: 'Season 1 (Updated)',
          episodeCount: 8,
        );

        expect(copy.tmdbShowId, 1396);
        expect(copy.seasonNumber, 1);
        expect(copy.name, 'Season 1 (Updated)');
        expect(copy.episodeCount, 8);
      });

      test('должен сохранить неизменённые поля', () {
        const TvSeason original = TvSeason(
          tmdbShowId: 1396,
          seasonNumber: 1,
          name: 'Season 1',
          episodeCount: 7,
          posterUrl: 'https://example.com/poster.jpg',
          airDate: '2008-01-20',
        );

        final TvSeason copy = original.copyWith(name: 'Updated');

        expect(copy.tmdbShowId, 1396);
        expect(copy.seasonNumber, 1);
        expect(copy.episodeCount, 7);
        expect(copy.posterUrl, 'https://example.com/poster.jpg');
        expect(copy.airDate, '2008-01-20');
      });

      test('должен позволить изменить все поля', () {
        const TvSeason original = TvSeason(
          tmdbShowId: 1,
          seasonNumber: 1,
        );

        final TvSeason copy = original.copyWith(
          tmdbShowId: 2,
          seasonNumber: 5,
          name: 'New Name',
          episodeCount: 10,
          posterUrl: 'new_poster',
          airDate: '2025-01-01',
        );

        expect(copy.tmdbShowId, 2);
        expect(copy.seasonNumber, 5);
        expect(copy.name, 'New Name');
        expect(copy.episodeCount, 10);
        expect(copy.posterUrl, 'new_poster');
        expect(copy.airDate, '2025-01-01');
      });
    });

    group('equality', () {
      test(
          'сезоны с одинаковым showId и seasonNumber должны быть равны', () {
        const TvSeason season1 = TvSeason(
          tmdbShowId: 1396,
          seasonNumber: 1,
          name: 'Season 1',
        );
        const TvSeason season2 = TvSeason(
          tmdbShowId: 1396,
          seasonNumber: 1,
          name: 'Different Name',
        );

        expect(season1, equals(season2));
        expect(season1.hashCode, equals(season2.hashCode));
      });

      test('сезоны с разными showId не должны быть равны', () {
        const TvSeason season1 = TvSeason(
          tmdbShowId: 1396,
          seasonNumber: 1,
        );
        const TvSeason season2 = TvSeason(
          tmdbShowId: 1399,
          seasonNumber: 1,
        );

        expect(season1, isNot(equals(season2)));
      });

      test('сезоны с разными seasonNumber не должны быть равны', () {
        const TvSeason season1 = TvSeason(
          tmdbShowId: 1396,
          seasonNumber: 1,
        );
        const TvSeason season2 = TvSeason(
          tmdbShowId: 1396,
          seasonNumber: 2,
        );

        expect(season1, isNot(equals(season2)));
      });

      test('идентичные объекты должны быть равны', () {
        const TvSeason season = TvSeason(
          tmdbShowId: 1396,
          seasonNumber: 1,
        );

        expect(season, equals(season));
      });

      test('сравнение с другим типом не должно быть равно', () {
        const TvSeason season = TvSeason(
          tmdbShowId: 1396,
          seasonNumber: 1,
        );

        // ignore: unrelated_type_equality_checks
        expect(season == 'not a season', isFalse);
      });
    });

    test('toString должен вернуть читаемое представление', () {
      const TvSeason season = TvSeason(
        tmdbShowId: 1396,
        seasonNumber: 3,
      );

      expect(season.toString(), 'TvSeason(showId: 1396, season: 3)');
    });

    test('toString должен работать с сезоном 0', () {
      const TvSeason season = TvSeason(
        tmdbShowId: 1396,
        seasonNumber: 0,
      );

      expect(season.toString(), 'TvSeason(showId: 1396, season: 0)');
    });
  });
}
