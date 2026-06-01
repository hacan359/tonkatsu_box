import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/widgets/dialogs/edit_connection_dialog.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/models/canvas_connection.dart';

void main() {
  group('EditConnectionDialog', () {
    Future<void> pumpDialog(
      WidgetTester tester, {
      String? initialLabel,
      String? initialColor,
      ConnectionStyle? initialStyle,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    EditConnectionDialog.show(
                      context,
                      initialLabel: initialLabel,
                      initialColor: initialColor,
                      initialStyle: initialStyle,
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('should show dialog with title', (WidgetTester tester) async {
      await pumpDialog(tester);
      expect(find.text('Edit Connection'), findsOneWidget);
    });

    testWidgets('should show label text field', (WidgetTester tester) async {
      await pumpDialog(tester);
      expect(find.text('Label (optional)'), findsOneWidget);
    });

    testWidgets('should show initial label', (WidgetTester tester) async {
      await pumpDialog(tester, initialLabel: 'depends on');
      expect(find.text('depends on'), findsOneWidget);
    });

    testWidgets('should show Color section', (WidgetTester tester) async {
      await pumpDialog(tester);
      expect(find.text('Color'), findsOneWidget);
    });

    testWidgets('should show Style section', (WidgetTester tester) async {
      await pumpDialog(tester);
      expect(find.text('Style'), findsOneWidget);
    });

    testWidgets('should show style segments', (WidgetTester tester) async {
      await pumpDialog(tester);
      expect(find.text('Solid'), findsOneWidget);
      expect(find.text('Dashed'), findsOneWidget);
      expect(find.text('Arrow'), findsOneWidget);
    });

    testWidgets('should show Cancel and Save buttons',
        (WidgetTester tester) async {
      await pumpDialog(tester);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('Cancel should close without result',
        (WidgetTester tester) async {
      await pumpDialog(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Edit Connection'), findsNothing);
    });

    testWidgets('Save should close with result',
        (WidgetTester tester) async {
      Map<String, dynamic>? result;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await EditConnectionDialog.show(context);
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'my label');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!['label'], 'my label');
      expect(result!['color'], '#666666');
      expect(result!['style'], 'solid');
    });

    testWidgets('Save with empty label should return null label',
        (WidgetTester tester) async {
      Map<String, dynamic>? result;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await EditConnectionDialog.show(context);
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!['label'], isNull);
    });

    testWidgets('should show color swatch that opens picker',
        (WidgetTester tester) async {
      await pumpDialog(tester);
      // Inline palette was replaced with a single swatch that opens
      // ColorPickerDialog (a0ce1c0).
      expect(find.text('Color'), findsOneWidget);
      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('should select initial style', (WidgetTester tester) async {
      await pumpDialog(tester, initialStyle: ConnectionStyle.arrow);
      final SegmentedButton<ConnectionStyle> segmented =
          tester.widget(find.byType(SegmentedButton<ConnectionStyle>));
      expect(segmented.selected, contains(ConnectionStyle.arrow));
    });

    testWidgets('should change style when tapping segment',
        (WidgetTester tester) async {
      Map<String, dynamic>? result;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await EditConnectionDialog.show(context);
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dashed'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result!['style'], 'dashed');
    });
  });
}
