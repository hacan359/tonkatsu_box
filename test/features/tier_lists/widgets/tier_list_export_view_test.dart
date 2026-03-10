// Виджет-тесты для TierListExportView.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/tier_lists/providers/tier_list_detail_provider.dart';
import 'package:xerabora/features/tier_lists/widgets/tier_list_export_view.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/tier_definition.dart';
import 'package:xerabora/shared/models/tier_list_entry.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(registerAllFallbacks);

  group('TierListExportView', () {
    late GlobalKey repaintKey;
    late TierListDetailState state;

    setUp(() {
      repaintKey = GlobalKey();

      final CollectionItem item1 = createTestCollectionItem(
        id: 1,
        externalId: 100,
        game: createTestGame(id: 100, name: 'Game One'),
      );

      final CollectionItem item2 = createTestCollectionItem(
        id: 2,
        externalId: 200,
        game: createTestGame(id: 200, name: 'Game Two'),
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
          createTestTierListEntry(
            collectionItemId: 2,
            tierKey: 'A',
            sortOrder: 0,
          ),
        ],
        items: <CollectionItem>[item1, item2],
      );
    });

    testWidgets('should render without errors', (WidgetTester tester) async {
      await tester.pumpApp(
        SingleChildScrollView(
          child: TierListExportView(
            repaintKey: repaintKey,
            state: state,
          ),
        ),
        settle: false,
      );
      await tester.pump();

      expect(find.byType(TierListExportView), findsOneWidget);
    });

    testWidgets('should display tier list name', (WidgetTester tester) async {
      await tester.pumpApp(
        SingleChildScrollView(
          child: TierListExportView(
            repaintKey: repaintKey,
            state: state,
          ),
        ),
        settle: false,
      );
      await tester.pump();

      expect(find.text('My Tier List'), findsOneWidget);
    });

    testWidgets('should render export tier rows for each definition',
        (WidgetTester tester) async {
      await tester.pumpApp(
        SingleChildScrollView(
          child: TierListExportView(
            repaintKey: repaintKey,
            state: state,
          ),
        ),
        settle: false,
      );
      await tester.pump();

      // Each definition has a label text rendered in the export row.
      expect(find.text('S'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
    });
  });
}
