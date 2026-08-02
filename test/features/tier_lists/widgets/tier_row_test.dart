import 'package:core/models/collection_item.dart';
import 'package:core/models/tier_definition.dart';
import 'package:core/models/tier_list_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/tier_lists/widgets/tier_item_card.dart';
import 'package:tonkatsu_box/features/tier_lists/widgets/tier_row.dart';

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
          titleLanguage: '',
          onDrop: (_, _) {},
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
          titleLanguage: '',
          onDrop: (_, _) {},
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
          titleLanguage: '',
          onDrop: (_, _) {},
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
          titleLanguage: '',
          onDrop: (_, _) {},
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
          titleLanguage: '',
          onDrop: (_, _) {},
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
          titleLanguage: '',
          onDrop: (_, _) {},
          onDefinitionTap: () {},
        ),
        settle: false,
      );
      await tester.pump();

      expect(find.byType(TierItemCard), findsOneWidget);
    });

    group('intra-tier drop slots', () {
      late CollectionItem item3;

      setUp(() {
        item3 = createTestCollectionItem(
          id: 3,
          externalId: 300,
          game: createTestGame(id: 300, name: 'Game Three'),
        );
      });

      Future<void> dragCard(
        WidgetTester tester,
        int fromIndex,
        int toIndex,
      ) async {
        final Finder cards = find.byType(TierItemCard);
        final TestGesture gesture = await tester.startGesture(
          tester.getCenter(cards.at(fromIndex)),
        );
        await tester.pump(const Duration(milliseconds: 100));
        await gesture.moveTo(tester.getCenter(cards.at(toIndex)));
        await tester.pump();
        await gesture.up();
        await tester.pump();
      }

      Widget buildRow(
        List<TierListEntry> entries,
        Map<int, CollectionItem> itemsMap,
        void Function(int, int?) onDrop,
      ) {
        return TierRow(
          tierListId: 1,
          definition: definition,
          entries: entries,
          itemsMap: itemsMap,
          titleLanguage: '',
          onDrop: onDrop,
          onDefinitionTap: () {},
        );
      }

      testWidgets('dropping a card onto an earlier card inserts before it',
          (WidgetTester tester) async {
        final List<TierListEntry> entries = <TierListEntry>[
          createTestTierListEntry(
              collectionItemId: 1, tierKey: 'S', sortOrder: 0),
          createTestTierListEntry(
              collectionItemId: 2, tierKey: 'S', sortOrder: 1),
        ];
        final Map<int, CollectionItem> itemsMap = <int, CollectionItem>{
          1: item1,
          2: item2,
        };
        final List<(int, int?)> drops = <(int, int?)>[];

        await tester.pumpApp(
          buildRow(
            entries,
            itemsMap,
            (int id, int? index) => drops.add((id, index)),
          ),
          settle: false,
        );
        await tester.pump();

        await dragCard(tester, 1, 0);

        expect(drops, <(int, int?)>[(2, 0)]);
      });

      testWidgets(
          'dropping a card onto a later card adjusts index for its removal',
          (WidgetTester tester) async {
        final List<TierListEntry> entries = <TierListEntry>[
          createTestTierListEntry(
              collectionItemId: 1, tierKey: 'S', sortOrder: 0),
          createTestTierListEntry(
              collectionItemId: 2, tierKey: 'S', sortOrder: 1),
          createTestTierListEntry(
              collectionItemId: 3, tierKey: 'S', sortOrder: 2),
        ];
        final Map<int, CollectionItem> itemsMap = <int, CollectionItem>{
          1: item1,
          2: item2,
          3: item3,
        };
        final List<(int, int?)> drops = <(int, int?)>[];

        await tester.pumpApp(
          buildRow(
            entries,
            itemsMap,
            (int id, int? index) => drops.add((id, index)),
          ),
          settle: false,
        );
        await tester.pump();

        await dragCard(tester, 0, 2);

        expect(drops, <(int, int?)>[(1, 1)]);
      });
    });
  });
}
