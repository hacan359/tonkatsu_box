import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/extensions/snackbar_extension.dart';

void main() {
  Widget wrapWithButton(String label, VoidCallback onPressed) => MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => ElevatedButton(
              onPressed: onPressed,
              child: Text(label),
            ),
          ),
        ),
      );

  group('SnackType', () {
    test('should expose success, error and info values', () {
      expect(SnackType.values.length, 3);
      expect(SnackType.values, contains(SnackType.success));
      expect(SnackType.values, contains(SnackType.error));
      expect(SnackType.values, contains(SnackType.info));
    });
  });

  group('showSnack', () {
    testWidgets('should show a SnackBar with the message text',
        (WidgetTester tester) async {
      late BuildContext savedContext;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(builder: (BuildContext context) {
              savedContext = context;
              return const SizedBox();
            }),
          ),
        ),
      );

      savedContext.showSnack('Test message');
      await tester.pumpAndSettle();

      expect(find.text('Test message'), findsOneWidget);
    });

    testWidgets('success → check_circle_outline icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithButton(
        'Show',
        () {},
      ));
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Builder(builder: (BuildContext context) {
            ctx = context;
            return const SizedBox();
          }),
        ),
      ));
      ctx.showSnack('Success', type: SnackType.success);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('error → error_outline icon', (WidgetTester tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Builder(builder: (BuildContext context) {
            ctx = context;
            return const SizedBox();
          }),
        ),
      ));
      ctx.showSnack('Error', type: SnackType.error);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('info (default) → info_outline icon',
        (WidgetTester tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Builder(builder: (BuildContext context) {
            ctx = context;
            return const SizedBox();
          }),
        ),
      ));
      ctx.showSnack('Info');
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('should replace the icon with a spinner when loading',
        (WidgetTester tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Builder(builder: (BuildContext context) {
            ctx = context;
            return const SizedBox();
          }),
        ),
      ));
      ctx.showSnack(
        'Loading...',
        loading: true,
        duration: const Duration(seconds: 30),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsNothing);
      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('auto-hides previous SnackBar before showing new one',
        (WidgetTester tester) async {
      late BuildContext savedContext;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Builder(builder: (BuildContext context) {
            savedContext = context;
            return const SizedBox();
          }),
        ),
      ));

      savedContext.showSnack('First message');
      await tester.pumpAndSettle();
      expect(find.text('First message'), findsOneWidget);

      savedContext.showSnack('Second message');
      await tester.pumpAndSettle();
      expect(find.text('Second message'), findsOneWidget);
      expect(find.text('First message'), findsNothing);
    });

    testWidgets('should invoke the action callback when tapped',
        (WidgetTester tester) async {
      bool actionPressed = false;
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Builder(builder: (BuildContext context) {
            ctx = context;
            return const SizedBox();
          }),
        ),
      ));
      ctx.showSnack(
        'With action',
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => actionPressed = true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('UNDO'), findsOneWidget);
      await tester.tap(find.text('UNDO'));
      expect(actionPressed, isTrue);
    });

    testWidgets('should pass a custom duration to the SnackBar',
        (WidgetTester tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Builder(builder: (BuildContext context) {
            ctx = context;
            return const SizedBox();
          }),
        ),
      ));
      ctx.showSnack(
        'Quick',
        duration: const Duration(milliseconds: 500),
      );
      await tester.pump();

      final SnackBar snackBar =
          tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.duration, const Duration(milliseconds: 500));
    });
  });

  group('hideSnack', () {
    testWidgets('should hide the current SnackBar', (WidgetTester tester) async {
      late BuildContext savedContext;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Builder(builder: (BuildContext context) {
            savedContext = context;
            return const SizedBox();
          }),
        ),
      ));

      savedContext.showSnack(
        'Visible',
        duration: const Duration(seconds: 30),
      );
      await tester.pumpAndSettle();
      expect(find.text('Visible'), findsOneWidget);

      savedContext.hideSnack();
      await tester.pumpAndSettle();
      expect(find.text('Visible'), findsNothing);
    });

    testWidgets('should not throw when no SnackBar is visible',
        (WidgetTester tester) async {
      late BuildContext savedContext;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Builder(builder: (BuildContext context) {
            savedContext = context;
            return const SizedBox();
          }),
        ),
      ));

      expect(() => savedContext.hideSnack(), returnsNormally);
    });
  });
}
