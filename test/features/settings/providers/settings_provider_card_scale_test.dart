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
  });

  Future<ProviderContainer> createContainer({
    Map<String, Object> initialPrefs = const <String, Object>{},
  }) async {
    SharedPreferences.setMockInitialValues(initialPrefs);
    prefs = await SharedPreferences.getInstance();

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

  group('SettingsNotifier — cardScale', () {
    group('значение по умолчанию', () {
      test('cardScale == 1.0 по умолчанию', () async {
        final ProviderContainer container = await createContainer();

        final SettingsState state = container.read(settingsNotifierProvider);

        expect(state.cardScale, equals(SettingsKeys.cardScaleDefault));
      });
    });

    group('setCardScale', () {
      test('сохраняет в prefs и обновляет состояние', () async {
        final ProviderContainer container = await createContainer();

        final SettingsNotifier notifier =
            container.read(settingsNotifierProvider.notifier);

        await notifier.setCardScale(1.3);

        final SettingsState state = container.read(settingsNotifierProvider);

        expect(state.cardScale, equals(1.3));
        expect(prefs.getDouble('card_scale'), equals(1.3));
      });

      test('persist: false обновляет состояние без записи в prefs', () async {
        final ProviderContainer container = await createContainer();

        final SettingsNotifier notifier =
            container.read(settingsNotifierProvider.notifier);

        await notifier.setCardScale(0.8, persist: false);

        final SettingsState state = container.read(settingsNotifierProvider);

        expect(state.cardScale, equals(0.8));
        expect(prefs.getDouble('card_scale'), isNull);
      });

      test('значение выше максимума ограничивается', () async {
        final ProviderContainer container = await createContainer();

        final SettingsNotifier notifier =
            container.read(settingsNotifierProvider.notifier);

        await notifier.setCardScale(5.0);

        final SettingsState state = container.read(settingsNotifierProvider);

        expect(state.cardScale, equals(SettingsKeys.cardScaleMax));
        expect(prefs.getDouble('card_scale'), equals(SettingsKeys.cardScaleMax));
      });

      test('значение ниже минимума ограничивается', () async {
        final ProviderContainer container = await createContainer();

        final SettingsNotifier notifier =
            container.read(settingsNotifierProvider.notifier);

        await notifier.setCardScale(0.1);

        final SettingsState state = container.read(settingsNotifierProvider);

        expect(state.cardScale, equals(SettingsKeys.cardScaleMin));
      });
    });

    group('_loadFromPrefs', () {
      test('загружает сохранённое значение из prefs', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{'card_scale': 1.4},
        );

        final SettingsState state = container.read(settingsNotifierProvider);

        expect(state.cardScale, equals(1.4));
      });

      test('некорректное значение из prefs ограничивается диапазоном',
          () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{'card_scale': 9.0},
        );

        final SettingsState state = container.read(settingsNotifierProvider);

        expect(state.cardScale, equals(SettingsKeys.cardScaleMax));
      });
    });

    group('clearSettings', () {
      test('сбрасывает cardScale к значению по умолчанию', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{'card_scale': 1.4},
        );

        final SettingsNotifier notifier =
            container.read(settingsNotifierProvider.notifier);

        await notifier.clearSettings();

        final SettingsState state = container.read(settingsNotifierProvider);

        expect(state.cardScale, equals(SettingsKeys.cardScaleDefault));
        expect(prefs.getDouble('card_scale'), isNull);
      });
    });

    group('copyWith', () {
      test('cardScale обновляется через copyWith', () {
        const SettingsState original = SettingsState();
        final SettingsState updated = original.copyWith(cardScale: 1.2);

        expect(updated.cardScale, equals(1.2));
        expect(original.cardScale, equals(1.0));
      });

      test('copyWith без cardScale сохраняет текущее значение', () {
        const SettingsState original = SettingsState(cardScale: 1.5);
        final SettingsState updated = original.copyWith(tmdbApiKey: 'key');

        expect(updated.cardScale, equals(1.5));
      });
    });
  });
}
