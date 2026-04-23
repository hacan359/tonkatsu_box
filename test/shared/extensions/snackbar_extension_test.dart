// Тесты для unified SnackBar extension.
// Фокус: текст сообщения доходит до UI, type выбирает соответствующую
// иконку, loading заменяет иконку на CircularProgressIndicator, action /
// duration / hideSnack работают. Не проверяем конкретные цвета / размеры
// иконок / шрифта / border — design decisions.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/shared/extensions/snackbar_extension.dart';

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
    test('содержит success, error, info', () {
      expect(SnackType.values.length, 3);
      expect(SnackType.values, contains(SnackType.success));
      expect(SnackType.values, contains(SnackType.error));
      expect(SnackType.values, contains(SnackType.info));
    });
  });

  group('showSnack', () {
    testWidgets('показывает SnackBar с текстом сообщения',
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
      // Rebuild with actual showSnack call
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

    testWidgets('loading заменяет иконку на CircularProgressIndicator',
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

    testWidgets('action callback вызывается при tap',
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

    testWidgets('custom duration пробрасывается в SnackBar',
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
    testWidgets('скрывает текущий SnackBar', (WidgetTester tester) async {
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

    testWidgets('не кидает исключение когда SnackBar не виден',
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
