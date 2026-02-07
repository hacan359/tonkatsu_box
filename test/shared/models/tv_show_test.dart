// Тесты для модели TvShow.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/tv_show.dart';

void main() {
  group('TvShow', () {
    group('fromJson', () {
      test('должен создать из полного JSON', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1396,
          'name': 'Breaking Bad',
          'original_name': 'Breaking Bad',
          'poster_path': '/ggFHVNu6YYI5L9pCfOacjizRGt.jpg',
          'backdrop_path': '/tsRy63Mu5cu8etL1X7ZLyf7UP1M.jpg',
          'overview': 'A high school chemistry teacher diagnosed with cancer...',
          'genres': <Map<String, dynamic>>[
            <String, dynamic>{'id': 18, 'name': 'Drama'},
            <String, dynamic>{'id': 80, 'name': 'Crime'},
          ],
          'first_air_date': '2008-01-20',
          'number_of_seasons': 5,
          'number_of_episodes': 62,
          'vote_average': 8.912,
          'status': 'Ended',
        };

        final TvShow show = TvShow.fromJson(json);

        expect(show.tmdbId, 1396);
        expect(show.title, 'Breaking Bad');
        expect(show.originalTitle, 'Breaking Bad');
        expect(show.posterUrl,
            'https://image.tmdb.org/t/p/w500/ggFHVNu6YYI5L9pCfOacjizRGt.jpg');
        expect(show.backdropUrl,
            'https://image.tmdb.org/t/p/w780/tsRy63Mu5cu8etL1X7ZLyf7UP1M.jpg');
        expect(show.overview,
            'A high school chemistry teacher diagnosed with cancer...');
        expect(show.genres, <String>['Drama', 'Crime']);
        expect(show.firstAirYear, 2008);
        expect(show.totalSeasons, 5);
        expect(show.totalEpisodes, 62);
        expect(show.rating, 8.912);
        expect(show.status, 'Ended');
        expect(show.cachedAt, isNotNull);
      });

      test('должен создать из минимального JSON (только id и name)', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1396,
          'name': 'Breaking Bad',
        };

        final TvShow show = TvShow.fromJson(json);

        expect(show.tmdbId, 1396);
        expect(show.title, 'Breaking Bad');
        expect(show.originalTitle, isNull);
        expect(show.posterUrl, isNull);
        expect(show.backdropUrl, isNull);
        expect(show.overview, isNull);
        expect(show.genres, isNull);
        expect(show.firstAirYear, isNull);
        expect(show.totalSeasons, isNull);
        expect(show.totalEpisodes, isNull);
        expect(show.rating, isNull);
        expect(show.status, isNull);
        expect(show.cachedAt, isNotNull);
      });

      test('должен использовать title если name отсутствует', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1396,
          'title': 'Breaking Bad via title',
        };

        final TvShow show = TvShow.fromJson(json);

        expect(show.title, 'Breaking Bad via title');
      });

      test('должен предпочитать name перед title', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1396,
          'name': 'Name Value',
          'title': 'Title Value',
        };

        final TvShow show = TvShow.fromJson(json);

        expect(show.title, 'Name Value');
      });

      test('должен использовать original_title если original_name отсутствует',
          () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1396,
          'name': 'Breaking Bad',
          'original_title': 'Original via title',
        };

        final TvShow show = TvShow.fromJson(json);

        expect(show.originalTitle, 'Original via title');
      });

      test('должен предпочитать original_name перед original_title', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1396,
          'name': 'Breaking Bad',
          'original_name': 'Original Name',
          'original_title': 'Original Title',
        };

        final TvShow show = TvShow.fromJson(json);

        expect(show.originalTitle, 'Original Name');
      });

      test('должен обработать genre_ids вместо genres', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1396,
          'name': 'Breaking Bad',
          'genre_ids': <int>[18, 80],
        };

        final TvShow show = TvShow.fromJson(json);

        expect(show.genres, <String>['18', '80']);
      });

      test('должен предпочитать genres перед genre_ids', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1396,
          'name': 'Breaking Bad',
          'genres': <Map<String, dynamic>>[
            <String, dynamic>{'id': 18, 'name': 'Drama'},
          ],
          'genre_ids': <int>[18, 80],
        };

        final TvShow show = TvShow.fromJson(json);

        expect(show.genres, <String>['Drama']);
      });

      test('должен обработать null poster_path и backdrop_path', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1396,
          'name': 'Breaking Bad',
          'poster_path': null,
          'backdrop_path': null,
        };

        final TvShow show = TvShow.fromJson(json);

        expect(show.posterUrl, isNull);
        expect(show.backdropUrl, isNull);
      });

      test('должен обработать отсутствующие poster_path и backdrop_path', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1396,
          'name': 'Breaking Bad',
        };

        final TvShow show = TvShow.fromJson(json);

        expect(show.posterUrl, isNull);
        expect(show.backdropUrl, isNull);
      });

      test('должен обработать пустую строку first_air_date', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1396,
          'name': 'Breaking Bad',
          'first_air_date': '',
        };

        final TvShow show = TvShow.fromJson(json);

        expect(show.firstAirYear, isNull);
      });

      test('должен обработать null first_air_date', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1396,
          'name': 'Breaking Bad',
          'first_air_date': null,
        };

        final TvShow show = TvShow.fromJson(json);

        expect(show.firstAirYear, isNull);
      });

      test(
          'должен обработать короткую строку first_air_date (менее 4 символов)',
          () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1396,
          'name': 'Breaking Bad',
          'first_air_date': '20',
        };

        final TvShow show = TvShow.fromJson(json);

        expect(show.firstAirYear, isNull);
      });

      test('должен обработать vote_average как int', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1396,
          'name': 'Breaking Bad',
          'vote_average': 9,
        };

        final TvShow show = TvShow.fromJson(json);

        expect(show.rating, 9.0);
      });

      test('должен обработать null vote_average', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1396,
          'name': 'Breaking Bad',
          'vote_average': null,
        };

        final TvShow show = TvShow.fromJson(json);

        expect(show.rating, isNull);
      });

      test('должен обработать null number_of_seasons и number_of_episodes',
          () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1396,
          'name': 'Breaking Bad',
          'number_of_seasons': null,
          'number_of_episodes': null,
        };

        final TvShow show = TvShow.fromJson(json);

        expect(show.totalSeasons, isNull);
        expect(show.totalEpisodes, isNull);
      });

      test('должен обработать null status', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1396,
          'name': 'Breaking Bad',
          'status': null,
        };

        final TvShow show = TvShow.fromJson(json);

        expect(show.status, isNull);
      });

      test('должен обработать пустой массив genres', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1396,
          'name': 'Breaking Bad',
          'genres': <Map<String, dynamic>>[],
        };

        final TvShow show = TvShow.fromJson(json);

        expect(show.genres, <String>[]);
      });
    });

    group('fromDb', () {
      test('должен создать из полной записи БД', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'tmdb_id': 1396,
          'title': 'Breaking Bad',
          'original_title': 'Breaking Bad',
          'poster_url': 'https://image.tmdb.org/t/p/w500/poster.jpg',
          'backdrop_url': 'https://image.tmdb.org/t/p/w780/backdrop.jpg',
          'overview': 'A chemistry teacher...',
          'genres': jsonEncode(<String>['Drama', 'Crime']),
          'first_air_year': 2008,
          'total_seasons': 5,
          'total_episodes': 62,
          'rating': 8.9,
          'status': 'Ended',
          'cached_at': 1700000000,
        };

        final TvShow show = TvShow.fromDb(row);

        expect(show.tmdbId, 1396);
        expect(show.title, 'Breaking Bad');
        expect(show.originalTitle, 'Breaking Bad');
        expect(show.posterUrl, 'https://image.tmdb.org/t/p/w500/poster.jpg');
        expect(
            show.backdropUrl, 'https://image.tmdb.org/t/p/w780/backdrop.jpg');
        expect(show.overview, 'A chemistry teacher...');
        expect(show.genres, <String>['Drama', 'Crime']);
        expect(show.firstAirYear, 2008);
        expect(show.totalSeasons, 5);
        expect(show.totalEpisodes, 62);
        expect(show.rating, 8.9);
        expect(show.status, 'Ended');
        expect(show.cachedAt, 1700000000);
      });

      test('должен обработать null genres', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'tmdb_id': 1396,
          'title': 'Breaking Bad',
          'original_title': null,
          'poster_url': null,
          'backdrop_url': null,
          'overview': null,
          'genres': null,
          'first_air_year': null,
          'total_seasons': null,
          'total_episodes': null,
          'rating': null,
          'status': null,
          'cached_at': null,
        };

        final TvShow show = TvShow.fromDb(row);

        expect(show.tmdbId, 1396);
        expect(show.title, 'Breaking Bad');
        expect(show.genres, isNull);
        expect(show.originalTitle, isNull);
        expect(show.posterUrl, isNull);
        expect(show.backdropUrl, isNull);
        expect(show.overview, isNull);
        expect(show.firstAirYear, isNull);
        expect(show.totalSeasons, isNull);
        expect(show.totalEpisodes, isNull);
        expect(show.rating, isNull);
        expect(show.status, isNull);
        expect(show.cachedAt, isNull);
      });

      test('должен обработать пустую строку genres', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'tmdb_id': 1396,
          'title': 'Breaking Bad',
          'original_title': null,
          'poster_url': null,
          'backdrop_url': null,
          'overview': null,
          'genres': '',
          'first_air_year': null,
          'total_seasons': null,
          'total_episodes': null,
          'rating': null,
          'status': null,
          'cached_at': null,
        };

        final TvShow show = TvShow.fromDb(row);

        expect(show.genres, isNull);
      });
    });

    group('toDb', () {
      test('должен преобразовать в Map для БД', () {
        const TvShow show = TvShow(
          tmdbId: 1396,
          title: 'Breaking Bad',
          originalTitle: 'Breaking Bad',
          posterUrl: 'https://image.tmdb.org/t/p/w500/poster.jpg',
          backdropUrl: 'https://image.tmdb.org/t/p/w780/backdrop.jpg',
          overview: 'A chemistry teacher...',
          genres: <String>['Drama', 'Crime'],
          firstAirYear: 2008,
          totalSeasons: 5,
          totalEpisodes: 62,
          rating: 8.9,
          status: 'Ended',
          cachedAt: 1700000000,
        );

        final Map<String, dynamic> db = show.toDb();

        expect(db['tmdb_id'], 1396);
        expect(db['title'], 'Breaking Bad');
        expect(db['original_title'], 'Breaking Bad');
        expect(db['poster_url'], 'https://image.tmdb.org/t/p/w500/poster.jpg');
        expect(
            db['backdrop_url'], 'https://image.tmdb.org/t/p/w780/backdrop.jpg');
        expect(db['overview'], 'A chemistry teacher...');
        expect(db['genres'], jsonEncode(<String>['Drama', 'Crime']));
        expect(db['first_air_year'], 2008);
        expect(db['total_seasons'], 5);
        expect(db['total_episodes'], 62);
        expect(db['rating'], 8.9);
        expect(db['status'], 'Ended');
        expect(db['cached_at'], 1700000000);
      });

      test('должен обработать null значения', () {
        const TvShow show = TvShow(
          tmdbId: 1396,
          title: 'Breaking Bad',
        );

        final Map<String, dynamic> db = show.toDb();

        expect(db['tmdb_id'], 1396);
        expect(db['title'], 'Breaking Bad');
        expect(db['original_title'], isNull);
        expect(db['poster_url'], isNull);
        expect(db['backdrop_url'], isNull);
        expect(db['overview'], isNull);
        expect(db['genres'], isNull);
        expect(db['first_air_year'], isNull);
        expect(db['total_seasons'], isNull);
        expect(db['total_episodes'], isNull);
        expect(db['rating'], isNull);
        expect(db['status'], isNull);
        expect(db['cached_at'], isNull);
      });
    });

    group('toDb/fromDb round-trip', () {
      test('должен сохранить и восстановить все данные', () {
        const TvShow original = TvShow(
          tmdbId: 1396,
          title: 'Breaking Bad',
          originalTitle: 'Breaking Bad',
          posterUrl: 'https://image.tmdb.org/t/p/w500/poster.jpg',
          backdropUrl: 'https://image.tmdb.org/t/p/w780/backdrop.jpg',
          overview: 'A chemistry teacher...',
          genres: <String>['Drama', 'Crime', 'Thriller'],
          firstAirYear: 2008,
          totalSeasons: 5,
          totalEpisodes: 62,
          rating: 8.9,
          status: 'Ended',
          cachedAt: 1700000000,
        );

        final Map<String, dynamic> db = original.toDb();
        final TvShow restored = TvShow.fromDb(db);

        expect(restored.tmdbId, original.tmdbId);
        expect(restored.title, original.title);
        expect(restored.originalTitle, original.originalTitle);
        expect(restored.posterUrl, original.posterUrl);
        expect(restored.backdropUrl, original.backdropUrl);
        expect(restored.overview, original.overview);
        expect(restored.genres, original.genres);
        expect(restored.firstAirYear, original.firstAirYear);
        expect(restored.totalSeasons, original.totalSeasons);
        expect(restored.totalEpisodes, original.totalEpisodes);
        expect(restored.rating, original.rating);
        expect(restored.status, original.status);
        expect(restored.cachedAt, original.cachedAt);
      });

      test('должен сохранить и восстановить минимальные данные', () {
        const TvShow original = TvShow(
          tmdbId: 1396,
          title: 'Breaking Bad',
        );

        final Map<String, dynamic> db = original.toDb();
        final TvShow restored = TvShow.fromDb(db);

        expect(restored.tmdbId, original.tmdbId);
        expect(restored.title, original.title);
        expect(restored.genres, isNull);
        expect(restored.rating, isNull);
        expect(restored.status, isNull);
      });
    });

    group('copyWith', () {
      test('должен создать копию с изменёнными полями', () {
        const TvShow original = TvShow(
          tmdbId: 1396,
          title: 'Breaking Bad',
          rating: 8.9,
          totalSeasons: 5,
        );

        final TvShow copy = original.copyWith(
          title: 'Breaking Bad (Updated)',
          rating: 9.5,
        );

        expect(copy.tmdbId, 1396);
        expect(copy.title, 'Breaking Bad (Updated)');
        expect(copy.rating, 9.5);
        expect(copy.totalSeasons, 5);
      });

      test('должен сохранить неизменённые поля', () {
        const TvShow original = TvShow(
          tmdbId: 1396,
          title: 'Breaking Bad',
          originalTitle: 'Breaking Bad',
          posterUrl: 'https://example.com/poster.jpg',
          backdropUrl: 'https://example.com/backdrop.jpg',
          overview: 'Description',
          genres: <String>['Drama'],
          firstAirYear: 2008,
          totalSeasons: 5,
          totalEpisodes: 62,
          rating: 8.9,
          status: 'Ended',
          cachedAt: 1700000000,
        );

        final TvShow copy = original.copyWith(title: 'Updated');

        expect(copy.tmdbId, 1396);
        expect(copy.originalTitle, 'Breaking Bad');
        expect(copy.posterUrl, 'https://example.com/poster.jpg');
        expect(copy.backdropUrl, 'https://example.com/backdrop.jpg');
        expect(copy.overview, 'Description');
        expect(copy.genres, <String>['Drama']);
        expect(copy.firstAirYear, 2008);
        expect(copy.totalSeasons, 5);
        expect(copy.totalEpisodes, 62);
        expect(copy.rating, 8.9);
        expect(copy.status, 'Ended');
        expect(copy.cachedAt, 1700000000);
      });

      test('должен позволить изменить все поля', () {
        const TvShow original = TvShow(
          tmdbId: 1,
          title: 'Original',
        );

        final TvShow copy = original.copyWith(
          tmdbId: 2,
          title: 'New Title',
          originalTitle: 'New Original',
          posterUrl: 'new_poster',
          backdropUrl: 'new_backdrop',
          overview: 'new overview',
          genres: <String>['Comedy'],
          firstAirYear: 2025,
          totalSeasons: 3,
          totalEpisodes: 30,
          rating: 7.5,
          status: 'Returning Series',
          cachedAt: 9999999,
        );

        expect(copy.tmdbId, 2);
        expect(copy.title, 'New Title');
        expect(copy.originalTitle, 'New Original');
        expect(copy.posterUrl, 'new_poster');
        expect(copy.backdropUrl, 'new_backdrop');
        expect(copy.overview, 'new overview');
        expect(copy.genres, <String>['Comedy']);
        expect(copy.firstAirYear, 2025);
        expect(copy.totalSeasons, 3);
        expect(copy.totalEpisodes, 30);
        expect(copy.rating, 7.5);
        expect(copy.status, 'Returning Series');
        expect(copy.cachedAt, 9999999);
      });
    });

    group('equality', () {
      test('сериалы с одинаковым tmdbId должны быть равны', () {
        const TvShow show1 = TvShow(tmdbId: 1396, title: 'Breaking Bad');
        const TvShow show2 = TvShow(tmdbId: 1396, title: 'Another Title');

        expect(show1, equals(show2));
        expect(show1.hashCode, equals(show2.hashCode));
      });

      test('сериалы с разными tmdbId не должны быть равны', () {
        const TvShow show1 = TvShow(tmdbId: 1396, title: 'Breaking Bad');
        const TvShow show2 = TvShow(tmdbId: 1399, title: 'Breaking Bad');

        expect(show1, isNot(equals(show2)));
      });

      test('идентичные объекты должны быть равны', () {
        const TvShow show = TvShow(tmdbId: 1396, title: 'Breaking Bad');

        expect(show, equals(show));
      });

      test('сравнение с другим типом не должно быть равно', () {
        const TvShow show = TvShow(tmdbId: 1396, title: 'Breaking Bad');

        // ignore: unrelated_type_equality_checks
        expect(show == 'not a show', isFalse);
      });
    });

    group('computed properties', () {
      test('formattedRating должен вернуть рейтинг с одним десятичным знаком',
          () {
        const TvShow show =
            TvShow(tmdbId: 1, title: 'Test', rating: 8.912);

        expect(show.formattedRating, '8.9');
      });

      test('formattedRating должен вернуть null при отсутствии рейтинга', () {
        const TvShow show = TvShow(tmdbId: 1, title: 'Test');

        expect(show.formattedRating, isNull);
      });

      test('formattedRating должен отформатировать целый рейтинг', () {
        const TvShow show =
            TvShow(tmdbId: 1, title: 'Test', rating: 9.0);

        expect(show.formattedRating, '9.0');
      });

      test('formattedRating должен отформатировать нулевой рейтинг', () {
        const TvShow show =
            TvShow(tmdbId: 1, title: 'Test', rating: 0.0);

        expect(show.formattedRating, '0.0');
      });

      test('genresString должен объединить жанры через запятую', () {
        const TvShow show = TvShow(
          tmdbId: 1,
          title: 'Test',
          genres: <String>['Drama', 'Crime', 'Thriller'],
        );

        expect(show.genresString, 'Drama, Crime, Thriller');
      });

      test('genresString должен вернуть null при отсутствии жанров', () {
        const TvShow show = TvShow(tmdbId: 1, title: 'Test');

        expect(show.genresString, isNull);
      });

      test('genresString должен обработать один жанр', () {
        const TvShow show = TvShow(
          tmdbId: 1,
          title: 'Test',
          genres: <String>['Drama'],
        );

        expect(show.genresString, 'Drama');
      });

      test('genresString должен обработать пустой список жанров', () {
        const TvShow show = TvShow(
          tmdbId: 1,
          title: 'Test',
          genres: <String>[],
        );

        expect(show.genresString, '');
      });
    });

    test('toString должен вернуть читаемое представление', () {
      const TvShow show = TvShow(tmdbId: 1396, title: 'Breaking Bad');

      expect(show.toString(), 'TvShow(tmdbId: 1396, title: Breaking Bad)');
    });

    test('toString должен работать с Unicode в названии', () {
      const TvShow show =
          TvShow(tmdbId: 100, title: 'Игра Престолов');

      expect(show.toString(),
          'TvShow(tmdbId: 100, title: Игра Престолов)');
    });
  });
}
