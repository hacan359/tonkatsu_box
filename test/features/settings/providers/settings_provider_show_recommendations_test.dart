// Тесты для настройки showRecommendations в SettingsNotifier.

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

    // По умолчанию getPlatformCount возвращает 0.
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

  group('SettingsNotifier — showRecommendations', () {
    group('значение по умолчанию', () {
      test('showRecommendations == true по умолчанию', () async {
        final ProviderContainer container = await createContainer();

        final SettingsState state =
            container.read(settingsNotifierProvider);

        expect(state.showRecommendations, isTrue);
      });

      test(
        'showRecommendations == true когда ключ отсутствует в prefs',
        () async {
          final ProviderContainer container = await createContainer(
            initialPrefs: <String, Object>{
              // Другие ключи, но не show_recommendations.
              'tmdb_api_key': 'some_key',
            },
          );

          final SettingsState state =
              container.read(settingsNotifierProvider);

          expect(state.showRecommendations, isTrue);
        },
      );
    });

    group('setShowRecommendations', () {
      test('enabled: true — сохраняет в prefs и обновляет состояние',
          () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            'show_recommendations': false,
          },
        );

        final SettingsNotifier notifier =
            container.read(settingsNotifierProvider.notifier);

        // Начальное состояние — false (загружено из prefs).
        SettingsState state = container.read(settingsNotifierProvider);
        expect(state.showRecommendations, isFalse);

        await notifier.setShowRecommendations(enabled: true);

        state = container.read(settingsNotifierProvider);

        expect(state.showRecommendations, isTrue);
        expect(prefs.getBool('show_recommendations'), isTrue);
      });

      test('enabled: false — сохраняет в prefs и обновляет состояние',
          () async {
        final ProviderContainer container = await createContainer();

        final SettingsNotifier notifier =
            container.read(settingsNotifierProvider.notifier);

        // Начальное состояние — true (по умолчанию).
        SettingsState state = container.read(settingsNotifierProvider);
        expect(state.showRecommendations, isTrue);

        await notifier.setShowRecommendations(enabled: false);

        state = container.read(settingsNotifierProvider);

        expect(state.showRecommendations, isFalse);
        expect(prefs.getBool('show_recommendations'), isFalse);
      });

      test('повторная установка того же значения не ломает состояние',
          () async {
        final ProviderContainer container = await createContainer();

        final SettingsNotifier notifier =
            container.read(settingsNotifierProvider.notifier);

        await notifier.setShowRecommendations(enabled: true);
        await notifier.setShowRecommendations(enabled: true);

        final SettingsState state =
            container.read(settingsNotifierProvider);

        expect(state.showRecommendations, isTrue);
        expect(prefs.getBool('show_recommendations'), isTrue);
      });
    });

    group('сохранение между перезагрузками (_loadFromPrefs)', () {
      test('загружает true из prefs при инициализации', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            'show_recommendations': true,
          },
        );

        final SettingsState state =
            container.read(settingsNotifierProvider);

        expect(state.showRecommendations, isTrue);
      });

      test('загружает false из prefs при инициализации', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            'show_recommendations': false,
          },
        );

        final SettingsState state =
            container.read(settingsNotifierProvider);

        expect(state.showRecommendations, isFalse);
      });

      test(
        'значение сохраняется и восстанавливается после пересоздания контейнера',
        () async {
          // Первый контейнер — устанавливаем false.
          final ProviderContainer container1 = await createContainer();

          final SettingsNotifier notifier1 =
              container1.read(settingsNotifierProvider.notifier);
          await notifier1.setShowRecommendations(enabled: false);

          // Проверяем, что значение записано в prefs.
          expect(prefs.getBool('show_recommendations'), isFalse);

          // Второй контейнер с теми же prefs — значение должно загрузиться.
          final ProviderContainer container2 = ProviderContainer(
            overrides: <Override>[
              sharedPreferencesProvider.overrideWithValue(prefs),
              igdbApiProvider.overrideWithValue(mockIgdbApi),
              steamGridDbApiProvider.overrideWithValue(mockSteamGridDbApi),
              tmdbApiProvider.overrideWithValue(mockTmdbApi),
              databaseServiceProvider.overrideWithValue(mockDbService),
            ],
          );
          addTearDown(container2.dispose);

          final SettingsState state =
              container2.read(settingsNotifierProvider);
          expect(state.showRecommendations, isFalse);
        },
      );
    });

    group('clearSettings', () {
      test('сбрасывает showRecommendations к значению по умолчанию (true)',
          () async {
        when(() => mockDbService.clearPlatforms()).thenAnswer((_) async {});

        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            'show_recommendations': false,
          },
        );

        final SettingsNotifier notifier =
            container.read(settingsNotifierProvider.notifier);

        // Начальное состояние — false.
        SettingsState state = container.read(settingsNotifierProvider);
        expect(state.showRecommendations, isFalse);

        await notifier.clearSettings();

        state = container.read(settingsNotifierProvider);

        // После очистки — дефолтное значение true.
        expect(state.showRecommendations, isTrue);
        // Ключ удалён из prefs.
        expect(prefs.getBool('show_recommendations'), isNull);
      });
    });

    group('copyWith', () {
      test('showRecommendations обновляется через copyWith', () {
        const SettingsState original = SettingsState(showRecommendations: true);
        final SettingsState updated =
            original.copyWith(showRecommendations: false);

        expect(updated.showRecommendations, isFalse);
        // Оригинал не изменился (immutability).
        expect(original.showRecommendations, isTrue);
      });

      test('copyWith без showRecommendations сохраняет текущее значение', () {
        const SettingsState original =
            SettingsState(showRecommendations: false);
        final SettingsState updated = original.copyWith(tmdbApiKey: 'key');

        expect(updated.showRecommendations, isFalse);
      });
    });
  });
}
