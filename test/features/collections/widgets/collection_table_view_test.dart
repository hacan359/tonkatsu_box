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
  /// Для стабильного поиска при фильтрации (текст заголовка меняется)
  /// используем Key-based fallback.
  Finder headerFinder(String label) {
    // Имя колонки → TableColumn для Key-based поиска
    const Map<String, TableColumn> columnMap = <String, TableColumn>{
      'Name': TableColumn.name,
      'Type': TableColumn.type,
      'Platform': TableColumn.platform,
      'Status': TableColumn.status,
      'Rating': TableColumn.rating,
      'Year': TableColumn.year,
      'Added': TableColumn.added,
    };
    final TableColumn? column = columnMap[label];
    if (column != null) {
      return find.byKey(ValueKey<TableColumn>(column));
    }
    final String lower = label.toLowerCase();
    return find.ancestor(
      of: find.byWidgetPredicate((Widget w) {
        if (w is! Text) return false;
        final String? t = w.data ?? w.textSpan?.toPlainText();
        return t != null && t.toLowerCase().contains(lower);
      }),
      matching: find.byType(InkWell),
    );
  }

  // =========================================================================
  // TableColumn enum
  // =========================================================================

  group('TableColumn', () {
    test('should have 8 values', () {
      expect(TableColumn.values.length, 8);
    });

    test('should contain all expected columns', () {
      expect(
        TableColumn.values,
        containsAll(<TableColumn>[
          TableColumn.name,
          TableColumn.type,
          TableColumn.platform,
          TableColumn.status,
          TableColumn.tag,
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

      testWidgets('should render empty rating cell when null',
          (WidgetTester tester) async {
        await pumpTableView(tester, items: <CollectionItem>[tvGamma]);

        // tvGamma has no userRating — star icon must be absent in rating cell.
        expect(find.byIcon(Icons.star_rounded), findsNothing);
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

      testWidgets('should filter by rating on tap, cycle through values',
          (WidgetTester tester) async {
        await pumpTableView(tester, items: threeItems());

        // First tap: filter to first rating value (0 = null rating)
        await tester.tap(headerFinder('Rating').first);
        await tester.pumpAndSettle();

        // Only Gamma Show has null rating (0)
        List<String> names = itemNamesInOrder(tester);
        expect(names, <String>['Gamma Show']);

        // Second tap: next rating value (7)
        await tester.tap(headerFinder('Rating').first);
        await tester.pumpAndSettle();
        names = itemNamesInOrder(tester);
        expect(names, <String>['Beta Movie']);

        // Third tap: next rating value (9)
        await tester.tap(headerFinder('Rating').first);
        await tester.pumpAndSettle();
        names = itemNamesInOrder(tester);
        expect(names, <String>['Alpha Game']);

        // Fourth tap: reset to show all
        await tester.tap(headerFinder('Rating').first);
        await tester.pumpAndSettle();
        names = itemNamesInOrder(tester);
        expect(names.length, 3);
      });

      testWidgets('should filter by status on tap, cycle through values',
          (WidgetTester tester) async {
        await pumpTableView(tester, items: threeItems());

        // First tap: filter to first status (inProgress)
        await tester.tap(headerFinder('Status').first);
        await tester.pumpAndSettle();

        List<String> names = itemNamesInOrder(tester);
        expect(names, <String>['Beta Movie']);

        // Second tap: next status (completed)
        await tester.tap(headerFinder('Status').first);
        await tester.pumpAndSettle();
        names = itemNamesInOrder(tester);
        expect(names, <String>['Alpha Game']);

        // Third tap: next status (planned)
        await tester.tap(headerFinder('Status').first);
        await tester.pumpAndSettle();
        names = itemNamesInOrder(tester);
        expect(names, <String>['Gamma Show']);

        // Fourth tap: reset
        await tester.tap(headerFinder('Status').first);
        await tester.pumpAndSettle();
        names = itemNamesInOrder(tester);
        expect(names.length, 3);
      });

      testWidgets('should filter by type on tap, cycle through values',
          (WidgetTester tester) async {
        await pumpTableView(tester, items: threeItems());

        // First tap: filter to first type (game)
        await tester.tap(headerFinder('Type').first);
        await tester.pumpAndSettle();

        List<String> names = itemNamesInOrder(tester);
        expect(names, <String>['Alpha Game']);

        // Second tap: next type (movie)
        await tester.tap(headerFinder('Type').first);
        await tester.pumpAndSettle();
        names = itemNamesInOrder(tester);
        expect(names, <String>['Beta Movie']);

        // Third tap: next type (tvShow)
        await tester.tap(headerFinder('Type').first);
        await tester.pumpAndSettle();
        names = itemNamesInOrder(tester);
        expect(names, <String>['Gamma Show']);

        // Fourth tap: reset
        await tester.tap(headerFinder('Type').first);
        await tester.pumpAndSettle();
        names = itemNamesInOrder(tester);
        expect(names.length, 3);
      });

      testWidgets('should filter by platform on tap, cycle through values',
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

        // Both visible initially
        expect(find.text('ZZZ Game'), findsOneWidget);
        expect(find.text('AAA Game'), findsOneWidget);

        // Tap Platform header → filter to first platform ("Aaa Platform")
        await tester.tap(headerFinder('Platform').first);
        await tester.pumpAndSettle();

        expect(find.text('AAA Game'), findsOneWidget);
        expect(find.text('ZZZ Game'), findsNothing);

        // Tap again → filter to next platform ("Zzz Platform")
        await tester.tap(headerFinder('Aaa Platform').first);
        await tester.pumpAndSettle();

        expect(find.text('ZZZ Game'), findsOneWidget);
        expect(find.text('AAA Game'), findsNothing);

        // Tap again → reset filter (null)
        await tester.tap(headerFinder('Zzz Platform').first);
        await tester.pumpAndSettle();

        expect(find.text('ZZZ Game'), findsOneWidget);
        expect(find.text('AAA Game'), findsOneWidget);
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

      testWidgets('should not filter when only one value exists',
          (WidgetTester tester) async {
        // All three items have different status — test with same status
        // Use threeItems but override all to same status
        final List<CollectionItem> sameStatus = <CollectionItem>[
          gameAlpha.copyWith(status: ItemStatus.completed),
          movieBeta.copyWith(status: ItemStatus.completed),
          tvGamma.copyWith(status: ItemStatus.completed),
        ];
        await pumpTableView(tester, items: sameStatus);

        // Tap Status — single value, no filter applied
        await tester.tap(headerFinder('Status').first);
        await tester.pumpAndSettle();

        final List<String> names = itemNamesInOrder(tester);
        expect(names.length, 3);
      });
    });
  });
}
