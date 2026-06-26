import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/models/collection_item.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
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

    group('matchesFormatFilter', () {
      test('passes everything when no format is selected', () {
        final CollectionItem item = createTestCollectionItem(
          mediaType: MediaType.manga,
          manga: createTestManga(format: 'MANGA'),
        );

        expect(
          MediaFormat.matchesFormatFilter(
            item,
            mangaFormats: const <String>{},
            animeFormats: const <String>{},
          ),
          isTrue,
        );
      });

      test('hides unrelated media types once a format is active', () {
        final CollectionItem game = createTestCollectionItem();

        expect(
          MediaFormat.matchesFormatFilter(
            game,
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
          MediaFormat.matchesFormatFilter(
            item,
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
          MediaFormat.matchesFormatFilter(
            item,
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
          MediaFormat.matchesFormatFilter(
            item,
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
          MediaFormat.matchesFormatFilter(
            manga,
            mangaFormats: const <String>{'MANGA'},
            animeFormats: const <String>{'TV'},
          ),
          isTrue,
        );
        expect(
          MediaFormat.matchesFormatFilter(
            anime,
            mangaFormats: const <String>{'MANGA'},
            animeFormats: const <String>{'TV'},
          ),
          isTrue,
        );
      });

      test('hides a manga with no format when the filter is active', () {
        final CollectionItem item = createTestCollectionItem(
          mediaType: MediaType.manga,
          manga: createTestManga(),
        );

        expect(
          MediaFormat.matchesFormatFilter(
            item,
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
