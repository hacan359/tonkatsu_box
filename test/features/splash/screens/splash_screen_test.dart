// Navigation to AppShell is not tested — AppShell requires many providers
// (database, settings, gamepad, etc.) outside this test's scope.

import 'package:xerabora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/features/splash/screens/splash_screen.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockDatabaseService mockDb;

  setUp(() {
    mockDb = MockDatabaseService();

    when(() => mockDb.database).thenAnswer((_) async => MockDatabase());
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: <Override>[
        databaseServiceProvider.overrideWithValue(mockDb),
      ],
      child: const MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
        home: SplashScreen(),
      ),
    );
  }

  group('SplashScreen', () {
    testWidgets('рендерит логотип', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('содержит ScaleTransition с Image внутри',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(
        find.descendant(
          of: find.byType(ScaleTransition),
          matching: find.byType(Image),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Scaffold имеет прозрачный фон (тайловый фон в builder)',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      final Scaffold scaffold =
          tester.widget<Scaffold>(find.byType(Scaffold).first);
      // Background is set via MaterialApp.builder, so Scaffold is transparent.
      expect(scaffold.backgroundColor, isNull);
    });
  });

  group('SplashScreen pre-warming', () {
    testWidgets('вызывает database getter в initState',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      verify(() => mockDb.database).called(1);
    });

    testWidgets('повторный pump не дублирует вызовы DB',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump();

      verify(() => mockDb.database).called(1);
    });

    testWidgets('не навигирует до завершения анимации',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.pump();
      expect(find.byType(SplashScreen), findsOneWidget);
    });
  });
}
