import 'package:core/models/collection_item.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/tag.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/helpers/collection_filters.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('CollectionFilters.apply', () {
    CollectionItem make({
      int id = 1,
      MediaType mediaType = MediaType.game,
      int? platformId,
      ItemStatus status = ItemStatus.notStarted,
      String? name,
      String? userComment,
      String? authorComment,
      bool isFavorite = false,
    }) =>
        createTestCollectionItem(
          id: id,
          mediaType: mediaType,
          externalId: id,
          platformId: platformId,
          status: status,
          overrideName: name,
          userComment: userComment,
          authorComment: authorComment,
          isFavorite: isFavorite,
        );

    final List<Tag> tags = <Tag>[
      createTestTag(id: 10, name: 'Favorites'),
      createTestTag(id: 20, name: 'Backlog'),
    ];
    const Map<int, List<int>> noLinks = <int, List<int>>{};

    test('no filters returns the list unchanged', () {
      final List<CollectionItem> items = <CollectionItem>[make(id: 1), make(id: 2)];
      expect(const CollectionFilters().apply(items, tags, noLinks), items);
    });

    test('filters by media type', () {
      final List<CollectionItem> items = <CollectionItem>[
        make(id: 1, mediaType: MediaType.game),
        make(id: 2, mediaType: MediaType.movie),
        make(id: 3, mediaType: MediaType.movie),
      ];
      final List<CollectionItem> r = const CollectionFilters(
        mediaTypes: <MediaType>{MediaType.movie},
      ).apply(items, tags, noLinks);
      expect(r.map((CollectionItem i) => i.id), <int>[2, 3]);
    });

    test('filters by platform id, excluding null platforms', () {
      final List<CollectionItem> items = <CollectionItem>[
        make(id: 1, platformId: 48),
        make(id: 2, platformId: 6),
        make(id: 3),
      ];
      final List<CollectionItem> r = const CollectionFilters(
        platformIds: <int>{48},
      ).apply(items, tags, noLinks);
      expect(r.map((CollectionItem i) => i.id), <int>[1]);
    });

    test('filters by tag id over the item-tags map', () {
      final List<CollectionItem> items = <CollectionItem>[
        make(id: 1),
        make(id: 2),
        make(id: 3),
      ];
      final Map<int, List<int>> links = <int, List<int>>{
        1: <int>[10],
        2: <int>[20],
      };
      final List<CollectionItem> r = const CollectionFilters(
        tagIds: <int>{10},
      ).apply(items, tags, links);
      expect(r.map((CollectionItem i) => i.id), <int>[1]);
    });

    test('tag filter is OR: any selected tag keeps the item', () {
      final List<CollectionItem> items = <CollectionItem>[
        make(id: 1),
        make(id: 2),
        make(id: 3),
      ];
      final Map<int, List<int>> links = <int, List<int>>{
        1: <int>[10],
        2: <int>[20],
        3: <int>[10, 20],
      };
      final List<CollectionItem> r = const CollectionFilters(
        tagIds: <int>{10, 20},
      ).apply(items, tags, links);
      expect(r.map((CollectionItem i) => i.id), <int>[1, 2, 3]);
    });

    test('tag filter hides untagged items', () {
      final List<CollectionItem> items = <CollectionItem>[
        make(id: 1),
        make(id: 2),
      ];
      final Map<int, List<int>> links = <int, List<int>>{
        1: <int>[10],
      };
      final List<CollectionItem> r = const CollectionFilters(
        tagIds: <int>{10, 20},
      ).apply(items, tags, links);
      expect(r.map((CollectionItem i) => i.id), <int>[1]);
    });

    test('filters by status', () {
      final List<CollectionItem> items = <CollectionItem>[
        make(id: 1, status: ItemStatus.completed),
        make(id: 2, status: ItemStatus.inProgress),
      ];
      final List<CollectionItem> r = const CollectionFilters(
        statuses: <ItemStatus>{ItemStatus.completed},
      ).apply(items, tags, noLinks);
      expect(r.map((CollectionItem i) => i.id), <int>[1]);
    });

    test('keeps an item matching ANY of several statuses', () {
      final List<CollectionItem> items = <CollectionItem>[
        make(id: 1, status: ItemStatus.completed),
        make(id: 2, status: ItemStatus.inProgress),
        make(id: 3, status: ItemStatus.ignored),
      ];
      final List<CollectionItem> r = const CollectionFilters(
        statuses: <ItemStatus>{ItemStatus.completed, ItemStatus.ignored},
      ).apply(items, tags, noLinks);
      expect(r.map((CollectionItem i) => i.id), <int>[1, 3]);
    });

    test('an empty status set filters nothing out', () {
      final List<CollectionItem> items = <CollectionItem>[
        make(id: 1, status: ItemStatus.completed),
        make(id: 2, status: ItemStatus.inProgress),
      ];
      final List<CollectionItem> r =
          const CollectionFilters().apply(items, tags, noLinks);
      expect(r.map((CollectionItem i) => i.id), <int>[1, 2]);
    });

    test('filters by favourite', () {
      final List<CollectionItem> items = <CollectionItem>[
        make(id: 1, isFavorite: true),
        make(id: 2),
      ];
      final List<CollectionItem> r =
          const CollectionFilters(favoriteOnly: true).apply(items, tags, noLinks);
      expect(r.map((CollectionItem i) => i.id), <int>[1]);
    });

    test('favourite combines with the other filters', () {
      final List<CollectionItem> items = <CollectionItem>[
        make(id: 1, isFavorite: true, status: ItemStatus.completed),
        make(id: 2, isFavorite: true, status: ItemStatus.inProgress),
        make(id: 3, status: ItemStatus.completed),
      ];
      final List<CollectionItem> r = const CollectionFilters(
        favoriteOnly: true,
        statuses: <ItemStatus>{ItemStatus.completed},
      ).apply(items, tags, noLinks);
      expect(r.map((CollectionItem i) => i.id), <int>[1]);
    });

    test('search matches name case-insensitively', () {
      final List<CollectionItem> items = <CollectionItem>[
        make(id: 1, name: 'The Legend of Zelda'),
        make(id: 2, name: 'Halo'),
      ];
      final List<CollectionItem> r = const CollectionFilters(
        searchQuery: 'zelda',
      ).apply(items, tags, noLinks);
      expect(r.map((CollectionItem i) => i.id), <int>[1]);
    });

    test('search matches by any tag name of the item', () {
      final List<CollectionItem> items = <CollectionItem>[
        make(id: 1, name: 'A'),
        make(id: 2, name: 'B'),
      ];
      final Map<int, List<int>> links = <int, List<int>>{
        1: <int>[20, 10], // Backlog + Favorites
        2: <int>[20], // Backlog
      };
      final List<CollectionItem> r = const CollectionFilters(
        searchQuery: 'favor',
      ).apply(items, tags, links);
      expect(r.map((CollectionItem i) => i.id), <int>[1]);
    });

    test('search matches user and author comments', () {
      final List<CollectionItem> items = <CollectionItem>[
        make(id: 1, name: 'A', userComment: 'masterpiece'),
        make(id: 2, name: 'B', authorComment: 'underrated gem'),
        make(id: 3, name: 'C'),
      ];
      expect(
        const CollectionFilters(searchQuery: 'master')
            .apply(items, tags, noLinks)
            .map((CollectionItem i) => i.id),
        <int>[1],
      );
      expect(
        const CollectionFilters(searchQuery: 'gem')
            .apply(items, tags, noLinks)
            .map((CollectionItem i) => i.id),
        <int>[2],
      );
    });

    test('manga format filter narrows to the format, hiding other types', () {
      final List<CollectionItem> items = <CollectionItem>[
        createTestCollectionItem(
          id: 1,
          mediaType: MediaType.manga,
          manga: createTestManga(format: 'MANGA'),
        ),
        createTestCollectionItem(
          id: 2,
          mediaType: MediaType.manga,
          manga: createTestManga(format: 'MANHWA'),
        ),
        createTestCollectionItem(id: 3, mediaType: MediaType.game),
      ];
      final List<CollectionItem> r = const CollectionFilters(
        mangaFormats: <String>{'MANGA'},
      ).apply(items, tags, noLinks);
      expect(r.map((CollectionItem i) => i.id), <int>[1]);
    });

    test('manga and anime format filters keep either type (OR)', () {
      final List<CollectionItem> items = <CollectionItem>[
        createTestCollectionItem(
          id: 1,
          mediaType: MediaType.manga,
          manga: createTestManga(format: 'MANGA'),
        ),
        createTestCollectionItem(
          id: 2,
          mediaType: MediaType.anime,
          anime: createTestAnime(format: 'TV'),
        ),
        createTestCollectionItem(
          id: 3,
          mediaType: MediaType.anime,
          anime: createTestAnime(format: 'OVA'),
        ),
        createTestCollectionItem(id: 4, mediaType: MediaType.game),
      ];
      final List<CollectionItem> r = const CollectionFilters(
        mangaFormats: <String>{'MANGA'},
        animeFormats: <String>{'TV'},
      ).apply(items, tags, noLinks);
      expect(r.map((CollectionItem i) => i.id), <int>[1, 2]);
    });

    test('platform and format subfilters keep either kind (OR)', () {
      final List<CollectionItem> items = <CollectionItem>[
        make(id: 1, platformId: 18),
        make(id: 2, platformId: 6),
        createTestCollectionItem(
          id: 3,
          mediaType: MediaType.anime,
          anime: createTestAnime(format: 'OVA'),
        ),
        createTestCollectionItem(
          id: 4,
          mediaType: MediaType.anime,
          anime: createTestAnime(format: 'TV'),
        ),
      ];
      final List<CollectionItem> r = const CollectionFilters(
        platformIds: <int>{18},
        animeFormats: <String>{'OVA'},
      ).apply(items, tags, noLinks);
      expect(r.map((CollectionItem i) => i.id), <int>[1, 3]);
    });

    test('combines filters with AND semantics', () {
      final List<CollectionItem> items = <CollectionItem>[
        make(id: 1, mediaType: MediaType.game, status: ItemStatus.completed),
        make(id: 2, mediaType: MediaType.game, status: ItemStatus.inProgress),
        make(id: 3, mediaType: MediaType.movie, status: ItemStatus.completed),
      ];
      final List<CollectionItem> r = const CollectionFilters(
        mediaTypes: <MediaType>{MediaType.game},
        statuses: <ItemStatus>{ItemStatus.completed},
      ).apply(items, tags, noLinks);
      expect(r.map((CollectionItem i) => i.id), <int>[1]);
    });
  });
}
