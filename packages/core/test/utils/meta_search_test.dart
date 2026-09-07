import 'package:core/models/collection_item.dart';
import 'package:core/models/media_type.dart';
import 'package:core/testing/builders.dart';
import 'package:core/utils/meta_search.dart';
import 'package:test/test.dart';

void main() {
  group('parseMetaQuery', () {
    test('empty and separator-only input gives no groups', () {
      expect(parseMetaQuery(''), isEmpty);
      expect(parseMetaQuery(' , / , '), isEmpty);
    });

    test('splits AND on commas and OR on slash or pipe', () {
      expect(
        parseMetaQuery('Horror / Thriller, 2019 | 2020'),
        <List<String>>[
          <String>['horror', 'thriller'],
          <String>['2019', '2020'],
        ],
      );
    });

    test('keeps phrases whole and collapses inner whitespace', () {
      expect(
        parseMetaQuery('  Kyoto   Animation , slice of life'),
        <List<String>>[
          <String>['kyoto animation'],
          <String>['slice of life'],
        ],
      );
    });

    test('accepts the fullwidth comma', () {
      expect(parseMetaQuery('恐怖，2019'), <List<String>>[
        <String>['恐怖'],
        <String>['2019'],
      ]);
    });
  });

  group('matchesMetaQuery', () {
    final CollectionItem anime = createTestCollectionItem(
      mediaType: MediaType.anime,
      anime: createTestAnime(
        genres: <String>['Slice of Life', 'Comedy'],
        studios: <String>['Kyoto Animation'],
        startYear: 2019,
      ),
    );

    test('empty query matches everything', () {
      expect(matchesMetaQuery(anime, ''), isTrue);
    });

    test('phrase must sit inside a single descriptor', () {
      expect(matchesMetaQuery(anime, 'kyoto animation'), isTrue);
      expect(matchesMetaQuery(anime, 'kyoto comedy'), isFalse);
    });

    test('AND requires every group, OR any alternative', () {
      expect(matchesMetaQuery(anime, 'comedy, 2019'), isTrue);
      expect(matchesMetaQuery(anime, 'comedy, 2020'), isFalse);
      expect(matchesMetaQuery(anime, 'horror / comedy'), isTrue);
      expect(matchesMetaQuery(anime, 'horror / drama'), isFalse);
      expect(matchesMetaQuery(anime, 'horror / comedy, kyoto'), isTrue);
    });

    test('is case-insensitive', () {
      expect(matchesMetaQuery(anime, 'SLICE OF LIFE'), isTrue);
    });

    test('parsed variant matches the same way for a pre-parsed query', () {
      final List<List<String>> groups = parseMetaQuery('comedy, kyoto');
      expect(matchesParsedMetaQuery(anime, groups), isTrue);
      expect(matchesParsedMetaQuery(anime, parseMetaQuery('drama')), isFalse);
      expect(matchesParsedMetaQuery(anime, const <List<String>>[]), isTrue);
    });

    test('a descriptor with a slash or comma matches as one phrase', () {
      final CollectionItem album = createTestCollectionItem(
        mediaType: MediaType.audio,
        audioItem: createTestAudioItem(
          artists: <String>['AC/DC'],
          genres: <String>['Rock, Hard'],
        ),
      );
      expect(matchesMetaQuery(album, metaTermFor('AC/DC')), isTrue);
      expect(matchesMetaQuery(album, 'ac dc'), isTrue);
      expect(matchesMetaQuery(album, 'rock hard'), isTrue);
    });

    test('item without descriptors matches only the empty query', () {
      final CollectionItem bare = createTestCollectionItem(
        mediaType: MediaType.game,
        game: createTestGame(genres: null),
      );
      expect(matchesMetaQuery(bare, 'rpg'), isFalse);
      expect(matchesMetaQuery(bare, ''), isTrue);
    });
  });

  group('metaTermFor', () {
    test('flattens query separators to single spaces and keeps case', () {
      expect(metaTermFor('AC/DC'), 'AC DC');
      expect(metaTermFor(' Sony Music,  Inc. '), 'Sony Music Inc.');
      expect(metaTermFor('Sci-Fi|Fantasy'), 'Sci-Fi Fantasy');
    });
  });

  group('appendMetaTerm', () {
    test('returns the term alone when the query is blank', () {
      expect(appendMetaTerm('   ', 'Horror'), 'Horror');
    });

    test('appends a new AND group', () {
      expect(appendMetaTerm('Horror', 'Kyoto Animation'),
          'Horror, Kyoto Animation');
    });

    test('does not duplicate a phrase already present, ignoring case', () {
      expect(appendMetaTerm('horror, Comedy', 'HORROR'), 'horror, Comedy');
    });

    test('a phrase inside an OR group still gets appended', () {
      expect(appendMetaTerm('Horror / Comedy', 'Horror'),
          'Horror / Comedy, Horror');
    });

    test('a chip value with separators is appended as one phrase', () {
      expect(appendMetaTerm('Rock', 'AC/DC'), 'Rock, AC DC');
      expect(appendMetaTerm('Rock, AC DC', 'AC/DC'), 'Rock, AC DC');
    });
  });
}
