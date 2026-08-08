import 'package:core/utils/tvdb_json.dart';
import 'package:test/test.dart';

void main() {
  group('tvdbNumericId', () {
    test('reads the int id of a detail record', () {
      expect(tvdbNumericId(<String, dynamic>{'id': 113}), 113);
    });

    test('reads the string tvdb_id of a search hit', () {
      expect(
        tvdbNumericId(<String, dynamic>{'id': 'movie-113', 'tvdb_id': '113'}),
        113,
      );
    });

    test('falls back to the suffix of a prefixed id', () {
      expect(tvdbNumericId(<String, dynamic>{'id': 'series-81189'}), 81189);
    });

    test('returns null when there is no usable id', () {
      expect(tvdbNumericId(<String, dynamic>{'name': 'x'}), isNull);
    });
  });

  group('tvdbTranslation', () {
    final List<dynamic> listShape = <dynamic>[
      <String, dynamic>{'name': 'Начало', 'language': 'rus'},
      <String, dynamic>{'name': 'Inception', 'language': 'eng'},
    ];
    final Map<String, dynamic> mapShape = <String, dynamic>{
      'rus': 'Начало',
      'eng': 'Inception',
    };

    test('picks the locale from the meta list shape', () {
      expect(tvdbTranslation(listShape, 'name', 'ru'), 'Начало');
    });

    test('picks the locale from the search map shape', () {
      expect(tvdbTranslation(mapShape, 'name', 'ru'), 'Начало');
    });

    test('falls back to English for a locale with no translation', () {
      expect(tvdbTranslation(listShape, 'name', 'fr'), 'Inception');
    });

    test('accepts both Portuguese codes upstream uses', () {
      expect(
        tvdbTranslation(
          <dynamic>[
            <String, dynamic>{'name': 'A Origem', 'language': 'pt'},
          ],
          'name',
          'pt',
        ),
        'A Origem',
      );
    });

    test('returns null when nothing matches and there is no English', () {
      expect(
        tvdbTranslation(
          <dynamic>[
            <String, dynamic>{'name': 'Počátek', 'language': 'ces'},
          ],
          'name',
          'ru',
        ),
        isNull,
      );
    });

    test('ignores an empty string so the caller can fall back', () {
      expect(
        tvdbTranslation(<String, dynamic>{'rus': '', 'eng': 'Inception'},
            'name', 'ru'),
        'Inception',
      );
    });
  });

  group('tvdbImageUrl', () {
    test('keeps an absolute url from search and detail', () {
      expect(
        tvdbImageUrl('https://artworks.thetvdb.com/banners/a.jpg'),
        'https://artworks.thetvdb.com/banners/a.jpg',
      );
    });

    test('prefixes the bare path that filter returns', () {
      expect(
        tvdbImageUrl('/banners/movies/63/posters/x.jpg'),
        'https://artworks.thetvdb.com/banners/movies/63/posters/x.jpg',
      );
    });

    test('returns null for null and empty', () {
      expect(tvdbImageUrl(null), isNull);
      expect(tvdbImageUrl(''), isNull);
    });
  });

  group('tvdbThumbUrl', () {
    test('inserts the _t suffix before the extension', () {
      expect(
        tvdbThumbUrl('https://artworks.thetvdb.com/banners/a.jpg'),
        'https://artworks.thetvdb.com/banners/a_t.jpg',
      );
    });

    test('leaves an extensionless url alone', () {
      expect(tvdbThumbUrl('https://x/banners/a'), 'https://x/banners/a');
    });
  });

  group('tvdbRemoteId', () {
    final List<dynamic> remoteIds = <dynamic>[
      <String, dynamic>{'id': 'tt1375666', 'type': 2, 'sourceName': 'IMDB'},
      <String, dynamic>{
        'id': '27205',
        'type': 10,
        'sourceName': 'TheMovieDB.com',
      },
    ];

    test('matches by source name, not by the type number', () {
      expect(tvdbRemoteId(remoteIds, 'TheMovieDB.com'), '27205');
      expect(tvdbRemoteId(remoteIds, 'IMDB'), 'tt1375666');
    });

    test('returns null for an absent provider', () {
      expect(tvdbRemoteId(remoteIds, 'Trakt'), isNull);
    });
  });

  group('tvdbYear', () {
    test('reads a bare year and a full date', () {
      expect(tvdbYear('2010'), 2010);
      expect(tvdbYear('2010-07-08'), 2010);
      expect(tvdbYear(1999), 1999);
    });

    test('returns null for the empty string upstream sends', () {
      expect(tvdbYear(''), isNull);
      expect(tvdbYear(null), isNull);
    });
  });

  group('tvdbNames', () {
    test('reads names out of the id/name/slug shape', () {
      expect(
        tvdbNames(<dynamic>[
          <String, dynamic>{'id': 19, 'name': 'Action', 'slug': 'action'},
          <String, dynamic>{'id': 12, 'name': 'Drama', 'slug': 'drama'},
        ]),
        <String>['Action', 'Drama'],
      );
    });

    test('returns null for an empty or absent list', () {
      expect(tvdbNames(<dynamic>[]), isNull);
      expect(tvdbNames(null), isNull);
    });
  });

  group('tvdbRecordUrl', () {
    test('prefers the slug path the site actually serves', () {
      expect(
        tvdbRecordUrl('movies', 'inception', 113),
        'https://thetvdb.com/movies/inception',
      );
      expect(
        tvdbRecordUrl('series', 'breaking-bad', 81189),
        'https://thetvdb.com/series/breaking-bad',
      );
    });

    test('falls back to the id query form when the slug is missing', () {
      expect(
        tvdbRecordUrl('movies', null, 113),
        'https://thetvdb.com/?tab=movies&id=113',
      );
      expect(
        tvdbRecordUrl('series', '', 81189),
        'https://thetvdb.com/?tab=series&id=81189',
      );
    });
  });
}
