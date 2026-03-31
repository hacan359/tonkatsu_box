// Виджет-тесты для TierItemCard.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/tier_lists/widgets/tier_item_card.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/platform.dart';
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

    testWidgets('should show platform overlay for mapped platforms',
        (WidgetTester tester) async {
      // SNES (id: 19) has an overlay asset → text badge hidden
      final CollectionItem gameWithOverlay = createTestCollectionItem(
        id: 10,
        externalId: 300,
        platformId: 19,
        game: createTestGame(id: 300, name: 'Super Mario World'),
        platform: const Platform(
          id: 19,
          name: 'Super Nintendo',
          abbreviation: 'SNES',
        ),
      );

      await tester.pumpApp(
        TierItemCard(item: gameWithOverlay),
        settle: false,
      );
      await tester.pump();

      expect(find.text('Super Mario World'), findsOneWidget);
      // Overlay replaces text badge for mapped platforms
      expect(find.text('SNES'), findsNothing);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should show platform text badge for unmapped platforms',
        (WidgetTester tester) async {
      // id: 9999 has no overlay → text badge shown
      final CollectionItem gameWithTextBadge = createTestCollectionItem(
        id: 10,
        externalId: 300,
        platformId: 9999,
        game: createTestGame(id: 300, name: 'Super Mario World'),
        platform: const Platform(
          id: 9999,
          name: 'Unknown Console',
          abbreviation: 'UNK',
        ),
      );

      await tester.pumpApp(
        TierItemCard(item: gameWithTextBadge),
        settle: false,
      );
      await tester.pump();

      expect(find.text('Super Mario World'), findsOneWidget);
      expect(find.text('UNK'), findsOneWidget);
    });

    testWidgets('should not show platform for non-game items',
        (WidgetTester tester) async {
      final CollectionItem movieItem = createTestCollectionItem(
        id: 11,
        externalId: 400,
        mediaType: MediaType.movie,
        movie: createTestMovie(tmdbId: 400, title: 'Test Movie'),
      );

      await tester.pumpApp(
        TierItemCard(item: movieItem),
        settle: false,
      );
      await tester.pump();

      expect(find.text('Test Movie'), findsOneWidget);
      // No platform text should appear for movies
      expect(find.text('SNES'), findsNothing);
      expect(find.text('Unknown Platform'), findsNothing);
    });

    testWidgets('should not show platform when platform is null',
        (WidgetTester tester) async {
      final CollectionItem gameNoPlatform = createTestCollectionItem(
        id: 12,
        externalId: 500,
        game: createTestGame(id: 500, name: 'No Platform Game'),
      );

      await tester.pumpApp(
        TierItemCard(item: gameNoPlatform),
        settle: false,
      );
      await tester.pump();

      expect(find.text('No Platform Game'), findsOneWidget);
      expect(find.text('Unknown Platform'), findsNothing);
    });
  });
}
