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
import 'package:tonkatsu_box/shared/constants/rich_hero_style.dart';

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

  group('SettingsNotifier — richHeroStyle', () {
    test('should default to classic when prefs are empty', () async {
      final ProviderContainer container = await createContainer();

      final SettingsState state = container.read(settingsNotifierProvider);

      expect(state.richHeroStyle, RichHeroStyle.classic);
    });

    test('should load a stored style id from prefs', () async {
      final ProviderContainer container = await createContainer(
        initialPrefs: <String, Object>{'rich_hero_style': 'comic'},
      );

      final SettingsState state = container.read(settingsNotifierProvider);

      expect(state.richHeroStyle, RichHeroStyle.comic);
    });

    test('should fall back to classic when the stored id is unknown',
        () async {
      final ProviderContainer container = await createContainer(
        initialPrefs: <String, Object>{'rich_hero_style': 'bogus'},
      );

      final SettingsState state = container.read(settingsNotifierProvider);

      expect(state.richHeroStyle, RichHeroStyle.classic);
    });

    test('should persist the id and update state when set', () async {
      final ProviderContainer container = await createContainer();
      final SettingsNotifier notifier =
          container.read(settingsNotifierProvider.notifier);

      await notifier.setRichHeroStyle(RichHeroStyle.brutalist);

      expect(
        container.read(settingsNotifierProvider).richHeroStyle,
        RichHeroStyle.brutalist,
      );
      expect(prefs.getString('rich_hero_style'), 'brutalist');
    });

    test('should reset to classic on clearSettings', () async {
      final ProviderContainer container = await createContainer(
        initialPrefs: <String, Object>{'rich_hero_style': 'slats'},
      );
      final SettingsNotifier notifier =
          container.read(settingsNotifierProvider.notifier);
      expect(
        container.read(settingsNotifierProvider).richHeroStyle,
        RichHeroStyle.slats,
      );

      await notifier.clearSettings();

      expect(
        container.read(settingsNotifierProvider).richHeroStyle,
        RichHeroStyle.classic,
      );
      expect(prefs.getString('rich_hero_style'), isNull);
    });

    test('copyWith should replace and preserve the style', () {
      const SettingsState state = SettingsState();

      final SettingsState changed =
          state.copyWith(richHeroStyle: RichHeroStyle.stickers);
      final SettingsState untouched = changed.copyWith(cardScale: 1.2);

      expect(changed.richHeroStyle, RichHeroStyle.stickers);
      expect(untouched.richHeroStyle, RichHeroStyle.stickers);
    });
  });
}
