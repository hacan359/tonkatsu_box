// Tests for AddTimeDialog widget.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/widgets/dialogs/add_time_dialog.dart';
import 'package:xerabora/l10n/app_localizations.dart';

void main() {
  group('AddTimeDialog', () {
    Widget buildTestApp({
      required void Function(int? result) onResult,
      int initialMinutes = 0,
      bool isEdit = false,
    }) {
      return MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () async {
                  final int? result = await AddTimeDialog.show(
                    context,
                    initialMinutes: initialMinutes,
                    isEdit: isEdit,
                  );
                  onResult(result);
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );
    }

    testWidgets('shows "Add time" title when isEdit is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(onResult: (_) {}));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Add time'), findsOneWidget);
    });

    testWidgets('shows "Edit time" title when isEdit is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(
        onResult: (_) {},
        isEdit: true,
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Edit time'), findsOneWidget);
    });

    testWidgets('pre-fills hours and minutes from initialMinutes',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(
        onResult: (_) {},
        initialMinutes: 150,
        isEdit: true,
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // 150 minutes = 2 hours, 30 minutes
      final TextField hoursField = tester.widget<TextField>(
        find.byType(TextField).first,
      );
      final TextField minutesField = tester.widget<TextField>(
        find.byType(TextField).last,
      );

      expect(hoursField.controller?.text, '2');
      expect(minutesField.controller?.text, '30');
    });

    testWidgets('cancel returns null',
        (WidgetTester tester) async {
      int? result = 999;

      await tester.pumpWidget(buildTestApp(
        onResult: (int? r) => result = r,
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('entering hours=1, minutes=30 and pressing Save returns 90',
        (WidgetTester tester) async {
      int? result;

      await tester.pumpWidget(buildTestApp(
        onResult: (int? r) => result = r,
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '1');
      await tester.enterText(find.byType(TextField).last, '30');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, 90);
    });

    testWidgets('entering hours=0, minutes=90 and pressing Save returns 90',
        (WidgetTester tester) async {
      int? result;

      await tester.pumpWidget(buildTestApp(
        onResult: (int? r) => result = r,
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '0');
      await tester.enterText(find.byType(TextField).last, '90');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, 90);
    });

    testWidgets('empty fields treated as 0',
        (WidgetTester tester) async {
      int? result;

      await tester.pumpWidget(buildTestApp(
        onResult: (int? r) => result = r,
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Leave both fields empty, just press Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, 0);
    });
  });
}
