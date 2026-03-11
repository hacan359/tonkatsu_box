// Виджет-тесты для TierItemCard.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/tier_lists/widgets/tier_item_card.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/widgets/cached_image.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(registerAllFallbacks);

  group('TierItemCard', () {
    late CollectionItem itemWithThumb;
    late CollectionItem itemNoThumb;

    setUp(() {
      itemWithThumb = createTestCollectionItem(
        id: 1,
        externalId: 100,
        game: createTestGame(
          id: 100,
          name: 'Chrono Trigger',
          coverUrl: 'https://example.com/cover.jpg',
        ),
      );

      itemNoThumb = createTestCollectionItem(
        id: 2,
        externalId: 200,
        game: createTestGame(
          id: 200,
          name: 'No Cover Game',
        ),
      );
    });

    testWidgets('should render without errors', (WidgetTester tester) async {
      await tester.pumpApp(
        TierItemCard(item: itemWithThumb),
        settle: false,
      );
      await tester.pump();

      expect(find.byType(TierItemCard), findsOneWidget);
    });

    testWidgets('should render Tooltip', (WidgetTester tester) async {
      await tester.pumpApp(
        TierItemCard(item: itemWithThumb),
        settle: false,
      );
      await tester.pump();

      final Finder tooltipFinder = find.byType(Tooltip);
      expect(tooltipFinder, findsOneWidget);

      final Tooltip tooltip = tester.widget<Tooltip>(tooltipFinder);
      expect(tooltip.message, equals('Chrono Trigger'));
    });

    testWidgets('should not wrap in Draggable when isDraggable is false',
        (WidgetTester tester) async {
      await tester.pumpApp(
        TierItemCard(item: itemWithThumb, isDraggable: false),
        settle: false,
      );
      await tester.pump();

      expect(find.byType(Draggable<int>), findsNothing);
    });

    testWidgets('should wrap in Draggable when isDraggable is true',
        (WidgetTester tester) async {
      await tester.pumpApp(
        TierItemCard(item: itemWithThumb, isDraggable: true),
        settle: false,
      );
      await tester.pump();

      final Finder draggableFinder = find.byType(Draggable<int>);
      expect(draggableFinder, findsOneWidget);

      final Draggable<int> draggable =
          tester.widget<Draggable<int>>(draggableFinder);
      expect(draggable.data, equals(1));
    });

    testWidgets('should show placeholder when thumbnailUrl is null',
        (WidgetTester tester) async {
      await tester.pumpApp(
        TierItemCard(item: itemNoThumb),
        settle: false,
      );
      await tester.pump();

      expect(find.byType(CachedImage), findsNothing);
    });

    testWidgets('should use custom width and height',
        (WidgetTester tester) async {
      const double customWidth = 100;
      const double customHeight = 140;

      await tester.pumpApp(
        TierItemCard(
          item: itemNoThumb,
          width: customWidth,
          height: customHeight,
        ),
        settle: false,
      );
      await tester.pump();

      final Finder sizedBoxFinder = find.byWidgetPredicate(
        (Widget widget) =>
            widget is SizedBox &&
            widget.width == customWidth &&
            widget.height == customHeight,
      );
      expect(sizedBoxFinder, findsOneWidget);
    });
  });
}
