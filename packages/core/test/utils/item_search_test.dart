import 'package:core/models/collection_item.dart';
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
      expect(search('  ').isEmpty, isTrue);
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

    test('creatorsOf is empty for types without a creator field', () {
      expect(ItemSearch.creatorsOf(game), isEmpty);
    });
  });
}
