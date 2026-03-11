import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/tier_list.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('TierList', () {
    group('fromDb', () {
      test('должен создавать из записи БД', () {
        final TierList tierList = TierList.fromDb(<String, dynamic>{
          'id': 1,
          'name': 'My Tier List',
          'collection_id': 42,
          'created_at': 1705312800,
        });

        expect(tierList.id, 1);
        expect(tierList.name, 'My Tier List');
        expect(tierList.collectionId, 42);
        expect(tierList.createdAt.year, 2024);
      });

      test('должен обрабатывать null collection_id', () {
        final TierList tierList = TierList.fromDb(<String, dynamic>{
          'id': 2,
          'name': 'Global List',
          'collection_id': null,
          'created_at': 1705312800,
        });

        expect(tierList.collectionId, isNull);
        expect(tierList.isGlobal, isTrue);
      });
    });

    group('toDb', () {
      test('должен сериализовать в Map', () {
        final TierList tierList = createTestTierList(
          id: 5,
          name: 'RPG Tier',
          collectionId: 10,
        );

        final Map<String, dynamic> db = tierList.toDb();
        expect(db['id'], 5);
        expect(db['name'], 'RPG Tier');
        expect(db['collection_id'], 10);
        expect(db['created_at'], isA<int>());
      });

      test('должен сериализовать null collection_id', () {
        final TierList tierList = createTestTierList(collectionId: null);
        final Map<String, dynamic> db = tierList.toDb();
        expect(db['collection_id'], isNull);
      });
    });

    group('isGlobal', () {
      test('должен возвращать true для null collectionId', () {
        final TierList tierList = createTestTierList(collectionId: null);
        expect(tierList.isGlobal, isTrue);
      });

      test('должен возвращать false для non-null collectionId', () {
        final TierList tierList = createTestTierList(collectionId: 1);
        expect(tierList.isGlobal, isFalse);
      });
    });

    group('copyWith', () {
      test('должен копировать с изменённым name', () {
        final TierList original = createTestTierList(name: 'Old');
        final TierList copy = original.copyWith(name: 'New');
        expect(copy.name, 'New');
        expect(copy.id, original.id);
      });

      test('должен очищать collectionId', () {
        final TierList original = createTestTierList(collectionId: 5);
        final TierList copy = original.copyWith(clearCollectionId: true);
        expect(copy.collectionId, isNull);
      });
    });

    group('equality', () {
      test('равенство по id', () {
        final TierList a = createTestTierList(id: 1, name: 'A');
        final TierList b = createTestTierList(id: 1, name: 'B');
        expect(a, equals(b));
      });

      test('неравенство при разных id', () {
        final TierList a = createTestTierList(id: 1);
        final TierList b = createTestTierList(id: 2);
        expect(a, isNot(equals(b)));
      });
    });
  });
}
