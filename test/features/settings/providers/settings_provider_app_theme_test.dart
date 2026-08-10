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
import 'package:tonkatsu_box/shared/theme/app_theme_id.dart';

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

  group('SettingsNotifier — appTheme', () {
    group('значение по умолчанию', () {
      test('appTheme == dark по умолчанию', () async {
        final ProviderContainer container = await createContainer();

        final SettingsState state = container.read(settingsNotifierProvider);

        expect(state.appTheme, AppThemeId.dark);
      });
    });

    group('setAppTheme', () {
      test('сохраняет в prefs и обновляет состояние', () async {
        final ProviderContainer container = await createContainer();

        final SettingsNotifier notifier =
            container.read(settingsNotifierProvider.notifier);

        await notifier.setAppTheme(AppThemeId.sakura);

        final SettingsState state = container.read(settingsNotifierProvider);

        expect(state.appTheme, AppThemeId.sakura);
        expect(prefs.getString('app_theme'), AppThemeId.sakura.id);
      });

      test('взводит одноразовый skip_picker_once — ремоунт через сплеш '
          'не должен показать пикер профилей', () async {
        final ProviderContainer container = await createContainer();

        await container
            .read(settingsNotifierProvider.notifier)
            .setAppTheme(AppThemeId.sakura);

        expect(prefs.getBool(SettingsKeys.skipPickerOnce), isTrue);
      });
    });

    group('_loadFromPrefs', () {
      test('загружает сохранённую тему из prefs', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{'app_theme': 'sakura'},
        );

        final SettingsState state = container.read(settingsNotifierProvider);

        expect(state.appTheme, AppThemeId.sakura);
      });

      test('неизвестное значение из prefs откатывается к dark', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{'app_theme': 'garbage'},
        );

        final SettingsState state = container.read(settingsNotifierProvider);

        expect(state.appTheme, AppThemeId.dark);
      });
    });

    group('clearSettings', () {
      test('сбрасывает appTheme к значению по умолчанию', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{'app_theme': 'sakura'},
        );

        final SettingsNotifier notifier =
            container.read(settingsNotifierProvider.notifier);

        await notifier.clearSettings();

        final SettingsState state = container.read(settingsNotifierProvider);

        expect(state.appTheme, AppThemeId.dark);
        expect(prefs.getString('app_theme'), isNull);
      });
    });

    group('copyWith', () {
      test('appTheme обновляется через copyWith', () {
        const SettingsState original = SettingsState();
        final SettingsState updated =
            original.copyWith(appTheme: AppThemeId.sakura);

        expect(updated.appTheme, AppThemeId.sakura);
        expect(original.appTheme, AppThemeId.dark);
      });

      test('copyWith без appTheme сохраняет текущее значение', () {
        const SettingsState original =
            SettingsState(appTheme: AppThemeId.sakura);
        final SettingsState updated = original.copyWith(tmdbApiKey: 'key');

        expect(updated.appTheme, AppThemeId.sakura);
      });
    });
  });
}
