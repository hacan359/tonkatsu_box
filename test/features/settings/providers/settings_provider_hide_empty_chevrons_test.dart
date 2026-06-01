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
  late SharedPreferences prefs;

  setUp(() async {
    mockIgdbApi = MockIgdbApi();
    mockSteamGridDbApi = MockSteamGridDbApi();
    mockTmdbApi = MockTmdbApi();
    mockDbService = MockDatabaseService();

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

  group('SettingsNotifier — hideEmptyMediaTypeChevrons', () {
    group('значение по умолчанию', () {
      test('hideEmptyMediaTypeChevrons == false по умолчанию', () async {
        final ProviderContainer container = await createContainer();

        final SettingsState state =
            container.read(settingsNotifierProvider);

        expect(state.hideEmptyMediaTypeChevrons, isFalse);
      });
    });

    group('setHideEmptyMediaTypeChevrons', () {
      test('enabled: true — сохраняет в prefs и обновляет состояние',
          () async {
        final ProviderContainer container = await createContainer();

        final SettingsNotifier notifier =
            container.read(settingsNotifierProvider.notifier);

        await notifier.setHideEmptyMediaTypeChevrons(enabled: true);

        final SettingsState state = container.read(settingsNotifierProvider);

        expect(state.hideEmptyMediaTypeChevrons, isTrue);
        expect(prefs.getBool('hide_empty_media_type_chevrons'), isTrue);
      });

      test('enabled: false — сохраняет в prefs и обновляет состояние',
          () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            'hide_empty_media_type_chevrons': true,
          },
        );

        final SettingsNotifier notifier =
            container.read(settingsNotifierProvider.notifier);

        SettingsState state = container.read(settingsNotifierProvider);
        expect(state.hideEmptyMediaTypeChevrons, isTrue);

        await notifier.setHideEmptyMediaTypeChevrons(enabled: false);

        state = container.read(settingsNotifierProvider);

        expect(state.hideEmptyMediaTypeChevrons, isFalse);
        expect(prefs.getBool('hide_empty_media_type_chevrons'), isFalse);
      });
    });

    group('_loadFromPrefs', () {
      test('загружает true из prefs', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            'hide_empty_media_type_chevrons': true,
          },
        );

        final SettingsState state =
            container.read(settingsNotifierProvider);

        expect(state.hideEmptyMediaTypeChevrons, isTrue);
      });
    });

    group('clearSettings', () {
      test('сбрасывает hideEmptyMediaTypeChevrons к false', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            'hide_empty_media_type_chevrons': true,
          },
        );

        final SettingsNotifier notifier =
            container.read(settingsNotifierProvider.notifier);

        await notifier.clearSettings();

        final SettingsState state = container.read(settingsNotifierProvider);

        expect(state.hideEmptyMediaTypeChevrons, isFalse);
        expect(prefs.getBool('hide_empty_media_type_chevrons'), isNull);
      });
    });

    group('copyWith', () {
      test('hideEmptyMediaTypeChevrons обновляется через copyWith', () {
        const SettingsState original =
            SettingsState(hideEmptyMediaTypeChevrons: false);
        final SettingsState updated =
            original.copyWith(hideEmptyMediaTypeChevrons: true);

        expect(updated.hideEmptyMediaTypeChevrons, isTrue);
        expect(original.hideEmptyMediaTypeChevrons, isFalse);
      });

      test('copyWith без hideEmptyMediaTypeChevrons сохраняет текущее значение',
          () {
        const SettingsState original =
            SettingsState(hideEmptyMediaTypeChevrons: true);
        final SettingsState updated = original.copyWith(tmdbApiKey: 'key');

        expect(updated.hideEmptyMediaTypeChevrons, isTrue);
      });
    });
  });
}
