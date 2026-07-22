import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/mood_grids/widgets/mood_grid_cell_media.dart';
import 'package:tonkatsu_box/features/mood_grids/widgets/mood_grid_cell_widget.dart';
import 'package:tonkatsu_box/features/mood_grids/widgets/mood_grid_export_view.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/models/mood_grid.dart';
import 'package:tonkatsu_box/shared/models/mood_grid_cell.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(registerAllFallbacks);

  group('MoodGridExportView', () {
    late GlobalKey repaintKey;

    setUp(() {
      repaintKey = GlobalKey();
    });

    MoodGrid createGrid({int rows = 2, int cols = 2, String? template}) {
      return MoodGrid(
        id: 1,
        name: 'My Mood Grid',
        rows: rows,
        cols: cols,
        captionTemplate: template,
        createdAt: testDate,
        updatedAt: testDate,
      );
    }

    Future<void> pumpView(
      WidgetTester tester,
      MoodGrid grid, {
      List<MoodGridCell> cells = const <MoodGridCell>[],
      double cellWidth = 140,
    }) async {
      await tester.pumpApp(
        Material(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: MoodGridExportView(
                repaintKey: repaintKey,
                grid: grid,
                cells: cells,
                mediaByPosition: const <int, MoodGridCellMedia>{},
                cellWidth: cellWidth,
              ),
            ),
          ),
        ),
        settle: false,
      );
      await tester.pump();
    }

    testWidgets('should render without layout overflow', (
      WidgetTester tester,
    ) async {
      await pumpView(tester, createGrid());

      expect(tester.takeException(), isNull);
      expect(find.byType(MoodGridExportView), findsOneWidget);
      expect(find.text('My Mood Grid'), findsOneWidget);
    });

    testWidgets('should render without overflow when captions are shown', (
      WidgetTester tester,
    ) async {
      await pumpView(tester, createGrid(template: '{title}'));

      expect(tester.takeException(), isNull);
      expect(find.byType(MoodGridExportView), findsOneWidget);
    });

    testWidgets('should render without overflow for a single column', (
      WidgetTester tester,
    ) async {
      await pumpView(tester, createGrid(rows: 1, cols: 1));

      expect(tester.takeException(), isNull);
    });

    testWidgets('should not render empty cells', (WidgetTester tester) async {
      const List<MoodGridCell> cells = <MoodGridCell>[
        MoodGridCell(id: 1, gridId: 1, position: 0),
        MoodGridCell(
          id: 2,
          gridId: 1,
          position: 1,
          mediaType: MediaType.game,
          externalId: 7,
        ),
      ];

      await pumpView(tester, createGrid(rows: 1, cols: 2), cells: cells);

      // Only the filled cell renders; empty slots leave blank space and
      // never show the `+` placeholder.
      expect(find.byType(MoodGridCellWidget), findsOneWidget);
      expect(find.byIcon(Icons.add), findsNothing);
    });

    testWidgets('should size cells from cellWidth', (
      WidgetTester tester,
    ) async {
      const List<MoodGridCell> cells = <MoodGridCell>[
        MoodGridCell(
          id: 1,
          gridId: 1,
          position: 0,
          mediaType: MediaType.game,
          externalId: 7,
        ),
      ];

      await pumpView(
        tester,
        createGrid(rows: 1, cols: 1),
        cells: cells,
        cellWidth: 200,
      );

      final Size size = tester.getSize(find.byType(MoodGridCellWidget));
      expect(size.width, 200);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should render on a phone-sized surface', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpView(tester, createGrid(rows: 2, cols: 3));

      expect(tester.takeException(), isNull);
    });
  });
}
