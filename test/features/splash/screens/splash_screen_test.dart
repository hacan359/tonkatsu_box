import 'package:xerabora/l10n/app_localizations.dart';
// Тесты для SplashScreen.
//
// SplashScreen — ConsumerStatefulWidget с анимированным логотипом.
// При запуске pre-warm'ит базу данных в фоне. Навигация на NavigationShell
// происходит только когда И анимация завершена, И DB открыта —
// это предотвращает конкуренцию DB-init и route transition на main thread.
//
// Навигация на NavigationShell не тестируется — NavigationShell требует
// множество провайдеров (database, settings, gamepad и др.), что выходит
// за scope этого теста.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/features/splash/screens/splash_screen.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

class MockDatabase extends Mock implements Database {}

void main() {
  late MockDatabaseService mockDb;

  setUp(() {
    mockDb = MockDatabaseService();

    // Pre-warm вызывает .database getter — возвращаем готовый Future.
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

      // ScaleTransition оборачивает Image — это наша анимация
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
      // Scaffold прозрачный — фон задаётся через MaterialApp.builder
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

      // database getter вызывается ровно 1 раз
      verify(() => mockDb.database).called(1);
    });

    testWidgets('не навигирует до завершения анимации',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      // DB уже "готова" (mock возвращает сразу), но анимация не завершена
      // Проверяем что SplashScreen всё ещё отображается
      await tester.pump();
      expect(find.byType(SplashScreen), findsOneWidget);
    });
  });
}
