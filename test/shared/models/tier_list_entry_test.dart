import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/tier_list_entry.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('TierListEntry', () {
    group('fromDb', () {
      test('должен создавать из записи БД', () {
        final TierListEntry entry = TierListEntry.fromDb(<String, dynamic>{
          'collection_item_id': 42,
          'tier_key': 'S',
          'sort_order': 0,
        });

        expect(entry.collectionItemId, 42);
        expect(entry.tierKey, 'S');
        expect(entry.sortOrder, 0);
      });
    });

    group('toDb', () {
      test('должен сериализовать с tierListId', () {
        final TierListEntry entry = createTestTierListEntry(
          collectionItemId: 10,
          tierKey: 'A',
          sortOrder: 2,
        );

        final Map<String, dynamic> db = entry.toDb(5);
        expect(db['tier_list_id'], 5);
        expect(db['collection_item_id'], 10);
        expect(db['tier_key'], 'A');
        expect(db['sort_order'], 2);
      });
    });

    group('toExport / fromExport', () {
      test('round-trip', () {
        final TierListEntry original = createTestTierListEntry(
          collectionItemId: 7,
          tierKey: 'B',
          sortOrder: 3,
        );

        final Map<String, dynamic> exported = original.toExport();
        final TierListEntry restored = TierListEntry.fromExport(exported);

        expect(restored.collectionItemId, original.collectionItemId);
        expect(restored.tierKey, original.tierKey);
        expect(restored.sortOrder, original.sortOrder);
      });
    });

    group('copyWith', () {
      test('должен копировать с изменённым tierKey', () {
        final TierListEntry original = createTestTierListEntry(tierKey: 'S');
        final TierListEntry copy = original.copyWith(tierKey: 'A');
        expect(copy.tierKey, 'A');
        expect(copy.collectionItemId, original.collectionItemId);
      });

      test('должен копировать с изменённым sortOrder', () {
        final TierListEntry original = createTestTierListEntry(sortOrder: 0);
        final TierListEntry copy = original.copyWith(sortOrder: 5);
        expect(copy.sortOrder, 5);
      });
    });

    group('equality', () {
      test('равенство по collectionItemId + tierKey', () {
        final TierListEntry a = createTestTierListEntry(
          collectionItemId: 1,
          tierKey: 'S',
          sortOrder: 0,
        );
        final TierListEntry b = createTestTierListEntry(
          collectionItemId: 1,
          tierKey: 'S',
          sortOrder: 5,
        );
        expect(a, equals(b));
      });

      test('неравенство при разных collectionItemId', () {
        final TierListEntry a = createTestTierListEntry(collectionItemId: 1);
        final TierListEntry b = createTestTierListEntry(collectionItemId: 2);
        expect(a, isNot(equals(b)));
      });

      test('неравенство при разных tierKey', () {
        final TierListEntry a = createTestTierListEntry(tierKey: 'S');
        final TierListEntry b = createTestTierListEntry(tierKey: 'A');
        expect(a, isNot(equals(b)));
      });
    });
  });
}
