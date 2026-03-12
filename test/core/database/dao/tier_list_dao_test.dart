import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/database/dao/tier_list_dao.dart';
import 'package:xerabora/shared/models/tier_definition.dart';
import 'package:xerabora/shared/models/tier_list.dart';
import 'package:xerabora/shared/models/tier_list_entry.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockDatabase mockDb;
  late TierListDao dao;

  setUp(() {
    mockDb = MockDatabase();
    dao = TierListDao(() async => mockDb);
  });

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  group('TierListDao', () {
    // ==================== Tier Lists ====================

    group('getAllTierLists', () {
      test('returns all tier lists ordered by created_at DESC', () async {
        when(
          () => mockDb.query(
            'tier_lists',
            orderBy: 'created_at DESC',
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 2,
              'name': 'List 2',
              'collection_id': null,
              'created_at': 1705320000,
            },
            <String, dynamic>{
              'id': 1,
              'name': 'List 1',
              'collection_id': 5,
              'created_at': 1705310000,
            },
          ],
        );

        final List<TierList> result = await dao.getAllTierLists();

        expect(result, hasLength(2));
        expect(result[0].name, 'List 2');
        expect(result[1].collectionId, 5);
      });

      test('returns empty list when no tier lists', () async {
        when(
          () => mockDb.query(
            'tier_lists',
            orderBy: 'created_at DESC',
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        final List<TierList> result = await dao.getAllTierLists();
        expect(result, isEmpty);
      });
    });

    group('getTierListsByCollection', () {
      test('returns tier lists for specific collection', () async {
        when(
          () => mockDb.query(
            'tier_lists',
            where: 'collection_id = ?',
            whereArgs: <Object?>[42],
            orderBy: 'created_at DESC',
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 1,
              'name': 'Collection TL',
              'collection_id': 42,
              'created_at': 1705320000,
            },
          ],
        );

        final List<TierList> result =
            await dao.getTierListsByCollection(42);

        expect(result, hasLength(1));
        expect(result.first.collectionId, 42);
      });
    });

    group('getTierListById', () {
      test('returns tier list when found', () async {
        when(
          () => mockDb.query(
            'tier_lists',
            where: 'id = ?',
            whereArgs: <Object?>[1],
            limit: 1,
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 1,
              'name': 'Test',
              'collection_id': null,
              'created_at': 1705320000,
            },
          ],
        );

        final TierList? result = await dao.getTierListById(1);
        expect(result, isNotNull);
        expect(result!.name, 'Test');
      });

      test('returns null when not found', () async {
        when(
          () => mockDb.query(
            'tier_lists',
            where: 'id = ?',
            whereArgs: <Object?>[999],
            limit: 1,
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        final TierList? result = await dao.getTierListById(999);
        expect(result, isNull);
      });
    });

    group('createTierList', () {
      test('inserts and returns tier list with id', () async {
        when(
          () => mockDb.insert('tier_lists', any()),
        ).thenAnswer((_) async => 7);

        final TierList result = await dao.createTierList(
          'My RPG Tier',
          collectionId: 3,
        );

        expect(result.id, 7);
        expect(result.name, 'My RPG Tier');
        expect(result.collectionId, 3);
      });

      test('creates global tier list when no collectionId', () async {
        when(
          () => mockDb.insert('tier_lists', any()),
        ).thenAnswer((_) async => 1);

        final TierList result = await dao.createTierList('Global');

        expect(result.isGlobal, isTrue);
      });
    });

    group('renameTierList', () {
      test('updates name', () async {
        when(
          () => mockDb.update(
            'tier_lists',
            <String, dynamic>{'name': 'New Name'},
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 1);

        await dao.renameTierList(1, 'New Name');

        verify(
          () => mockDb.update(
            'tier_lists',
            <String, dynamic>{'name': 'New Name'},
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).called(1);
      });
    });

    group('deleteTierList', () {
      test('deletes by id', () async {
        when(
          () => mockDb.delete(
            'tier_lists',
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 1);

        await dao.deleteTierList(1);

        verify(
          () => mockDb.delete(
            'tier_lists',
            where: 'id = ?',
            whereArgs: <Object?>[1],
          ),
        ).called(1);
      });
    });

    // ==================== Definitions ====================

    group('getTierDefinitions', () {
      test('returns definitions ordered by sort_order', () async {
        when(
          () => mockDb.query(
            'tier_definitions',
            where: 'tier_list_id = ?',
            whereArgs: <Object?>[1],
            orderBy: 'sort_order ASC',
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{
              'tier_key': 'S',
              'label': 'S',
              'color': 0xFFFF4444,
              'sort_order': 0,
            },
            <String, dynamic>{
              'tier_key': 'A',
              'label': 'A',
              'color': 0xFFFF8C00,
              'sort_order': 1,
            },
          ],
        );

        final List<TierDefinition> result =
            await dao.getTierDefinitions(1);

        expect(result, hasLength(2));
        expect(result[0].tierKey, 'S');
        expect(result[1].tierKey, 'A');
      });
    });

    group('saveTierDefinitions', () {
      test('deletes old and inserts new definitions', () async {
        final TransactionMockDatabase txnDb = TransactionMockDatabase();
        final MockTransaction mockTxn = MockTransaction();
        txnDb.stubTransaction(mockTxn);

        final TierListDao txnDao = TierListDao(() async => txnDb);

        when(
          () => mockTxn.delete(
            'tier_definitions',
            where: 'tier_list_id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 2);

        when(
          () => mockTxn.insert('tier_definitions', any()),
        ).thenAnswer((_) async => 1);

        await txnDao.saveTierDefinitions(1, TierDefinition.defaults);

        verify(
          () => mockTxn.delete(
            'tier_definitions',
            where: 'tier_list_id = ?',
            whereArgs: <Object?>[1],
          ),
        ).called(1);
        verify(
          () => mockTxn.insert('tier_definitions', any()),
        ).called(4);
      });
    });

    // ==================== Entries ====================

    group('getTierListEntries', () {
      test('returns entries ordered by sort_order', () async {
        when(
          () => mockDb.query(
            'tier_list_entries',
            where: 'tier_list_id = ?',
            whereArgs: <Object?>[1],
            orderBy: 'sort_order ASC',
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{
              'collection_item_id': 10,
              'tier_key': 'S',
              'sort_order': 0,
            },
            <String, dynamic>{
              'collection_item_id': 20,
              'tier_key': 'S',
              'sort_order': 1,
            },
          ],
        );

        final List<TierListEntry> result =
            await dao.getTierListEntries(1);

        expect(result, hasLength(2));
        expect(result[0].collectionItemId, 10);
        expect(result[1].collectionItemId, 20);
      });
    });

    group('setItemTier', () {
      test('deletes old entry and inserts new', () async {
        when(
          () => mockDb.delete(
            'tier_list_entries',
            where: 'tier_list_id = ? AND collection_item_id = ?',
            whereArgs: <Object?>[1, 42],
          ),
        ).thenAnswer((_) async => 0);

        when(
          () => mockDb.insert('tier_list_entries', any()),
        ).thenAnswer((_) async => 1);

        await dao.setItemTier(1, 42, 'A', 0);

        verify(
          () => mockDb.delete(
            'tier_list_entries',
            where: 'tier_list_id = ? AND collection_item_id = ?',
            whereArgs: <Object?>[1, 42],
          ),
        ).called(1);
        verify(
          () => mockDb.insert('tier_list_entries', any()),
        ).called(1);
      });
    });

    group('removeItemFromTier', () {
      test('deletes entry', () async {
        when(
          () => mockDb.delete(
            'tier_list_entries',
            where: 'tier_list_id = ? AND collection_item_id = ?',
            whereArgs: <Object?>[1, 42],
          ),
        ).thenAnswer((_) async => 1);

        await dao.removeItemFromTier(1, 42);

        verify(
          () => mockDb.delete(
            'tier_list_entries',
            where: 'tier_list_id = ? AND collection_item_id = ?',
            whereArgs: <Object?>[1, 42],
          ),
        ).called(1);
      });
    });

    group('reorderTierItems', () {
      test('updates sort_order for each item', () async {
        final TransactionMockDatabase txnDb = TransactionMockDatabase();
        final MockTransaction mockTxn = MockTransaction();
        txnDb.stubTransaction(mockTxn);

        final TierListDao txnDao = TierListDao(() async => txnDb);

        when(
          () => mockTxn.update(
            'tier_list_entries',
            any(),
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
          ),
        ).thenAnswer((_) async => 1);

        await txnDao.reorderTierItems(1, 'S', <int>[20, 10, 30]);

        verify(
          () => mockTxn.update(
            'tier_list_entries',
            any(),
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
          ),
        ).called(3);
      });
    });

    group('clearTierListEntries', () {
      test('deletes all entries for tier list', () async {
        when(
          () => mockDb.delete(
            'tier_list_entries',
            where: 'tier_list_id = ?',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 5);

        await dao.clearTierListEntries(1);

        verify(
          () => mockDb.delete(
            'tier_list_entries',
            where: 'tier_list_id = ?',
            whereArgs: <Object?>[1],
          ),
        ).called(1);
      });
    });

    group('removeItemFromCollectionTierLists', () {
      test('deletes entries for item in collection tier lists', () async {
        when(
          () => mockDb.rawDelete(
            'DELETE FROM tier_list_entries '
            'WHERE collection_item_id = ? '
            'AND tier_list_id IN '
            '(SELECT id FROM tier_lists WHERE collection_id = ?)',
            <Object?>[42, 5],
          ),
        ).thenAnswer((_) async => 1);

        await dao.removeItemFromCollectionTierLists(42, 5);

        verify(
          () => mockDb.rawDelete(
            'DELETE FROM tier_list_entries '
            'WHERE collection_item_id = ? '
            'AND tier_list_id IN '
            '(SELECT id FROM tier_lists WHERE collection_id = ?)',
            <Object?>[42, 5],
          ),
        ).called(1);
      });

      test('does nothing when no matching entries', () async {
        when(
          () => mockDb.rawDelete(
            any(),
            any(),
          ),
        ).thenAnswer((_) async => 0);

        await dao.removeItemFromCollectionTierLists(999, 999);

        verify(() => mockDb.rawDelete(any(), any())).called(1);
      });
    });

    group('getTierListIdsForItem', () {
      test('returns tier list IDs containing the item', () async {
        when(
          () => mockDb.rawQuery(
            'SELECT DISTINCT tier_list_id FROM tier_list_entries '
            'WHERE collection_item_id = ?',
            <Object?>[42],
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'tier_list_id': 1},
            <String, dynamic>{'tier_list_id': 3},
          ],
        );

        final List<int> result = await dao.getTierListIdsForItem(42);

        expect(result, <int>[1, 3]);
      });

      test('returns empty list when item not in any tier list', () async {
        when(
          () => mockDb.rawQuery(
            'SELECT DISTINCT tier_list_id FROM tier_list_entries '
            'WHERE collection_item_id = ?',
            <Object?>[999],
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        final List<int> result = await dao.getTierListIdsForItem(999);

        expect(result, isEmpty);
      });
    });

    group('getRankedCount', () {
      test('returns count of entries', () async {
        when(
          () => mockDb.rawQuery(
            'SELECT COUNT(*) as count FROM tier_list_entries WHERE tier_list_id = ?',
            <Object?>[1],
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'count': 12},
          ],
        );

        final int result = await dao.getRankedCount(1);
        expect(result, 12);
      });
    });
  });
}
