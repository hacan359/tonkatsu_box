import 'package:core/models/collection_item.dart';
import 'package:core/models/custom_media.dart';
import 'package:core/models/media_type.dart';
import 'package:core/testing/builders.dart';
import 'package:core/utils/anime_manga_title_language.dart';
import 'package:core/utils/item_search.dart';
import 'package:core/utils/meta_search.dart';
import 'package:test/test.dart';

void main() {
  group('ItemSearch', () {
    ItemSearch search(
      String query, {
      SearchMode mode = SearchMode.title,
      Map<int, List<int>> itemTags = const <int, List<int>>{},
      Map<int, String> tagNames = const <int, String>{},
    }) =>
        ItemSearch(
          query: query,
          mode: mode,
          itemTags: itemTags,
          tagNames: tagNames,
          titleLanguage: AnimeMangaTitleLanguage.defaultId,
        );

    final CollectionItem game = createTestCollectionItem(
      id: 1,
      overrideName: 'Chrono Trigger',
      userComment: 'best soundtrack',
      authorComment: 'shared by Ann',
      game: createTestGame(genres: <String>['RPG']),
    );

    test('empty or blank query matches everything', () {
      expect(search('').matches(game), isTrue);
      expect(search('   ').matches(game), isTrue);
    });

    test('matches the display name case-insensitively', () {
      expect(search('CHRONO').matches(game), isTrue);
      expect(search('zelda').matches(game), isFalse);
    });

    test('matches user and author comments', () {
      expect(search('soundtrack').matches(game), isTrue);
      expect(search('ann').matches(game), isTrue);
    });

    test('matches a tag name through the item tag links', () {
      final ItemSearch s = search(
        'backlog',
        itemTags: <int, List<int>>{1: <int>[20]},
        tagNames: <int, String>{20: 'Backlog'},
      );
      expect(s.matches(game), isTrue);
      expect(search('backlog', tagNames: <int, String>{20: 'Backlog'})
          .matches(game), isFalse);
    });

    test('matches album artists and book authors', () {
      final CollectionItem album = createTestCollectionItem(
        id: 2,
        mediaType: MediaType.audio,
        audioItem: createTestAudioItem(
          title: 'The Wall',
          artists: <String>['Pink Floyd'],
        ),
      );
      final CollectionItem book = createTestCollectionItem(
        id: 3,
        mediaType: MediaType.book,
        book: createTestBook(title: 'Dune', authors: <String>['Frank Herbert']),
      );
      expect(search('pink floyd').matches(album), isTrue);
      expect(search('herbert').matches(book), isTrue);
      expect(search('herbert').matches(album), isFalse);
    });

    test('title mode ignores genres, meta mode ignores the name', () {
      expect(search('rpg').matches(game), isFalse);
      expect(search('rpg', mode: SearchMode.meta).matches(game), isTrue);
      expect(search('chrono', mode: SearchMode.meta).matches(game), isFalse);
    });

    test('creatorsOf is empty for a game without developers', () {
      expect(ItemSearch.creatorsOf(game), isEmpty);
    });

    test('matches directors, show creators, developers and card authors', () {
      final CollectionItem movie = createTestCollectionItem(
        id: 4,
        mediaType: MediaType.movie,
        movie: createTestMovie(title: 'Alien')
            .copyWith(directors: <String>['Ridley Scott']),
      );
      final CollectionItem show = createTestCollectionItem(
        id: 5,
        mediaType: MediaType.tvShow,
        tvShow: createTestTvShow(title: 'BB')
            .copyWith(creators: <String>['Vince Gilligan']),
      );
      final CollectionItem animated = createTestCollectionItem(
        id: 6,
        mediaType: MediaType.animation,
        tvShow: createTestTvShow(title: 'Arcane')
            .copyWith(creators: <String>['Fortiche']),
      );
      final CollectionItem hk = createTestCollectionItem(
        id: 7,
        game: createTestGame(name: 'Hollow Knight').copyWith(
          developers: <String>['Team Cherry'],
          publishers: <String>['Fangamer'],
        ),
      );
      final CollectionItem card = createTestCollectionItem(
        id: 8,
        mediaType: MediaType.custom,
        customMedia: const CustomMedia(
          id: 1,
          title: 'Zine',
          authors: <String>['Jane Doe'],
        ),
      );
      expect(search('scott').matches(movie), isTrue);
      expect(search('gilligan').matches(show), isTrue);
      expect(search('fortiche').matches(animated), isTrue);
      expect(search('cherry').matches(hk), isTrue);
      expect(search('jane').matches(card), isTrue);
    });

    test('title search skips publishers, meta search keeps them', () {
      final CollectionItem hk = createTestCollectionItem(
        id: 7,
        game: createTestGame(name: 'Hollow Knight')
            .copyWith(publishers: <String>['Fangamer']),
      );
      expect(search('fangamer').matches(hk), isFalse);
      expect(search('fangamer', mode: SearchMode.meta).matches(hk), isTrue);
    });

    test('meta search finds a show by its studio, title search does not', () {
      final CollectionItem show = createTestCollectionItem(
        id: 9,
        mediaType: MediaType.tvShow,
        tvShow: createTestTvShow(title: 'The Wire')
            .copyWith(studios: <String>['HBO']),
      );
      expect(search('hbo').matches(show), isFalse);
      expect(search('hbo', mode: SearchMode.meta).matches(show), isTrue);
    });
  });
}
