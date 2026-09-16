import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/widgets/dual_date_picker_dialog.dart';

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

    group('allowClear', () {
      Future<DualDateResult?> openResultAndGet(
        WidgetTester tester, {
        required bool allowClear,
        required Future<void> Function(WidgetTester tester) interact,
      }) async {
        DualDateResult? result;
        bool done = false;
        await tester.pumpApp(
          Builder(
            builder: (BuildContext context) => ElevatedButton(
              onPressed: () async {
                result = await showDualDatePickerResult(
                  context: context,
                  initialDate: initial,
                  firstDate: first,
                  lastDate: last,
                  allowClear: allowClear,
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

      testWidgets('hides the clear action by default', (WidgetTester t) async {
        await _open(t, initial, first, last);
        expect(find.text('No date'), findsNothing);
      });

      testWidgets('clear action returns a cleared result', (WidgetTester t) async {
        final DualDateResult? r = await openResultAndGet(
          t,
          allowClear: true,
          interact: (WidgetTester t) async => t.tap(find.text('No date')),
        );
        expect(r, isNotNull);
        expect(r!.cleared, isTrue);
        expect(r.date, isNull);
      });

      testWidgets('confirm still returns the picked date', (WidgetTester t) async {
        final DualDateResult? r = await openResultAndGet(
          t,
          allowClear: true,
          interact: (WidgetTester t) async => t.tap(find.text('OK')),
        );
        expect(r, isNotNull);
        expect(r!.cleared, isFalse);
        expect(r.date, DateTime(2024, 3, 15));
      });

      testWidgets('cancel returns null result', (WidgetTester t) async {
        final DualDateResult? r = await openResultAndGet(
          t,
          allowClear: true,
          interact: (WidgetTester t) async => t.tap(find.text('Cancel')),
        );
        expect(r, isNull);
      });
    });

    group('allowBoth', () {
      const String bothLabel = 'Started and finished this day';

      Future<DualDateResult?> openResultAndGet(
        WidgetTester tester, {
        required bool allowBoth,
        required Future<void> Function(WidgetTester tester) interact,
      }) async {
        DualDateResult? result;
        bool done = false;
        await tester.pumpApp(
          Builder(
            builder: (BuildContext context) => ElevatedButton(
              onPressed: () async {
                result = await showDualDatePickerResult(
                  context: context,
                  initialDate: initial,
                  firstDate: first,
                  lastDate: last,
                  allowBoth: allowBoth,
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

      testWidgets('hides the both action by default', (WidgetTester t) async {
        await _open(t, initial, first, last);
        expect(find.text(bothLabel), findsNothing);
      });

      testWidgets('both action returns the picked date flagged for both fields',
          (WidgetTester t) async {
        final DualDateResult? r = await openResultAndGet(
          t,
          allowBoth: true,
          interact: (WidgetTester t) async => t.tap(find.text(bothLabel)),
        );
        expect(r, isNotNull);
        expect(r!.appliesToBoth, isTrue);
        expect(r.cleared, isFalse);
        expect(r.date, DateTime(2024, 3, 15));
      });

      testWidgets('both action follows the typed date', (WidgetTester t) async {
        final DualDateResult? r = await openResultAndGet(
          t,
          allowBoth: true,
          interact: (WidgetTester t) async {
            await t.enterText(find.byType(TextField), '2024-03-20');
            await t.pump();
            await t.tap(find.text(bothLabel));
          },
        );
        expect(r?.appliesToBoth, isTrue);
        expect(r?.date, DateTime(2024, 3, 20));
      });

      testWidgets('both action is disabled while the typed date is invalid',
          (WidgetTester t) async {
        await t.pumpApp(
          Builder(
            builder: (BuildContext context) => ElevatedButton(
              onPressed: () => showDualDatePickerResult(
                context: context,
                initialDate: initial,
                firstDate: first,
                lastDate: last,
                allowBoth: true,
              ),
              child: const Text('open'),
            ),
          ),
          wrapInScaffold: true,
        );
        await t.tap(find.text('open'));
        await t.pumpAndSettle();
        await t.enterText(find.byType(TextField), 'nope');
        await t.pump();

        final TextButton button = t.widget<TextButton>(
          find.widgetWithText(TextButton, bothLabel),
        );
        expect(button.onPressed, isNull);
      });

      testWidgets('confirm keeps a single-field result', (WidgetTester t) async {
        final DualDateResult? r = await openResultAndGet(
          t,
          allowBoth: true,
          interact: (WidgetTester t) async => t.tap(find.text('OK')),
        );
        expect(r?.appliesToBoth, isFalse);
        expect(r?.date, DateTime(2024, 3, 15));
      });

      testWidgets('renders at phone size without overflow',
          (WidgetTester t) async {
        t.view.physicalSize = const Size(360, 640);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        await openResultAndGet(
          t,
          allowBoth: true,
          interact: (WidgetTester t) async => t.tap(find.text('Cancel')),
        );
        expect(t.takeException(), isNull);
      });

      testWidgets('should render on a landscape phone with the keyboard up',
          (WidgetTester t) async {
        t.view.physicalSize = const Size(640, 300);
        t.view.devicePixelRatio = 1;
        t.view.viewInsets = const FakeViewPadding(bottom: 150);
        addTearDown(t.view.reset);
        await openResultAndGet(
          t,
          allowBoth: true,
          interact: (WidgetTester t) async => t.tap(find.text('Cancel')),
        );
        expect(t.takeException(), isNull);
      });
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
