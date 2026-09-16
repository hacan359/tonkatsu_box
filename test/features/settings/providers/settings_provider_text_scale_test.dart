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
    group('textScale', () {
      test('should default to 1.0 when nothing is stored', () async {
        final ProviderContainer container = await createContainer();

        expect(
          container.read(settingsNotifierProvider).textScale,
          SettingsKeys.textScaleDefault,
        );
      });

      test('should load and clamp the stored value', () async {
        final ProviderContainer low = await createContainer(
          initialPrefs: <String, Object>{SettingsKeys.textScale: 0.1},
        );
        expect(
          low.read(settingsNotifierProvider).textScale,
          SettingsKeys.textScaleMin,
        );

        final ProviderContainer stored = await createContainer(
          initialPrefs: <String, Object>{SettingsKeys.textScale: 1.15},
        );
        expect(stored.read(settingsNotifierProvider).textScale, 1.15);
      });
    });

    group('setTextScale', () {
      test('should persist the clamped value when persist is true', () async {
        final ProviderContainer container = await createContainer();

        await container
            .read(settingsNotifierProvider.notifier)
            .setTextScale(5.0);

        expect(
          container.read(settingsNotifierProvider).textScale,
          SettingsKeys.textScaleMax,
        );
        expect(
          prefs.getDouble(SettingsKeys.textScale),
          SettingsKeys.textScaleMax,
        );
      });

      test('should update state only when persist is false', () async {
        final ProviderContainer container = await createContainer();

        await container
            .read(settingsNotifierProvider.notifier)
            .setTextScale(1.15, persist: false);

        expect(container.read(settingsNotifierProvider).textScale, 1.15);
        expect(prefs.getDouble(SettingsKeys.textScale), isNull);
      });
    });

    group('clearSettings', () {
      test('should reset textScale to the default', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{SettingsKeys.textScale: 1.3},
        );

        await container.read(settingsNotifierProvider.notifier).clearSettings();

        expect(
          container.read(settingsNotifierProvider).textScale,
          SettingsKeys.textScaleDefault,
        );
        expect(prefs.getDouble(SettingsKeys.textScale), isNull);
      });
    });

    group('copyWith', () {
      test('should keep textScale when the field is omitted', () {
        const SettingsState original = SettingsState(textScale: 1.3);

        expect(original.copyWith(appLanguage: 'ru').textScale, 1.3);
        expect(original.copyWith(textScale: 0.85).textScale, 0.85);
      });
    });
  });
}
