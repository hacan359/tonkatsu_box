import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/widgets/canvas_game_card.dart';
import 'package:xerabora/shared/models/canvas_item.dart';
import 'package:xerabora/shared/models/game.dart';

void main() {
  group('CanvasGameCard', () {
    final DateTime testDate = DateTime(2024, 6, 15);

    CanvasItem createGameItem({
      Game? game,
    }) {
      return CanvasItem(
        id: 1,
        collectionId: 10,
        itemType: CanvasItemType.game,
        itemRefId: 100,
        x: 0,
        y: 0,
        width: 160,
        height: 220,
        zIndex: 0,
        createdAt: testDate,
        game: game,
      );
    }

    Widget buildTestWidget(CanvasItem item) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 160,
            height: 220,
            child: CanvasGameCard(item: item),
          ),
        ),
      );
    }

    testWidgets('should display game name when game is set',
        (WidgetTester tester) async {
      final CanvasItem item = createGameItem(
        game: const Game(
          id: 100,
          name: 'Super Mario Bros.',
          coverUrl: 'https://images.igdb.com/test.jpg',
        ),
      );

      await tester.pumpWidget(buildTestWidget(item));

      expect(find.text('Super Mario Bros.'), findsOneWidget);
    });

    testWidgets('should display "Unknown Game" when game is null',
        (WidgetTester tester) async {
      final CanvasItem item = createGameItem();

      await tester.pumpWidget(buildTestWidget(item));

      expect(find.text('Unknown Game'), findsOneWidget);
    });

    testWidgets('should display placeholder icon when no cover URL',
        (WidgetTester tester) async {
      final CanvasItem item = createGameItem(
        game: const Game(id: 100, name: 'Test Game'),
      );

      await tester.pumpWidget(buildTestWidget(item));

      expect(find.byIcon(Icons.videogame_asset), findsOneWidget);
    });

    testWidgets('should use CachedNetworkImage when cover URL exists',
        (WidgetTester tester) async {
      final CanvasItem item = createGameItem(
        game: const Game(
          id: 100,
          name: 'Test Game',
          coverUrl: 'https://images.igdb.com/test.jpg',
        ),
      );

      await tester.pumpWidget(buildTestWidget(item));

      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('should contain a Card widget', (WidgetTester tester) async {
      final CanvasItem item = createGameItem();

      await tester.pumpWidget(buildTestWidget(item));

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('should display game name with null name in game',
        (WidgetTester tester) async {
      // Game is null, so should show 'Unknown Game'
      final CanvasItem item = createGameItem();

      await tester.pumpWidget(buildTestWidget(item));

      expect(find.text('Unknown Game'), findsOneWidget);
    });
  });
}
