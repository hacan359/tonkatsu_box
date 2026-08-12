import 'package:core/models/album.dart';
import 'package:core/models/data_source.dart';
import 'package:core/utils/stable_id.dart';
import 'package:test/test.dart';

void main() {
  group('Album', () {
    group('fromMusicBrainzReleaseGroup', () {
      final Map<String, dynamic> searchDoc = <String, dynamic>{
        'id': 'f5093c06-23e3-404f-aeaa-40f72885ee3a',
        'score': 100,
        'title': 'The Dark Side of the Moon',
        'primary-type': 'Album',
        'secondary-types': <dynamic>[],
        'first-release-date': '1973-03-24',
        'artist-credit': <dynamic>[
          <String, dynamic>{
            'name': 'Pink Floyd',
            'artist': <String, dynamic>{
              'id': '83d91898-7763-47d7-b03b-b92132375c47',
              'name': 'Pink Floyd',
            },
          },
        ],
        'tags': <dynamic>[
          <String, dynamic>{'count': 25, 'name': 'rock'},
          <String, dynamic>{'count': 42, 'name': 'progressive rock'},
        ],
      };

      test('parses a search doc', () {
        final Album album = Album.fromMusicBrainzReleaseGroup(searchDoc);

        expect(album.id, fnv1a64('f5093c06-23e3-404f-aeaa-40f72885ee3a'));
        expect(album.source, DataSource.musicBrainz);
        expect(album.mbid, 'f5093c06-23e3-404f-aeaa-40f72885ee3a');
        expect(album.title, 'The Dark Side of the Moon');
        expect(album.artists, <String>['Pink Floyd']);
        expect(
          album.artistMbids,
          <String>['83d91898-7763-47d7-b03b-b92132375c47'],
        );
        expect(album.primaryType, 'Album');
        expect(album.secondaryTypes, isEmpty);
        expect(album.releaseYear, 1973);
        expect(album.firstReleaseDate, '1973-03-24');
        // Tags come back vote-ordered regardless of payload order.
        expect(album.tags, <String>['progressive rock', 'rock']);
        expect(album.genres, isEmpty);
        expect(album.rating, isNull);
        expect(
          album.coverUrl,
          'https://coverartarchive.org/release-group/'
          'f5093c06-23e3-404f-aeaa-40f72885ee3a/front-500',
        );
        expect(
          album.externalUrl,
          'https://musicbrainz.org/release-group/'
          'f5093c06-23e3-404f-aeaa-40f72885ee3a',
        );
      });

      test('parses lookup extras: rating scaled to 1-10 and genres', () {
        final Map<String, dynamic> lookup = <String, dynamic>{
          ...searchDoc,
          'rating': <String, dynamic>{'value': 4.75, 'votes-count': 106},
          'genres': <dynamic>[
            <String, dynamic>{'count': 42, 'name': 'progressive rock'},
          ],
        };

        final Album album = Album.fromMusicBrainzReleaseGroup(lookup);

        expect(album.rating, closeTo(9.5, 0.001));
        expect(album.ratingCount, 106);
        expect(album.genres, <String>['progressive rock']);
      });

      test('tolerates a minimal payload', () {
        final Album album = Album.fromMusicBrainzReleaseGroup(
          <String, dynamic>{'id': 'abc'},
        );

        expect(album.title, 'Unknown');
        expect(album.artists, isEmpty);
        expect(album.releaseYear, isNull);
        expect(album.firstReleaseDate, isNull);
      });

      test('extracts the year from a truncated date', () {
        final Album album = Album.fromMusicBrainzReleaseGroup(
          <String, dynamic>{'id': 'abc', 'first-release-date': '1969'},
        );

        expect(album.releaseYear, 1969);
      });
    });

    group('toDb / fromDb', () {
      test('round-trips every field', () {
        const Album album = Album(
          id: 42,
          source: DataSource.musicBrainz,
          mbid: 'mbid-42',
          title: 'Wish You Were Here',
          artists: <String>['Pink Floyd'],
          artistMbids: <String>['a-1'],
          primaryType: 'Album',
          secondaryTypes: <String>['Live'],
          releaseYear: 1975,
          firstReleaseDate: '1975-09-12',
          genres: <String>['progressive rock'],
          tags: <String>['rock'],
          rating: 9.4,
          ratingCount: 88,
          listenCount: 100500,
          releaseMbid: 'rel-1',
          releaseTitle: 'WYWH (remaster)',
          label: 'Harvest',
          format: 'CD',
          trackCount: 5,
          discCount: 1,
          totalLengthMs: 2661000,
          coverUrl: 'https://example.com/cover.jpg',
          externalUrl: 'https://musicbrainz.org/release-group/mbid-42',
          cachedAt: 1700000000,
        );

        final Album restored = Album.fromDb(album.toDb());

        expect(restored.id, album.id);
        expect(restored.source, album.source);
        expect(restored.mbid, album.mbid);
        expect(restored.title, album.title);
        expect(restored.artists, album.artists);
        expect(restored.artistMbids, album.artistMbids);
        expect(restored.primaryType, album.primaryType);
        expect(restored.secondaryTypes, album.secondaryTypes);
        expect(restored.releaseYear, album.releaseYear);
        expect(restored.firstReleaseDate, album.firstReleaseDate);
        expect(restored.genres, album.genres);
        expect(restored.tags, album.tags);
        expect(restored.rating, album.rating);
        expect(restored.ratingCount, album.ratingCount);
        expect(restored.listenCount, album.listenCount);
        expect(restored.releaseMbid, album.releaseMbid);
        expect(restored.releaseTitle, album.releaseTitle);
        expect(restored.label, album.label);
        expect(restored.format, album.format);
        expect(restored.trackCount, album.trackCount);
        expect(restored.discCount, album.discCount);
        expect(restored.totalLengthMs, album.totalLengthMs);
        expect(restored.coverUrl, album.coverUrl);
        expect(restored.externalUrl, album.externalUrl);
        expect(restored.cachedAt, album.cachedAt);
      });

      test('empty lists store as NULL and read back empty', () {
        const Album album = Album(
          id: 1,
          source: DataSource.musicBrainz,
          mbid: 'm',
          title: 't',
        );

        final Map<String, dynamic> row = album.toDb();
        expect(row['artists'], isNull);
        expect(row['genres'], isNull);

        final Album restored = Album.fromDb(row);
        expect(restored.artists, isEmpty);
        expect(restored.genres, isEmpty);
      });
    });

    group('toExport', () {
      test('omits cached_at', () {
        const Album album = Album(
          id: 1,
          source: DataSource.musicBrainz,
          mbid: 'm',
          title: 't',
          cachedAt: 123,
        );

        expect(album.toExport().containsKey('cached_at'), isFalse);
        expect(album.toExport()['mbid'], 'm');
      });
    });

    group('withLookupDetails', () {
      test('fills lookup extras without wiping the row', () {
        const Album row = Album(
          id: 1,
          source: DataSource.musicBrainz,
          mbid: 'm',
          title: 't',
          tags: <String>['rock'],
          listenCount: 500,
        );
        const Album full = Album(
          id: 1,
          source: DataSource.musicBrainz,
          mbid: 'm',
          title: 't',
          genres: <String>['progressive rock'],
          rating: 9.5,
          ratingCount: 106,
        );

        final Album merged = row.withLookupDetails(full);

        expect(merged.genres, <String>['progressive rock']);
        expect(merged.rating, 9.5);
        expect(merged.ratingCount, 106);
        expect(merged.tags, <String>['rock']);
        expect(merged.listenCount, 500);
      });

      test('fills a missing artist credit from the lookup', () {
        const Album row = Album(
          id: 1,
          source: DataSource.musicBrainz,
          mbid: 'm',
          title: 't',
        );
        const Album full = Album(
          id: 1,
          source: DataSource.musicBrainz,
          mbid: 'm',
          title: 't',
          artists: <String>['7раса'],
          artistMbids: <String>['a-1'],
          primaryType: 'Album',
          releaseYear: 2004,
        );

        final Album merged = row.withLookupDetails(full);

        expect(merged.artists, <String>['7раса']);
        expect(merged.artistMbids, <String>['a-1']);
        expect(merged.primaryType, 'Album');
        expect(merged.releaseYear, 2004);
      });

      test('keeps the row artist credit over the lookup one', () {
        const Album row = Album(
          id: 1,
          source: DataSource.musicBrainz,
          mbid: 'm',
          title: 't',
          artists: <String>['Row Artist'],
        );
        const Album full = Album(
          id: 1,
          source: DataSource.musicBrainz,
          mbid: 'm',
          title: 't',
          artists: <String>['Lookup Artist'],
        );

        expect(
          row.withLookupDetails(full).artists,
          <String>['Row Artist'],
        );
      });
    });

    group('helpers', () {
      test('coverUrlForReleaseGroup builds sized urls', () {
        expect(
          Album.coverUrlForReleaseGroup('m', size: 250),
          'https://coverartarchive.org/release-group/m/front-250',
        );
        expect(
          Album.coverUrlForRelease('r'),
          'https://coverartarchive.org/release/r/front-500',
        );
      });

      test('totalLengthMinutes floors milliseconds', () {
        const Album album = Album(
          id: 1,
          source: DataSource.musicBrainz,
          mbid: 'm',
          title: 't',
          totalLengthMs: 2661000,
        );
        expect(album.totalLengthMinutes, 44);
      });

      test('equality is (id, source)', () {
        const Album a = Album(
          id: 1,
          source: DataSource.musicBrainz,
          mbid: 'm',
          title: 'a',
        );
        const Album b = Album(
          id: 1,
          source: DataSource.musicBrainz,
          mbid: 'm',
          title: 'b',
        );
        expect(a, equals(b));
      });
    });
  });
}
