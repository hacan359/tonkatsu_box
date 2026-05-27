import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/widgets/media_progress_row.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('MediaProgressRow', () {
    Future<void> pump(
      WidgetTester tester, {
      required int current,
      required int? total,
      VoidCallback? onIncrement,
      VoidCallback? onEdit,
    }) {
      return tester.pumpApp(
        MediaProgressRow(
          label: 'Episodes',
          current: current,
          total: total,
          accentColor: const Color(0xFF000000),
          onIncrement: onIncrement ?? () {},
          onEdit: onEdit ?? () {},
        ),
        wrapInScaffold: true,
      );
    }

    testWidgets('shows "current / total" and a progress bar when total is set',
        (WidgetTester t) async {
      await pump(t, current: 3, total: 10);

      expect(find.text('3 / 10'), findsOneWidget);
      final LinearProgressIndicator bar = t.widget(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, closeTo(0.3, 1e-9));
    });

    testWidgets('shows only current and hides the bar when total is null',
        (WidgetTester t) async {
      await pump(t, current: 7, total: null);

      expect(find.text('7'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('hides the bar when total is zero', (WidgetTester t) async {
      await pump(t, current: 0, total: 0);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('clamps the bar to 1.0 when current exceeds total',
        (WidgetTester t) async {
      await pump(t, current: 15, total: 10);

      final LinearProgressIndicator bar = t.widget(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, 1.0);
    });

    testWidgets('fires onIncrement and onEdit', (WidgetTester t) async {
      int inc = 0;
      int edit = 0;
      await pump(
        t,
        current: 1,
        total: 5,
        onIncrement: () => inc++,
        onEdit: () => edit++,
      );

      await t.tap(find.byIcon(Icons.add));
      expect(inc, 1);

      await t.tap(find.text('1 / 5'));
      expect(edit, 1);
    });
  });
}
