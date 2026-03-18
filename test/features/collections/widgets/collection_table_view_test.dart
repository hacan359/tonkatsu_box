// Unit-тесты для CollectionTableView.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/widgets/collection_table_view.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/models/platform.dart' as p;

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(registerAllFallbacks);

  // -- Общие тестовые данные --

  final CollectionItem gameAlpha = createTestCollectionItem(
    id: 1,
    mediaType: MediaType.game,
    status: ItemStatus.completed,
    userRating: 9,
    addedAt: DateTime(2024, 3, 1),
    game: createTestGame(
      id: 101,
      name: 'Alpha Game',
      releaseDate: DateTime(2020),
      genres: <String>['RPG', 'Action'],
    ),
    platform: const p.Platform(id: 1, name: 'PlayStation', abbreviation: 'PS'),
  );

  final CollectionItem movieBeta = createTestCollectionItem(
    id: 2,
    mediaType: MediaType.movie,
    status: ItemStatus.inProgress,
    userRating: 7,
    addedAt: DateTime(2024, 1, 10),
    movie: createTestMovie(
      tmdbId: 202,
      title: 'Beta Movie',
      releaseYear: 2018,
      genres: <String>['Drama'],
    ),
  );

  final CollectionItem tvGamma = createTestCollectionItem(
    id: 3,
    mediaType: MediaType.tvShow,
    status: ItemStatus.planned,
    addedAt: DateTime(2024, 6, 20),
    tvShow: createTestTvShow(
      tmdbId: 303,
      title: 'Gamma Show',
      firstAirYear: 2023,
    ),
  );

  List<CollectionItem> threeItems() =>
      <CollectionItem>[gameAlpha, movieBeta, tvGamma];

  // -- Хелпер для pump --

  Future<void> pumpTableView(
    WidgetTester tester, {
    required List<CollectionItem> items,
    ValueChanged<CollectionItem>? onItemTap,
  }) async {
    final List<CollectionItem> tapped = <CollectionItem>[];
    await tester.pumpApp(
      CollectionTableView(
        items: items,
        onItemTap: onItemTap ?? tapped.add,
      ),
      wrapInScaffold: true,
      mediaQuerySize: const Size(1200, 800),
    );
  }

  /// Находит InkWell заголовка таблицы по тексту колонки.
  ///
  /// Заголовки рендерятся через Text.rich(TextSpan(text: label)),
  /// поэтому find.text() не всегда находит их (для active column
  /// добавляется WidgetSpan с иконкой). Используем textContaining.
  Finder headerFinder(String label) {
    return find.ancestor(
      of: find.textContaining(label),
      matching: find.byType(InkWell),
    );
  }

  // =========================================================================
  // TableColumn enum
  // =========================================================================

  group('TableColumn', () {
    test('should have 7 values', () {
      expect(TableColumn.values.length, 7);
    });

    test('should contain all expected columns', () {
      expect(
        TableColumn.values,
        containsAll(<TableColumn>[
          TableColumn.name,
          TableColumn.type,
          TableColumn.platform,
          TableColumn.status,
          TableColumn.rating,
          TableColumn.year,
          TableColumn.added,
        ]),
      );
    });
  });

  // =========================================================================
  // CollectionTableView
  // =========================================================================

  group('CollectionTableView', () {
    // -----------------------------------------------------------------------
    // Rendering
    // -----------------------------------------------------------------------

    group('rendering', () {
      testWidgets('should render all item names', (WidgetTester tester) async {
        await pumpTableView(tester, items: threeItems());

        expect(find.text('Alpha Game'), findsOneWidget);
        expect(find.text('Beta Movie'), findsOneWidget);
        expect(find.text('Gamma Show'), findsOneWidget);
      });

      testWidgets('should render empty list without errors',
          (WidgetTester tester) async {
        await pumpTableView(tester, items: <CollectionItem>[]);

        expect(find.byType(CollectionTableView), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);
      });

      testWidgets('should display genres when present',
          (WidgetTester tester) async {
        await pumpTableView(tester, items: <CollectionItem>[gameAlpha]);

        expect(find.text('RPG, Action'), findsOneWidget);
      });

      testWidgets('should hide genres when null',
          (WidgetTester tester) async {
        await pumpTableView(tester, items: <CollectionItem>[tvGamma]);

        // tvGamma has no genres — only the item name should be present
        expect(find.text('Gamma Show'), findsOneWidget);
      });

      testWidgets('should show platform abbreviation for games',
          (WidgetTester tester) async {
        await pumpTableView(tester, items: <CollectionItem>[gameAlpha]);

        expect(find.text('PS'), findsOneWidget);
      });

      testWidgets('should show empty platform label for non-games',
          (WidgetTester tester) async {
        await pumpTableView(tester, items: <CollectionItem>[movieBeta]);

        // Movie should have empty platform label — no platform text
        expect(find.text('Beta Movie'), findsOneWidget);
      });

      testWidgets('should show platform name when abbreviation is null',
          (WidgetTester tester) async {
        final CollectionItem gameNoPlatformAbbr = createTestCollectionItem(
          id: 10,
          mediaType: MediaType.game,
          game: createTestGame(id: 110, name: 'NoAbbrGame'),
          platform: const p.Platform(id: 5, name: 'Nintendo 64'),
        );

        await pumpTableView(
          tester,
          items: <CollectionItem>[gameNoPlatformAbbr],
        );

        expect(find.text('Nintendo 64'), findsOneWidget);
      });
    });

    // -----------------------------------------------------------------------
    // Rating display
    // -----------------------------------------------------------------------

    group('rating display', () {
      testWidgets('should show rating value when present',
          (WidgetTester tester) async {
        await pumpTableView(tester, items: <CollectionItem>[gameAlpha]);

        expect(find.text('9'), findsOneWidget);
      });

      testWidgets('should show dash when rating is null',
          (WidgetTester tester) async {
        await pumpTableView(tester, items: <CollectionItem>[tvGamma]);

        // tvGamma has no userRating — em-dash should appear
        expect(find.text('\u2014'), findsOneWidget);
      });
    });

    // -----------------------------------------------------------------------
    // Tap callback
    // -----------------------------------------------------------------------

    group('onItemTap', () {
      testWidgets('should fire callback with correct item when row tapped',
          (WidgetTester tester) async {
        final List<CollectionItem> tapped = <CollectionItem>[];

        await pumpTableView(
          tester,
          items: threeItems(),
          onItemTap: tapped.add,
        );

        await tester.tap(find.text('Beta Movie'));
        await tester.pumpAndSettle();

        expect(tapped, hasLength(1));
        expect(tapped.first.id, movieBeta.id);
      });
    });

    // -----------------------------------------------------------------------
    // Sorting
    // -----------------------------------------------------------------------

    group('sorting', () {
      /// Извлекает имена элементов в порядке отображения.
      List<String> itemNamesInOrder(WidgetTester tester) {
        final Iterable<Text> textWidgets = tester
            .widgetList<Text>(find.byType(Text))
            .where(
              (Text t) =>
                  t.data == 'Alpha Game' ||
                  t.data == 'Beta Movie' ||
                  t.data == 'Gamma Show',
            );
        return textWidgets.map((Text t) => t.data!).toList();
      }

      testWidgets('should sort by name ascending by default',
          (WidgetTester tester) async {
        await pumpTableView(tester, items: threeItems());

        final List<String> names = itemNamesInOrder(tester);
        expect(names, <String>['Alpha Game', 'Beta Movie', 'Gamma Show']);
      });

      testWidgets(
          'should toggle to descending when tapping same column header',
          (WidgetTester tester) async {
        await pumpTableView(tester, items: threeItems());

        // Name is the active sort column — tap its header InkWell
        await tester.tap(headerFinder('Name').first);
        await tester.pumpAndSettle();

        final List<String> names = itemNamesInOrder(tester);
        expect(names, <String>['Gamma Show', 'Beta Movie', 'Alpha Game']);
      });

      testWidgets(
          'should switch to ascending when tapping a different column header',
          (WidgetTester tester) async {
        await pumpTableView(tester, items: threeItems());

        // Tap "Year" header — switches column to year, ascending
        await tester.tap(headerFinder('Year').first);
        await tester.pumpAndSettle();

        // Year ascending: movieBeta(2018) < gameAlpha(2020) < tvGamma(2023)
        final List<String> names = itemNamesInOrder(tester);
        expect(names, <String>['Beta Movie', 'Alpha Game', 'Gamma Show']);
      });

      testWidgets('should sort by rating with nulls as zero',
          (WidgetTester tester) async {
        await pumpTableView(tester, items: threeItems());

        await tester.tap(headerFinder('Rating').first);
        await tester.pumpAndSettle();

        // Ascending: tvGamma(null=0) < movieBeta(7) < gameAlpha(9)
        final List<String> names = itemNamesInOrder(tester);
        expect(names, <String>['Gamma Show', 'Beta Movie', 'Alpha Game']);
      });

      testWidgets('should sort by status index ascending',
          (WidgetTester tester) async {
        await pumpTableView(tester, items: threeItems());

        await tester.tap(headerFinder('Status').first);
        await tester.pumpAndSettle();

        // Enum index: inProgress(1) < completed(2) < planned(4)
        final List<String> names = itemNamesInOrder(tester);
        expect(names, <String>['Beta Movie', 'Alpha Game', 'Gamma Show']);
      });

      testWidgets('should sort by type index ascending',
          (WidgetTester tester) async {
        await pumpTableView(tester, items: threeItems());

        await tester.tap(headerFinder('Type').first);
        await tester.pumpAndSettle();

        // MediaType index: game(0) < movie(1) < tvShow(2)
        final List<String> names = itemNamesInOrder(tester);
        expect(names, <String>['Alpha Game', 'Beta Movie', 'Gamma Show']);
      });

      testWidgets('should sort by platform name ascending',
          (WidgetTester tester) async {
        final CollectionItem gameZ = createTestCollectionItem(
          id: 10,
          mediaType: MediaType.game,
          game: createTestGame(id: 110, name: 'ZZZ Game'),
          platform: const p.Platform(id: 2, name: 'Zzz Platform'),
        );
        final CollectionItem gameA = createTestCollectionItem(
          id: 11,
          mediaType: MediaType.game,
          game: createTestGame(id: 111, name: 'AAA Game'),
          platform: const p.Platform(id: 3, name: 'Aaa Platform'),
        );

        await pumpTableView(
          tester,
          items: <CollectionItem>[gameZ, gameA],
        );

        // Default sort = name ascending: "AAA Game" < "ZZZ Game"
        List<String> names = tester
            .widgetList<Text>(find.byType(Text))
            .where(
              (Text t) => t.data == 'ZZZ Game' || t.data == 'AAA Game',
            )
            .map((Text t) => t.data!)
            .toList();
        expect(names, <String>['AAA Game', 'ZZZ Game']);

        // Tap "Platform" header — switches to platform ascending
        // "Aaa Platform" < "Zzz Platform" → same order as name
        // But we tap twice for descending to prove sorting changed
        await tester.tap(headerFinder('Platform').first);
        await tester.pumpAndSettle();
        await tester.tap(headerFinder('Platform').first);
        await tester.pumpAndSettle();

        // Descending: "Zzz Platform" > "Aaa Platform"
        names = tester
            .widgetList<Text>(find.byType(Text))
            .where(
              (Text t) => t.data == 'ZZZ Game' || t.data == 'AAA Game',
            )
            .map((Text t) => t.data!)
            .toList();
        expect(names, <String>['ZZZ Game', 'AAA Game']);
      });

      testWidgets('should sort by year with nulls as zero',
          (WidgetTester tester) async {
        final CollectionItem noYearItem = createTestCollectionItem(
          id: 4,
          mediaType: MediaType.game,
          game: createTestGame(id: 104, name: 'Delta Game'),
          addedAt: DateTime(2024, 5, 1),
        );

        await pumpTableView(
          tester,
          items: <CollectionItem>[gameAlpha, noYearItem],
        );

        await tester.tap(headerFinder('Year').first);
        await tester.pumpAndSettle();

        // Ascending: noYearItem(null=0) < gameAlpha(2020)
        final Iterable<Text> texts = tester
            .widgetList<Text>(find.byType(Text))
            .where(
              (Text t) => t.data == 'Alpha Game' || t.data == 'Delta Game',
            );
        final List<String> names = texts.map((Text t) => t.data!).toList();
        expect(names, <String>['Delta Game', 'Alpha Game']);
      });

      testWidgets('should toggle descending and back to ascending',
          (WidgetTester tester) async {
        await pumpTableView(tester, items: threeItems());

        // Default: ascending by name
        List<String> names = itemNamesInOrder(tester);
        expect(names.first, 'Alpha Game');

        // Tap Name → descending
        await tester.tap(headerFinder('Name').first);
        await tester.pumpAndSettle();
        names = itemNamesInOrder(tester);
        expect(names.first, 'Gamma Show');

        // Tap Name again → ascending
        await tester.tap(headerFinder('Name').first);
        await tester.pumpAndSettle();
        names = itemNamesInOrder(tester);
        expect(names.first, 'Alpha Game');
      });

      testWidgets('should sort by type descending when tapped twice',
          (WidgetTester tester) async {
        await pumpTableView(tester, items: threeItems());

        // First tap: ascending by type
        await tester.tap(headerFinder('Type').first);
        await tester.pumpAndSettle();

        // Second tap: descending by type
        await tester.tap(headerFinder('Type').first);
        await tester.pumpAndSettle();

        // MediaType index descending: tvShow(2) > movie(1) > game(0)
        final List<String> names = itemNamesInOrder(tester);
        expect(names, <String>['Gamma Show', 'Beta Movie', 'Alpha Game']);
      });
    });
  });
}
