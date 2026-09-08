import 'package:core/models/collection.dart';
import 'package:core/models/collection_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/helpers/item_editability.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('isItemEditable', () {
    final List<Collection> collections = <Collection>[
      createTestCollection(id: 1),
      createTestCollection(id: 2),
    ];

    test('should be editable when the item is uncategorized', () {
      final CollectionItem item = createTestCollectionItem(collectionId: null);
      expect(isItemEditable(item, null), isTrue);
      expect(isItemEditable(item, collections), isTrue);
    });

    test('should follow the owning collection', () {
      final CollectionItem item = createTestCollectionItem(collectionId: 2);
      expect(isItemEditable(item, collections), isTrue);
    });

    test('should stay locked when the collection is unknown', () {
      final CollectionItem item = createTestCollectionItem(collectionId: 9);
      expect(isItemEditable(item, collections), isFalse);
    });

    test('should stay locked while collections have not loaded', () {
      final CollectionItem item = createTestCollectionItem(collectionId: 1);
      expect(isItemEditable(item, null), isFalse);
    });
  });
}
