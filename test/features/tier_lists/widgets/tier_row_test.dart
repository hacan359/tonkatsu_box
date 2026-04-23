// Виджет-тесты для TierRow.

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/tier_lists/widgets/tier_item_card.dart';
import 'package:xerabora/features/tier_lists/widgets/tier_row.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/tier_definition.dart';
import 'package:xerabora/shared/models/tier_list_entry.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(registerAllFallbacks);

  group('TierRow', () {
    late TierDefinition definition;
    late CollectionItem item1;
    late CollectionItem item2;

    setUp(() {
      definition = createTestTierDefinition(
        tierKey: 'S',
        label: 'S',
        colorValue: 0xFFFF4444,
        sortOrder: 0,
      );

      item1 = createTestCollectionItem(
        id: 1,
        externalId: 100,
        game: createTestGame(id: 100, name: 'Game One'),
      );

      item2 = createTestCollectionItem(
        id: 2,
        externalId: 200,
        game: createTestGame(id: 200, name: 'Game Two'),
      );
    });

    testWidgets('should render without errors', (WidgetTester tester) async {
      await tester.pumpApp(
        TierRow(
          tierListId: 1,
          definition: definition,
          entries: const <TierListEntry>[],
          itemsMap: const <int, CollectionItem>{},
          onDrop: (_) {},
          onDefinitionTap: () {},
        ),
        settle: false,
      );
      await tester.pump();

      expect(find.byType(TierRow), findsOneWidget);
    });

    testWidgets('should render tier label from definition',
        (WidgetTester tester) async {
      await tester.pumpApp(
        TierRow(
          tierListId: 1,
          definition: definition,
          entries: const <TierListEntry>[],
          itemsMap: const <int, CollectionItem>{},
          onDrop: (_) {},
          onDefinitionTap: () {},
        ),
        settle: false,
      );
      await tester.pump();

      expect(find.text('S'), findsOneWidget);
    });

    testWidgets('should not render any TierItemCard when entries is empty',
        (WidgetTester tester) async {
      await tester.pumpApp(
        TierRow(
          tierListId: 1,
          definition: definition,
          entries: const <TierListEntry>[],
          itemsMap: const <int, CollectionItem>{},
          onDrop: (_) {},
          onDefinitionTap: () {},
        ),
        settle: false,
      );
      await tester.pump();

      expect(find.byType(TierItemCard), findsNothing);
    });

    testWidgets('should render TierItemCard for each entry with matching item',
        (WidgetTester tester) async {
      final List<TierListEntry> entries = <TierListEntry>[
        createTestTierListEntry(collectionItemId: 1, tierKey: 'S', sortOrder: 0),
        createTestTierListEntry(collectionItemId: 2, tierKey: 'S', sortOrder: 1),
      ];

      final Map<int, CollectionItem> itemsMap = <int, CollectionItem>{
        1: item1,
        2: item2,
      };

      await tester.pumpApp(
        TierRow(
          tierListId: 1,
          definition: definition,
          entries: entries,
          itemsMap: itemsMap,
          onDrop: (_) {},
          onDefinitionTap: () {},
        ),
        settle: false,
      );
      await tester.pump();

      expect(find.byType(TierItemCard), findsNWidgets(2));
    });

    testWidgets('should call onDefinitionTap when label is tapped',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpApp(
        TierRow(
          tierListId: 1,
          definition: definition,
          entries: const <TierListEntry>[],
          itemsMap: const <int, CollectionItem>{},
          onDrop: (_) {},
          onDefinitionTap: () => tapped = true,
        ),
        settle: false,
      );
      await tester.pump();

      await tester.tap(find.text('S'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('should skip entries where item not found in itemsMap',
        (WidgetTester tester) async {
      final List<TierListEntry> entries = <TierListEntry>[
        createTestTierListEntry(collectionItemId: 1, tierKey: 'S', sortOrder: 0),
        createTestTierListEntry(
          collectionItemId: 999,
          tierKey: 'S',
          sortOrder: 1,
        ),
      ];

      final Map<int, CollectionItem> itemsMap = <int, CollectionItem>{
        1: item1,
      };

      await tester.pumpApp(
        TierRow(
          tierListId: 1,
          definition: definition,
          entries: entries,
          itemsMap: itemsMap,
          onDrop: (_) {},
          onDefinitionTap: () {},
        ),
        settle: false,
      );
      await tester.pump();

      // Only 1 TierItemCard for item1; item 999 is missing from map.
      expect(find.byType(TierItemCard), findsOneWidget);
    });
  });
}
