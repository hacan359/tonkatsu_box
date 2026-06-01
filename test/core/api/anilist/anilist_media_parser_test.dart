import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/api/anilist/anilist_media_parser.dart';
import 'package:tonkatsu_box/shared/models/anime.dart';
import 'package:tonkatsu_box/shared/models/manga.dart';

Map<String, dynamic> _page({
  List<Map<String, dynamic>> media = const <Map<String, dynamic>>[],
  bool hasNextPage = false,
  int lastPage = 1,
}) =>
    <String, dynamic>{
      'Page': <String, dynamic>{
        'pageInfo': <String, dynamic>{
          'hasNextPage': hasNextPage,
          'lastPage': lastPage,
        },
        'media': media,
      },
    };

void main() {
  group('AniListMediaParser.animePage', () {
    test('null data yields empty result', () {
      final (List<Anime>, bool, int) r = AniListMediaParser.animePage(null);
      expect(r.$1, isEmpty);
      expect(r.$2, isFalse);
      expect(r.$3, 0);
    });

    test('missing Page node yields empty result', () {
      final (List<Anime>, bool, int) r =
          AniListMediaParser.animePage(<String, dynamic>{});
      expect(r.$1, isEmpty);
    });

    test('reads pageInfo flags', () {
      final (List<Anime>, bool, int) r = AniListMediaParser.animePage(
        _page(hasNextPage: true, lastPage: 5),
      );
      expect(r.$1, isEmpty);
      expect(r.$2, isTrue);
      expect(r.$3, 5);
    });

    test('parses media entries into Anime', () {
      final (List<Anime>, bool, int) r = AniListMediaParser.animePage(
        _page(media: <Map<String, dynamic>>[
          <String, dynamic>{'id': 1, 'title': <String, dynamic>{'romaji': 'A'}},
          <String, dynamic>{'id': 2, 'title': <String, dynamic>{'romaji': 'B'}},
        ]),
      );
      expect(r.$1.map((Anime a) => a.id), <int>[1, 2]);
    });
  });

  group('AniListMediaParser.mangaPage', () {
    test('null data yields empty result', () {
      final (List<Manga>, bool, int) r = AniListMediaParser.mangaPage(null);
      expect(r.$1, isEmpty);
      expect(r.$3, 0);
    });

    test('parses media entries into Manga', () {
      final (List<Manga>, bool, int) r = AniListMediaParser.mangaPage(
        _page(media: <Map<String, dynamic>>[
          <String, dynamic>{'id': 9, 'title': <String, dynamic>{'romaji': 'M'}},
        ]),
      );
      expect(r.$1.single.id, 9);
    });
  });

  group('AniListMediaParser.fuzzyDate', () {
    test('null map or null year yields null', () {
      expect(AniListMediaParser.fuzzyDate(null), isNull);
      expect(
        AniListMediaParser.fuzzyDate(<String, dynamic>{'year': null}),
        isNull,
      );
    });

    test('year only defaults month and day to 1', () {
      expect(
        AniListMediaParser.fuzzyDate(<String, dynamic>{'year': 2020}),
        DateTime.utc(2020, 1, 1),
      );
    });

    test('full fuzzy date is parsed', () {
      expect(
        AniListMediaParser.fuzzyDate(
          <String, dynamic>{'year': 2014, 'month': 6, 'day': 15},
        ),
        DateTime.utc(2014, 6, 15),
      );
    });
  });
}
