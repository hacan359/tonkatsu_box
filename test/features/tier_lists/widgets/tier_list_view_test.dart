import 'package:core/models/collection_item.dart';
import 'package:core/models/tier_definition.dart';
import 'package:core/models/tier_list_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/features/tier_lists/providers/tier_list_detail_provider.dart';
import 'package:tonkatsu_box/features/tier_lists/widgets/tier_item_card.dart';
import 'package:tonkatsu_box/features/tier_lists/widgets/tier_list_view.dart';
import 'package:tonkatsu_box/features/tier_lists/widgets/tier_row.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(registerAllFallbacks);

  group('TierListView', () {
    late TierListDetailState state;
    late CollectionItem item1;
    late CollectionItem item2;
    late CollectionItem item3;

    setUp(() {
      item1 = createTestCollectionItem(
        id: 1,
        externalId: 100,
        game: createTestGame(id: 100, name: 'Elden Ring'),
      );

      item2 = createTestCollectionItem(
        id: 2,
        externalId: 200,
        game: createTestGame(id: 200, name: 'Dark Souls'),
      );

      item3 = createTestCollectionItem(
        id: 3,
        externalId: 300,
        game: createTestGame(id: 300, name: 'Bloodborne'),
      );

      state = TierListDetailState(
        tierList: createTestTierList(id: 1, name: 'My Tier List'),
        definitions: <TierDefinition>[
          createTestTierDefinition(
            tierKey: 'S',
            label: 'S',
            colorValue: 0xFFFF4444,
            sortOrder: 0,
          ),
          createTestTierDefinition(
            tierKey: 'A',
            label: 'A',
            colorValue: 0xFFFF8C00,
            sortOrder: 1,
          ),
        ],
        entries: <TierListEntry>[
          createTestTierListEntry(
            collectionItemId: 1,
            tierKey: 'S',
            sortOrder: 0,
          ),
        ],
        items: <CollectionItem>[item1, item2, item3],
      );
    });

    testWidgets('should render TierRow for each definition',
        (WidgetTester tester) async {
      await tester.pumpApp(
        TierListView(tierListId: 1, state: state),
        settle: false,
      );
      await tester.pump();

      expect(find.byType(TierRow), findsNWidgets(2));
    });

    testWidgets('should render unranked items', (WidgetTester tester) async {
      await tester.pumpApp(
        TierListView(tierListId: 1, state: state),
        settle: false,
      );
      await tester.pump();

      // S tier has 1 card, 2 unranked cards = 3 total.
      expect(find.byType(TierItemCard), findsNWidgets(3));
    });

    group('filterQuery', () {
      testWidgets('should filter unranked items by name',
          (WidgetTester tester) async {
        await tester.pumpApp(
          TierListView(
            tierListId: 1,
            state: state,
            filterQuery: 'Dark',
          ),
          settle: false,
        );
        await tester.pump();

        // Tier items are not filtered; only "Dark Souls" matches in unranked.
        expect(find.byType(TierItemCard), findsNWidgets(2));
      });

      testWidgets('should filter unranked items case-insensitively',
          (WidgetTester tester) async {
        await tester.pumpApp(
          TierListView(
            tierListId: 1,
            state: state,
            filterQuery: 'blood',
          ),
          settle: false,
        );
        await tester.pump();

        expect(find.byType(TierItemCard), findsNWidgets(2));
      });

      testWidgets('should show no unranked items when filter matches nothing',
          (WidgetTester tester) async {
        await tester.pumpApp(
          TierListView(
            tierListId: 1,
            state: state,
            filterQuery: 'zzzzz',
          ),
          settle: false,
        );
        await tester.pump();

        expect(find.byType(TierItemCard), findsOneWidget);
      });

      testWidgets('should show all unranked items when filterQuery is empty',
          (WidgetTester tester) async {
        await tester.pumpApp(
          TierListView(
            tierListId: 1,
            state: state,
            filterQuery: '',
          ),
          settle: false,
        );
        await tester.pump();

        expect(find.byType(TierItemCard), findsNWidgets(3));
      });
    });

    testWidgets('should show empty state when all items are ranked',
        (WidgetTester tester) async {
      final TierListDetailState allRanked = TierListDetailState(
        tierList: createTestTierList(id: 1, name: 'Full'),
        definitions: <TierDefinition>[
          createTestTierDefinition(tierKey: 'S', sortOrder: 0),
        ],
        entries: <TierListEntry>[
          createTestTierListEntry(collectionItemId: 1, tierKey: 'S'),
          createTestTierListEntry(collectionItemId: 2, tierKey: 'S'),
        ],
        items: <CollectionItem>[item1, item2],
      );

      await tester.pumpApp(
        TierListView(tierListId: 1, state: allRanked),
        settle: false,
      );
      await tester.pump();

      expect(find.byType(TierItemCard), findsNWidgets(2));
    });

    group('tier reorder via options sheet', () {
      late MockTierListDao mockTierListDao;
      late MockCollectionDao mockCollectionDao;

      setUp(() {
        mockTierListDao = MockTierListDao();
        mockCollectionDao = MockCollectionDao();
        when(() => mockTierListDao.getTierListById(1)).thenAnswer(
          (_) async => createTestTierList(id: 1, collectionId: 10),
        );
        when(() => mockCollectionDao.getCollectionItemsWithData(10))
            .thenAnswer((_) async => <CollectionItem>[]);
        when(() => mockTierListDao.getTierDefinitions(1))
            .thenAnswer((_) async => state.definitions);
        when(() => mockTierListDao.getTierListEntries(1))
            .thenAnswer((_) async => <TierListEntry>[]);
        when(() => mockTierListDao.saveTierDefinitions(1, any()))
            .thenAnswer((_) async {});
      });

      Future<void> pumpView(WidgetTester tester) async {
        // The tiers pane is a third of the viewport — keep both rows tappable.
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpApp(
          TierListView(tierListId: 1, state: state),
          overrides: <Override>[
            tierListDaoProvider.overrideWithValue(mockTierListDao),
            collectionDaoProvider.overrideWithValue(mockCollectionDao),
          ],
          settle: false,
        );
        // The real screen watches (and loads) the provider; warm it up so
        // sheet actions see loaded state.
        ProviderScope.containerOf(
          tester.element(find.byType(TierListView)),
        ).read(tierListDetailProvider(1));
        await tester.pump();
      }

      testWidgets('move down persists swapped definitions',
          (WidgetTester tester) async {
        await pumpView(tester);

        await tester.tap(find.text('S'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        await tester.tap(find.byIcon(Icons.arrow_downward));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        final List<TierDefinition> saved = verify(
          () => mockTierListDao.saveTierDefinitions(1, captureAny()),
        ).captured.single as List<TierDefinition>;
        expect(
          <String>[for (final TierDefinition d in saved) d.tierKey],
          <String>['A', 'S'],
        );
      });

      testWidgets('move up persists swapped definitions',
          (WidgetTester tester) async {
        await pumpView(tester);

        await tester.tap(find.text('A'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        await tester.tap(find.byIcon(Icons.arrow_upward));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        final List<TierDefinition> saved = verify(
          () => mockTierListDao.saveTierDefinitions(1, captureAny()),
        ).captured.single as List<TierDefinition>;
        expect(
          <String>[for (final TierDefinition d in saved) d.tierKey],
          <String>['A', 'S'],
        );
      });

      testWidgets('dragging a tier label onto another tier persists reorder',
          (WidgetTester tester) async {
        await pumpView(tester);

        final TestGesture gesture = await tester.startGesture(
          tester.getCenter(find.text('S')),
        );
        await tester.pump(const Duration(milliseconds: 100));
        await gesture.moveTo(tester.getCenter(find.text('A')));
        await tester.pump();
        await gesture.up();
        await tester.pump();

        final List<TierDefinition> saved = verify(
          () => mockTierListDao.saveTierDefinitions(1, captureAny()),
        ).captured.single as List<TierDefinition>;
        expect(
          <String>[for (final TierDefinition d in saved) d.tierKey],
          <String>['A', 'S'],
        );
      });

      testWidgets('first tier has no move-up action, last has no move-down',
          (WidgetTester tester) async {
        await pumpView(tester);

        await tester.tap(find.text('S'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byIcon(Icons.arrow_upward), findsNothing);
        expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
      });
    });
  });
}
