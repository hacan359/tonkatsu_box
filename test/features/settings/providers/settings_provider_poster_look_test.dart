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
import 'package:tonkatsu_box/shared/widgets/poster_look.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late SharedPreferences prefs;

  Future<ProviderContainer> createContainer({
    Map<String, Object> initialPrefs = const <String, Object>{},
  }) async {
    final MockDatabaseService db = MockDatabaseService();
    final MockGameDao gameDao = MockGameDao();
    when(() => db.gameDao).thenReturn(gameDao);
    when(gameDao.getPlatformCount).thenAnswer((_) async => 0);

    SharedPreferences.setMockInitialValues(initialPrefs);
    prefs = await SharedPreferences.getInstance();

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
        apiKeysProvider.overrideWithValue(const ApiKeys()),
        igdbApiProvider.overrideWithValue(MockIgdbApi()),
        steamGridDbApiProvider.overrideWithValue(MockSteamGridDbApi()),
        tmdbApiProvider.overrideWithValue(MockTmdbApi()),
        databaseServiceProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('SettingsNotifier', () {
    group('build', () {
      test(
        'should default to the classic look when nothing is stored',
        () async {
          final ProviderContainer container = await createContainer();

          expect(
            container.read(settingsNotifierProvider).posterLook,
            PosterLook.classic,
          );
        },
      );

      test('should load the stored look', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            SettingsKeys.posterLook: PosterLook.cinema.id,
          },
        );

        expect(
          container.read(settingsNotifierProvider).posterLook,
          PosterLook.cinema,
        );
      });

      test(
        'should fall back to classic when the stored id is unknown',
        () async {
          final ProviderContainer container = await createContainer(
            initialPrefs: <String, Object>{SettingsKeys.posterLook: 'gone'},
          );

          expect(
            container.read(settingsNotifierProvider).posterLook,
            PosterLook.classic,
          );
        },
      );
    });

    group('setPosterLook', () {
      test('should update the state and persist the id', () async {
        final ProviderContainer container = await createContainer();

        await container
            .read(settingsNotifierProvider.notifier)
            .setPosterLook(PosterLook.slab);

        expect(
          container.read(settingsNotifierProvider).posterLook,
          PosterLook.slab,
        );
        expect(prefs.getString(SettingsKeys.posterLook), PosterLook.slab.id);
      });

      test('should write nothing when the look is unchanged', () async {
        final ProviderContainer container = await createContainer();

        await container
            .read(settingsNotifierProvider.notifier)
            .setPosterLook(PosterLook.classic);

        expect(prefs.getString(SettingsKeys.posterLook), isNull);
      });
    });
  });

  group('SettingsState', () {
    group('copyWith', () {
      test('should replace the look and keep it when omitted', () {
        const SettingsState state = SettingsState();

        final SettingsState changed = state.copyWith(
          posterLook: PosterLook.tilt,
        );

        expect(changed.posterLook, PosterLook.tilt);
        expect(changed.copyWith().posterLook, PosterLook.tilt);
      });
    });
  });
}
