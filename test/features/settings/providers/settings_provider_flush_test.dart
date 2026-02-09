// Тесты для SettingsNotifier — flushDatabase, exportConfig, importConfig.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/core/api/igdb_api.dart';
import 'package:xerabora/core/api/steamgriddb_api.dart';
import 'package:xerabora/core/api/tmdb_api.dart';
import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/core/services/config_service.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';

// Моки
class MockIgdbApi extends Mock implements IgdbApi {}

class MockSteamGridDbApi extends Mock implements SteamGridDbApi {}

class MockTmdbApi extends Mock implements TmdbApi {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockConfigService extends Mock implements ConfigService {}

void main() {
  late MockIgdbApi mockIgdbApi;
  late MockSteamGridDbApi mockSteamGridDbApi;
  late MockTmdbApi mockTmdbApi;
  late MockDatabaseService mockDbService;
  late MockConfigService mockConfigService;
  late SharedPreferences prefs;

  setUp(() async {
    mockIgdbApi = MockIgdbApi();
    mockSteamGridDbApi = MockSteamGridDbApi();
    mockTmdbApi = MockTmdbApi();
    mockDbService = MockDatabaseService();
    mockConfigService = MockConfigService();

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
        configServiceProvider.overrideWithValue(mockConfigService),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('flushDatabase', () {
    test('должен вызвать clearAllData на DatabaseService', () async {
      when(() => mockDbService.clearAllData()).thenAnswer((_) async {});

      final ProviderContainer container = await createContainer();
      // Читаем состояние чтобы инициализировать notifier
      container.read(settingsNotifierProvider);

      final SettingsNotifier notifier =
          container.read(settingsNotifierProvider.notifier);
      await notifier.flushDatabase();

      verify(() => mockDbService.clearAllData()).called(1);
    });

    test('должен сбросить platformCount в 0', () async {
      when(() => mockDbService.getPlatformCount()).thenAnswer((_) async => 50);
      when(() => mockDbService.clearAllData()).thenAnswer((_) async {});

      final ProviderContainer container = await createContainer();
      container.read(settingsNotifierProvider);

      // Ждём загрузку platformCount
      await Future<void>.delayed(Duration.zero);

      final SettingsNotifier notifier =
          container.read(settingsNotifierProvider.notifier);
      await notifier.flushDatabase();

      final SettingsState state = container.read(settingsNotifierProvider);
      expect(state.platformCount, equals(0));
    });

    test('должен сохранить настройки после flush', () async {
      when(() => mockDbService.clearAllData()).thenAnswer((_) async {});

      final ProviderContainer container = await createContainer(
        initialPrefs: <String, Object>{
          'igdb_client_id': 'preserved_id',
          'tmdb_api_key': 'preserved_tmdb',
        },
      );
      container.read(settingsNotifierProvider);

      final SettingsNotifier notifier =
          container.read(settingsNotifierProvider.notifier);
      await notifier.flushDatabase();

      final SettingsState state = container.read(settingsNotifierProvider);
      expect(state.clientId, equals('preserved_id'));
      expect(state.tmdbApiKey, equals('preserved_tmdb'));
    });
  });

  group('exportConfig', () {
    test('должен делегировать ConfigService.exportToFile', () async {
      when(() => mockConfigService.exportToFile()).thenAnswer(
        (_) async => const ConfigResult.success('/path/to/config.json'),
      );

      final ProviderContainer container = await createContainer();
      container.read(settingsNotifierProvider);

      final SettingsNotifier notifier =
          container.read(settingsNotifierProvider.notifier);
      final ConfigResult result = await notifier.exportConfig();

      expect(result.success, isTrue);
      expect(result.filePath, equals('/path/to/config.json'));
      verify(() => mockConfigService.exportToFile()).called(1);
    });

    test('должен вернуть cancelled при отмене', () async {
      when(() => mockConfigService.exportToFile()).thenAnswer(
        (_) async => const ConfigResult.cancelled(),
      );

      final ProviderContainer container = await createContainer();
      container.read(settingsNotifierProvider);

      final SettingsNotifier notifier =
          container.read(settingsNotifierProvider.notifier);
      final ConfigResult result = await notifier.exportConfig();

      expect(result.isCancelled, isTrue);
    });

    test('должен вернуть failure при ошибке', () async {
      when(() => mockConfigService.exportToFile()).thenAnswer(
        (_) async => const ConfigResult.failure('Write error'),
      );

      final ProviderContainer container = await createContainer();
      container.read(settingsNotifierProvider);

      final SettingsNotifier notifier =
          container.read(settingsNotifierProvider.notifier);
      final ConfigResult result = await notifier.exportConfig();

      expect(result.success, isFalse);
      expect(result.error, equals('Write error'));
    });
  });

  group('importConfig', () {
    test('должен делегировать ConfigService.importFromFile', () async {
      when(() => mockConfigService.importFromFile()).thenAnswer(
        (_) async => const ConfigResult.success('/path/to/config.json'),
      );

      final ProviderContainer container = await createContainer();
      container.read(settingsNotifierProvider);

      final SettingsNotifier notifier =
          container.read(settingsNotifierProvider.notifier);
      final ConfigResult result = await notifier.importConfig();

      expect(result.success, isTrue);
      verify(() => mockConfigService.importFromFile()).called(1);
    });

    test('должен перезагрузить state после успешного импорта', () async {
      when(() => mockConfigService.importFromFile()).thenAnswer(
        (_) async {
          // Имитируем что ConfigService записал в prefs
          await prefs.setString(SettingsKeys.tmdbApiKey, 'imported_tmdb');
          return const ConfigResult.success('/path');
        },
      );

      final ProviderContainer container = await createContainer();
      container.read(settingsNotifierProvider);

      final SettingsNotifier notifier =
          container.read(settingsNotifierProvider.notifier);
      await notifier.importConfig();

      final SettingsState state = container.read(settingsNotifierProvider);
      expect(state.tmdbApiKey, equals('imported_tmdb'));
    });

    test('должен обновить API клиенты после импорта', () async {
      when(() => mockConfigService.importFromFile()).thenAnswer(
        (_) async {
          await prefs.setString(SettingsKeys.steamGridDbApiKey, 'new_sgdb');
          await prefs.setString(SettingsKeys.tmdbApiKey, 'new_tmdb');
          return const ConfigResult.success('/path');
        },
      );

      final ProviderContainer container = await createContainer();
      container.read(settingsNotifierProvider);

      final SettingsNotifier notifier =
          container.read(settingsNotifierProvider.notifier);
      await notifier.importConfig();

      verify(() => mockSteamGridDbApi.setApiKey('new_sgdb')).called(1);
      verify(() => mockTmdbApi.setApiKey('new_tmdb')).called(1);
    });

    test('не должен перезагружать state при отмене', () async {
      when(() => mockConfigService.importFromFile()).thenAnswer(
        (_) async => const ConfigResult.cancelled(),
      );

      final ProviderContainer container = await createContainer(
        initialPrefs: <String, Object>{
          'tmdb_api_key': 'original',
        },
      );
      container.read(settingsNotifierProvider);

      final SettingsNotifier notifier =
          container.read(settingsNotifierProvider.notifier);
      await notifier.importConfig();

      final SettingsState state = container.read(settingsNotifierProvider);
      expect(state.tmdbApiKey, equals('original'));
    });

    test('не должен перезагружать state при ошибке', () async {
      when(() => mockConfigService.importFromFile()).thenAnswer(
        (_) async => const ConfigResult.failure('Read error'),
      );

      final ProviderContainer container = await createContainer(
        initialPrefs: <String, Object>{
          'tmdb_api_key': 'original',
        },
      );
      container.read(settingsNotifierProvider);

      final SettingsNotifier notifier =
          container.read(settingsNotifierProvider.notifier);
      await notifier.importConfig();

      final SettingsState state = container.read(settingsNotifierProvider);
      expect(state.tmdbApiKey, equals('original'));
    });
  });
}
