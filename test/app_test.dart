import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/app.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/core/services/update_service.dart';
import 'package:tonkatsu_box/data/repositories/collection_repository.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';
import 'package:tonkatsu_box/shared/models/collection.dart';
import 'package:tonkatsu_box/features/splash/screens/splash_screen.dart';
import 'package:tonkatsu_box/features/welcome/screens/welcome_screen.dart';
import 'package:tonkatsu_box/shared/navigation/app_bottom_bar.dart';
import 'package:tonkatsu_box/shared/navigation/app_shell.dart';
import 'package:tonkatsu_box/shared/navigation/app_sidebar.dart';

import 'helpers/test_helpers.dart';

void main() {
  group('TonkatsuBoxApp', () {
    late MockCollectionRepository mockRepo;
    late MockDatabaseService mockDb;

    setUp(() {
      mockRepo = MockCollectionRepository();
      when(() => mockRepo.getAll()).thenAnswer((_) async => <Collection>[]);
      when(() => mockRepo.getStats(any())).thenAnswer(
        (_) async => CollectionStats.empty,
      );

      mockDb = MockDatabaseService();
      when(() => mockDb.database).thenAnswer((_) async => MockDatabase());
      when(() => mockDb.getPlatformCount()).thenAnswer((_) async => 0);
    });

    testWidgets('должен рендерить MaterialApp', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
            collectionRepositoryProvider.overrideWithValue(mockRepo),
            databaseServiceProvider.overrideWithValue(mockDb),
            updateCheckProvider.overrideWith((Ref ref) async => null),
          ],
          child: const TonkatsuBoxApp(),
        ),
      );

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should show SplashScreen при запуске',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
            collectionRepositoryProvider.overrideWithValue(mockRepo),
            databaseServiceProvider.overrideWithValue(mockDb),
            updateCheckProvider.overrideWith((Ref ref) async => null),
          ],
          child: const TonkatsuBoxApp(),
        ),
      );

      expect(find.byType(SplashScreen), findsOneWidget);
    });

    testWidgets('should show AppShell после splash анимации',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        kWelcomeCompletedKey: true,
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
            collectionRepositoryProvider.overrideWithValue(mockRepo),
            databaseServiceProvider.overrideWithValue(mockDb),
            updateCheckProvider.overrideWith((Ref ref) async => null),
          ],
          child: const TonkatsuBoxApp(),
        ),
      );

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.byType(AppShell), findsOneWidget);
    });

    testWidgets('should show WelcomeScreen при первом запуске',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
            collectionRepositoryProvider.overrideWithValue(mockRepo),
            databaseServiceProvider.overrideWithValue(mockDb),
            updateCheckProvider.overrideWith((Ref ref) async => null),
          ],
          child: const TonkatsuBoxApp(),
        ),
      );

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
    });

    testWidgets('should use Material 3', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
            collectionRepositoryProvider.overrideWithValue(mockRepo),
            databaseServiceProvider.overrideWithValue(mockDb),
            updateCheckProvider.overrideWith((Ref ref) async => null),
          ],
          child: const TonkatsuBoxApp(),
        ),
      );

      final MaterialApp app =
          tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(app.theme?.useMaterial3, isTrue);
    });

    testWidgets(
        'AppShell на узком экране (<600px) рендерит AppBottomBar, а не AppSidebar',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues(<String, Object>{
        kWelcomeCompletedKey: true,
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
            collectionRepositoryProvider.overrideWithValue(mockRepo),
            databaseServiceProvider.overrideWithValue(mockDb),
            updateCheckProvider.overrideWith((Ref ref) async => null),
          ],
          child: const TonkatsuBoxApp(),
        ),
      );

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(AppBottomBar), findsOneWidget);
      expect(find.byType(AppSidebar), findsNothing);
    });

    testWidgets(
        'AppShell на широком экране (>=600px) рендерит AppSidebar, а не AppBottomBar',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues(<String, Object>{
        kWelcomeCompletedKey: true,
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
            collectionRepositoryProvider.overrideWithValue(mockRepo),
            databaseServiceProvider.overrideWithValue(mockDb),
            updateCheckProvider.overrideWith((Ref ref) async => null),
          ],
          child: const TonkatsuBoxApp(),
        ),
      );

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.byType(AppShell), findsOneWidget);
      expect(find.byType(AppSidebar), findsOneWidget);
      expect(find.byType(AppBottomBar), findsNothing);
    });

    testWidgets('should hide debug banner', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
            collectionRepositoryProvider.overrideWithValue(mockRepo),
            databaseServiceProvider.overrideWithValue(mockDb),
            updateCheckProvider.overrideWith((Ref ref) async => null),
          ],
          child: const TonkatsuBoxApp(),
        ),
      );

      final MaterialApp app =
          tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(app.debugShowCheckedModeBanner, isFalse);
    });
  });
}
