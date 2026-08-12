import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/api/musicbrainz/musicbrainz_release_group_api.dart';

void main() {
  group('MusicBrainzReleaseGroupApi.buildQuery', () {
    test('free text alone is escaped', () {
      expect(
        MusicBrainzReleaseGroupApi.buildQuery(query: 'dark side'),
        'dark side',
      );
    });

    test('filters alone form a browse query', () {
      expect(
        MusicBrainzReleaseGroupApi.buildQuery(
          primaryType: 'album',
          excludeSecondaryTypes: true,
          tag: 'progressive rock',
          yearFrom: 1970,
          yearTo: 1979,
        ),
        'primarytype:album AND -secondarytype:* AND '
        'tag:"progressive rock" AND firstreleasedate:[1970 TO 1979]',
      );
    });

    test('open-ended year ranges use wildcards', () {
      expect(
        MusicBrainzReleaseGroupApi.buildQuery(yearFrom: 1990),
        'firstreleasedate:[1990 TO *]',
      );
      expect(
        MusicBrainzReleaseGroupApi.buildQuery(yearTo: 1990),
        'firstreleasedate:[* TO 1990]',
      );
    });

    test('everything empty produces an empty query', () {
      expect(MusicBrainzReleaseGroupApi.buildQuery(), isEmpty);
    });

    test('a query field wraps the text into a quoted field match', () {
      expect(
        MusicBrainzReleaseGroupApi.buildQuery(
          query: 'pink floyd',
          queryField: 'artist',
        ),
        'artist:"pink floyd"',
      );
      expect(
        MusicBrainzReleaseGroupApi.buildQuery(
          query: 'say "hi"',
          queryField: 'releasegroup',
        ),
        r'releasegroup:"say \"hi\""',
      );
    });
  });

  group('MusicBrainzReleaseGroupApi.escapeLucene', () {
    test('escapes operator characters', () {
      expect(
        MusicBrainzReleaseGroupApi.escapeLucene('AC/DC'),
        r'AC\/DC',
      );
      expect(
        MusicBrainzReleaseGroupApi.escapeLucene('what?'),
        r'what\?',
      );
      expect(
        MusicBrainzReleaseGroupApi.escapeLucene('a:b (c)'),
        r'a\:b \(c\)',
      );
    });

    test('defuses bare boolean operators', () {
      expect(
        MusicBrainzReleaseGroupApi.escapeLucene('Blood AND Thunder'),
        'Blood and Thunder',
      );
      expect(
        MusicBrainzReleaseGroupApi.escapeLucene('NOT AN OPERATOR'),
        'not AN OPERATOR',
      );
    });

    test('plain text passes through', () {
      expect(
        MusicBrainzReleaseGroupApi.escapeLucene('dark side of the moon'),
        'dark side of the moon',
      );
    });
  });
}
