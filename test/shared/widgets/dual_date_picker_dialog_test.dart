import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/widgets/dual_date_picker_dialog.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('DualDatePickerDialog', () {
    final DateTime first = DateTime(2020, 1, 1);
    final DateTime last = DateTime(2025, 12, 31);
    final DateTime initial = DateTime(2024, 3, 15);

    Future<DateTime?> openAndGet(
      WidgetTester tester,
      Future<void> Function(WidgetTester tester) interact,
    ) async {
      DateTime? result;
      bool done = false;
      await tester.pumpApp(
        Builder(
          builder: (BuildContext context) => ElevatedButton(
            onPressed: () async {
              result = await showDualDatePicker(
                context: context,
                initialDate: initial,
                firstDate: first,
                lastDate: last,
              );
              done = true;
            },
            child: const Text('open'),
          ),
        ),
        wrapInScaffold: true,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await interact(tester);
      await tester.pumpAndSettle();
      expect(done, isTrue, reason: 'dialog should have been dismissed');
      return result;
    }

    bool okEnabled(WidgetTester tester) {
      final TextButton ok = tester.widget(find.widgetWithText(TextButton, 'OK'));
      return ok.onPressed != null;
    }

    testWidgets('confirms the initial date when untouched', (WidgetTester t) async {
      final DateTime? r =
          await openAndGet(t, (WidgetTester t) async => t.tap(find.text('OK')));
      expect(r, DateTime(2024, 3, 15));
    });

    testWidgets('accepts a valid in-range typed date', (WidgetTester t) async {
      final DateTime? r = await openAndGet(t, (WidgetTester t) async {
        await t.enterText(find.byType(TextField), '2024-06-20');
        await t.pump();
        await t.tap(find.text('OK'));
      });
      expect(r, DateTime(2024, 6, 20));
    });

    testWidgets('cancel returns null', (WidgetTester t) async {
      final DateTime? r = await openAndGet(
        t,
        (WidgetTester t) async => t.tap(find.text('Cancel')),
      );
      expect(r, isNull);
    });

    testWidgets('disables OK on an invalid format', (WidgetTester t) async {
      await _open(t, initial, first, last);
      await t.enterText(find.byType(TextField), 'not-a-date');
      await t.pump();
      expect(okEnabled(t), isFalse);
    });

    testWidgets('disables OK on an out-of-range date', (WidgetTester t) async {
      await _open(t, initial, first, last);
      await t.enterText(find.byType(TextField), '2030-01-01');
      await t.pump();
      expect(okEnabled(t), isFalse);
    });

    testWidgets('disables OK on empty input, re-enables when fixed',
        (WidgetTester t) async {
      await _open(t, initial, first, last);

      await t.enterText(find.byType(TextField), '');
      await t.pump();
      expect(okEnabled(t), isFalse);

      await t.enterText(find.byType(TextField), '2021-05-05');
      await t.pump();
      expect(okEnabled(t), isTrue);
    });
  });
}

Future<void> _open(
  WidgetTester tester,
  DateTime initial,
  DateTime first,
  DateTime last,
) async {
  await tester.pumpApp(
    DualDatePickerDialog(initialDate: initial, firstDate: first, lastDate: last),
    wrapInScaffold: true,
  );
}
