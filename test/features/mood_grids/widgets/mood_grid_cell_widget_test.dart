import 'package:core/models/media_type.dart';
import 'package:core/models/mood_grid_cell.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/mood_grids/widgets/mood_grid_cell_media.dart';
import 'package:tonkatsu_box/features/mood_grids/widgets/mood_grid_cell_widget.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  const MoodGridCell emptyCell = MoodGridCell(id: 1, gridId: 1, position: 0);
  const MoodGridCell filledCell = MoodGridCell(
    id: 2,
    gridId: 1,
    position: 1,
    label: 'Favorite Game',
    mediaType: MediaType.game,
    externalId: 7,
  );

  // Center loosens constraints like the real Row-based grid layout does;
  // a tight full-screen constraint would blow up the 2:3 cover.
  Widget wrap(Widget cell) => Material(child: Center(child: cell));

  group('MoodGridCellWidget', () {
    testWidgets('tap on the cover zone fires onTap only', (
      WidgetTester tester,
    ) async {
      bool coverTapped = false;
      bool labelTapped = false;
      await tester.pumpApp(
        wrap(
          MoodGridCellWidget(
            cell: emptyCell,
            media: MoodGridCellMedia.empty,
            onTap: () => coverTapped = true,
            onLabelTap: () => labelTapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(AspectRatio));

      expect(coverTapped, isTrue);
      expect(labelTapped, isFalse);
    });

    testWidgets('tap on the label zone fires onLabelTap only', (
      WidgetTester tester,
    ) async {
      bool coverTapped = false;
      bool labelTapped = false;
      await tester.pumpApp(
        wrap(
          MoodGridCellWidget(
            cell: filledCell,
            media: MoodGridCellMedia.empty,
            onTap: () => coverTapped = true,
            onLabelTap: () => labelTapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Favorite Game'));

      expect(labelTapped, isTrue);
      expect(coverTapped, isFalse);
    });

    testWidgets('label zone is tappable when the label is empty', (
      WidgetTester tester,
    ) async {
      bool labelTapped = false;
      await tester.pumpApp(
        wrap(
          MoodGridCellWidget(
            cell: emptyCell,
            media: MoodGridCellMedia.empty,
            onLabelTap: () => labelTapped = true,
          ),
        ),
      );

      // The label InkWell is the second one (cover first, label second).
      await tester.tap(find.byType(InkWell).last);

      expect(labelTapped, isTrue);
    });

    testWidgets('secondary tap reports a context-menu position', (
      WidgetTester tester,
    ) async {
      Offset? menuPos;
      await tester.pumpApp(
        wrap(
          MoodGridCellWidget(
            cell: filledCell,
            media: MoodGridCellMedia.empty,
            onContextMenu: (Offset pos) => menuPos = pos,
          ),
        ),
      );

      await tester.tap(
        find.byType(MoodGridCellWidget),
        buttons: kSecondaryButton,
      );

      expect(menuPos, isNotNull);
    });

    testWidgets('renders a two-line label without exceptions on a phone', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const MoodGridCell longLabelCell = MoodGridCell(
        id: 3,
        gridId: 1,
        position: 0,
        label: 'A very long category label that would have been clipped '
            'by the old fixed-height box',
      );
      await tester.pumpApp(
        wrap(
          const MoodGridCellWidget(
            cell: longLabelCell,
            media: MoodGridCellMedia.empty,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final Text text = tester.widget<Text>(
        find.textContaining('A very long category label'),
      );
      expect(text.maxLines, 2);
    });
  });
}
