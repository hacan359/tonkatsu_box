import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/app.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/core/services/update_service.dart';
import 'package:tonkatsu_box/data/repositories/collection_repository.dart';
import 'package:tonkatsu_box/features/genre_cloud/providers/genre_cloud_provider.dart';
import 'package:tonkatsu_box/features/genre_cloud/screens/genre_cloud_screen.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';
import 'package:tonkatsu_box/features/welcome/screens/welcome_screen.dart';
import 'package:tonkatsu_box/shared/models/collection.dart';
import 'package:tonkatsu_box/shared/models/collection_item.dart';
import 'package:tonkatsu_box/shared/navigation/nav_center_button.dart';
import 'package:tonkatsu_box/shared/navigation/nav_icon_button.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('AppShell personalization destination', () {
    late MockCollectionRepository mockRepo;
    late MockDatabaseService mockDb;
    late MockGameDao mockGameDao;

    setUp(() {
      mockRepo = MockCollectionRepository();
      when(() => mockRepo.getAll()).thenAnswer((_) async => <Collection>[]);
      when(() => mockRepo.getStats(any())).thenAnswer(
        (_) async => CollectionStats.empty,
      );

      mockDb = MockDatabaseService();
      mockGameDao = MockGameDao();
      when(() => mockDb.gameDao).thenReturn(mockGameDao);
      when(() => mockDb.database).thenAnswer((_) async => MockDatabase());
      when(() => mockGameDao.getPlatformCount()).thenAnswer((_) async => 0);
    });

    Future<void> pumpShell(WidgetTester tester) async {
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
            genreCloudItemsProvider.overrideWith(
              (Ref ref) => const AsyncValue<List<CollectionItem>>.data(
                <CollectionItem>[],
              ),
            ),
          ],
          child: const TonkatsuBoxApp(),
        ),
      );

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    }

    testWidgets('should not stay shown after switching tabs and returning', (
      WidgetTester tester,
    ) async {
      await pumpShell(tester);
      expect(find.byType(GenreCloudScreen), findsNothing);

      // Open Personalization via the centre nav button.
      await tester.tap(find.byType(NavCenterButton));
      await tester.pumpAndSettle();
      expect(find.byType(GenreCloudScreen), findsOneWidget);

      // Switch to another tab — the cloud must be hidden.
      await tester.tap(find.byType(NavIconButton).at(1));
      await tester.pumpAndSettle();
      expect(find.byType(GenreCloudScreen), findsNothing);

      // Return to the first tab — the cloud must NOT reappear (the regression:
      // it used to stay glued to that tab's navigator while Home was highlighted).
      await tester.tap(find.byType(NavIconButton).at(0));
      await tester.pumpAndSettle();
      expect(find.byType(GenreCloudScreen), findsNothing);
    });

    testWidgets('should reopen the cloud from the centre button', (
      WidgetTester tester,
    ) async {
      await pumpShell(tester);

      await tester.tap(find.byType(NavCenterButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(NavIconButton).at(0));
      await tester.pumpAndSettle();
      expect(find.byType(GenreCloudScreen), findsNothing);

      await tester.tap(find.byType(NavCenterButton));
      await tester.pumpAndSettle();
      expect(find.byType(GenreCloudScreen), findsOneWidget);
    });
  });
}
