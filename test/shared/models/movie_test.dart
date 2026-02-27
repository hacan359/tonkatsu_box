// Тесты для модели Movie.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/movie.dart';

void main() {
  group('Movie', () {
    group('fromJson', () {
      test('должен создать из полного JSON', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 27205,
          'title': 'Inception',
          'original_title': 'Inception',
          'poster_path': '/qmDpIHrmpJINaRKAfWQfftjCdyi.jpg',
          'backdrop_path': '/s3TBrRGB1iav7gFOCNx3H31MoES.jpg',
          'overview': 'A thief who steals corporate secrets...',
          'genres': <Map<String, dynamic>>[
            <String, dynamic>{'id': 28, 'name': 'Action'},
            <String, dynamic>{'id': 878, 'name': 'Science Fiction'},
            <String, dynamic>{'id': 12, 'name': 'Adventure'},
          ],
          'release_date': '2010-07-16',
          'vote_average': 8.364,
          'runtime': 148,
        };

        final Movie movie = Movie.fromJson(json);

        expect(movie.tmdbId, 27205);
        expect(movie.title, 'Inception');
        expect(movie.originalTitle, 'Inception');
        expect(movie.posterUrl,
            'https://image.tmdb.org/t/p/w342/qmDpIHrmpJINaRKAfWQfftjCdyi.jpg');
        expect(movie.backdropUrl,
            'https://image.tmdb.org/t/p/w780/s3TBrRGB1iav7gFOCNx3H31MoES.jpg');
        expect(movie.overview, 'A thief who steals corporate secrets...');
        expect(
            movie.genres, <String>['Action', 'Science Fiction', 'Adventure']);
        expect(movie.releaseYear, 2010);
        expect(movie.rating, 8.364);
        expect(movie.runtime, 148);
        expect(movie.cachedAt, isNotNull);
        expect(movie.externalUrl, 'https://www.themoviedb.org/movie/27205');
      });

      test('должен создать из минимального JSON (только id и title)', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 550,
          'title': 'Fight Club',
        };

        final Movie movie = Movie.fromJson(json);

        expect(movie.tmdbId, 550);
        expect(movie.title, 'Fight Club');
        expect(movie.originalTitle, isNull);
        expect(movie.posterUrl, isNull);
        expect(movie.backdropUrl, isNull);
        expect(movie.overview, isNull);
        expect(movie.genres, isNull);
        expect(movie.releaseYear, isNull);
        expect(movie.rating, isNull);
        expect(movie.runtime, isNull);
        expect(movie.cachedAt, isNotNull);
        expect(movie.externalUrl, 'https://www.themoviedb.org/movie/550');
      });

      test('должен обработать genre_ids вместо genres', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 550,
          'title': 'Fight Club',
          'genre_ids': <int>[18, 53, 35],
        };

        final Movie movie = Movie.fromJson(json);

        expect(movie.genres, <String>['18', '53', '35']);
      });

      test('должен предпочитать genres перед genre_ids', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 550,
          'title': 'Fight Club',
          'genres': <Map<String, dynamic>>[
            <String, dynamic>{'id': 18, 'name': 'Drama'},
          ],
          'genre_ids': <int>[18, 53],
        };

        final Movie movie = Movie.fromJson(json);

        expect(movie.genres, <String>['Drama']);
      });

      test('должен обработать null poster_path и backdrop_path', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 999,
          'title': 'No Poster Movie',
          'poster_path': null,
          'backdrop_path': null,
        };

        final Movie movie = Movie.fromJson(json);

        expect(movie.posterUrl, isNull);
        expect(movie.backdropUrl, isNull);
      });

      test('должен обработать отсутствующие poster_path и backdrop_path', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 999,
          'title': 'No Poster Movie',
        };

        final Movie movie = Movie.fromJson(json);

        expect(movie.posterUrl, isNull);
        expect(movie.backdropUrl, isNull);
      });

      test('должен обработать пустую строку release_date', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 999,
          'title': 'Unknown Date Movie',
          'release_date': '',
        };

        final Movie movie = Movie.fromJson(json);

        expect(movie.releaseYear, isNull);
      });

      test('должен обработать null release_date', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 999,
          'title': 'Null Date Movie',
          'release_date': null,
        };

        final Movie movie = Movie.fromJson(json);

        expect(movie.releaseYear, isNull);
      });

      test('должен обработать короткую строку release_date (менее 4 символов)',
          () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 999,
          'title': 'Short Date Movie',
          'release_date': '20',
        };

        final Movie movie = Movie.fromJson(json);

        expect(movie.releaseYear, isNull);
      });

      test('должен обработать vote_average как int', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 550,
          'title': 'Fight Club',
          'vote_average': 8,
        };

        final Movie movie = Movie.fromJson(json);

        expect(movie.rating, 8.0);
      });

      test('должен обработать null vote_average', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 550,
          'title': 'Fight Club',
          'vote_average': null,
        };

        final Movie movie = Movie.fromJson(json);

        expect(movie.rating, isNull);
      });

      test('должен обработать null overview и original_title', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 550,
          'title': 'Fight Club',
          'overview': null,
          'original_title': null,
        };

        final Movie movie = Movie.fromJson(json);

        expect(movie.overview, isNull);
        expect(movie.originalTitle, isNull);
      });

      test('должен обработать null runtime', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 550,
          'title': 'Fight Club',
          'runtime': null,
        };

        final Movie movie = Movie.fromJson(json);

        expect(movie.runtime, isNull);
      });

      test('должен обработать пустой массив genres', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 550,
          'title': 'Fight Club',
          'genres': <Map<String, dynamic>>[],
        };

        final Movie movie = Movie.fromJson(json);

        expect(movie.genres, <String>[]);
      });
    });

    group('fromDb', () {
      test('должен создать из полной записи БД', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'tmdb_id': 27205,
          'title': 'Inception',
          'original_title': 'Inception',
          'poster_url': 'https://image.tmdb.org/t/p/w500/poster.jpg',
          'backdrop_url': 'https://image.tmdb.org/t/p/w780/backdrop.jpg',
          'overview': 'A thief who steals corporate secrets...',
          'genres': jsonEncode(<String>['Action', 'Science Fiction']),
          'release_year': 2010,
          'rating': 8.4,
          'runtime': 148,
          'cached_at': 1700000000,
          'external_url': 'https://www.themoviedb.org/movie/27205',
        };

        final Movie movie = Movie.fromDb(row);

        expect(movie.tmdbId, 27205);
        expect(movie.title, 'Inception');
        expect(movie.originalTitle, 'Inception');
        expect(movie.posterUrl, 'https://image.tmdb.org/t/p/w500/poster.jpg');
        expect(
            movie.backdropUrl, 'https://image.tmdb.org/t/p/w780/backdrop.jpg');
        expect(movie.overview, 'A thief who steals corporate secrets...');
        expect(movie.genres, <String>['Action', 'Science Fiction']);
        expect(movie.releaseYear, 2010);
        expect(movie.rating, 8.4);
        expect(movie.runtime, 148);
        expect(movie.cachedAt, 1700000000);
        expect(movie.externalUrl, 'https://www.themoviedb.org/movie/27205');
      });

      test('должен обработать null genres', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'tmdb_id': 550,
          'title': 'Fight Club',
          'original_title': null,
          'poster_url': null,
          'backdrop_url': null,
          'overview': null,
          'genres': null,
          'release_year': null,
          'rating': null,
          'runtime': null,
          'cached_at': null,
          'external_url': null,
        };

        final Movie movie = Movie.fromDb(row);

        expect(movie.tmdbId, 550);
        expect(movie.title, 'Fight Club');
        expect(movie.genres, isNull);
        expect(movie.originalTitle, isNull);
        expect(movie.posterUrl, isNull);
        expect(movie.backdropUrl, isNull);
        expect(movie.overview, isNull);
        expect(movie.releaseYear, isNull);
        expect(movie.rating, isNull);
        expect(movie.runtime, isNull);
        expect(movie.cachedAt, isNull);
        expect(movie.externalUrl, isNull);
      });

      test('должен обработать пустую строку genres', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'tmdb_id': 550,
          'title': 'Fight Club',
          'original_title': null,
          'poster_url': null,
          'backdrop_url': null,
          'overview': null,
          'genres': '',
          'release_year': null,
          'rating': null,
          'runtime': null,
          'cached_at': null,
        };

        final Movie movie = Movie.fromDb(row);

        expect(movie.genres, isNull);
      });
    });

    group('toDb', () {
      test('должен преобразовать в Map для БД', () {
        const Movie movie = Movie(
          tmdbId: 27205,
          title: 'Inception',
          originalTitle: 'Inception',
          posterUrl: 'https://image.tmdb.org/t/p/w500/poster.jpg',
          backdropUrl: 'https://image.tmdb.org/t/p/w780/backdrop.jpg',
          overview: 'A thief who steals corporate secrets...',
          genres: <String>['Action', 'Science Fiction'],
          releaseYear: 2010,
          rating: 8.4,
          runtime: 148,
          cachedAt: 1700000000,
          externalUrl: 'https://www.themoviedb.org/movie/27205',
        );

        final Map<String, dynamic> db = movie.toDb();

        expect(db['tmdb_id'], 27205);
        expect(db['title'], 'Inception');
        expect(db['original_title'], 'Inception');
        expect(db['poster_url'], 'https://image.tmdb.org/t/p/w500/poster.jpg');
        expect(
            db['backdrop_url'], 'https://image.tmdb.org/t/p/w780/backdrop.jpg');
        expect(db['overview'], 'A thief who steals corporate secrets...');
        expect(db['genres'], jsonEncode(<String>['Action', 'Science Fiction']));
        expect(db['release_year'], 2010);
        expect(db['rating'], 8.4);
        expect(db['runtime'], 148);
        expect(db['cached_at'], 1700000000);
        expect(db['external_url'], 'https://www.themoviedb.org/movie/27205');
      });

      test('должен обработать null значения', () {
        const Movie movie = Movie(
          tmdbId: 550,
          title: 'Fight Club',
        );

        final Map<String, dynamic> db = movie.toDb();

        expect(db['tmdb_id'], 550);
        expect(db['title'], 'Fight Club');
        expect(db['original_title'], isNull);
        expect(db['poster_url'], isNull);
        expect(db['backdrop_url'], isNull);
        expect(db['overview'], isNull);
        expect(db['genres'], isNull);
        expect(db['release_year'], isNull);
        expect(db['rating'], isNull);
        expect(db['runtime'], isNull);
        expect(db['cached_at'], isNull);
        expect(db['external_url'], isNull);
      });
    });

    group('toDb/fromDb round-trip', () {
      test('должен сохранить и восстановить все данные', () {
        const Movie original = Movie(
          tmdbId: 27205,
          title: 'Inception',
          originalTitle: 'Inception',
          posterUrl: 'https://image.tmdb.org/t/p/w500/poster.jpg',
          backdropUrl: 'https://image.tmdb.org/t/p/w780/backdrop.jpg',
          overview: 'A thief who steals corporate secrets...',
          genres: <String>['Action', 'Science Fiction', 'Adventure'],
          releaseYear: 2010,
          rating: 8.4,
          runtime: 148,
          cachedAt: 1700000000,
          externalUrl: 'https://www.themoviedb.org/movie/27205',
        );

        final Map<String, dynamic> db = original.toDb();
        final Movie restored = Movie.fromDb(db);

        expect(restored.tmdbId, original.tmdbId);
        expect(restored.title, original.title);
        expect(restored.originalTitle, original.originalTitle);
        expect(restored.posterUrl, original.posterUrl);
        expect(restored.backdropUrl, original.backdropUrl);
        expect(restored.overview, original.overview);
        expect(restored.genres, original.genres);
        expect(restored.releaseYear, original.releaseYear);
        expect(restored.rating, original.rating);
        expect(restored.runtime, original.runtime);
        expect(restored.cachedAt, original.cachedAt);
        expect(restored.externalUrl, original.externalUrl);
      });

      test('должен сохранить и восстановить минимальные данные', () {
        const Movie original = Movie(
          tmdbId: 550,
          title: 'Fight Club',
        );

        final Map<String, dynamic> db = original.toDb();
        final Movie restored = Movie.fromDb(db);

        expect(restored.tmdbId, original.tmdbId);
        expect(restored.title, original.title);
        expect(restored.genres, isNull);
        expect(restored.rating, isNull);
        expect(restored.runtime, isNull);
      });
    });

    group('copyWith', () {
      test('должен создать копию с изменёнными полями', () {
        const Movie original = Movie(
          tmdbId: 27205,
          title: 'Inception',
          rating: 8.4,
          runtime: 148,
        );

        final Movie copy = original.copyWith(
          title: 'Inception (Updated)',
          rating: 9.0,
        );

        expect(copy.tmdbId, 27205);
        expect(copy.title, 'Inception (Updated)');
        expect(copy.rating, 9.0);
        expect(copy.runtime, 148);
      });

      test('должен сохранить неизменённые поля', () {
        const Movie original = Movie(
          tmdbId: 27205,
          title: 'Inception',
          originalTitle: 'Inception',
          posterUrl: 'https://example.com/poster.jpg',
          backdropUrl: 'https://example.com/backdrop.jpg',
          overview: 'Description',
          genres: <String>['Action'],
          releaseYear: 2010,
          rating: 8.4,
          runtime: 148,
          cachedAt: 1700000000,
          externalUrl: 'https://www.themoviedb.org/movie/27205',
        );

        final Movie copy = original.copyWith(title: 'Updated');

        expect(copy.tmdbId, 27205);
        expect(copy.originalTitle, 'Inception');
        expect(copy.posterUrl, 'https://example.com/poster.jpg');
        expect(copy.backdropUrl, 'https://example.com/backdrop.jpg');
        expect(copy.overview, 'Description');
        expect(copy.genres, <String>['Action']);
        expect(copy.releaseYear, 2010);
        expect(copy.rating, 8.4);
        expect(copy.runtime, 148);
        expect(copy.cachedAt, 1700000000);
        expect(copy.externalUrl, 'https://www.themoviedb.org/movie/27205');
      });

      test('должен позволить изменить все поля', () {
        const Movie original = Movie(
          tmdbId: 1,
          title: 'Original',
        );

        final Movie copy = original.copyWith(
          tmdbId: 2,
          title: 'New Title',
          originalTitle: 'New Original',
          posterUrl: 'new_poster',
          backdropUrl: 'new_backdrop',
          overview: 'new overview',
          genres: <String>['Drama'],
          releaseYear: 2025,
          rating: 7.5,
          runtime: 120,
          cachedAt: 9999999,
          externalUrl: 'https://www.themoviedb.org/movie/2',
        );

        expect(copy.tmdbId, 2);
        expect(copy.title, 'New Title');
        expect(copy.originalTitle, 'New Original');
        expect(copy.posterUrl, 'new_poster');
        expect(copy.backdropUrl, 'new_backdrop');
        expect(copy.overview, 'new overview');
        expect(copy.genres, <String>['Drama']);
        expect(copy.releaseYear, 2025);
        expect(copy.rating, 7.5);
        expect(copy.runtime, 120);
        expect(copy.cachedAt, 9999999);
        expect(copy.externalUrl, 'https://www.themoviedb.org/movie/2');
      });
    });

    group('equality', () {
      test('фильмы с одинаковым tmdbId должны быть равны', () {
        const Movie movie1 = Movie(tmdbId: 27205, title: 'Inception');
        const Movie movie2 = Movie(tmdbId: 27205, title: 'Another Title');

        expect(movie1, equals(movie2));
        expect(movie1.hashCode, equals(movie2.hashCode));
      });

      test('фильмы с разными tmdbId не должны быть равны', () {
        const Movie movie1 = Movie(tmdbId: 27205, title: 'Inception');
        const Movie movie2 = Movie(tmdbId: 550, title: 'Inception');

        expect(movie1, isNot(equals(movie2)));
      });

      test('идентичные объекты должны быть равны', () {
        const Movie movie = Movie(tmdbId: 27205, title: 'Inception');

        expect(movie, equals(movie));
      });

      test('сравнение с другим типом не должно быть равно', () {
        const Movie movie = Movie(tmdbId: 27205, title: 'Inception');

        // ignore: unrelated_type_equality_checks
        expect(movie == 'not a movie', isFalse);
      });
    });

    group('computed properties', () {
      test('formattedRating должен вернуть рейтинг с одним десятичным знаком',
          () {
        const Movie movie = Movie(tmdbId: 1, title: 'Test', rating: 8.364);

        expect(movie.formattedRating, '8.4');
      });

      test('formattedRating должен вернуть null при отсутствии рейтинга', () {
        const Movie movie = Movie(tmdbId: 1, title: 'Test');

        expect(movie.formattedRating, isNull);
      });

      test('formattedRating должен отформатировать целый рейтинг', () {
        const Movie movie = Movie(tmdbId: 1, title: 'Test', rating: 8.0);

        expect(movie.formattedRating, '8.0');
      });

      test('formattedRating должен отформатировать нулевой рейтинг', () {
        const Movie movie = Movie(tmdbId: 1, title: 'Test', rating: 0.0);

        expect(movie.formattedRating, '0.0');
      });

      test('genresString должен объединить жанры через запятую', () {
        const Movie movie = Movie(
          tmdbId: 1,
          title: 'Test',
          genres: <String>['Action', 'Science Fiction', 'Adventure'],
        );

        expect(movie.genresString, 'Action, Science Fiction, Adventure');
      });

      test('genresString должен вернуть null при отсутствии жанров', () {
        const Movie movie = Movie(tmdbId: 1, title: 'Test');

        expect(movie.genresString, isNull);
      });

      test('genresString должен обработать один жанр', () {
        const Movie movie = Movie(
          tmdbId: 1,
          title: 'Test',
          genres: <String>['Drama'],
        );

        expect(movie.genresString, 'Drama');
      });

      test('genresString должен обработать пустой список жанров', () {
        const Movie movie = Movie(
          tmdbId: 1,
          title: 'Test',
          genres: <String>[],
        );

        expect(movie.genresString, '');
      });
    });

    test('toString должен вернуть читаемое представление', () {
      const Movie movie = Movie(tmdbId: 27205, title: 'Inception');

      expect(movie.toString(), 'Movie(tmdbId: 27205, title: Inception)');
    });

    test('toString должен работать с Unicode в названии', () {
      const Movie movie =
          Movie(tmdbId: 100, title: 'Властелин Колец');

      expect(movie.toString(),
          'Movie(tmdbId: 100, title: Властелин Колец)');
    });
  });
}
