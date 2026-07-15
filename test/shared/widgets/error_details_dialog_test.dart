import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/extensions/snackbar_extension.dart';
import 'package:tonkatsu_box/shared/widgets/error_details_dialog.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('showErrorDetailsDialog', () {
    testWidgets('should show message и detail без исключений',
        (WidgetTester tester) async {
      await tester.pumpApp(
        Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => showErrorDetailsDialog(
              context,
              message: 'Import failed: timeout',
              detail: 'GET /sync → 504',
            ),
            child: const Text('open'),
          ),
        ),
        wrapInScaffold: true,
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Import failed: timeout'), findsOneWidget);
      expect(find.text('GET /sync → 504'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should hide блок detail когда detail == null',
        (WidgetTester tester) async {
      await tester.pumpApp(
        Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => showErrorDetailsDialog(
              context,
              message: 'Import failed: timeout',
            ),
            child: const Text('open'),
          ),
        ),
        wrapInScaffold: true,
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Import failed: timeout'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('копирование не бросает исключений',
        (WidgetTester tester) async {
      await tester.pumpApp(
        Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => showErrorDetailsDialog(
              context,
              message: 'boom',
              detail: 'stack',
            ),
            child: const Text('open'),
          ),
        ),
        wrapInScaffold: true,
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.copy));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('showErrorSnack', () {
    testWidgets('открывает диалог деталей по действию снека',
        (WidgetTester tester) async {
      await tester.pumpApp(
        Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => context.showErrorSnack(
              'Import failed: timeout',
              detail: 'GET /sync → 504',
            ),
            child: const Text('fail'),
          ),
        ),
        wrapInScaffold: true,
      );

      await tester.tap(find.text('fail'));
      await tester.pumpAndSettle();

      expect(find.text('Import failed: timeout'), findsOneWidget);

      await tester.tap(find.byType(SnackBarAction));
      await tester.pumpAndSettle();

      expect(find.text('GET /sync → 504'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
