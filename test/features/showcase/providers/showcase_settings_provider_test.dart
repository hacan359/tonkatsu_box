import 'dart:convert';

import 'package:core/models/media_type.dart';
import 'package:core/models/profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/features/settings/providers/profile_provider.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';
import 'package:tonkatsu_box/features/showcase/providers/showcase_settings_provider.dart';

void main() {
  group('ShowcaseRowId', () {
    test('every key round-trips through fromKey', () {
      for (final ShowcaseRowId id in ShowcaseRowId.values) {
        expect(ShowcaseRowId.fromKey(id.key), id, reason: id.key);
      }
    });

    test('keys are unique', () {
      final Set<String> keys =
          ShowcaseRowId.values.map((ShowcaseRowId r) => r.key).toSet();
      expect(keys.length, ShowcaseRowId.values.length);
    });

    test('fromKey rejects unknown and empty keys', () {
      expect(ShowcaseRowId.fromKey('nonexistent'), isNull);
      expect(ShowcaseRowId.fromKey(''), isNull);
    });

    test('inGroup splits the rows without overlap or loss', () {
      final List<ShowcaseRowId> airing =
          ShowcaseRowId.inGroup(ShowcaseGroup.airing);
      final List<ShowcaseRowId> popular =
          ShowcaseRowId.inGroup(ShowcaseGroup.popular);
      expect(airing.toSet().intersection(popular.toSet()), isEmpty);
      expect(airing.length + popular.length, ShowcaseRowId.values.length);
      expect(airing, contains(ShowcaseRowId.animeThisSeason));
      expect(popular, contains(ShowcaseRowId.trendingMovies));
    });

    test('anime rows are ordered by the anime library type', () {
      expect(ShowcaseRowId.animeThisSeason.mediaType, MediaType.anime);
      expect(ShowcaseRowId.popularAnime.mediaType, MediaType.anime);
      expect(ShowcaseRowId.upcomingGames.mediaType, MediaType.game);
    });
  });

  group('ShowcaseSettings', () {
    test('every row is enabled by default', () {
      const ShowcaseSettings settings = ShowcaseSettings();
      for (final ShowcaseRowId id in ShowcaseRowId.values) {
        expect(settings.isEnabled(id), isTrue, reason: id.key);
      }
      expect(settings.hideOwned, isFalse);
    });

    test('hidden rows are reported as disabled', () {
      const ShowcaseSettings settings = ShowcaseSettings(
        hiddenRows: <ShowcaseRowId>{ShowcaseRowId.freshAlbums},
      );
      expect(settings.isEnabled(ShowcaseRowId.freshAlbums), isFalse);
      expect(settings.isEnabled(ShowcaseRowId.nowPlaying), isTrue);
    });
  });

  group('ShowcaseSettingsNotifier', () {
    Future<ProviderContainer> createContainer({
      Map<String, Object> initialPrefs = const <String, Object>{},
      String profileId = 'default',
    }) async {
      SharedPreferences.setMockInitialValues(initialPrefs);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          profilesDataProvider.overrideWith(
            (Ref ref) => ProfilesData(
              version: 1,
              currentProfileId: profileId,
              profiles: <Profile>[
                Profile(
                  id: profileId,
                  name: profileId,
                  color: '#000000',
                  createdAt: DateTime(2024),
                ),
              ],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('starts with everything visible when nothing is stored', () async {
      final ProviderContainer container = await createContainer();
      final ShowcaseSettings settings =
          container.read(showcaseSettingsProvider);
      expect(settings.hiddenRows, isEmpty);
      expect(settings.hideOwned, isFalse);
    });

    test('reads the hidden set and hideOwned from prefs', () async {
      final ProviderContainer container = await createContainer(
        initialPrefs: <String, Object>{
          ShowcaseSettingsKeys.hiddenRows('default'):
              jsonEncode(<String>['now_playing', 'bogus_key']),
          ShowcaseSettingsKeys.hideOwned('default'): true,
        },
      );
      final ShowcaseSettings settings =
          container.read(showcaseSettingsProvider);
      expect(settings.hiddenRows, <ShowcaseRowId>{ShowcaseRowId.nowPlaying});
      expect(settings.hideOwned, isTrue);
    });

    group('legacy Discover list', () {
      test('hides the rows of sections the user had off', () {
        final Set<ShowcaseRowId> hidden =
            ShowcaseSettingsNotifier.hiddenRowsFromLegacy(<String>{
          'top_rated_movies',
          'upcoming',
        });
        expect(
          hidden,
          <ShowcaseRowId>{
            ShowcaseRowId.trendingMovies,
            ShowcaseRowId.trendingTvShows,
            ShowcaseRowId.popularAnime,
          },
        );
      });

      test('sections without a row any more are ignored', () {
        final Set<ShowcaseRowId> hidden =
            ShowcaseSettingsNotifier.hiddenRowsFromLegacy(<String>{
          'trending',
          'upcoming',
          'anime',
          'popular_tv_shows',
        });
        expect(hidden, isEmpty);
      });

      test('never hides rows Discover did not have', () {
        final Set<ShowcaseRowId> hidden =
            ShowcaseSettingsNotifier.hiddenRowsFromLegacy(const <String>{});
        final Set<ShowcaseRowId> legacyRows = legacyDiscoverSections.values
            .expand((Set<ShowcaseRowId> rows) => rows)
            .toSet();
        expect(hidden, legacyRows);
        expect(hidden, isNot(contains(ShowcaseRowId.animeThisSeason)));
        expect(hidden, isNot(contains(ShowcaseRowId.nowPlaying)));
      });

      test('is converted on load and kept for other profiles', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            ShowcaseSettingsKeys.legacySections:
                jsonEncode(<String>['anime', 'top_rated_tv_shows']),
          },
        );
        final ShowcaseSettings loaded =
            container.read(showcaseSettingsProvider);
        expect(loaded.isEnabled(ShowcaseRowId.popularAnime), isTrue);
        expect(loaded.isEnabled(ShowcaseRowId.trendingMovies), isFalse);
        expect(loaded.isEnabled(ShowcaseRowId.upcomingMovies), isFalse);
        expect(loaded.isEnabled(ShowcaseRowId.animeThisSeason), isTrue);

        await container
            .read(showcaseSettingsProvider.notifier)
            .setHideOwned(value: true);
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(ShowcaseSettingsKeys.legacySections), isNotNull);
        expect(prefs.getString(ShowcaseSettingsKeys.hiddenRows('default')), isNotNull);
      });

      test('the new key wins over a leftover legacy list', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            ShowcaseSettingsKeys.hiddenRows('default'): jsonEncode(<String>[]),
            ShowcaseSettingsKeys.legacySections: jsonEncode(<String>[]),
          },
        );
        expect(container.read(showcaseSettingsProvider).hiddenRows, isEmpty);
      });
    });

    test('toggleRow hides, then shows again, and persists', () async {
      final ProviderContainer container = await createContainer();
      final ShowcaseSettingsNotifier notifier =
          container.read(showcaseSettingsProvider.notifier);

      await notifier.toggleRow(ShowcaseRowId.upcomingGames);
      expect(
        container.read(showcaseSettingsProvider).isEnabled(
              ShowcaseRowId.upcomingGames,
            ),
        isFalse,
      );
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(ShowcaseSettingsKeys.hiddenRows('default')),
        jsonEncode(<String>['upcoming_games']),
      );

      await notifier.toggleRow(ShowcaseRowId.upcomingGames);
      expect(
        container.read(showcaseSettingsProvider).isEnabled(
              ShowcaseRowId.upcomingGames,
            ),
        isTrue,
      );
    });

    test('resetToDefault clears the hidden set and hideOwned', () async {
      final ProviderContainer container = await createContainer(
        initialPrefs: <String, Object>{
          ShowcaseSettingsKeys.hiddenRows('default'): jsonEncode(<String>['now_playing']),
          ShowcaseSettingsKeys.hideOwned('default'): true,
        },
      );
      await container.read(showcaseSettingsProvider.notifier).resetToDefault();
      final ShowcaseSettings settings =
          container.read(showcaseSettingsProvider);
      expect(settings.hiddenRows, isEmpty);
      expect(settings.hideOwned, isFalse);
    });

    test('should keep the settings of each profile apart', () async {
      final ProviderContainer container = await createContainer(
        initialPrefs: <String, Object>{
          ShowcaseSettingsKeys.hiddenRows('default'):
              jsonEncode(<String>['now_playing']),
          ShowcaseSettingsKeys.hideOwned('default'): true,
        },
        profileId: 'second',
      );
      final ShowcaseSettings loaded = container.read(showcaseSettingsProvider);
      expect(loaded.hiddenRows, isEmpty);
      expect(loaded.hideOwned, isFalse);

      await container
          .read(showcaseSettingsProvider.notifier)
          .toggleRow(ShowcaseRowId.freshAlbums);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(ShowcaseSettingsKeys.hiddenRows('second')),
        jsonEncode(<String>['fresh_albums']),
      );
      expect(
        prefs.getString(ShowcaseSettingsKeys.hiddenRows('default')),
        jsonEncode(<String>['now_playing']),
      );
    });

    test('should fall back to the unsuffixed Discover hide-owned flag',
        () async {
      final ProviderContainer container = await createContainer(
        initialPrefs: <String, Object>{
          ShowcaseSettingsKeys.legacyHideOwned: true,
        },
      );
      expect(container.read(showcaseSettingsProvider).hideOwned, isTrue);
    });

    test('should show everything when the stored list is not valid JSON',
        () async {
      final ProviderContainer container = await createContainer(
        initialPrefs: <String, Object>{
          ShowcaseSettingsKeys.hiddenRows('default'): '{broken',
        },
      );
      expect(container.read(showcaseSettingsProvider).hiddenRows, isEmpty);
    });
  });
}
