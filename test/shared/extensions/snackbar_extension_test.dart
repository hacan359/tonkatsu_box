import 'package:xerabora/l10n/app_localizations.dart';
// Тесты для unified SnackBar extension.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xerabora/shared/extensions/snackbar_extension.dart';
import 'package:xerabora/shared/theme/app_colors.dart';

void main() {
  group('SnackType', () {
    test('has 3 values', () {
      expect(SnackType.values.length, 3);
    });

    test('contains success, error, info', () {
      expect(SnackType.values, contains(SnackType.success));
      expect(SnackType.values, contains(SnackType.error));
      expect(SnackType.values, contains(SnackType.info));
    });
  });

  group('showSnack', () {
    testWidgets('shows SnackBar with message text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () => context.showSnack('Test message'),
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Test message'), findsOneWidget);
    });

    testWidgets('success type shows check_circle_outline icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () => context.showSnack(
                    'Success',
                    type: SnackType.success,
                  ),
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      final Icon icon = tester.widget<Icon>(
        find.byIcon(Icons.check_circle_outline),
      );
      expect(icon.color, AppColors.success);
      expect(icon.size, 18);
    });

    testWidgets('error type shows error_outline icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () => context.showSnack(
                    'Error',
                    type: SnackType.error,
                  ),
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      final Icon icon = tester.widget<Icon>(
        find.byIcon(Icons.error_outline),
      );
      expect(icon.color, AppColors.error);
      expect(icon.size, 18);
    });

    testWidgets('info type shows info_outline icon (default)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () => context.showSnack('Info'),
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      final Icon icon = tester.widget<Icon>(
        find.byIcon(Icons.info_outline),
      );
      expect(icon.color, AppColors.brand);
      expect(icon.size, 18);
    });

    testWidgets('loading replaces icon with CircularProgressIndicator',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () => context.showSnack(
                    'Loading...',
                    loading: true,
                    duration: const Duration(seconds: 30),
                  ),
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      // Should show CircularProgressIndicator, not an icon
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsNothing);
      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('auto-hides previous SnackBar before showing new one',
        (WidgetTester tester) async {
      late BuildContext savedContext;

      await tester.pumpWidget(
        MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                savedContext = context;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Show first SnackBar
      savedContext.showSnack('First message');
      await tester.pumpAndSettle();
      expect(find.text('First message'), findsOneWidget);

      // Show second SnackBar — first should be auto-hidden
      savedContext.showSnack('Second message');
      await tester.pumpAndSettle();
      expect(find.text('Second message'), findsOneWidget);
      expect(find.text('First message'), findsNothing);
    });

    testWidgets('passes action to SnackBar', (WidgetTester tester) async {
      bool actionPressed = false;

      await tester.pumpWidget(
        MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () => context.showSnack(
                    'With action',
                    action: SnackBarAction(
                      label: 'UNDO',
                      onPressed: () => actionPressed = true,
                    ),
                  ),
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('UNDO'), findsOneWidget);
      await tester.tap(find.text('UNDO'));
      expect(actionPressed, isTrue);
    });

    testWidgets('uses custom duration', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () => context.showSnack(
                    'Quick',
                    duration: const Duration(milliseconds: 500),
                  ),
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();
      expect(find.text('Quick'), findsOneWidget);

      // Verify the SnackBar was created with the correct duration
      final SnackBar snackBar = tester.widget<SnackBar>(
        find.byType(SnackBar),
      );
      expect(snackBar.duration, const Duration(milliseconds: 500));
    });

    testWidgets('message text has correct style', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () => context.showSnack('Styled text'),
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      final Text messageText = tester.widget<Text>(find.text('Styled text'));
      expect(messageText.style?.color, AppColors.textPrimary);
      expect(messageText.style?.fontSize, 13);
      expect(messageText.maxLines, 2);
      expect(messageText.overflow, TextOverflow.ellipsis);
    });

    testWidgets('SnackBar has surfaceLight background',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () => context.showSnack('BG test'),
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      final SnackBar snackBar = tester.widget<SnackBar>(
        find.byType(SnackBar),
      );
      expect(snackBar.backgroundColor, AppColors.surfaceLight);
      expect(snackBar.elevation, 4);
      expect(snackBar.behavior, SnackBarBehavior.floating);
      expect(snackBar.dismissDirection, DismissDirection.horizontal);
    });

    testWidgets('success border color is green with alpha',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () => context.showSnack(
                    'Success border',
                    type: SnackType.success,
                  ),
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      final SnackBar snackBar = tester.widget<SnackBar>(
        find.byType(SnackBar),
      );
      final RoundedRectangleBorder shape =
          snackBar.shape! as RoundedRectangleBorder;
      final BorderSide side = shape.side;
      expect(side.color, AppColors.success.withAlpha(128));
    });

    testWidgets('error border color is red with alpha',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () => context.showSnack(
                    'Error border',
                    type: SnackType.error,
                  ),
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      final SnackBar snackBar = tester.widget<SnackBar>(
        find.byType(SnackBar),
      );
      final RoundedRectangleBorder shape =
          snackBar.shape! as RoundedRectangleBorder;
      final BorderSide side = shape.side;
      expect(side.color, AppColors.error.withAlpha(128));
    });

    testWidgets('info border color is surfaceBorder',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () => context.showSnack('Info border'),
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      final SnackBar snackBar = tester.widget<SnackBar>(
        find.byType(SnackBar),
      );
      final RoundedRectangleBorder shape =
          snackBar.shape! as RoundedRectangleBorder;
      final BorderSide side = shape.side;
      expect(side.color, AppColors.surfaceBorder);
    });
  });

  group('hideSnack', () {
    testWidgets('hides currently visible SnackBar',
        (WidgetTester tester) async {
      late BuildContext savedContext;

      await tester.pumpWidget(
        MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                savedContext = context;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Show a SnackBar
      savedContext.showSnack(
        'Visible',
        duration: const Duration(seconds: 30),
      );
      await tester.pumpAndSettle();
      expect(find.text('Visible'), findsOneWidget);

      // Hide it
      savedContext.hideSnack();
      await tester.pumpAndSettle();
      expect(find.text('Visible'), findsNothing);
    });

    testWidgets('does not throw when no SnackBar is visible',
        (WidgetTester tester) async {
      late BuildContext savedContext;

      await tester.pumpWidget(
        MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                savedContext = context;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Should not throw
      expect(() => savedContext.hideSnack(), returnsNormally);
    });
  });
}
