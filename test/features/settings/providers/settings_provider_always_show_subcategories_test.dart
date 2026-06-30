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

  group('SettingsNotifier — alwaysShowSubcategories', () {
    test('alwaysShowSubcategories == false по умолчанию', () async {
      final ProviderContainer container = await createContainer();

      final SettingsState state = container.read(settingsNotifierProvider);

      expect(state.alwaysShowSubcategories, isFalse);
    });

    group('setAlwaysShowSubcategories', () {
      test('enabled: true — сохраняет в prefs и обновляет состояние', () async {
        final ProviderContainer container = await createContainer();

        final SettingsNotifier notifier =
            container.read(settingsNotifierProvider.notifier);

        await notifier.setAlwaysShowSubcategories(enabled: true);

        final SettingsState state = container.read(settingsNotifierProvider);

        expect(state.alwaysShowSubcategories, isTrue);
        expect(prefs.getBool('always_show_subcategories'), isTrue);
      });

      test('enabled: false — сохраняет в prefs и обновляет состояние',
          () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            'always_show_subcategories': true,
          },
        );

        final SettingsNotifier notifier =
            container.read(settingsNotifierProvider.notifier);

        SettingsState state = container.read(settingsNotifierProvider);
        expect(state.alwaysShowSubcategories, isTrue);

        await notifier.setAlwaysShowSubcategories(enabled: false);

        state = container.read(settingsNotifierProvider);

        expect(state.alwaysShowSubcategories, isFalse);
        expect(prefs.getBool('always_show_subcategories'), isFalse);
      });
    });

    group('_loadFromPrefs', () {
      test('загружает true из prefs', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            'always_show_subcategories': true,
          },
        );

        final SettingsState state = container.read(settingsNotifierProvider);

        expect(state.alwaysShowSubcategories, isTrue);
      });
    });

    group('clearSettings', () {
      test('сбрасывает alwaysShowSubcategories к false', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            'always_show_subcategories': true,
          },
        );

        final SettingsNotifier notifier =
            container.read(settingsNotifierProvider.notifier);

        await notifier.clearSettings();

        final SettingsState state = container.read(settingsNotifierProvider);

        expect(state.alwaysShowSubcategories, isFalse);
        expect(prefs.getBool('always_show_subcategories'), isNull);
      });
    });

    group('copyWith', () {
      test('alwaysShowSubcategories обновляется через copyWith', () {
        const SettingsState original =
            SettingsState(alwaysShowSubcategories: false);
        final SettingsState updated =
            original.copyWith(alwaysShowSubcategories: true);

        expect(updated.alwaysShowSubcategories, isTrue);
        expect(original.alwaysShowSubcategories, isFalse);
      });

      test('copyWith без alwaysShowSubcategories сохраняет текущее значение',
          () {
        const SettingsState original =
            SettingsState(alwaysShowSubcategories: true);
        final SettingsState updated = original.copyWith(tmdbApiKey: 'key');

        expect(updated.alwaysShowSubcategories, isTrue);
      });
    });
  });
}
