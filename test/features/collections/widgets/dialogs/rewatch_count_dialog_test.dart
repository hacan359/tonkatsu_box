import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/widgets/dialogs/rewatch_count_dialog.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';

void main() {
  group('RewatchCountDialog', () {
    Widget buildTestApp({
      required void Function(({int? count})? result) onResult,
      int? initialCount,
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
                  final ({int? count})? result = await RewatchCountDialog.show(
                    context,
                    initialCount: initialCount,
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

    testWidgets('should render without exception on a phone-sized screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestApp(onResult: (_) {}));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should pre-fill the field from initialCount',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(
        onResult: (_) {},
        initialCount: 3,
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final TextField field =
          tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, '3');
    });

    testWidgets('should leave the field empty when initialCount is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(onResult: (_) {}));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final TextField field =
          tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, isEmpty);
    });

    testWidgets('should return the entered count when saved',
        (WidgetTester tester) async {
      ({int? count})? result;

      await tester.pumpWidget(buildTestApp(
        onResult: (({int? count})? r) => result = r,
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '5');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result?.count, 5);
    });

    testWidgets('should return count null when saved with an empty field',
        (WidgetTester tester) async {
      ({int? count})? result;

      await tester.pumpWidget(buildTestApp(
        onResult: (({int? count})? r) => result = r,
        initialCount: 2,
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result?.count, isNull);
    });

    testWidgets('should return null (no record) when cancelled',
        (WidgetTester tester) async {
      ({int? count})? result = (count: 999);

      await tester.pumpWidget(buildTestApp(
        onResult: (({int? count})? r) => result = r,
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });
}
