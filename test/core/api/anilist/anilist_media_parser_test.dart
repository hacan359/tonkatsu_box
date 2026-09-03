import 'package:core/models/anilist_studio.dart';
import 'package:core/models/anime.dart';
import 'package:core/models/manga.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/api/anilist/anilist_media_parser.dart';

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

  Map<String, dynamic> recommendationsMedia(List<Map<String, dynamic>?> nodes) =>
      <String, dynamic>{
        'recommendations': <String, dynamic>{
          'nodes': <Map<String, dynamic>?>[
            for (final Map<String, dynamic>? rec in nodes)
              <String, dynamic>{'mediaRecommendation': rec},
          ],
        },
      };

  Map<String, dynamic> recMedia(int id, String type, String title) =>
      <String, dynamic>{
        'type': type,
        'id': id,
        'title': <String, dynamic>{'romaji': title},
      };

  group('AniListMediaParser.recommendedAnimeBatch', () {
    test('maps nodes per seed preserving order', () {
      final Map<int, List<Anime>> r = AniListMediaParser.recommendedAnimeBatch(
        <String, dynamic>{
          's0': recommendationsMedia(<Map<String, dynamic>?>[
            recMedia(11061, 'ANIME', 'Hunter x Hunter'),
            recMedia(20, 'ANIME', 'Naruto'),
          ]),
          's1': recommendationsMedia(<Map<String, dynamic>?>[
            recMedia(1, 'ANIME', 'Cowboy Bebop'),
          ]),
        },
        <int>[21, 205],
      );
      expect(r[21]!.map((Anime a) => a.id), <int>[11061, 20]);
      expect(r[21]!.first.title, 'Hunter x Hunter');
      expect(r[205]!.single.id, 1);
    });

    test('drops null mediaRecommendation (deleted media)', () {
      final Map<int, List<Anime>> r = AniListMediaParser.recommendedAnimeBatch(
        <String, dynamic>{
          's0': recommendationsMedia(<Map<String, dynamic>?>[
            null,
            recMedia(20, 'ANIME', 'Naruto'),
          ]),
        },
        <int>[21],
      );
      expect(r[21]!.map((Anime a) => a.id), <int>[20]);
    });

    test('drops cross-type entries (a manga recommended for an anime)', () {
      final Map<int, List<Anime>> r = AniListMediaParser.recommendedAnimeBatch(
        <String, dynamic>{
          's0': recommendationsMedia(<Map<String, dynamic>?>[
            recMedia(30002, 'MANGA', 'Berserk'),
            recMedia(20, 'ANIME', 'Naruto'),
          ]),
        },
        <int>[21],
      );
      expect(r[21]!.map((Anime a) => a.id), <int>[20]);
    });

    test('null data or a deleted seed yields empty lists per seed', () {
      expect(
        AniListMediaParser.recommendedAnimeBatch(null, <int>[21])[21],
        isEmpty,
      );
      // Seed s0 deleted server-side: its Media comes back null.
      final Map<int, List<Anime>> r = AniListMediaParser.recommendedAnimeBatch(
        <String, dynamic>{'s0': null},
        <int>[21],
      );
      expect(r[21], isEmpty);
    });
  });

  group('AniListMediaParser.recommendedMangaBatch', () {
    test('maps nodes and keeps only MANGA entries', () {
      final Map<int, List<Manga>> r = AniListMediaParser.recommendedMangaBatch(
        <String, dynamic>{
          's0': recommendationsMedia(<Map<String, dynamic>?>[
            recMedia(30642, 'MANGA', 'Vinland Saga'),
            recMedia(20, 'ANIME', 'Naruto'),
            recMedia(30656, 'MANGA', 'Vagabond'),
          ]),
        },
        <int>[30002],
      );
      expect(r[30002]!.map((Manga m) => m.id), <int>[30642, 30656]);
    });
  });

  group('AniListMediaParser.studios', () {
    test('null or missing Page yields empty list', () {
      expect(AniListMediaParser.studios(null), isEmpty);
      expect(AniListMediaParser.studios(<String, dynamic>{}), isEmpty);
    });

    test('parses id, name and the animation flag', () {
      final List<AniListStudio> r = AniListMediaParser.studios(
        <String, dynamic>{
          'Page': <String, dynamic>{
            'studios': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 2,
                'name': 'Kyoto Animation',
                'isAnimationStudio': true,
              },
              <String, dynamic>{
                'id': 6454,
                'name': 'Madman Entertainment',
                'isAnimationStudio': false,
              },
            ],
          },
        },
      );
      expect(r.map((AniListStudio s) => s.id), <int>[2, 6454]);
      expect(r.first.name, 'Kyoto Animation');
      expect(r.first.isAnimationStudio, isTrue);
      expect(r.last.isAnimationStudio, isFalse);
    });
  });

  group('AniListMediaParser.animeStudioPage', () {
    Map<String, dynamic> studioPage({
      List<Map<String, dynamic>>? nodes,
      bool hasNextPage = false,
      int lastPage = 1,
      bool withMedia = true,
    }) =>
        <String, dynamic>{
          'Page': <String, dynamic>{
            'studios': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 2,
                'name': 'Kyoto Animation',
                if (withMedia)
                  'media': <String, dynamic>{
                    'pageInfo': <String, dynamic>{
                      'hasNextPage': hasNextPage,
                      'lastPage': lastPage,
                    },
                    'nodes': nodes ?? <Map<String, dynamic>>[],
                  },
              },
            ],
          },
        };

    test('null data yields empty result', () {
      final (List<Anime>, bool, int) r =
          AniListMediaParser.animeStudioPage(null);
      expect(r.$1, isEmpty);
      expect(r.$2, isFalse);
      expect(r.$3, 0);
    });

    test('no studio matched yields empty result', () {
      final (List<Anime>, bool, int) r = AniListMediaParser.animeStudioPage(
        <String, dynamic>{
          'Page': <String, dynamic>{'studios': <Map<String, dynamic>>[]},
        },
      );
      expect(r.$1, isEmpty);
      expect(r.$3, 0);
    });

    test('studio without a media connection yields empty result', () {
      final (List<Anime>, bool, int) r =
          AniListMediaParser.animeStudioPage(studioPage(withMedia: false));
      expect(r.$1, isEmpty);
    });

    test('reads nodes and pageInfo of the first studio', () {
      final (List<Anime>, bool, int) r = AniListMediaParser.animeStudioPage(
        studioPage(
          hasNextPage: true,
          lastPage: 166,
          nodes: <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 21827,
              'title': <String, dynamic>{'romaji': 'Violet Evergarden'},
            },
            <String, dynamic>{
              'id': 20954,
              'title': <String, dynamic>{'romaji': 'Koe no Katachi'},
            },
          ],
        ),
      );
      expect(r.$1.map((Anime a) => a.id), <int>[21827, 20954]);
      expect(r.$2, isTrue);
      expect(r.$3, 166);
    });
  });
}
