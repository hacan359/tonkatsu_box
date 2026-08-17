import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/core/api/igdb_api.dart';
import 'package:tonkatsu_box/core/api/steamgriddb_api.dart';
import 'package:tonkatsu_box/core/api/tmdb_api.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/core/services/api_key_initializer.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockIgdbApi mockIgdbApi;
  late MockSteamGridDbApi mockSteamGridDbApi;
  late MockTmdbApi mockTmdbApi;
  late MockDatabaseService mockDbService;
  late MockGameDao mockGameDao;
  late SharedPreferences prefs;

  setUp(() async {
    mockIgdbApi = MockIgdbApi();
    mockSteamGridDbApi = MockSteamGridDbApi();
    mockTmdbApi = MockTmdbApi();
    mockDbService = MockDatabaseService();
    mockGameDao = MockGameDao();
    when(() => mockDbService.gameDao).thenReturn(mockGameDao);
    when(() => mockGameDao.getPlatformCount()).thenAnswer((_) async => 0);
    when(() => mockIgdbApi.getAccessToken(
          clientId: any(named: 'clientId'),
          clientSecret: any(named: 'clientSecret'),
        )).thenThrow(const IgdbApiException('Test: no real API'));
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer createContainer() {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
        apiKeysProvider.overrideWithValue(const ApiKeys()),
        igdbApiProvider.overrideWithValue(mockIgdbApi),
        steamGridDbApiProvider.overrideWithValue(mockSteamGridDbApi),
        tmdbApiProvider.overrideWithValue(mockTmdbApi),
        databaseServiceProvider.overrideWithValue(mockDbService),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('SettingsNotifier ScreenScraper dev credentials', () {
    test('a set pair survives a rebuild from the same prefs', () async {
      final ProviderContainer first = createContainer();
      await first
          .read(settingsNotifierProvider.notifier)
          .setScreenScraperDevCredentials(devId: 'dev', devPassword: 'secret');

      expect(prefs.getString(SettingsKeys.screenScraperDevId), 'dev');
      expect(
        prefs.getString(SettingsKeys.screenScraperDevPassword),
        'secret',
      );

      // A fresh container over the same prefs is what an app restart is.
      final SettingsState state =
          createContainer().read(settingsNotifierProvider);

      expect(state.screenScraperDevId, 'dev');
      expect(state.screenScraperDevPassword, 'secret');
    });

    test('an empty value removes the pref instead of storing a blank', () async {
      final ProviderContainer container = createContainer();
      final SettingsNotifier notifier =
          container.read(settingsNotifierProvider.notifier);

      await notifier.setScreenScraperDevCredentials(
        devId: 'dev',
        devPassword: 'secret',
      );
      await notifier.setScreenScraperDevCredentials(
        devId: '',
        devPassword: '',
      );

      expect(prefs.getString(SettingsKeys.screenScraperDevId), isNull);
      expect(prefs.getString(SettingsKeys.screenScraperDevPassword), isNull);
    });

    test('should drop the pair from prefs when settings are cleared', () async {
      final ProviderContainer container = createContainer();
      final SettingsNotifier notifier =
          container.read(settingsNotifierProvider.notifier);
      await notifier.setScreenScraperDevCredentials(
        devId: 'dev',
        devPassword: 'secret',
      );

      await notifier.clearSettings();

      expect(prefs.getString(SettingsKeys.screenScraperDevId), isNull);
      expect(prefs.getString(SettingsKeys.screenScraperDevPassword), isNull);
      expect(
        container.read(settingsNotifierProvider).screenScraperDevId,
        isNull,
      );
    });
  });
}
