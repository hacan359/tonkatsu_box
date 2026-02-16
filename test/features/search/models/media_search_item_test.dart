import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/search/models/media_search_item.dart';
import 'package:xerabora/shared/models/movie.dart';
import 'package:xerabora/shared/models/tv_show.dart';

void main() {
  group('MediaSearchItemType', () {
    test('has movie and tvShow values', () {
      expect(MediaSearchItemType.values, hasLength(2));
      expect(MediaSearchItemType.movie, isNotNull);
      expect(MediaSearchItemType.tvShow, isNotNull);
    });
  });

  group('MediaSearchItem', () {
    group('fromMovie', () {
      test('creates item from movie', () {
        const Movie movie = Movie(
          tmdbId: 1,
          title: 'Test Movie',
          releaseYear: 2024,
          rating: 8.5,
          posterUrl: 'https://image.tmdb.org/poster.jpg',
          genres: <String>['Action', 'Drama'],
        );

        const MediaSearchItem item = MediaSearchItem.fromMovie(movie);

        expect(item.type, MediaSearchItemType.movie);
        expect(item.movie, movie);
        expect(item.tvShow, isNull);
      });

      test('delegates getters to movie', () {
        const Movie movie = Movie(
          tmdbId: 42,
          title: 'Inception',
          releaseYear: 2010,
          rating: 8.8,
          posterUrl: 'https://image.tmdb.org/inception.jpg',
          genres: <String>['Sci-Fi', 'Thriller'],
        );

        const MediaSearchItem item = MediaSearchItem.fromMovie(movie);

        expect(item.title, 'Inception');
        expect(item.year, 2010);
        expect(item.rating, 8.8);
        expect(item.posterUrl, 'https://image.tmdb.org/inception.jpg');
        expect(item.genres, <String>['Sci-Fi', 'Thriller']);
        expect(item.tmdbId, 42);
      });
    });

    group('fromTvShow', () {
      test('creates item from tv show', () {
        const TvShow tvShow = TvShow(
          tmdbId: 2,
          title: 'Test Show',
          firstAirYear: 2023,
          rating: 7.5,
          posterUrl: 'https://image.tmdb.org/show.jpg',
          genres: <String>['Comedy'],
        );

        const MediaSearchItem item = MediaSearchItem.fromTvShow(tvShow);

        expect(item.type, MediaSearchItemType.tvShow);
        expect(item.tvShow, tvShow);
        expect(item.movie, isNull);
      });

      test('delegates getters to tv show', () {
        const TvShow tvShow = TvShow(
          tmdbId: 99,
          title: 'Breaking Bad',
          firstAirYear: 2008,
          rating: 9.5,
          posterUrl: 'https://image.tmdb.org/bb.jpg',
          genres: <String>['Drama', 'Crime'],
        );

        const MediaSearchItem item = MediaSearchItem.fromTvShow(tvShow);

        expect(item.title, 'Breaking Bad');
        expect(item.year, 2008);
        expect(item.rating, 9.5);
        expect(item.posterUrl, 'https://image.tmdb.org/bb.jpg');
        expect(item.genres, <String>['Drama', 'Crime']);
        expect(item.tmdbId, 99);
      });
    });

    group('isAnimation', () {
      test('returns true when genres contain Animation string', () {
        const Movie movie = Movie(
          tmdbId: 1,
          title: 'Spirited Away',
          genres: <String>['Animation', 'Fantasy'],
        );

        const MediaSearchItem item = MediaSearchItem.fromMovie(movie);

        expect(item.isAnimation, isTrue);
      });

      test('returns true when genres contain genre ID 16', () {
        const Movie movie = Movie(
          tmdbId: 1,
          title: 'Spirited Away',
          genres: <String>['16', '14'],
        );

        const MediaSearchItem item = MediaSearchItem.fromMovie(movie);

        expect(item.isAnimation, isTrue);
      });

      test('returns false when genres do not contain animation', () {
        const Movie movie = Movie(
          tmdbId: 1,
          title: 'Inception',
          genres: <String>['Action', 'Sci-Fi'],
        );

        const MediaSearchItem item = MediaSearchItem.fromMovie(movie);

        expect(item.isAnimation, isFalse);
      });

      test('returns false when genres is null', () {
        const Movie movie = Movie(tmdbId: 1, title: 'No Genres');

        const MediaSearchItem item = MediaSearchItem.fromMovie(movie);

        expect(item.isAnimation, isFalse);
      });

      test('returns false when genres is empty', () {
        const Movie movie = Movie(
          tmdbId: 1,
          title: 'Empty Genres',
          genres: <String>[],
        );

        const MediaSearchItem item = MediaSearchItem.fromMovie(movie);

        expect(item.isAnimation, isFalse);
      });

      test('works for tv shows with Animation genre', () {
        const TvShow tvShow = TvShow(
          tmdbId: 1,
          title: 'Attack on Titan',
          genres: <String>['Animation', 'Action'],
        );

        const MediaSearchItem item = MediaSearchItem.fromTvShow(tvShow);

        expect(item.isAnimation, isTrue);
      });

      test('works for tv shows with genre ID 16', () {
        const TvShow tvShow = TvShow(
          tmdbId: 1,
          title: 'Naruto',
          genres: <String>['16', '10759'],
        );

        const MediaSearchItem item = MediaSearchItem.fromTvShow(tvShow);

        expect(item.isAnimation, isTrue);
      });
    });

    group('nullable getters', () {
      test('returns null year for movie without release year', () {
        const Movie movie = Movie(tmdbId: 1, title: 'No Year');

        const MediaSearchItem item = MediaSearchItem.fromMovie(movie);

        expect(item.year, isNull);
      });

      test('returns null rating for movie without rating', () {
        const Movie movie = Movie(tmdbId: 1, title: 'No Rating');

        const MediaSearchItem item = MediaSearchItem.fromMovie(movie);

        expect(item.rating, isNull);
      });

      test('returns null posterUrl for movie without poster', () {
        const Movie movie = Movie(tmdbId: 1, title: 'No Poster');

        const MediaSearchItem item = MediaSearchItem.fromMovie(movie);

        expect(item.posterUrl, isNull);
      });

      test('returns null genres for movie without genres', () {
        const Movie movie = Movie(tmdbId: 1, title: 'No Genres');

        const MediaSearchItem item = MediaSearchItem.fromMovie(movie);

        expect(item.genres, isNull);
      });

      test('returns null year for tv show without first air year', () {
        const TvShow tvShow = TvShow(tmdbId: 1, title: 'No Year');

        const MediaSearchItem item = MediaSearchItem.fromTvShow(tvShow);

        expect(item.year, isNull);
      });
    });

    group('equality', () {
      test('movie items with same tmdbId are equal', () {
        const MediaSearchItem item1 = MediaSearchItem.fromMovie(
          Movie(tmdbId: 1, title: 'Movie A'),
        );
        const MediaSearchItem item2 = MediaSearchItem.fromMovie(
          Movie(tmdbId: 1, title: 'Movie B'),
        );

        expect(item1, equals(item2));
        expect(item1.hashCode, equals(item2.hashCode));
      });

      test('movie items with different tmdbId are not equal', () {
        const MediaSearchItem item1 = MediaSearchItem.fromMovie(
          Movie(tmdbId: 1, title: 'Movie'),
        );
        const MediaSearchItem item2 = MediaSearchItem.fromMovie(
          Movie(tmdbId: 2, title: 'Movie'),
        );

        expect(item1, isNot(equals(item2)));
      });

      test('tv show items with same tmdbId are equal', () {
        const MediaSearchItem item1 = MediaSearchItem.fromTvShow(
          TvShow(tmdbId: 1, title: 'Show A'),
        );
        const MediaSearchItem item2 = MediaSearchItem.fromTvShow(
          TvShow(tmdbId: 1, title: 'Show B'),
        );

        expect(item1, equals(item2));
        expect(item1.hashCode, equals(item2.hashCode));
      });

      test('movie and tv show with same tmdbId are not equal', () {
        const MediaSearchItem movieItem = MediaSearchItem.fromMovie(
          Movie(tmdbId: 1, title: 'Movie'),
        );
        const MediaSearchItem tvItem = MediaSearchItem.fromTvShow(
          TvShow(tmdbId: 1, title: 'Show'),
        );

        expect(movieItem, isNot(equals(tvItem)));
      });

      test('identical items return true', () {
        const MediaSearchItem item = MediaSearchItem.fromMovie(
          Movie(tmdbId: 1, title: 'Movie'),
        );

        expect(item == item, isTrue);
      });
    });
  });
}
