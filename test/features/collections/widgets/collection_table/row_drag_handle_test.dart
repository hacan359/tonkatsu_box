import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/features/collections/widgets/collection_table/row_drag_handle.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../../../helpers/test_helpers.dart';

class _MockStateManager extends Mock implements TrinaGridStateManager {}

void main() {
  group('RowDragHandle', () {
    late _MockStateManager stateManager;
    late TrinaRow<dynamic> row;

    setUp(() {
      stateManager = _MockStateManager();
      when(() => stateManager.configuration)
          .thenReturn(const TrinaGridConfiguration());
      row = TrinaRow<dynamic>(cells: <String, TrinaCell>{});
    });

    Future<void> pumpHandle(WidgetTester tester) {
      return tester.pumpApp(
        SizedBox(
          width: 48,
          height: 48,
          child: RowDragHandle(row: row, stateManager: stateManager),
        ),
        wrapInScaffold: true,
      );
    }

    testWidgets('should start drag from a hold on touch platforms',
        (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await pumpHandle(tester);

        expect(
          find.byType(LongPressDraggable<TrinaRow<dynamic>>),
          findsOneWidget,
        );
        expect(find.byType(Draggable<TrinaRow<dynamic>>), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('should start drag immediately on desktop',
        (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        await pumpHandle(tester);

        expect(find.byType(Draggable<TrinaRow<dynamic>>), findsOneWidget);
        expect(
          find.byType(LongPressDraggable<TrinaRow<dynamic>>),
          findsNothing,
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
