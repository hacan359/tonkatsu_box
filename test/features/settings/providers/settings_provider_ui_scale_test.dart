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
  late MockDatabaseService mockDbService;
  late MockGameDao mockGameDao;
  late SharedPreferences prefs;

  setUp(() {
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
        igdbApiProvider.overrideWithValue(MockIgdbApi()),
        steamGridDbApiProvider.overrideWithValue(MockSteamGridDbApi()),
        tmdbApiProvider.overrideWithValue(MockTmdbApi()),
        databaseServiceProvider.overrideWithValue(mockDbService),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('SettingsNotifier', () {
    group('uiScale', () {
      test('should default to 1.0 when nothing is stored', () async {
        final ProviderContainer container = await createContainer();

        expect(
          container.read(settingsNotifierProvider).uiScale,
          SettingsKeys.uiScaleDefault,
        );
      });

      test('should load and clamp the stored value', () async {
        final ProviderContainer high = await createContainer(
          initialPrefs: <String, Object>{SettingsKeys.uiScale: 9.0},
        );
        expect(
          high.read(settingsNotifierProvider).uiScale,
          SettingsKeys.uiScaleMax,
        );

        final ProviderContainer stored = await createContainer(
          initialPrefs: <String, Object>{SettingsKeys.uiScale: 0.8},
        );
        expect(stored.read(settingsNotifierProvider).uiScale, 0.8);
      });
    });

    group('setUiScale', () {
      test('should persist the clamped value when persist is true', () async {
        final ProviderContainer container = await createContainer();

        await container.read(settingsNotifierProvider.notifier).setUiScale(0.1);

        expect(
          container.read(settingsNotifierProvider).uiScale,
          SettingsKeys.uiScaleMin,
        );
        expect(prefs.getDouble(SettingsKeys.uiScale), SettingsKeys.uiScaleMin);
      });

      test('should update state only when persist is false', () async {
        final ProviderContainer container = await createContainer();

        await container
            .read(settingsNotifierProvider.notifier)
            .setUiScale(1.3, persist: false);

        expect(container.read(settingsNotifierProvider).uiScale, 1.3);
        expect(prefs.getDouble(SettingsKeys.uiScale), isNull);
      });

      test('should round float noise back onto the default fast path', () async {
        final ProviderContainer container = await createContainer();
        final SettingsNotifier notifier =
            container.read(settingsNotifierProvider.notifier);

        await notifier.setUiScale(1.1);
        await notifier.setUiScale(1.1 - SettingsKeys.uiScaleStep);

        expect(
          container.read(settingsNotifierProvider).uiScale,
          SettingsKeys.uiScaleDefault,
        );
      });
    });

    group('stepUiScale', () {
      test('should move one notch per call in either direction', () async {
        final ProviderContainer container = await createContainer();
        final SettingsNotifier notifier =
            container.read(settingsNotifierProvider.notifier);

        await notifier.stepUiScale(1);
        expect(container.read(settingsNotifierProvider).uiScale, 1.1);

        await notifier.stepUiScale(-2);
        expect(container.read(settingsNotifierProvider).uiScale, 0.9);
      });

      test('should stop at the range limits', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            SettingsKeys.uiScale: SettingsKeys.uiScaleMax,
          },
        );

        await container.read(settingsNotifierProvider.notifier).stepUiScale(1);

        expect(
          container.read(settingsNotifierProvider).uiScale,
          SettingsKeys.uiScaleMax,
        );
      });
    });

    group('clearSettings', () {
      test('should reset uiScale to the default', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{SettingsKeys.uiScale: 1.5},
        );

        await container.read(settingsNotifierProvider.notifier).clearSettings();

        expect(
          container.read(settingsNotifierProvider).uiScale,
          SettingsKeys.uiScaleDefault,
        );
        expect(prefs.getDouble(SettingsKeys.uiScale), isNull);
      });
    });

    group('copyWith', () {
      test('should keep uiScale when the field is omitted', () {
        const SettingsState original = SettingsState(uiScale: 1.5);

        expect(original.copyWith(appLanguage: 'ru').uiScale, 1.5);
        expect(original.copyWith(uiScale: 0.7).uiScale, 0.7);
      });
    });
  });
}
