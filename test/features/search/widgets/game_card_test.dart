import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/search/widgets/game_card.dart';
import 'package:xerabora/shared/models/game.dart';

void main() {
  const Game testGame = Game(
    id: 1,
    name: 'Test Game',
    summary: 'A test game description',
    releaseDate: null,
    rating: 85.0,
    ratingCount: 100,
    genres: <String>['Action', 'RPG'],
    platformIds: <int>[1, 2, 3],
  );

  const Game gameWithReleaseDate = Game(
    id: 2,
    name: 'Game with Date',
    releaseDate: null,
    rating: null,
  );

  Widget buildTestWidget({
    Game game = testGame,
    VoidCallback? onTap,
    Widget? trailing,
    List<String>? platformNames,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: GameCard(
          game: game,
          onTap: onTap,
          trailing: trailing,
          platformNames: platformNames,
        ),
      ),
    );
  }

  group('GameCard', () {
    group('рендеринг основных элементов', () {
      testWidgets('должен показывать название игры', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.text('Test Game'), findsOneWidget);
      });

      testWidgets('должен показывать рейтинг', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.text('8.5'), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget);
      });

      testWidgets('должен показывать жанры', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.text('Action, RPG'), findsOneWidget);
      });

      testWidgets('должен показывать placeholder при отсутствии обложки', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.byIcon(Icons.videogame_asset), findsOneWidget);
      });

      testWidgets('должен показывать trailing widget', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          trailing: const Icon(Icons.add),
        ));

        expect(find.byIcon(Icons.add), findsOneWidget);
      });

      testWidgets('должен вызывать onTap при нажатии', (WidgetTester tester) async {
        bool tapped = false;

        await tester.pumpWidget(buildTestWidget(
          onTap: () => tapped = true,
        ));

        await tester.tap(find.byType(GameCard));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      });
    });

    group('отображение платформ', () {
      testWidgets('должен показывать платформы когда переданы', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          platformNames: <String>['PS5', 'Xbox', 'PC'],
        ));

        expect(find.text('PS5 • Xbox • PC'), findsOneWidget);
      });

      testWidgets('должен показывать одну платформу без разделителя', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          platformNames: <String>['Nintendo Switch'],
        ));

        expect(find.text('Nintendo Switch'), findsOneWidget);
      });

      testWidgets('должен не показывать платформы когда null', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          platformNames: null,
        ));

        // Не должно быть текста с разделителем платформ
        expect(find.textContaining('•'), findsNothing);
      });

      testWidgets('должен не показывать платформы когда пустой список', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          platformNames: <String>[],
        ));

        expect(find.textContaining('•'), findsNothing);
      });

      testWidgets('платформы должны иметь primary цвет', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          platformNames: <String>['PS5', 'Xbox'],
        ));

        final Finder platformText = find.text('PS5 • Xbox');
        expect(platformText, findsOneWidget);

        final Text textWidget = tester.widget<Text>(platformText);
        final ThemeData theme = Theme.of(tester.element(platformText));
        expect(textWidget.style?.color, theme.colorScheme.primary);
      });
    });

    group('edge cases', () {
      testWidgets('должен работать без рейтинга', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(game: gameWithReleaseDate));

        expect(find.text('Game with Date'), findsOneWidget);
        expect(find.byIcon(Icons.star), findsNothing);
      });

      testWidgets('должен работать без жанров', (WidgetTester tester) async {
        const Game gameWithoutGenres = Game(
          id: 3,
          name: 'No Genres Game',
        );

        await tester.pumpWidget(buildTestWidget(game: gameWithoutGenres));

        expect(find.text('No Genres Game'), findsOneWidget);
        expect(find.text('Action, RPG'), findsNothing);
      });

      testWidgets('должен обрезать длинное название', (WidgetTester tester) async {
        const Game gameWithLongName = Game(
          id: 4,
          name: 'This is a very long game name that should be truncated because it does not fit',
        );

        await tester.pumpWidget(buildTestWidget(game: gameWithLongName));

        final Text nameWidget = tester.widget<Text>(
          find.text('This is a very long game name that should be truncated because it does not fit'),
        );
        expect(nameWidget.overflow, TextOverflow.ellipsis);
        expect(nameWidget.maxLines, 2);
      });

      testWidgets('должен обрезать длинный список платформ', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(
          platformNames: <String>[
            'PlayStation 5',
            'Xbox Series X',
            'Nintendo Switch',
            'PC Windows',
            'macOS',
          ],
        ));

        final Text platformText = tester.widget<Text>(
          find.textContaining('PlayStation 5'),
        );
        expect(platformText.overflow, TextOverflow.ellipsis);
        expect(platformText.maxLines, 1);
      });
    });
  });

  group('GameGridCard', () {
    testWidgets('должен показывать название и год', (WidgetTester tester) async {
      final DateTime releaseDate = DateTime(2023, 6, 15);
      final Game gameWithYear = Game(
        id: 5,
        name: 'Grid Game',
        releaseDate: releaseDate,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 300,
            child: GameGridCard(
              game: gameWithYear,
            ),
          ),
        ),
      ));

      expect(find.text('Grid Game'), findsOneWidget);
      expect(find.text('2023'), findsOneWidget);
    });

    testWidgets('должен вызывать onTap', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 300,
            child: GameGridCard(
              game: testGame,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ));

      await tester.tap(find.byType(GameGridCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
