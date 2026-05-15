import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/widgets/rename_item_dialog.dart';
import 'package:xerabora/l10n/app_localizations.dart';

void main() {
  group('RenameItemDialog', () {
    testWidgets('pre-fills the field with the current override when present',
        (WidgetTester tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                capturedContext = context;
                return ElevatedButton(
                  onPressed: () => RenameItemDialog.show(
                    capturedContext,
                    currentOverride: 'Renamed',
                    originalName: 'Original',
                  ),
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Renamed'), findsOneWidget);
    });

    testWidgets('pre-fills the field with the original name when no override yet',
        (WidgetTester tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                capturedContext = context;
                return ElevatedButton(
                  onPressed: () => RenameItemDialog.show(
                    capturedContext,
                    currentOverride: null,
                    originalName: 'Original',
                  ),
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Original'), findsOneWidget);
    });

    testWidgets('Reset button is hidden when no override is set',
        (WidgetTester tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                capturedContext = context;
                return ElevatedButton(
                  onPressed: () => RenameItemDialog.show(
                    capturedContext,
                    currentOverride: null,
                    originalName: 'Original',
                  ),
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Reset to original'), findsNothing);
    });

    testWidgets('Save returns the trimmed text', (WidgetTester tester) async {
      String? captured;
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                capturedContext = context;
                return ElevatedButton(
                  onPressed: () async {
                    captured = await RenameItemDialog.show(
                      capturedContext,
                      currentOverride: null,
                      originalName: 'Original',
                    );
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '  New Name  ');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(captured, 'New Name');
    });

    testWidgets('Reset returns an empty string', (WidgetTester tester) async {
      String? captured;
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                capturedContext = context;
                return ElevatedButton(
                  onPressed: () async {
                    captured = await RenameItemDialog.show(
                      capturedContext,
                      currentOverride: 'Renamed',
                      originalName: 'Original',
                    );
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset to original'));
      await tester.pumpAndSettle();

      expect(captured, '');
    });

    testWidgets('Cancel returns null', (WidgetTester tester) async {
      String? captured = 'sentinel';
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                capturedContext = context;
                return ElevatedButton(
                  onPressed: () async {
                    captured = await RenameItemDialog.show(
                      capturedContext,
                      currentOverride: null,
                      originalName: 'Original',
                    );
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(captured, isNull);
    });
  });
}
