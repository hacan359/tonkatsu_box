import 'package:core/models/collection_item.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/recommendations/anime_taste_input.dart';
import 'package:tonkatsu_box/features/recommendations/engine/recommendation_models.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('anime_taste_input', () {
    test('animeTasteId carries the source', () {
      expect(animeTasteId(DataSource.anilist, 21), 'anime:anilist:21');
      expect(animeTasteId(DataSource.kitsu, 12), 'anime:kitsu:12');
    });

    group('tasteTitleFromAnimeItem', () {
      test('should build features from genres and tags', () {
        final CollectionItem item = createTestCollectionItem(
          mediaType: MediaType.anime,
          externalId: 21,
          source: DataSource.anilist,
          status: ItemStatus.completed,
          userRating: 9,
          isFavorite: true,
          anime: createTestAnime(
            id: 21,
            genres: <String>['Action', 'Adventure'],
            tags: <String>['Pirates', 'Shounen'],
          ),
        );

        final TasteTitle? t = tasteTitleFromAnimeItem(item);

        expect(t, isNotNull);
        expect(t!.id, 'anime:anilist:21');
        expect(
          t.features.keys,
          containsAll(<String>['Action', 'Adventure', 'Pirates', 'Shounen']),
        );
        expect(t.rating, 9);
        expect(t.isFavorite, isTrue);
      });

      test('should return null for a Kitsu-sourced anime (no features)', () {
        final CollectionItem item = createTestCollectionItem(
          mediaType: MediaType.anime,
          externalId: 12,
          source: DataSource.kitsu,
          anime: createTestAnime(
            id: 12,
            source: DataSource.kitsu,
            genres: <String>['Action'],
          ),
        );

        expect(tasteTitleFromAnimeItem(item), isNull);
      });

      test('should return null without genres and tags', () {
        final CollectionItem item = createTestCollectionItem(
          mediaType: MediaType.anime,
          externalId: 21,
          source: DataSource.anilist,
          anime: createTestAnime(id: 21),
        );

        expect(tasteTitleFromAnimeItem(item), isNull);
      });

      test('should return null for other media types', () {
        expect(
          tasteTitleFromAnimeItem(
            createTestCollectionItem(mediaType: MediaType.game),
          ),
          isNull,
        );
      });
    });

    group('tasteTitleFromAnime', () {
      test('should vectorize a candidate without user signals', () {
        final TasteTitle? t = tasteTitleFromAnime(
          createTestAnime(id: 11061, genres: <String>['Action']),
        );

        expect(t!.id, 'anime:anilist:11061');
        expect(t.rating, isNull);
        expect(t.isFavorite, isFalse);
      });
    });

    group('ownedAnimeTasteIds', () {
      test('should collect anime of every source, and only anime', () {
        final Set<String> owned = ownedAnimeTasteIds(<CollectionItem>[
          createTestCollectionItem(
            mediaType: MediaType.anime,
            externalId: 21,
            source: DataSource.anilist,
          ),
          createTestCollectionItem(
            mediaType: MediaType.anime,
            externalId: 12,
            source: DataSource.kitsu,
          ),
          createTestCollectionItem(
            mediaType: MediaType.movie,
            externalId: 603,
          ),
        ]);

        expect(owned, <String>{'anime:anilist:21', 'anime:kitsu:12'});
      });
    });
  });
}
