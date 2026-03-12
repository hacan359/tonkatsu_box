// Виджет-тесты для TierListView.

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/tier_lists/providers/tier_list_detail_provider.dart';
import 'package:xerabora/features/tier_lists/widgets/tier_item_card.dart';
import 'package:xerabora/features/tier_lists/widgets/tier_list_view.dart';
import 'package:xerabora/features/tier_lists/widgets/tier_row.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/tier_definition.dart';
import 'package:xerabora/shared/models/tier_list_entry.dart';

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

      // item2 and item3 are unranked (item1 is in S tier)
      // Unranked pool shows TierItemCard widgets
      // TierRow also shows TierItemCard, so count all and verify
      // S tier has 1 card, unranked has 2 cards = 3 total
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

        // S tier: 1 card (Elden Ring, not filtered — tier items are not filtered)
        // Unranked: only Dark Souls matches "Dark"
        // Total: 1 (tier) + 1 (unranked) = 2
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

        // Unranked: only Bloodborne matches "blood" (case-insensitive)
        // Total: 1 (tier) + 1 (unranked) = 2
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

        // S tier: 1 card, Unranked: 0
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

        // S tier: 1, Unranked: 2 = 3
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

      // No unranked items — empty state text should appear
      // TierRow has 2 cards, no unranked cards
      expect(find.byType(TierItemCard), findsNWidgets(2));
    });
  });
}
