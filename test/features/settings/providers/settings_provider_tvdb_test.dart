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

  group('SettingsNotifier TheTVDB key persistence', () {
    test('a set key survives a rebuild from the same prefs', () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      prefs = await SharedPreferences.getInstance();

      final ProviderContainer first = createContainer();
      await first
          .read(settingsNotifierProvider.notifier)
          .setTvdbApiKey('my-tvdb-key');

      expect(prefs.getString(SettingsKeys.tvdbApiKey), 'my-tvdb-key');

      // A fresh container over the same prefs is what an app restart is.
      final ProviderContainer second = createContainer();
      final SettingsState state = second.read(settingsNotifierProvider);

      expect(state.tvdbApiKey, 'my-tvdb-key');
    });

    test('should drop the key from prefs and state when settings are cleared',
        () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      prefs = await SharedPreferences.getInstance();

      final ProviderContainer container = createContainer();
      await container
          .read(settingsNotifierProvider.notifier)
          .setTvdbApiKey('my-tvdb-key');

      await container.read(settingsNotifierProvider.notifier).clearSettings();

      expect(prefs.getString(SettingsKeys.tvdbApiKey), isNull);
      final SettingsState state = container.read(settingsNotifierProvider);
      expect(state.hasTvdbKey, isFalse);
    });
  });
}
