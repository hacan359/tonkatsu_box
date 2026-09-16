import 'package:core/models/collection_item.dart';
import 'package:core/models/custom_media.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/platform.dart';
import 'package:core/testing/builders.dart';
import 'package:test/test.dart';

void main() {
  group('CollectionItem.searchableMeta', () {
    test('game exposes genres, the owned platform and the release year', () {
      final CollectionItem item = createTestCollectionItem(
        mediaType: MediaType.game,
        game: createTestGame(
          genres: <String>['RPG', 'Adventure'],
          releaseDate: DateTime(2015, 5, 19),
        ),
        platform: const Platform(id: 6, name: 'PC'),
      );
      expect(
        item.searchableMeta,
        containsAll(<String>['RPG', 'Adventure', 'PC', '2015']),
      );
    });

    test('movie and tv show expose genres', () {
      final CollectionItem movie = createTestCollectionItem(
        mediaType: MediaType.movie,
        movie: createTestMovie(genres: <String>['Horror'], releaseYear: 2019),
      );
      final CollectionItem show = createTestCollectionItem(
        mediaType: MediaType.tvShow,
        tvShow: createTestTvShow(genres: <String>['Drama']),
      );
      expect(movie.searchableMeta, containsAll(<String>['Horror', '2019']));
      expect(show.searchableMeta, contains('Drama'));
    });

    test('animation reads whichever sub-model is attached', () {
      final CollectionItem series = createTestCollectionItem(
        mediaType: MediaType.animation,
        platformId: AnimationSource.tvShow,
        tvShow: createTestTvShow(genres: <String>['Animation', 'Comedy']),
      );
      final CollectionItem film = createTestCollectionItem(
        mediaType: MediaType.animation,
        platformId: AnimationSource.movie,
        movie: createTestMovie(genres: <String>['Family']),
      );
      expect(series.searchableMeta, containsAll(<String>['Animation', 'Comedy']));
      expect(film.searchableMeta, contains('Family'));
    });

    test('anime exposes genres, tags, studios, season, format and source', () {
      final CollectionItem item = createTestCollectionItem(
        mediaType: MediaType.anime,
        anime: createTestAnime(
          genres: <String>['Slice of Life'],
          tags: <String>['School'],
          studios: <String>['Kyoto Animation'],
        ).copyWith(season: 'WINTER', format: 'TV', sourceMaterial: 'MANGA'),
      );
      expect(
        item.searchableMeta,
        containsAll(<String>[
          'Slice of Life',
          'School',
          'Kyoto Animation',
          'WINTER',
          'TV',
          'MANGA',
        ]),
      );
    });

    test('manga exposes genres, tags, authors, country and format', () {
      final CollectionItem item = createTestCollectionItem(
        mediaType: MediaType.manga,
        manga: createTestManga(genres: <String>['Action'], format: 'MANGA')
            .copyWith(
          tags: <String>['Ninja'],
          authors: <String>['Masashi Kishimoto'],
          countryOfOrigin: 'JP',
        ),
      );
      expect(
        item.searchableMeta,
        containsAll(<String>[
          'Action',
          'Ninja',
          'Masashi Kishimoto',
          'JP',
          'MANGA',
        ]),
      );
    });

    test('book exposes authors, publishers, subjects and series', () {
      final CollectionItem item = createTestCollectionItem(
        mediaType: MediaType.book,
        book: createTestBook(
          authors: <String>['Frank Herbert'],
          subjects: <String>['Science fiction'],
        ).copyWith(publishers: <String>['Chilton'], series: 'Dune'),
      );
      expect(
        item.searchableMeta,
        containsAll(<String>[
          'Frank Herbert',
          'Science fiction',
          'Chilton',
          'Dune',
        ]),
      );
    });

    test('visual novel exposes tags, developers and platforms', () {
      final CollectionItem item = createTestCollectionItem(
        mediaType: MediaType.visualNovel,
        visualNovel: createTestVisualNovel(
          tags: <String>['Romance'],
          developers: <String>['Key'],
          platforms: <String>['Windows'],
        ),
      );
      expect(
        item.searchableMeta,
        containsAll(<String>['Romance', 'Key', 'Windows']),
      );
    });

    test('audio exposes artists, genres, tags, types and label', () {
      final CollectionItem item = createTestCollectionItem(
        mediaType: MediaType.audio,
        audioItem: createTestAudioItem(
          artists: <String>['Pink Floyd'],
          genres: <String>['Progressive rock'],
          tags: <String>['70s'],
          primaryType: 'Album',
          secondaryTypes: <String>['Live'],
        ).copyWith(label: 'Harvest'),
      );
      expect(
        item.searchableMeta,
        containsAll(<String>[
          'Pink Floyd',
          'Progressive rock',
          '70s',
          'Album',
          'Live',
          'Harvest',
        ]),
      );
    });

    test('custom exposes split genres, platform name and format', () {
      final CollectionItem item = createTestCollectionItem(
        mediaType: MediaType.custom,
        customMedia: const CustomMedia(
          id: 1,
          title: 'Homebrew',
          genres: 'Puzzle, Indie',
          platformName: 'Board game',
          format: 'Box',
        ),
      );
      expect(
        item.searchableMeta,
        containsAll(<String>['Puzzle', 'Indie', 'Board game', 'Box']),
      );
    });

    test('drops empty values and has nothing for a bare item', () {
      final CollectionItem bare = createTestCollectionItem(
        mediaType: MediaType.custom,
        customMedia: const CustomMedia(id: 1, title: 'Bare', platformName: ''),
      );
      expect(bare.searchableMeta, isEmpty);
    });
  });
}
