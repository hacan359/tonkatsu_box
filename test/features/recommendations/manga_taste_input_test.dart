import 'package:core/models/collection_item.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/recommendations/engine/recommendation_models.dart';
import 'package:tonkatsu_box/features/recommendations/manga_taste_input.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('manga_taste_input', () {
    test('mangaTasteId carries the source', () {
      expect(mangaTasteId(DataSource.mangabaka, 42), 'manga:mangabaka:42');
      expect(mangaTasteId(DataSource.anilist, 30002), 'manga:anilist:30002');
    });

    group('tasteTitleFromMangaItem', () {
      CollectionItem itemFor(DataSource source) => createTestCollectionItem(
            mediaType: MediaType.manga,
            externalId: 42,
            source: source,
            manga: createTestManga(id: 42).copyWith(
              source: source,
              genres: <String>['Action'],
              tags: <String>['Dark Fantasy'],
            ),
          );

      test('should build a title only for the requested source', () {
        final CollectionItem item = itemFor(DataSource.mangabaka);

        final TasteTitle? t =
            tasteTitleFromMangaItem(item, DataSource.mangabaka);
        expect(t, isNotNull);
        expect(t!.id, 'manga:mangabaka:42');
        expect(
          t.features.keys,
          containsAll(<String>['Action', 'Dark Fantasy']),
        );

        expect(tasteTitleFromMangaItem(item, DataSource.anilist), isNull);
      });

      test('should return null for other media types', () {
        expect(
          tasteTitleFromMangaItem(
            createTestCollectionItem(mediaType: MediaType.book),
            DataSource.mangabaka,
          ),
          isNull,
        );
      });
    });

    group('ownedMangaTasteIds', () {
      test('should key owned manga by their own source', () {
        final Set<String> owned = ownedMangaTasteIds(<CollectionItem>[
          createTestCollectionItem(
            mediaType: MediaType.manga,
            externalId: 42,
            source: DataSource.mangabaka,
          ),
          createTestCollectionItem(
            mediaType: MediaType.manga,
            externalId: 42,
            source: DataSource.mangadex,
          ),
        ]);

        // Same numeric id, different sources — both kept apart.
        expect(
          owned,
          <String>{'manga:mangabaka:42', 'manga:mangadex:42'},
        );
      });
    });
  });
}
