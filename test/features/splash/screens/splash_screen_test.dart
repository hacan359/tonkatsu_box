// Navigation to AppShell is not tested — AppShell requires many providers
// (database, settings, gamepad, etc.) outside this test's scope.

import 'package:core/rpc/protocol.dart';
import 'package:core/rpc/rpc_transport.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/core/logging/startup_error.dart';
import 'package:tonkatsu_box/features/splash/screens/server_token_screen.dart';
import 'package:tonkatsu_box/features/splash/screens/splash_screen.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockDatabaseService mockDb;

  setUp(() {
    mockDb = MockDatabaseService();

    when(mockDb.warmUp).thenAnswer((_) async {});
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

      verify(mockDb.warmUp).called(1);
    });

    testWidgets('повторный pump не дублирует вызовы DB',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump();

      verify(mockDb.warmUp).called(1);
    });

    testWidgets('should open the token screen when the server answers 401',
        (WidgetTester tester) async {
      when(mockDb.warmUp).thenAnswer(
        (_) => Future<void>.error(
          const RpcException(kRpcErrorKindAuth, 'Missing or wrong token'),
        ),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ServerTokenScreen), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
    });

    testWidgets('should keep the splash on a non-auth failure',
        (WidgetTester tester) async {
      when(mockDb.warmUp).thenAnswer(
        (_) => Future<void>.error(
          const RpcException('transport', 'server unreachable'),
        ),
      );
      addTearDown(() => startupError.value = null);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(startupError.value, isNotNull);
      expect(find.byType(ServerTokenScreen), findsNothing);
      expect(find.byType(SplashScreen), findsOneWidget);
    });

    testWidgets('не навигирует до завершения анимации',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.pump();
      expect(find.byType(SplashScreen), findsOneWidget);
    });
  });
}
