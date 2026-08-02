import 'package:core/models/collection_item.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/utils/media_format.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('MediaFormat', () {
    group('present', () {
      test('returns distinct manga formats in canonical order', () {
        final List<CollectionItem> items = <CollectionItem>[
          createTestCollectionItem(
            id: 1,
            mediaType: MediaType.manga,
            manga: createTestManga(format: 'MANHWA'),
          ),
          createTestCollectionItem(
            id: 2,
            mediaType: MediaType.manga,
            manga: createTestManga(format: 'MANGA'),
          ),
          createTestCollectionItem(
            id: 3,
            mediaType: MediaType.manga,
            manga: createTestManga(format: 'MANGA'),
          ),
        ];

        expect(
          MediaFormat.present(items, MediaType.manga),
          <String>['MANGA', 'MANHWA'],
        );
      });

      test('puts unrecognised format codes last', () {
        final List<CollectionItem> items = <CollectionItem>[
          createTestCollectionItem(
            id: 1,
            mediaType: MediaType.manga,
            manga: createTestManga(format: 'WEBTOON'),
          ),
          createTestCollectionItem(
            id: 2,
            mediaType: MediaType.manga,
            manga: createTestManga(format: 'MANGA'),
          ),
        ];

        expect(
          MediaFormat.present(items, MediaType.manga),
          <String>['MANGA', 'WEBTOON'],
        );
      });

      test('ignores items with null or empty format', () {
        final List<CollectionItem> items = <CollectionItem>[
          createTestCollectionItem(
            id: 1,
            mediaType: MediaType.manga,
            manga: createTestManga(),
          ),
          createTestCollectionItem(
            id: 2,
            mediaType: MediaType.manga,
            manga: createTestManga(format: ''),
          ),
          createTestCollectionItem(
            id: 3,
            mediaType: MediaType.manga,
            manga: createTestManga(format: 'MANGA'),
          ),
        ];

        expect(
          MediaFormat.present(items, MediaType.manga),
          <String>['MANGA'],
        );
      });

      test('ignores items of other media types', () {
        final List<CollectionItem> items = <CollectionItem>[
          createTestCollectionItem(
            id: 1,
            mediaType: MediaType.anime,
            anime: createTestAnime(format: 'TV'),
          ),
          createTestCollectionItem(id: 2),
        ];

        expect(MediaFormat.present(items, MediaType.manga), isEmpty);
        expect(
          MediaFormat.present(items, MediaType.anime),
          <String>['TV'],
        );
      });

      test('returns empty for a non manga/anime type', () {
        final List<CollectionItem> items = <CollectionItem>[
          createTestCollectionItem(
            id: 1,
            mediaType: MediaType.manga,
            manga: createTestManga(format: 'MANGA'),
          ),
        ];

        expect(MediaFormat.present(items, MediaType.game), isEmpty);
      });
    });

    group('matchesSubfilters', () {
      test('passes everything when no format is selected', () {
        final CollectionItem item = createTestCollectionItem(
          mediaType: MediaType.manga,
          manga: createTestManga(format: 'MANGA'),
        );

        expect(
          MediaFormat.matchesSubfilters(
            item,
            platformIds: const <int>{},
            mangaFormats: const <String>{},
            animeFormats: const <String>{},
          ),
          isTrue,
        );
      });

      test('hides unrelated media types once a format is active', () {
        final CollectionItem game = createTestCollectionItem();

        expect(
          MediaFormat.matchesSubfilters(
            game,
            platformIds: const <int>{},
            mangaFormats: const <String>{'MANGA'},
            animeFormats: const <String>{},
          ),
          isFalse,
        );
      });

      test('keeps a manga whose format is selected', () {
        final CollectionItem item = createTestCollectionItem(
          mediaType: MediaType.manga,
          manga: createTestManga(format: 'MANGA'),
        );

        expect(
          MediaFormat.matchesSubfilters(
            item,
            platformIds: const <int>{},
            mangaFormats: const <String>{'MANGA'},
            animeFormats: const <String>{},
          ),
          isTrue,
        );
      });

      test('hides a manga whose format is not selected', () {
        final CollectionItem item = createTestCollectionItem(
          mediaType: MediaType.manga,
          manga: createTestManga(format: 'MANHWA'),
        );

        expect(
          MediaFormat.matchesSubfilters(
            item,
            platformIds: const <int>{},
            mangaFormats: const <String>{'MANGA'},
            animeFormats: const <String>{},
          ),
          isFalse,
        );
      });

      test('hides an anime when only a manga format is active', () {
        final CollectionItem item = createTestCollectionItem(
          mediaType: MediaType.anime,
          anime: createTestAnime(format: 'TV'),
        );

        expect(
          MediaFormat.matchesSubfilters(
            item,
            platformIds: const <int>{},
            mangaFormats: const <String>{'MANGA'},
            animeFormats: const <String>{},
          ),
          isFalse,
        );
      });

      test('keeps either type when both format sets are active', () {
        final CollectionItem manga = createTestCollectionItem(
          mediaType: MediaType.manga,
          manga: createTestManga(format: 'MANGA'),
        );
        final CollectionItem anime = createTestCollectionItem(
          mediaType: MediaType.anime,
          anime: createTestAnime(format: 'TV'),
        );

        expect(
          MediaFormat.matchesSubfilters(
            manga,
            platformIds: const <int>{},
            mangaFormats: const <String>{'MANGA'},
            animeFormats: const <String>{'TV'},
          ),
          isTrue,
        );
        expect(
          MediaFormat.matchesSubfilters(
            anime,
            platformIds: const <int>{},
            mangaFormats: const <String>{'MANGA'},
            animeFormats: const <String>{'TV'},
          ),
          isTrue,
        );
      });

      test('platform and format groups unite: NES game and OVA anime both '
          'pass', () {
        final CollectionItem nesGame =
            createTestCollectionItem(platformId: 18);
        final CollectionItem ovaAnime = createTestCollectionItem(
          mediaType: MediaType.anime,
          anime: createTestAnime(format: 'OVA'),
        );

        for (final CollectionItem item in <CollectionItem>[nesGame, ovaAnime]) {
          expect(
            MediaFormat.matchesSubfilters(
              item,
              platformIds: const <int>{18},
              mangaFormats: const <String>{},
              animeFormats: const <String>{'OVA'},
            ),
            isTrue,
          );
        }
      });

      test('a game on another platform fails even with formats active', () {
        final CollectionItem game = createTestCollectionItem(platformId: 6);

        expect(
          MediaFormat.matchesSubfilters(
            game,
            platformIds: const <int>{18},
            mangaFormats: const <String>{},
            animeFormats: const <String>{'OVA'},
          ),
          isFalse,
        );
      });

      test('platform-only selection keeps matching games and hides the rest',
          () {
        final CollectionItem nesGame =
            createTestCollectionItem(platformId: 18);
        final CollectionItem anime = createTestCollectionItem(
          mediaType: MediaType.anime,
          anime: createTestAnime(format: 'TV'),
        );

        expect(
          MediaFormat.matchesSubfilters(
            nesGame,
            platformIds: const <int>{18},
            mangaFormats: const <String>{},
            animeFormats: const <String>{},
          ),
          isTrue,
        );
        expect(
          MediaFormat.matchesSubfilters(
            anime,
            platformIds: const <int>{18},
            mangaFormats: const <String>{},
            animeFormats: const <String>{},
          ),
          isFalse,
        );
      });

      test('hides a manga with no format when the filter is active', () {
        final CollectionItem item = createTestCollectionItem(
          mediaType: MediaType.manga,
          manga: createTestManga(),
        );

        expect(
          MediaFormat.matchesSubfilters(
            item,
            platformIds: const <int>{},
            mangaFormats: const <String>{'MANGA'},
            animeFormats: const <String>{},
          ),
          isFalse,
        );
      });
    });

    group('label', () {
      test('maps a known manga code to its display label', () {
        expect(MediaFormat.label(MediaType.manga, 'MANHWA'), 'Manhwa');
        expect(MediaFormat.label(MediaType.manga, 'LIGHT_NOVEL'), 'Light Novel');
      });

      test('maps a known anime code to its display label', () {
        expect(MediaFormat.label(MediaType.anime, 'TV_SHORT'), 'TV Short');
        expect(MediaFormat.label(MediaType.anime, 'OVA'), 'OVA');
      });

      test('falls back to the raw code for an unknown value', () {
        expect(MediaFormat.label(MediaType.manga, 'WEBTOON'), 'WEBTOON');
      });
    });
  });
}
