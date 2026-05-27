import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/helpers/collection_filters.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/collection_tag.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('CollectionFilters.apply', () {
    CollectionItem make({
      int id = 1,
      MediaType mediaType = MediaType.game,
      int? platformId,
      int? tagId,
      ItemStatus status = ItemStatus.notStarted,
      String? name,
      String? userComment,
      String? authorComment,
    }) =>
        createTestCollectionItem(
          id: id,
          mediaType: mediaType,
          externalId: id,
          platformId: platformId,
          tagId: tagId,
          status: status,
          overrideName: name,
          userComment: userComment,
          authorComment: authorComment,
        );

    final List<CollectionTag> tags = <CollectionTag>[
      createTestCollectionTag(id: 10, name: 'Favorites'),
      createTestCollectionTag(id: 20, name: 'Backlog'),
    ];

    test('no filters returns the list unchanged', () {
      final List<CollectionItem> items = <CollectionItem>[make(id: 1), make(id: 2)];
      expect(const CollectionFilters().apply(items, tags), items);
    });

    test('filters by media type', () {
      final List<CollectionItem> items = <CollectionItem>[
        make(id: 1, mediaType: MediaType.game),
        make(id: 2, mediaType: MediaType.movie),
        make(id: 3, mediaType: MediaType.movie),
      ];
      final List<CollectionItem> r = const CollectionFilters(
        mediaTypes: <MediaType>{MediaType.movie},
      ).apply(items, tags);
      expect(r.map((CollectionItem i) => i.id), <int>[2, 3]);
    });

    test('filters by platform id, excluding null platforms', () {
      final List<CollectionItem> items = <CollectionItem>[
        make(id: 1, platformId: 48),
        make(id: 2, platformId: 6),
        make(id: 3),
      ];
      final List<CollectionItem> r =
          const CollectionFilters(platformIds: <int>{48}).apply(items, tags);
      expect(r.map((CollectionItem i) => i.id), <int>[1]);
    });

    test('filters by tag id', () {
      final List<CollectionItem> items = <CollectionItem>[
        make(id: 1, tagId: 10),
        make(id: 2, tagId: 20),
        make(id: 3),
      ];
      final List<CollectionItem> r =
          const CollectionFilters(tagIds: <int>{10}).apply(items, tags);
      expect(r.map((CollectionItem i) => i.id), <int>[1]);
    });

    test('filters by status', () {
      final List<CollectionItem> items = <CollectionItem>[
        make(id: 1, status: ItemStatus.completed),
        make(id: 2, status: ItemStatus.inProgress),
      ];
      final List<CollectionItem> r =
          const CollectionFilters(status: ItemStatus.completed).apply(items, tags);
      expect(r.map((CollectionItem i) => i.id), <int>[1]);
    });

    test('search matches name case-insensitively', () {
      final List<CollectionItem> items = <CollectionItem>[
        make(id: 1, name: 'The Legend of Zelda'),
        make(id: 2, name: 'Halo'),
      ];
      final List<CollectionItem> r =
          const CollectionFilters(searchQuery: 'zelda').apply(items, tags);
      expect(r.map((CollectionItem i) => i.id), <int>[1]);
    });

    test('search matches by tag name', () {
      final List<CollectionItem> items = <CollectionItem>[
        make(id: 1, name: 'A', tagId: 10), // tag "Favorites"
        make(id: 2, name: 'B', tagId: 20), // tag "Backlog"
      ];
      final List<CollectionItem> r =
          const CollectionFilters(searchQuery: 'favor').apply(items, tags);
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
            .apply(items, tags)
            .map((CollectionItem i) => i.id),
        <int>[1],
      );
      expect(
        const CollectionFilters(searchQuery: 'gem')
            .apply(items, tags)
            .map((CollectionItem i) => i.id),
        <int>[2],
      );
    });

    test('combines filters with AND semantics', () {
      final List<CollectionItem> items = <CollectionItem>[
        make(id: 1, mediaType: MediaType.game, status: ItemStatus.completed),
        make(id: 2, mediaType: MediaType.game, status: ItemStatus.inProgress),
        make(id: 3, mediaType: MediaType.movie, status: ItemStatus.completed),
      ];
      final List<CollectionItem> r = const CollectionFilters(
        mediaTypes: <MediaType>{MediaType.game},
        status: ItemStatus.completed,
      ).apply(items, tags);
      expect(r.map((CollectionItem i) => i.id), <int>[1]);
    });
  });
}
