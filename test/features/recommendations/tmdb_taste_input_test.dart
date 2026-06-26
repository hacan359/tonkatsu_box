import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/recommendations/engine/recommendation_models.dart';
import 'package:tonkatsu_box/features/recommendations/tmdb_taste_input.dart';
import 'package:tonkatsu_box/shared/models/collection_item.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('tmdb_taste_input', () {
    // No genre maps: keyFor leaves every token untouched, so features stay
    // exactly the raw genre strings passed in.
    final GenreKeyResolver noGenres =
        GenreKeyResolver.fromGenreMaps(const <Map<String, String>>[]);

    group('engine ids', () {
      test('format movie and tv ids', () {
        expect(movieTasteId(603), 'movie:603');
        expect(tvTasteId(1396), 'tv:1396');
      });
    });

    group('GenreKeyResolver', () {
      final GenreKeyResolver resolver =
          GenreKeyResolver.fromGenreMaps(<Map<String, String>>[
        <String, String>{'28': 'Action', '18': 'Drama'},
        <String, String>{'28': 'Боевик', '18': 'Драма'},
      ]);

      test('passes a known id string through unchanged', () {
        expect(resolver.keyFor('28'), '28');
      });

      test('maps an English name to its id', () {
        expect(resolver.keyFor('Action'), '28');
        expect(resolver.keyFor('Drama'), '18');
      });

      test('maps a Russian name to the same id as the English one', () {
        expect(resolver.keyFor('Боевик'), '28');
        expect(resolver.keyFor('Drama'), resolver.keyFor('Драма'));
      });

      test('matches names case-insensitively', () {
        // TMDB returns Russian names lowercased; the DAO capitalises them.
        expect(resolver.keyFor('боевик'), '28');
        expect(resolver.keyFor('action'), '28');
      });

      test('returns an unknown token unchanged', () {
        expect(resolver.keyFor('Nonexistent'), 'Nonexistent');
      });

      test('hasId reports membership', () {
        expect(resolver.hasId('28'), isTrue);
        expect(resolver.hasId('999'), isFalse);
      });
    });

    group('tasteTitleFromItem', () {
      test('maps a completed movie with rating and favorite', () {
        final CollectionItem item = createTestCollectionItem(
          mediaType: MediaType.movie,
          userRating: 9,
          isFavorite: true,
          movie: createTestMovie(
            tmdbId: 550,
            title: 'Fight Club',
            genres: <String>['Drama'],
          ),
        );
        final TasteTitle? t = tasteTitleFromItem(
          item,
          movieGenres: noGenres,
          tvGenres: noGenres,
        );
        expect(t, isNotNull);
        expect(t!.id, 'movie:550');
        expect(t.label, 'Fight Club');
        expect(t.features['Drama'], 1.0);
        expect(t.rating, 9);
        expect(t.isFavorite, isTrue);
      });

      test('maps a completed TV show to a tv id', () {
        final CollectionItem item = createTestCollectionItem(
          mediaType: MediaType.tvShow,
          tvShow: createTestTvShow(tmdbId: 1396, genres: <String>['Crime']),
        );
        final TasteTitle? t = tasteTitleFromItem(
          item,
          movieGenres: noGenres,
          tvGenres: noGenres,
        );
        expect(t?.id, 'tv:1396');
      });

      test('prefers the override name as the label', () {
        final CollectionItem item = createTestCollectionItem(
          mediaType: MediaType.movie,
          overrideName: 'Custom Title',
          movie: createTestMovie(title: 'Original', genres: <String>['Drama']),
        );
        final TasteTitle? t = tasteTitleFromItem(
          item,
          movieGenres: noGenres,
          tvGenres: noGenres,
        );
        expect(t?.label, 'Custom Title');
      });

      test('collapses a numeric genre id and its name to the same key', () {
        final GenreKeyResolver movieGenres =
            GenreKeyResolver.fromGenreMaps(<Map<String, String>>[
          <String, String>{'28': 'Action'},
        ]);
        final TasteTitle? fromId = tasteTitleFromItem(
          createTestCollectionItem(
            mediaType: MediaType.movie,
            movie: createTestMovie(genres: <String>['28']),
          ),
          movieGenres: movieGenres,
          tvGenres: noGenres,
        );
        final TasteTitle? fromName = tasteTitleFromItem(
          createTestCollectionItem(
            mediaType: MediaType.movie,
            movie: createTestMovie(genres: <String>['Action']),
          ),
          movieGenres: movieGenres,
          tvGenres: noGenres,
        );
        expect(fromId?.features.containsKey('28'), isTrue);
        expect(fromName?.features.containsKey('28'), isTrue);
      });

      test('returns null for a non movie/TV item', () {
        final CollectionItem item = createTestCollectionItem(
          mediaType: MediaType.game,
          game: createTestGame(genres: <String>['RPG']),
        );
        expect(
          tasteTitleFromItem(item, movieGenres: noGenres, tvGenres: noGenres),
          isNull,
        );
      });

      test('returns null when the movie payload is missing', () {
        final CollectionItem item =
            createTestCollectionItem(mediaType: MediaType.movie);
        expect(
          tasteTitleFromItem(item, movieGenres: noGenres, tvGenres: noGenres),
          isNull,
        );
      });

      test('returns null when there are no usable genres', () {
        final CollectionItem noGenresItem = createTestCollectionItem(
          mediaType: MediaType.movie,
          movie: createTestMovie(genres: null),
        );
        final CollectionItem emptyGenres = createTestCollectionItem(
          mediaType: MediaType.movie,
          movie: createTestMovie(genres: const <String>[]),
        );
        expect(
          tasteTitleFromItem(
            noGenresItem,
            movieGenres: noGenres,
            tvGenres: noGenres,
          ),
          isNull,
        );
        expect(
          tasteTitleFromItem(
            emptyGenres,
            movieGenres: noGenres,
            tvGenres: noGenres,
          ),
          isNull,
        );
      });
    });

    group('tasteTitleFromMovie / tasteTitleFromTvShow', () {
      test('candidate movie has no rating or favorite', () {
        final TasteTitle? t = tasteTitleFromMovie(
          createTestMovie(tmdbId: 11, genres: <String>['Action']),
          noGenres,
        );
        expect(t?.id, 'movie:11');
        expect(t?.rating, isNull);
        expect(t?.isFavorite, isFalse);
      });

      test('candidate tv show maps to a tv id', () {
        final TasteTitle? t = tasteTitleFromTvShow(
          createTestTvShow(tmdbId: 22, genres: <String>['Drama']),
          noGenres,
        );
        expect(t?.id, 'tv:22');
      });

      test('returns null without genres', () {
        expect(
          tasteTitleFromMovie(createTestMovie(genres: null), noGenres),
          isNull,
        );
        expect(
          tasteTitleFromTvShow(createTestTvShow(genres: null), noGenres),
          isNull,
        );
      });
    });

    group('ownedTasteIds', () {
      test('collects movie, tv and animation ids and ignores games', () {
        final Set<String> ids = ownedTasteIds(<CollectionItem>[
          createTestCollectionItem(mediaType: MediaType.movie, externalId: 1),
          createTestCollectionItem(mediaType: MediaType.tvShow, externalId: 2),
          createTestCollectionItem(
            mediaType: MediaType.animation,
            externalId: 3,
            platformId: AnimationSource.tvShow,
          ),
          createTestCollectionItem(
            mediaType: MediaType.animation,
            externalId: 4,
            platformId: AnimationSource.movie,
          ),
          createTestCollectionItem(mediaType: MediaType.game, externalId: 5),
        ]);
        expect(
          ids,
          <String>{'movie:1', 'tv:2', 'tv:3', 'movie:4'},
        );
      });
    });
  });
}
