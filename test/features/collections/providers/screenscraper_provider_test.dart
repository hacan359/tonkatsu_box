import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/core/api/igdb_api.dart';
import 'package:tonkatsu_box/core/api/screenscraper_api.dart';
import 'package:tonkatsu_box/core/api/steamgriddb_api.dart';
import 'package:tonkatsu_box/core/api/tmdb_api.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/core/services/api_key_initializer.dart';
import 'package:tonkatsu_box/core/services/screenscraper_cache_service.dart';
import 'package:tonkatsu_box/features/collections/providers/screenscraper_provider.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';

import '../../../helpers/test_helpers.dart';

class MockScreenScraperApi extends Mock implements ScreenScraperApi {}

class MockScreenScraperCacheService extends Mock
    implements ScreenScraperCacheService {}

/// SNES — the mapping has a `systemeid` for it, so the section is offered.
const int snesIgdbPlatform = 19;

/// Modern console, deliberately absent from the mapping.
const int ps5IgdbPlatform = 167;

const SsGame _game = SsGame(
  id: 2143,
  name: 'Chrono Trigger',
  medias: <SsMedia>[],
);

void main() {
  late MockIgdbApi mockIgdbApi;
  late MockSteamGridDbApi mockSteamGridDbApi;
  late MockTmdbApi mockTmdbApi;
  late MockDatabaseService mockDbService;
  late MockGameDao mockGameDao;
  late MockScreenScraperApi mockSsApi;
  late MockScreenScraperCacheService mockCache;
  late SharedPreferences prefs;

  Future<void> withPrefs(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    prefs = await SharedPreferences.getInstance();
  }

  setUp(() async {
    mockIgdbApi = MockIgdbApi();
    mockSteamGridDbApi = MockSteamGridDbApi();
    mockTmdbApi = MockTmdbApi();
    mockDbService = MockDatabaseService();
    mockGameDao = MockGameDao();
    mockSsApi = MockScreenScraperApi();
    mockCache = MockScreenScraperCacheService();

    when(() => mockDbService.gameDao).thenReturn(mockGameDao);
    when(() => mockGameDao.getPlatformCount()).thenAnswer((_) async => 0);
    when(() => mockIgdbApi.getAccessToken(
          clientId: any(named: 'clientId'),
          clientSecret: any(named: 'clientSecret'),
        )).thenThrow(const IgdbApiException('Test: no real API'));

    when(() => mockCache.read(any())).thenAnswer((_) async => null);
    when(() => mockCache.isNegativelyCached(any()))
        .thenAnswer((_) async => false);
    when(() => mockCache.writeGame(any(), any())).thenAnswer((_) async {});
    when(() => mockCache.writeNotFound(any())).thenAnswer((_) async {});
    when(() => mockSsApi.searchGame(
          name: any(named: 'name'),
          systemeId: any(named: 'systemeId'),
        )).thenAnswer((_) async => _game);

    await withPrefs(const <String, Object>{});
  });

  setUpAll(() {
    registerFallbackValue(_game);
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
        screenScraperApiProvider.overrideWithValue(mockSsApi),
        screenScraperCacheServiceProvider.overrideWithValue(mockCache),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<SsGame?> lookup(
    ProviderContainer container, {
    int platformId = snesIgdbPlatform,
  }) {
    return container.read(
      screenScraperGameProvider((
        gameName: 'Chrono Trigger',
        igdbPlatformId: platformId,
      )).future,
    );
  }

  group('screenScraperGameProvider', () {
    test('should not reach ScreenScraper without the dev pair', () async {
      // The regression this guards: the web build assumed a dev pair it never
      // had and every lookup came back as a proxy 503.
      await withPrefs(const <String, Object>{
        SettingsKeys.screenScraperSsid: 'user',
        SettingsKeys.screenScraperSspassword: 'pass',
      });

      expect(await lookup(createContainer()), isNull);
      verifyNever(() => mockSsApi.searchGame(
            name: any(named: 'name'),
            systemeId: any(named: 'systemeId'),
          ));
    });

    test('should not reach ScreenScraper without the user pair', () async {
      await withPrefs(const <String, Object>{
        SettingsKeys.screenScraperDevId: 'dev',
        SettingsKeys.screenScraperDevPassword: 'secret',
      });

      expect(await lookup(createContainer()), isNull);
      verifyNever(() => mockSsApi.searchGame(
            name: any(named: 'name'),
            systemeId: any(named: 'systemeId'),
          ));
    });

    test('should look the game up with both pairs configured', () async {
      await withPrefs(const <String, Object>{
        SettingsKeys.screenScraperSsid: 'user',
        SettingsKeys.screenScraperSspassword: 'pass',
        SettingsKeys.screenScraperDevId: 'dev',
        SettingsKeys.screenScraperDevPassword: 'secret',
      });

      final SsGame? found = await lookup(createContainer());

      expect(found?.id, _game.id);
      // systemeid 4 is SNES on the ScreenScraper side.
      verify(() => mockSsApi.searchGame(name: 'Chrono Trigger', systemeId: 4))
          .called(1);
      verify(() => mockCache.writeGame(any(), any())).called(1);
    });

    test('should skip a platform ScreenScraper does not cover', () async {
      await withPrefs(const <String, Object>{
        SettingsKeys.screenScraperSsid: 'user',
        SettingsKeys.screenScraperSspassword: 'pass',
        SettingsKeys.screenScraperDevId: 'dev',
        SettingsKeys.screenScraperDevPassword: 'secret',
      });

      expect(
        await lookup(createContainer(), platformId: ps5IgdbPlatform),
        isNull,
      );
      verifyNever(() => mockSsApi.searchGame(
            name: any(named: 'name'),
            systemeId: any(named: 'systemeId'),
          ));
    });

    test('should mark a miss so the next render does not refetch', () async {
      await withPrefs(const <String, Object>{
        SettingsKeys.screenScraperSsid: 'user',
        SettingsKeys.screenScraperSspassword: 'pass',
        SettingsKeys.screenScraperDevId: 'dev',
        SettingsKeys.screenScraperDevPassword: 'secret',
      });
      when(() => mockSsApi.searchGame(
            name: any(named: 'name'),
            systemeId: any(named: 'systemeId'),
          )).thenAnswer((_) async => null);

      expect(await lookup(createContainer()), isNull);
      verify(() => mockCache.writeNotFound(any())).called(1);
    });

    test('should serve a cached game without calling the API', () async {
      await withPrefs(const <String, Object>{
        SettingsKeys.screenScraperSsid: 'user',
        SettingsKeys.screenScraperSspassword: 'pass',
        SettingsKeys.screenScraperDevId: 'dev',
        SettingsKeys.screenScraperDevPassword: 'secret',
      });
      when(() => mockCache.read(any())).thenAnswer((_) async => _game);

      expect((await lookup(createContainer()))?.id, _game.id);
      verifyNever(() => mockSsApi.searchGame(
            name: any(named: 'name'),
            systemeId: any(named: 'systemeId'),
          ));
    });
  });
}
