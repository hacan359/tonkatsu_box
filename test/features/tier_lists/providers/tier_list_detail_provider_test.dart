// Тесты для TierListDetailState и TierListDetailNotifier.

import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/features/tier_lists/providers/tier_list_detail_provider.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/tier_definition.dart';
import 'package:xerabora/shared/models/tier_list.dart';
import 'package:xerabora/shared/models/tier_list_entry.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    registerAllFallbacks();
  });

  // =========================================================================
  // TierListDetailState
  // =========================================================================
  group('TierListDetailState', () {
    group('loading()', () {
      test('should create state with isLoading true', () {
        final TierListDetailState state = TierListDetailState.loading();

        expect(state.isLoading, isTrue);
        expect(state.tierList.id, 0);
        expect(state.tierList.name, '');
        expect(state.definitions, isEmpty);
        expect(state.entries, isEmpty);
        expect(state.items, isEmpty);
      });
    });

    group('placedItemIds', () {
      test('should return empty set when no entries', () {
        final TierListDetailState state = TierListDetailState(
          tierList: createTestTierList(),
          definitions: const <TierDefinition>[],
          entries: const <TierListEntry>[],
          items: const <CollectionItem>[],
        );

        expect(state.placedItemIds, isEmpty);
      });

      test('should return set of collectionItemIds from entries', () {
        final TierListDetailState state = TierListDetailState(
          tierList: createTestTierList(),
          definitions: const <TierDefinition>[],
          entries: <TierListEntry>[
            createTestTierListEntry(collectionItemId: 1, tierKey: 'S'),
            createTestTierListEntry(collectionItemId: 2, tierKey: 'A'),
            createTestTierListEntry(collectionItemId: 3, tierKey: 'S'),
          ],
          items: const <CollectionItem>[],
        );

        expect(state.placedItemIds, equals(<int>{1, 2, 3}));
      });
    });

    group('unrankedItems', () {
      test('should return all items when no entries', () {
        final List<CollectionItem> items = <CollectionItem>[
          createTestCollectionItem(id: 1),
          createTestCollectionItem(id: 2),
        ];
        final TierListDetailState state = TierListDetailState(
          tierList: createTestTierList(),
          definitions: const <TierDefinition>[],
          entries: const <TierListEntry>[],
          items: items,
        );

        expect(state.unrankedItems, hasLength(2));
      });

      test('should exclude placed items', () {
        final List<CollectionItem> items = <CollectionItem>[
          createTestCollectionItem(id: 1),
          createTestCollectionItem(id: 2),
          createTestCollectionItem(id: 3),
        ];
        final TierListDetailState state = TierListDetailState(
          tierList: createTestTierList(),
          definitions: const <TierDefinition>[],
          entries: <TierListEntry>[
            createTestTierListEntry(collectionItemId: 1, tierKey: 'S'),
            createTestTierListEntry(collectionItemId: 3, tierKey: 'A'),
          ],
          items: items,
        );

        expect(state.unrankedItems, hasLength(1));
        expect(state.unrankedItems.first.id, 2);
      });

      test('should return empty list when all items are placed', () {
        final List<CollectionItem> items = <CollectionItem>[
          createTestCollectionItem(id: 1),
        ];
        final TierListDetailState state = TierListDetailState(
          tierList: createTestTierList(),
          definitions: const <TierDefinition>[],
          entries: <TierListEntry>[
            createTestTierListEntry(collectionItemId: 1, tierKey: 'S'),
          ],
          items: items,
        );

        expect(state.unrankedItems, isEmpty);
      });
    });

    group('entriesByTier', () {
      test('should return empty lists for each definition when no entries', () {
        final TierListDetailState state = TierListDetailState(
          tierList: createTestTierList(),
          definitions: <TierDefinition>[
            createTestTierDefinition(tierKey: 'S'),
            createTestTierDefinition(tierKey: 'A'),
          ],
          entries: const <TierListEntry>[],
          items: const <CollectionItem>[],
        );

        final Map<String, List<TierListEntry>> result = state.entriesByTier;
        expect(result.keys, containsAll(<String>['S', 'A']));
        expect(result['S'], isEmpty);
        expect(result['A'], isEmpty);
      });

      test('should group entries by tier key', () {
        final TierListDetailState state = TierListDetailState(
          tierList: createTestTierList(),
          definitions: <TierDefinition>[
            createTestTierDefinition(tierKey: 'S'),
            createTestTierDefinition(tierKey: 'A'),
          ],
          entries: <TierListEntry>[
            createTestTierListEntry(collectionItemId: 1, tierKey: 'S'),
            createTestTierListEntry(collectionItemId: 2, tierKey: 'A'),
            createTestTierListEntry(collectionItemId: 3, tierKey: 'S'),
          ],
          items: const <CollectionItem>[],
        );

        final Map<String, List<TierListEntry>> result = state.entriesByTier;
        expect(result['S'], hasLength(2));
        expect(result['A'], hasLength(1));
      });

      test('should create key for entries with unknown tier key', () {
        final TierListDetailState state = TierListDetailState(
          tierList: createTestTierList(),
          definitions: <TierDefinition>[
            createTestTierDefinition(tierKey: 'S'),
          ],
          entries: <TierListEntry>[
            createTestTierListEntry(collectionItemId: 1, tierKey: 'X'),
          ],
          items: const <CollectionItem>[],
        );

        final Map<String, List<TierListEntry>> result = state.entriesByTier;
        expect(result['X'], hasLength(1));
        expect(result['S'], isEmpty);
      });
    });

    group('copyWith', () {
      test('should return same values when no arguments provided', () {
        final TierList tierList = createTestTierList();
        final List<TierDefinition> definitions = <TierDefinition>[
          createTestTierDefinition(),
        ];
        final List<TierListEntry> entries = <TierListEntry>[
          createTestTierListEntry(),
        ];
        final List<CollectionItem> items = <CollectionItem>[
          createTestCollectionItem(),
        ];
        final TierListDetailState original = TierListDetailState(
          tierList: tierList,
          definitions: definitions,
          entries: entries,
          items: items,
          isLoading: true,
        );

        final TierListDetailState copy = original.copyWith();

        expect(copy.tierList, same(tierList));
        expect(copy.definitions, same(definitions));
        expect(copy.entries, same(entries));
        expect(copy.items, same(items));
        expect(copy.isLoading, isTrue);
      });

      test('should override specified fields', () {
        final TierListDetailState original = TierListDetailState(
          tierList: createTestTierList(id: 1),
          definitions: const <TierDefinition>[],
          entries: const <TierListEntry>[],
          items: const <CollectionItem>[],
        );

        final TierList newTierList = createTestTierList(id: 2);
        final List<TierDefinition> newDefs = <TierDefinition>[
          createTestTierDefinition(tierKey: 'X'),
        ];
        final TierListDetailState copy = original.copyWith(
          tierList: newTierList,
          definitions: newDefs,
          isLoading: true,
        );

        expect(copy.tierList.id, 2);
        expect(copy.definitions, hasLength(1));
        expect(copy.isLoading, isTrue);
        expect(copy.entries, isEmpty);
        expect(copy.items, isEmpty);
      });
    });
  });

  // =========================================================================
  // TierListDetailNotifier
  // =========================================================================
  group('TierListDetailNotifier', () {
    late ProviderContainer container;
    late MockTierListDao mockTierListDao;
    late MockCollectionDao mockCollectionDao;

    setUp(() {
      mockTierListDao = MockTierListDao();
      mockCollectionDao = MockCollectionDao();
      container = ProviderContainer(
        overrides: <Override>[
          tierListDaoProvider.overrideWithValue(mockTierListDao),
          collectionDaoProvider.overrideWithValue(mockCollectionDao),
        ],
      );
      addTearDown(container.dispose);
    });

    // Helper: stub successful load for a collection-scoped tier list.
    void stubLoadCollectionScoped({
      int tierListId = 1,
      TierList? tierList,
      List<CollectionItem> items = const <CollectionItem>[],
      List<TierDefinition> definitions = const <TierDefinition>[],
      List<TierListEntry> entries = const <TierListEntry>[],
    }) {
      final TierList tl =
          tierList ?? createTestTierList(id: tierListId, collectionId: 10);
      when(() => mockTierListDao.getTierListById(tierListId))
          .thenAnswer((_) async => tl);
      when(() => mockCollectionDao.getCollectionItemsWithData(
            tl.collectionId,
          )).thenAnswer((_) async => items);
      when(() => mockTierListDao.getTierDefinitions(tierListId))
          .thenAnswer((_) async => definitions);
      when(() => mockTierListDao.getTierListEntries(tierListId))
          .thenAnswer((_) async => entries);
      // Stub saveTierDefinitions in case defaults are created
      when(() => mockTierListDao.saveTierDefinitions(
            tierListId,
            any(),
          )).thenAnswer((_) async {});
    }

    // Helper: stub successful load for a global tier list.
    void stubLoadGlobal({
      int tierListId = 1,
      TierList? tierList,
      List<CollectionItem> items = const <CollectionItem>[],
      List<TierDefinition> definitions = const <TierDefinition>[],
      List<TierListEntry> entries = const <TierListEntry>[],
    }) {
      final TierList tl = tierList ?? createTestTierList(id: tierListId);
      when(() => mockTierListDao.getTierListById(tierListId))
          .thenAnswer((_) async => tl);
      when(() => mockCollectionDao.getAllCollectionItemsWithData())
          .thenAnswer((_) async => items);
      when(() => mockTierListDao.getTierDefinitions(tierListId))
          .thenAnswer((_) async => definitions);
      when(() => mockTierListDao.getTierListEntries(tierListId))
          .thenAnswer((_) async => entries);
      when(() => mockTierListDao.saveTierDefinitions(
            tierListId,
            any(),
          )).thenAnswer((_) async {});
    }

    /// Triggers build and waits for async _load() to complete.
    Future<TierListDetailState> listenAndWait(int tierListId) async {
      container.listen(
        tierListDetailProvider(tierListId),
        (Object? _, Object? _) {},
      );
      // Allow microtasks (_load) to complete.
      await Future<void>.delayed(Duration.zero);
      return container.read(tierListDetailProvider(tierListId));
    }

    group('build', () {
      test('should return loading state initially', () {
        stubLoadCollectionScoped();

        container.listen(
          tierListDetailProvider(1),
          (Object? _, Object? _) {},
        );
        final TierListDetailState state =
            container.read(tierListDetailProvider(1));

        expect(state.isLoading, isTrue);
      });

      test('should load collection-scoped tier list', () async {
        final List<CollectionItem> items = <CollectionItem>[
          createTestCollectionItem(id: 1),
          createTestCollectionItem(id: 2),
        ];
        final List<TierDefinition> defs = <TierDefinition>[
          createTestTierDefinition(tierKey: 'S'),
        ];
        final List<TierListEntry> entries = <TierListEntry>[
          createTestTierListEntry(collectionItemId: 1, tierKey: 'S'),
        ];

        stubLoadCollectionScoped(
          items: items,
          definitions: defs,
          entries: entries,
        );

        final TierListDetailState state = await listenAndWait(1);

        expect(state.isLoading, isFalse);
        expect(state.tierList.collectionId, 10);
        expect(state.items, hasLength(2));
        expect(state.definitions, hasLength(1));
        expect(state.entries, hasLength(1));
        verify(() => mockCollectionDao.getCollectionItemsWithData(10))
            .called(1);
        verifyNever(() => mockCollectionDao.getAllCollectionItemsWithData());
      });

      test('should load global tier list', () async {
        final List<CollectionItem> items = <CollectionItem>[
          createTestCollectionItem(id: 1),
        ];
        final List<TierDefinition> defs = <TierDefinition>[
          createTestTierDefinition(tierKey: 'S'),
        ];

        stubLoadGlobal(
          items: items,
          definitions: defs,
        );

        final TierListDetailState state = await listenAndWait(1);

        expect(state.isLoading, isFalse);
        expect(state.tierList.isGlobal, isTrue);
        expect(state.items, hasLength(1));
        verify(() => mockCollectionDao.getAllCollectionItemsWithData())
            .called(1);
      });

      test('should stay in loading state when tier list not found', () async {
        when(() => mockTierListDao.getTierListById(99))
            .thenAnswer((_) async => null);

        final TierListDetailState state = await listenAndWait(99);

        expect(state.isLoading, isTrue);
      });

      test('should create default definitions when definitions are empty',
          () async {
        stubLoadCollectionScoped(
          definitions: const <TierDefinition>[],
        );

        final TierListDetailState state = await listenAndWait(1);

        expect(state.definitions, equals(TierDefinition.defaults));
        verify(() => mockTierListDao.saveTierDefinitions(
              1,
              TierDefinition.defaults,
            )).called(1);
      });

      test('should not create defaults when definitions exist', () async {
        final List<TierDefinition> defs = <TierDefinition>[
          createTestTierDefinition(tierKey: 'S'),
        ];

        stubLoadCollectionScoped(definitions: defs);

        final TierListDetailState state = await listenAndWait(1);

        expect(state.definitions, hasLength(1));
        verifyNever(() => mockTierListDao.saveTierDefinitions(1, any()));
      });
    });

    group('refresh', () {
      test('should set loading true then reload data', () async {
        final List<TierDefinition> defs = <TierDefinition>[
          createTestTierDefinition(tierKey: 'S'),
        ];
        stubLoadCollectionScoped(definitions: defs);

        await listenAndWait(1);

        // Stub reload with updated data
        final List<CollectionItem> newItems = <CollectionItem>[
          createTestCollectionItem(id: 5),
        ];
        when(() => mockCollectionDao.getCollectionItemsWithData(10))
            .thenAnswer((_) async => newItems);

        final TierListDetailNotifier notifier =
            container.read(tierListDetailProvider(1).notifier);
        await notifier.refresh();

        final TierListDetailState state =
            container.read(tierListDetailProvider(1));
        expect(state.isLoading, isFalse);
        expect(state.items, hasLength(1));
        expect(state.items.first.id, 5);
      });
    });

    group('moveToTier', () {
      test('should move item to tier at end when no index specified',
          () async {
        final List<TierDefinition> defs = <TierDefinition>[
          createTestTierDefinition(tierKey: 'S'),
          createTestTierDefinition(tierKey: 'A'),
        ];
        final List<CollectionItem> items = <CollectionItem>[
          createTestCollectionItem(id: 1),
          createTestCollectionItem(id: 2),
        ];
        stubLoadCollectionScoped(
          definitions: defs,
          items: items,
        );

        when(() => mockTierListDao.setItemTier(1, 1, 'S', any()))
            .thenAnswer((_) async {});

        await listenAndWait(1);

        final TierListDetailNotifier notifier =
            container.read(tierListDetailProvider(1).notifier);
        await notifier.moveToTier(1, 'S');

        final TierListDetailState state =
            container.read(tierListDetailProvider(1));
        expect(state.entries, hasLength(1));
        expect(state.entries.first.collectionItemId, 1);
        expect(state.entries.first.tierKey, 'S');
        expect(state.entries.first.sortOrder, 0);
      });

      test('should move item to tier at specific index', () async {
        final List<TierDefinition> defs = <TierDefinition>[
          createTestTierDefinition(tierKey: 'S'),
        ];
        final List<TierListEntry> entries = <TierListEntry>[
          createTestTierListEntry(
              collectionItemId: 10, tierKey: 'S', sortOrder: 0),
        ];
        final List<CollectionItem> items = <CollectionItem>[
          createTestCollectionItem(id: 10),
          createTestCollectionItem(id: 20),
        ];

        stubLoadCollectionScoped(
          definitions: defs,
          entries: entries,
          items: items,
        );

        when(() => mockTierListDao.setItemTier(1, 20, 'S', 0))
            .thenAnswer((_) async {});

        await listenAndWait(1);

        final TierListDetailNotifier notifier =
            container.read(tierListDetailProvider(1).notifier);
        await notifier.moveToTier(20, 'S', index: 0);

        final TierListDetailState state =
            container.read(tierListDetailProvider(1));
        expect(state.entries, hasLength(2));
        verify(() => mockTierListDao.setItemTier(1, 20, 'S', 0)).called(1);
      });

      test('should replace existing entry when moving already placed item',
          () async {
        final List<TierDefinition> defs = <TierDefinition>[
          createTestTierDefinition(tierKey: 'S'),
          createTestTierDefinition(tierKey: 'A'),
        ];
        final List<TierListEntry> entries = <TierListEntry>[
          createTestTierListEntry(
              collectionItemId: 1, tierKey: 'S', sortOrder: 0),
        ];
        final List<CollectionItem> items = <CollectionItem>[
          createTestCollectionItem(id: 1),
        ];

        stubLoadCollectionScoped(
          definitions: defs,
          entries: entries,
          items: items,
        );

        when(() => mockTierListDao.setItemTier(1, 1, 'A', 0))
            .thenAnswer((_) async {});

        await listenAndWait(1);

        final TierListDetailNotifier notifier =
            container.read(tierListDetailProvider(1).notifier);
        await notifier.moveToTier(1, 'A');

        final TierListDetailState state =
            container.read(tierListDetailProvider(1));
        // Should have exactly one entry (old removed, new added)
        expect(state.entries, hasLength(1));
        expect(state.entries.first.tierKey, 'A');
      });
    });

    group('removeFromTier', () {
      test('should remove item from entries', () async {
        final List<TierDefinition> defs = <TierDefinition>[
          createTestTierDefinition(tierKey: 'S'),
        ];
        final List<TierListEntry> entries = <TierListEntry>[
          createTestTierListEntry(
              collectionItemId: 1, tierKey: 'S', sortOrder: 0),
          createTestTierListEntry(
              collectionItemId: 2, tierKey: 'S', sortOrder: 1),
        ];
        final List<CollectionItem> items = <CollectionItem>[
          createTestCollectionItem(id: 1),
          createTestCollectionItem(id: 2),
        ];

        stubLoadCollectionScoped(
          definitions: defs,
          entries: entries,
          items: items,
        );

        when(() => mockTierListDao.removeItemFromTier(1, 1))
            .thenAnswer((_) async {});

        await listenAndWait(1);

        final TierListDetailNotifier notifier =
            container.read(tierListDetailProvider(1).notifier);
        await notifier.removeFromTier(1);

        final TierListDetailState state =
            container.read(tierListDetailProvider(1));
        expect(state.entries, hasLength(1));
        expect(state.entries.first.collectionItemId, 2);
        verify(() => mockTierListDao.removeItemFromTier(1, 1)).called(1);
      });

      test('should result in empty entries when removing last item', () async {
        final List<TierDefinition> defs = <TierDefinition>[
          createTestTierDefinition(tierKey: 'S'),
        ];
        final List<TierListEntry> entries = <TierListEntry>[
          createTestTierListEntry(
              collectionItemId: 1, tierKey: 'S', sortOrder: 0),
        ];
        final List<CollectionItem> items = <CollectionItem>[
          createTestCollectionItem(id: 1),
        ];

        stubLoadCollectionScoped(
          definitions: defs,
          entries: entries,
          items: items,
        );

        when(() => mockTierListDao.removeItemFromTier(1, 1))
            .thenAnswer((_) async {});

        await listenAndWait(1);

        final TierListDetailNotifier notifier =
            container.read(tierListDetailProvider(1).notifier);
        await notifier.removeFromTier(1);

        final TierListDetailState state =
            container.read(tierListDetailProvider(1));
        expect(state.entries, isEmpty);
        expect(state.unrankedItems, hasLength(1));
      });
    });

    group('reorder', () {
      test('should reorder entries within a tier', () async {
        final List<TierDefinition> defs = <TierDefinition>[
          createTestTierDefinition(tierKey: 'S'),
        ];
        final List<TierListEntry> entries = <TierListEntry>[
          createTestTierListEntry(
              collectionItemId: 1, tierKey: 'S', sortOrder: 0),
          createTestTierListEntry(
              collectionItemId: 2, tierKey: 'S', sortOrder: 1),
          createTestTierListEntry(
              collectionItemId: 3, tierKey: 'S', sortOrder: 2),
        ];
        final List<CollectionItem> items = <CollectionItem>[
          createTestCollectionItem(id: 1),
          createTestCollectionItem(id: 2),
          createTestCollectionItem(id: 3),
        ];

        stubLoadCollectionScoped(
          definitions: defs,
          entries: entries,
          items: items,
        );

        when(() => mockTierListDao.reorderTierItems(1, 'S', any()))
            .thenAnswer((_) async {});

        await listenAndWait(1);

        final TierListDetailNotifier notifier =
            container.read(tierListDetailProvider(1).notifier);
        // Move item at index 0 to index 2
        await notifier.reorder('S', 0, 2);

        final TierListDetailState state =
            container.read(tierListDetailProvider(1));
        final List<TierListEntry> sTier = state.entriesByTier['S']!;
        expect(sTier[0].collectionItemId, 2);
        expect(sTier[1].collectionItemId, 3);
        expect(sTier[2].collectionItemId, 1);
        // Verify sortOrder is updated
        expect(sTier[0].sortOrder, 0);
        expect(sTier[1].sortOrder, 1);
        expect(sTier[2].sortOrder, 2);
      });

      test('should be no-op when oldIndex is out of bounds', () async {
        final List<TierDefinition> defs = <TierDefinition>[
          createTestTierDefinition(tierKey: 'S'),
        ];
        final List<TierListEntry> entries = <TierListEntry>[
          createTestTierListEntry(
              collectionItemId: 1, tierKey: 'S', sortOrder: 0),
        ];
        final List<CollectionItem> items = <CollectionItem>[
          createTestCollectionItem(id: 1),
        ];

        stubLoadCollectionScoped(
          definitions: defs,
          entries: entries,
          items: items,
        );

        await listenAndWait(1);

        final TierListDetailNotifier notifier =
            container.read(tierListDetailProvider(1).notifier);
        await notifier.reorder('S', 5, 0);

        verifyNever(() => mockTierListDao.reorderTierItems(any(), any(), any()));
      });

      test('should be no-op when newIndex is out of bounds', () async {
        final List<TierDefinition> defs = <TierDefinition>[
          createTestTierDefinition(tierKey: 'S'),
        ];
        final List<TierListEntry> entries = <TierListEntry>[
          createTestTierListEntry(
              collectionItemId: 1, tierKey: 'S', sortOrder: 0),
        ];
        final List<CollectionItem> items = <CollectionItem>[
          createTestCollectionItem(id: 1),
        ];

        stubLoadCollectionScoped(
          definitions: defs,
          entries: entries,
          items: items,
        );

        await listenAndWait(1);

        final TierListDetailNotifier notifier =
            container.read(tierListDetailProvider(1).notifier);
        await notifier.reorder('S', 0, 5);

        verifyNever(() => mockTierListDao.reorderTierItems(any(), any(), any()));
      });

      test('should be no-op when tier key does not exist', () async {
        final List<TierDefinition> defs = <TierDefinition>[
          createTestTierDefinition(tierKey: 'S'),
        ];

        stubLoadCollectionScoped(definitions: defs);

        await listenAndWait(1);

        final TierListDetailNotifier notifier =
            container.read(tierListDetailProvider(1).notifier);
        // Empty tier, oldIndex 0 >= length 0 → no-op
        await notifier.reorder('NONEXISTENT', 0, 1);

        verifyNever(() => mockTierListDao.reorderTierItems(any(), any(), any()));
      });

      test('should not change other tiers when reordering', () async {
        final List<TierDefinition> defs = <TierDefinition>[
          createTestTierDefinition(tierKey: 'S'),
          createTestTierDefinition(tierKey: 'A'),
        ];
        final List<TierListEntry> entries = <TierListEntry>[
          createTestTierListEntry(
              collectionItemId: 1, tierKey: 'S', sortOrder: 0),
          createTestTierListEntry(
              collectionItemId: 2, tierKey: 'S', sortOrder: 1),
          createTestTierListEntry(
              collectionItemId: 3, tierKey: 'A', sortOrder: 0),
        ];
        final List<CollectionItem> items = <CollectionItem>[
          createTestCollectionItem(id: 1),
          createTestCollectionItem(id: 2),
          createTestCollectionItem(id: 3),
        ];

        stubLoadCollectionScoped(
          definitions: defs,
          entries: entries,
          items: items,
        );

        when(() => mockTierListDao.reorderTierItems(1, 'S', any()))
            .thenAnswer((_) async {});

        await listenAndWait(1);

        final TierListDetailNotifier notifier =
            container.read(tierListDetailProvider(1).notifier);
        await notifier.reorder('S', 0, 1);

        final TierListDetailState state =
            container.read(tierListDetailProvider(1));
        final List<TierListEntry> aTier = state.entriesByTier['A']!;
        expect(aTier, hasLength(1));
        expect(aTier.first.collectionItemId, 3);
      });
    });

    group('moveBetweenTiers', () {
      test('should remove from source tier and add to destination tier',
          () async {
        final List<TierDefinition> defs = <TierDefinition>[
          createTestTierDefinition(tierKey: 'S'),
          createTestTierDefinition(tierKey: 'A'),
        ];
        final List<TierListEntry> entries = <TierListEntry>[
          createTestTierListEntry(
              collectionItemId: 1, tierKey: 'S', sortOrder: 0),
        ];
        final List<CollectionItem> items = <CollectionItem>[
          createTestCollectionItem(id: 1),
        ];

        stubLoadCollectionScoped(
          definitions: defs,
          entries: entries,
          items: items,
        );

        when(() => mockTierListDao.removeItemFromTier(1, 1))
            .thenAnswer((_) async {});
        when(() => mockTierListDao.setItemTier(1, 1, 'A', any()))
            .thenAnswer((_) async {});

        await listenAndWait(1);

        final TierListDetailNotifier notifier =
            container.read(tierListDetailProvider(1).notifier);
        await notifier.moveBetweenTiers(1, 'S', 'A');

        final TierListDetailState state =
            container.read(tierListDetailProvider(1));
        expect(state.entriesByTier['S'], isEmpty);
        expect(state.entriesByTier['A'], hasLength(1));
        expect(state.entriesByTier['A']!.first.collectionItemId, 1);
      });

      test('should move to specific index in destination tier', () async {
        final List<TierDefinition> defs = <TierDefinition>[
          createTestTierDefinition(tierKey: 'S'),
          createTestTierDefinition(tierKey: 'A'),
        ];
        final List<TierListEntry> entries = <TierListEntry>[
          createTestTierListEntry(
              collectionItemId: 1, tierKey: 'S', sortOrder: 0),
          createTestTierListEntry(
              collectionItemId: 2, tierKey: 'A', sortOrder: 0),
        ];
        final List<CollectionItem> items = <CollectionItem>[
          createTestCollectionItem(id: 1),
          createTestCollectionItem(id: 2),
        ];

        stubLoadCollectionScoped(
          definitions: defs,
          entries: entries,
          items: items,
        );

        when(() => mockTierListDao.removeItemFromTier(1, 1))
            .thenAnswer((_) async {});
        when(() => mockTierListDao.setItemTier(1, 1, 'A', 0))
            .thenAnswer((_) async {});

        await listenAndWait(1);

        final TierListDetailNotifier notifier =
            container.read(tierListDetailProvider(1).notifier);
        await notifier.moveBetweenTiers(1, 'S', 'A', index: 0);

        verify(() => mockTierListDao.removeItemFromTier(1, 1)).called(1);
        verify(() => mockTierListDao.setItemTier(1, 1, 'A', 0)).called(1);
      });
    });

    group('updateTierDefinition', () {
      test('should update label of matching tier', () async {
        final List<TierDefinition> defs = <TierDefinition>[
          createTestTierDefinition(tierKey: 'S', label: 'S'),
          createTestTierDefinition(tierKey: 'A', label: 'A'),
        ];

        stubLoadCollectionScoped(definitions: defs);

        await listenAndWait(1);

        final TierListDetailNotifier notifier =
            container.read(tierListDetailProvider(1).notifier);
        await notifier.updateTierDefinition('S', label: 'Super');

        final TierListDetailState state =
            container.read(tierListDetailProvider(1));
        expect(
          state.definitions
              .firstWhere((TierDefinition d) => d.tierKey == 'S')
              .label,
          'Super',
        );
        // A tier should be unchanged
        expect(
          state.definitions
              .firstWhere((TierDefinition d) => d.tierKey == 'A')
              .label,
          'A',
        );
        verify(() => mockTierListDao.saveTierDefinitions(1, any())).called(1);
      });

      test('should update color of matching tier', () async {
        final List<TierDefinition> defs = <TierDefinition>[
          createTestTierDefinition(tierKey: 'S', colorValue: 0xFFFF0000),
        ];

        stubLoadCollectionScoped(definitions: defs);

        await listenAndWait(1);

        const Color newColor = Color(0xFF00FF00);
        final TierListDetailNotifier notifier =
            container.read(tierListDetailProvider(1).notifier);
        await notifier.updateTierDefinition('S', color: newColor);

        final TierListDetailState state =
            container.read(tierListDetailProvider(1));
        expect(
          state.definitions.first.color,
          equals(newColor),
        );
      });

      test('should not change non-matching tiers', () async {
        final List<TierDefinition> defs = <TierDefinition>[
          createTestTierDefinition(tierKey: 'S', label: 'S'),
          createTestTierDefinition(tierKey: 'A', label: 'A'),
        ];

        stubLoadCollectionScoped(definitions: defs);

        await listenAndWait(1);

        final TierListDetailNotifier notifier =
            container.read(tierListDetailProvider(1).notifier);
        await notifier.updateTierDefinition('X', label: 'Unknown');

        final TierListDetailState state =
            container.read(tierListDetailProvider(1));
        // Nothing should change since 'X' doesn't match any definition
        expect(state.definitions, hasLength(2));
        expect(state.definitions[0].label, 'S');
        expect(state.definitions[1].label, 'A');
      });
    });

    group('addTier', () {
      test('should append new tier definition', () async {
        final List<TierDefinition> defs = <TierDefinition>[
          createTestTierDefinition(tierKey: 'S', sortOrder: 0),
        ];

        stubLoadCollectionScoped(definitions: defs);

        await listenAndWait(1);

        const Color color = Color(0xFF123456);
        final TierListDetailNotifier notifier =
            container.read(tierListDetailProvider(1).notifier);
        await notifier.addTier('X', 'Custom', color);

        final TierListDetailState state =
            container.read(tierListDetailProvider(1));
        expect(state.definitions, hasLength(2));
        expect(state.definitions.last.tierKey, 'X');
        expect(state.definitions.last.label, 'Custom');
        expect(state.definitions.last.color, equals(color));
        expect(state.definitions.last.sortOrder, 1);
        verify(() => mockTierListDao.saveTierDefinitions(1, any())).called(1);
      });

      test('should set correct sortOrder based on existing definitions',
          () async {
        final List<TierDefinition> defs = <TierDefinition>[
          createTestTierDefinition(tierKey: 'S', sortOrder: 0),
          createTestTierDefinition(tierKey: 'A', sortOrder: 1),
          createTestTierDefinition(tierKey: 'B', sortOrder: 2),
        ];

        stubLoadCollectionScoped(definitions: defs);

        await listenAndWait(1);

        final TierListDetailNotifier notifier =
            container.read(tierListDetailProvider(1).notifier);
        await notifier.addTier('C', 'C', const Color(0xFF000000));

        final TierListDetailState state =
            container.read(tierListDetailProvider(1));
        expect(state.definitions.last.sortOrder, 3);
      });
    });

    group('removeTier', () {
      test('should remove tier definition and its entries', () async {
        final List<TierDefinition> defs = <TierDefinition>[
          createTestTierDefinition(tierKey: 'S', sortOrder: 0),
          createTestTierDefinition(tierKey: 'A', sortOrder: 1),
        ];
        final List<TierListEntry> entries = <TierListEntry>[
          createTestTierListEntry(
              collectionItemId: 1, tierKey: 'S', sortOrder: 0),
          createTestTierListEntry(
              collectionItemId: 2, tierKey: 'S', sortOrder: 1),
          createTestTierListEntry(
              collectionItemId: 3, tierKey: 'A', sortOrder: 0),
        ];
        final List<CollectionItem> items = <CollectionItem>[
          createTestCollectionItem(id: 1),
          createTestCollectionItem(id: 2),
          createTestCollectionItem(id: 3),
        ];

        stubLoadCollectionScoped(
          definitions: defs,
          entries: entries,
          items: items,
        );

        when(() => mockTierListDao.removeItemFromTier(1, any()))
            .thenAnswer((_) async {});

        await listenAndWait(1);

        final TierListDetailNotifier notifier =
            container.read(tierListDetailProvider(1).notifier);
        await notifier.removeTier('S');

        final TierListDetailState state =
            container.read(tierListDetailProvider(1));
        // S tier removed, only A remains
        expect(state.definitions, hasLength(1));
        expect(state.definitions.first.tierKey, 'A');
        // S entries removed, only A entry remains
        expect(state.entries, hasLength(1));
        expect(state.entries.first.tierKey, 'A');
        // Removed items should be in unranked
        expect(state.unrankedItems, hasLength(2));
      });

      test('should update sortOrder of remaining definitions', () async {
        final List<TierDefinition> defs = <TierDefinition>[
          createTestTierDefinition(tierKey: 'S', sortOrder: 0),
          createTestTierDefinition(tierKey: 'A', sortOrder: 1),
          createTestTierDefinition(tierKey: 'B', sortOrder: 2),
        ];

        stubLoadCollectionScoped(definitions: defs);

        await listenAndWait(1);

        final TierListDetailNotifier notifier =
            container.read(tierListDetailProvider(1).notifier);
        await notifier.removeTier('S');

        final TierListDetailState state =
            container.read(tierListDetailProvider(1));
        expect(state.definitions[0].tierKey, 'A');
        expect(state.definitions[0].sortOrder, 0);
        expect(state.definitions[1].tierKey, 'B');
        expect(state.definitions[1].sortOrder, 1);
      });

      test('should call removeItemFromTier for each entry in tier', () async {
        final List<TierDefinition> defs = <TierDefinition>[
          createTestTierDefinition(tierKey: 'S', sortOrder: 0),
        ];
        final List<TierListEntry> entries = <TierListEntry>[
          createTestTierListEntry(
              collectionItemId: 10, tierKey: 'S', sortOrder: 0),
          createTestTierListEntry(
              collectionItemId: 20, tierKey: 'S', sortOrder: 1),
        ];

        stubLoadCollectionScoped(
          definitions: defs,
          entries: entries,
        );

        when(() => mockTierListDao.removeItemFromTier(1, any()))
            .thenAnswer((_) async {});

        await listenAndWait(1);

        final TierListDetailNotifier notifier =
            container.read(tierListDetailProvider(1).notifier);
        await notifier.removeTier('S');

        verify(() => mockTierListDao.removeItemFromTier(1, 10)).called(1);
        verify(() => mockTierListDao.removeItemFromTier(1, 20)).called(1);
      });

      test('should handle removing tier with no entries', () async {
        final List<TierDefinition> defs = <TierDefinition>[
          createTestTierDefinition(tierKey: 'S', sortOrder: 0),
          createTestTierDefinition(tierKey: 'A', sortOrder: 1),
        ];

        stubLoadCollectionScoped(definitions: defs);

        await listenAndWait(1);

        final TierListDetailNotifier notifier =
            container.read(tierListDetailProvider(1).notifier);
        await notifier.removeTier('A');

        final TierListDetailState state =
            container.read(tierListDetailProvider(1));
        expect(state.definitions, hasLength(1));
        expect(state.definitions.first.tierKey, 'S');
        verifyNever(() => mockTierListDao.removeItemFromTier(any(), any()));
      });
    });

    group('clearAll', () {
      test('should clear all entries', () async {
        final List<TierDefinition> defs = <TierDefinition>[
          createTestTierDefinition(tierKey: 'S'),
          createTestTierDefinition(tierKey: 'A'),
        ];
        final List<TierListEntry> entries = <TierListEntry>[
          createTestTierListEntry(
              collectionItemId: 1, tierKey: 'S', sortOrder: 0),
          createTestTierListEntry(
              collectionItemId: 2, tierKey: 'A', sortOrder: 0),
        ];
        final List<CollectionItem> items = <CollectionItem>[
          createTestCollectionItem(id: 1),
          createTestCollectionItem(id: 2),
        ];

        stubLoadCollectionScoped(
          definitions: defs,
          entries: entries,
          items: items,
        );

        when(() => mockTierListDao.clearTierListEntries(1))
            .thenAnswer((_) async {});

        await listenAndWait(1);

        final TierListDetailNotifier notifier =
            container.read(tierListDetailProvider(1).notifier);
        await notifier.clearAll();

        final TierListDetailState state =
            container.read(tierListDetailProvider(1));
        expect(state.entries, isEmpty);
        expect(state.definitions, hasLength(2));
        expect(state.unrankedItems, hasLength(2));
        verify(() => mockTierListDao.clearTierListEntries(1)).called(1);
      });

      test('should be no-op when entries already empty', () async {
        final List<TierDefinition> defs = <TierDefinition>[
          createTestTierDefinition(tierKey: 'S'),
        ];

        stubLoadCollectionScoped(definitions: defs);

        when(() => mockTierListDao.clearTierListEntries(1))
            .thenAnswer((_) async {});

        await listenAndWait(1);

        final TierListDetailNotifier notifier =
            container.read(tierListDetailProvider(1).notifier);
        await notifier.clearAll();

        final TierListDetailState state =
            container.read(tierListDetailProvider(1));
        expect(state.entries, isEmpty);
        verify(() => mockTierListDao.clearTierListEntries(1)).called(1);
      });
    });
  });
}
