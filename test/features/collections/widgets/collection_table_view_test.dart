import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/widgets/collection_table/collection_table_view.dart';
import 'package:tonkatsu_box/features/collections/widgets/collection_table/table_filter.dart';
import 'package:tonkatsu_box/features/collections/widgets/collection_table/table_layout_store.dart';
import 'package:tonkatsu_box/shared/models/collection_item.dart';
import 'package:tonkatsu_box/shared/models/item_status.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/models/platform.dart' as p;
import 'package:trina_grid/trina_grid.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(registerAllFallbacks);

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

  Future<void> pumpTableView(
    WidgetTester tester, {
    required List<CollectionItem> items,
    ValueChanged<CollectionItem>? onItemTap,
    Set<int>? selectedIds,
    void Function(int itemId)? onToggleSelect,
    void Function(bool selectAll)? onToggleSelectAll,
    void Function(int oldIndex, int newIndex)? onReorder,
  }) async {
    // The grid lays out against the real test surface (MediaQuery overrides
    // don't affect layout), so widen it to fit every column.
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpApp(
      CollectionTableView(
        items: items,
        onItemTap: onItemTap ?? (CollectionItem _) {},
        selectedIds: selectedIds,
        onToggleSelect: onToggleSelect,
        onToggleSelectAll: onToggleSelectAll,
        onReorder: onReorder,
      ),
      wrapInScaffold: true,
    );
    // Extra frame for the async column-layout load.
    await tester.pump();
  }

  // Cells carry a double-tap recognizer (row double tap opens the item), so
  // a single tap only resolves after the double-tap window expires.
  Future<void> tapAndResolve(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('TableFilterCondition', () {
    test('maps each condition to the matching trina filter type', () {
      expect(
        TableFilterCondition.contains.trinaType,
        isA<TrinaFilterTypeContains>(),
      );
      expect(
        TableFilterCondition.equals.trinaType,
        isA<TrinaFilterTypeEquals>(),
      );
      expect(
        TableFilterCondition.startsWith.trinaType,
        isA<TrinaFilterTypeStartsWith>(),
      );
      expect(
        TableFilterCondition.endsWith.trinaType,
        isA<TrinaFilterTypeEndsWith>(),
      );
      expect(
        TableFilterCondition.atLeast.trinaType,
        isA<TrinaFilterTypeGreaterThanOrEqualTo>(),
      );
      expect(
        TableFilterCondition.atMost.trinaType,
        isA<TrinaFilterTypeLessThanOrEqualTo>(),
      );
    });
  });

  group('TableColumnLayout', () {
    test('encode/fromJson roundtrip preserves order and widths', () {
      const TableColumnLayout layout = TableColumnLayout(
        order: <String>['name', 'year', 'status'],
        widths: <String, double>{'name': 280, 'year': 72.5},
      );
      final TableColumnLayout decoded = TableColumnLayout.fromJson(
        jsonDecode(layout.encode()) as Map<String, dynamic>,
      );
      expect(decoded.order, <String>['name', 'year', 'status']);
      expect(decoded.widths['name'], 280);
      expect(decoded.widths['year'], 72.5);
    });
  });

  group('CollectionTableView', () {
    group('rendering', () {
      testWidgets('should render all item names', (WidgetTester tester) async {
        await pumpTableView(tester, items: threeItems());

        expect(find.text('Alpha Game'), findsOneWidget);
        expect(find.text('Beta Movie'), findsOneWidget);
        expect(find.text('Gamma Show'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should render empty list without errors',
          (WidgetTester tester) async {
        await pumpTableView(tester, items: <CollectionItem>[]);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should display genres when present',
          (WidgetTester tester) async {
        await pumpTableView(tester, items: <CollectionItem>[gameAlpha]);
        expect(find.text('RPG, Action'), findsOneWidget);
      });

      testWidgets('should show platform abbreviation for games',
          (WidgetTester tester) async {
        await pumpTableView(tester, items: <CollectionItem>[gameAlpha]);
        expect(find.text('PS'), findsOneWidget);
      });
    });

    group('onItemTap', () {
      testWidgets('tapping the item name opens it',
          (WidgetTester tester) async {
        final List<CollectionItem> tapped = <CollectionItem>[];
        await pumpTableView(
          tester,
          items: threeItems(),
          onItemTap: tapped.add,
        );

        await tapAndResolve(tester, find.text('Beta Movie'));

        expect(tapped, hasLength(1));
        expect(tapped.single.id, movieBeta.id);
      });
    });

    group('sorting', () {
      testWidgets('tapping the year header sorts rows by year',
          (WidgetTester tester) async {
        await pumpTableView(tester, items: threeItems());

        // Tap the title's left corner: the resize/menu icon overlays the
        // centre of narrow column titles.
        await tester.tapAt(
          tester.getTopLeft(find.text('YEAR')) + const Offset(2, 2),
        );
        await tester.pumpAndSettle();

        final double alphaY = tester.getTopLeft(find.text('Alpha Game')).dy;
        final double betaY = tester.getTopLeft(find.text('Beta Movie')).dy;
        final double gammaY = tester.getTopLeft(find.text('Gamma Show')).dy;
        // Ascending: Beta (2018) < Alpha (2020) < Gamma (2023).
        expect(betaY, lessThan(alphaY));
        expect(alphaY, lessThan(gammaY));
      });

      testWidgets('second tap flips the direction',
          (WidgetTester tester) async {
        await pumpTableView(tester, items: threeItems());

        await tester.tapAt(
          tester.getTopLeft(find.text('YEAR')) + const Offset(2, 2),
        );
        await tester.pumpAndSettle();
        await tester.tapAt(
          tester.getTopLeft(find.text('YEAR')) + const Offset(2, 2),
        );
        await tester.pumpAndSettle();

        final double betaY = tester.getTopLeft(find.text('Beta Movie')).dy;
        final double gammaY = tester.getTopLeft(find.text('Gamma Show')).dy;
        expect(gammaY, lessThan(betaY));
      });
    });

    group('selection', () {
      testWidgets('row checkbox toggles selection via callback',
          (WidgetTester tester) async {
        final List<int> toggled = <int>[];
        await pumpTableView(
          tester,
          items: <CollectionItem>[gameAlpha],
          selectedIds: <int>{},
          onToggleSelect: toggled.add,
          onToggleSelectAll: (bool _) {},
        );

        // The grid paints body rows before the header, so the row checkbox
        // comes first in the tree and the select-all one last.
        final Finder checkboxes = find.byType(Checkbox);
        expect(checkboxes, findsNWidgets(2));
        await tapAndResolve(tester, checkboxes.first);

        expect(toggled, <int>[gameAlpha.id]);
      });

      testWidgets('header checkbox fires select-all',
          (WidgetTester tester) async {
        final List<bool> selectAllCalls = <bool>[];
        await pumpTableView(
          tester,
          items: threeItems(),
          selectedIds: <int>{},
          onToggleSelect: (int _) {},
          onToggleSelectAll: selectAllCalls.add,
        );

        await tapAndResolve(tester, find.byType(Checkbox).last);

        expect(selectAllCalls, <bool>[true]);
      });
    });
  });
}
