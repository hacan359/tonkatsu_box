// Тесты для SettingsNotifier — управление настройками IGDB, SteamGridDB, TMDB.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/core/api/igdb_api.dart';
import 'package:xerabora/core/api/steamgriddb_api.dart';
import 'package:xerabora/core/api/tmdb_api.dart';
import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';

// Моки
class MockIgdbApi extends Mock implements IgdbApi {}

class MockSteamGridDbApi extends Mock implements SteamGridDbApi {}

class MockTmdbApi extends Mock implements TmdbApi {}

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late MockIgdbApi mockIgdbApi;
  late MockSteamGridDbApi mockSteamGridDbApi;
  late MockTmdbApi mockTmdbApi;
  late MockDatabaseService mockDbService;
  late SharedPreferences prefs;

  setUp(() async {
    mockIgdbApi = MockIgdbApi();
    mockSteamGridDbApi = MockSteamGridDbApi();
    mockTmdbApi = MockTmdbApi();
    mockDbService = MockDatabaseService();

    // По умолчанию getPlatformCount возвращает 0
    when(() => mockDbService.getPlatformCount()).thenAnswer((_) async => 0);
  });

  Future<ProviderContainer> createContainer({
    Map<String, Object> initialPrefs = const <String, Object>{},
  }) async {
    SharedPreferences.setMockInitialValues(initialPrefs);
    prefs = await SharedPreferences.getInstance();

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
        igdbApiProvider.overrideWithValue(mockIgdbApi),
        steamGridDbApiProvider.overrideWithValue(mockSteamGridDbApi),
        tmdbApiProvider.overrideWithValue(mockTmdbApi),
        databaseServiceProvider.overrideWithValue(mockDbService),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('SettingsKeys', () {
    test('collectionViewModePrefix должен быть корректным', () {
      expect(
        SettingsKeys.collectionViewModePrefix,
        equals('collection_view_mode_'),
      );
    });

    test('collectionViewModePrefix должен формировать ключ по collectionId',
        () {
      const int collectionId = 42;
      const String key =
          '${SettingsKeys.collectionViewModePrefix}$collectionId';
      expect(key, equals('collection_view_mode_42'));
    });
  });

  group('SettingsNotifier', () {
    group('build / _loadFromPrefs', () {
      test('должен загрузить TMDB ключ из prefs и установить в TmdbApi',
          () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            'tmdb_api_key': 'saved_tmdb_key',
          },
        );

        final SettingsState state =
            container.read(settingsNotifierProvider);

        expect(state.tmdbApiKey, equals('saved_tmdb_key'));
        verify(() => mockTmdbApi.setApiKey('saved_tmdb_key')).called(1);
      });

      test('не должен вызывать setApiKey на TmdbApi когда ключ отсутствует',
          () async {
        final ProviderContainer container = await createContainer();

        final SettingsState state =
            container.read(settingsNotifierProvider);

        expect(state.tmdbApiKey, isNull);
        verifyNever(() => mockTmdbApi.setApiKey(any()));
      });

      test('не должен вызывать setApiKey на TmdbApi когда ключ пустой',
          () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            'tmdb_api_key': '',
          },
        );

        final SettingsState state =
            container.read(settingsNotifierProvider);

        expect(state.tmdbApiKey, equals(''));
        verifyNever(() => mockTmdbApi.setApiKey(any()));
      });

      test('должен загрузить SteamGridDB ключ и установить в SteamGridDbApi',
          () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            'steamgriddb_api_key': 'saved_sgdb_key',
          },
        );

        final SettingsState state =
            container.read(settingsNotifierProvider);

        expect(state.steamGridDbApiKey, equals('saved_sgdb_key'));
        verify(() => mockSteamGridDbApi.setApiKey('saved_sgdb_key')).called(1);
      });

      test('должен загрузить все ключи из prefs одновременно', () async {
        final int futureExpiry =
            DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;

        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            'igdb_client_id': 'cid',
            'igdb_client_secret': 'csecret',
            'igdb_access_token': 'token123',
            'igdb_token_expires': futureExpiry,
            'igdb_last_sync': 1700000000,
            'steamgriddb_api_key': 'sgdb_key',
            'tmdb_api_key': 'tmdb_key',
          },
        );

        final SettingsState state =
            container.read(settingsNotifierProvider);

        expect(state.clientId, equals('cid'));
        expect(state.clientSecret, equals('csecret'));
        expect(state.accessToken, equals('token123'));
        expect(state.tokenExpires, equals(futureExpiry));
        expect(state.lastSync, equals(1700000000));
        expect(state.steamGridDbApiKey, equals('sgdb_key'));
        expect(state.tmdbApiKey, equals('tmdb_key'));

        verify(() => mockIgdbApi.setCredentials(
              clientId: 'cid',
              accessToken: 'token123',
            )).called(1);
        verify(() => mockSteamGridDbApi.setApiKey('sgdb_key')).called(1);
        verify(() => mockTmdbApi.setApiKey('tmdb_key')).called(1);
      });
    });

    group('setTmdbApiKey', () {
      test('должен сохранить ключ в prefs и обновить состояние', () async {
        final ProviderContainer container = await createContainer();

        final SettingsNotifier notifier =
            container.read(settingsNotifierProvider.notifier);

        await notifier.setTmdbApiKey('new_tmdb_key');

        final SettingsState state =
            container.read(settingsNotifierProvider);

        expect(state.tmdbApiKey, equals('new_tmdb_key'));
        expect(prefs.getString('tmdb_api_key'), equals('new_tmdb_key'));
        verify(() => mockTmdbApi.setApiKey('new_tmdb_key')).called(1);
      });

      test('должен удалить ключ из prefs при пустой строке', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            'tmdb_api_key': 'existing_key',
          },
        );

        final SettingsNotifier notifier =
            container.read(settingsNotifierProvider.notifier);

        await notifier.setTmdbApiKey('');

        final SettingsState state =
            container.read(settingsNotifierProvider);

        expect(state.tmdbApiKey, equals(''));
        expect(prefs.getString('tmdb_api_key'), isNull);
        verify(() => mockTmdbApi.clearApiKey()).called(1);
      });

      test('должен вызывать setApiKey а не clearApiKey при непустом ключе',
          () async {
        final ProviderContainer container = await createContainer();

        final SettingsNotifier notifier =
            container.read(settingsNotifierProvider.notifier);

        await notifier.setTmdbApiKey('abc123');

        verify(() => mockTmdbApi.setApiKey('abc123')).called(1);
        verifyNever(() => mockTmdbApi.clearApiKey());
      });
    });

    group('setSteamGridDbApiKey', () {
      test('должен сохранить ключ в prefs и обновить состояние', () async {
        final ProviderContainer container = await createContainer();

        final SettingsNotifier notifier =
            container.read(settingsNotifierProvider.notifier);

        await notifier.setSteamGridDbApiKey('new_sgdb_key');

        final SettingsState state =
            container.read(settingsNotifierProvider);

        expect(state.steamGridDbApiKey, equals('new_sgdb_key'));
        expect(
          prefs.getString('steamgriddb_api_key'),
          equals('new_sgdb_key'),
        );
        verify(() => mockSteamGridDbApi.setApiKey('new_sgdb_key')).called(1);
      });

      test('должен удалить ключ из prefs при пустой строке', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            'steamgriddb_api_key': 'existing_key',
          },
        );

        final SettingsNotifier notifier =
            container.read(settingsNotifierProvider.notifier);

        await notifier.setSteamGridDbApiKey('');

        final SettingsState state =
            container.read(settingsNotifierProvider);

        expect(state.steamGridDbApiKey, equals(''));
        expect(prefs.getString('steamgriddb_api_key'), isNull);
        verify(() => mockSteamGridDbApi.clearApiKey()).called(1);
      });
    });

    group('clearSettings', () {
      test('должен очистить все настройки включая TMDB ключ', () async {
        when(() => mockDbService.clearPlatforms()).thenAnswer((_) async {});

        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            'igdb_client_id': 'cid',
            'igdb_client_secret': 'csecret',
            'igdb_access_token': 'token',
            'igdb_token_expires': 9999999999,
            'igdb_last_sync': 1700000000,
            'steamgriddb_api_key': 'sgdb_key',
            'tmdb_api_key': 'tmdb_key',
          },
        );

        final SettingsNotifier notifier =
            container.read(settingsNotifierProvider.notifier);

        // Проверяем, что данные загружены
        SettingsState state = container.read(settingsNotifierProvider);
        expect(state.tmdbApiKey, equals('tmdb_key'));
        expect(state.steamGridDbApiKey, equals('sgdb_key'));
        expect(state.clientId, equals('cid'));

        await notifier.clearSettings();

        state = container.read(settingsNotifierProvider);

        expect(state.clientId, isNull);
        expect(state.clientSecret, isNull);
        expect(state.accessToken, isNull);
        expect(state.tokenExpires, isNull);
        expect(state.lastSync, isNull);
        expect(state.steamGridDbApiKey, isNull);
        expect(state.tmdbApiKey, isNull);
        expect(state.platformCount, equals(0));
        expect(state.connectionStatus, equals(ConnectionStatus.unknown));

        // Проверяем, что prefs очищены
        expect(prefs.getString('igdb_client_id'), isNull);
        expect(prefs.getString('igdb_client_secret'), isNull);
        expect(prefs.getString('igdb_access_token'), isNull);
        expect(prefs.getInt('igdb_token_expires'), isNull);
        expect(prefs.getInt('igdb_last_sync'), isNull);
        expect(prefs.getString('steamgriddb_api_key'), isNull);
        expect(prefs.getString('tmdb_api_key'), isNull);

        // Проверяем, что API клиенты очищены
        verify(() => mockIgdbApi.clearCredentials()).called(1);
        verify(() => mockSteamGridDbApi.clearApiKey()).called(1);
        verify(() => mockTmdbApi.clearApiKey()).called(1);
        verify(() => mockDbService.clearPlatforms()).called(1);
      });

      test('должен сбросить состояние к дефолтному', () async {
        when(() => mockDbService.clearPlatforms()).thenAnswer((_) async {});

        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            'tmdb_api_key': 'tmdb_key',
            'steamgriddb_api_key': 'sgdb_key',
          },
        );

        final SettingsNotifier notifier =
            container.read(settingsNotifierProvider.notifier);

        await notifier.clearSettings();

        final SettingsState state =
            container.read(settingsNotifierProvider);

        // Должен быть эквивалентен SettingsState() по умолчанию
        expect(state.isLoading, isFalse);
        expect(state.errorMessage, isNull);
        expect(state.hasTmdbKey, isFalse);
        expect(state.hasSteamGridDbKey, isFalse);
        expect(state.hasCredentials, isFalse);
      });
    });

    group('setCredentials', () {
      test('должен сохранить credentials в prefs и обновить состояние',
          () async {
        final ProviderContainer container = await createContainer();

        final SettingsNotifier notifier =
            container.read(settingsNotifierProvider.notifier);

        await notifier.setCredentials(
          clientId: 'new_cid',
          clientSecret: 'new_csecret',
        );

        final SettingsState state =
            container.read(settingsNotifierProvider);

        expect(state.clientId, equals('new_cid'));
        expect(state.clientSecret, equals('new_csecret'));
        expect(prefs.getString('igdb_client_id'), equals('new_cid'));
        expect(prefs.getString('igdb_client_secret'), equals('new_csecret'));
        expect(state.errorMessage, isNull);
      });
    });
  });
}
