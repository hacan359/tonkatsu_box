// Тесты для KodiSettingsNotifier — per-profile persistence + KodiApi sync.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/core/api/kodi_api.dart';
import 'package:xerabora/features/settings/providers/kodi_settings_provider.dart';
import 'package:xerabora/features/settings/providers/profile_provider.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';
import 'package:xerabora/shared/models/profile.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockKodiApi mockKodiApi;
  late SharedPreferences prefs;

  const String profileId = 'test-profile';
  final Profile testProfile = Profile(
    id: profileId,
    name: 'Test',
    color: '#EF7B44',
    createdAt: DateTime(2026),
  );

  setUp(() {
    mockKodiApi = MockKodiApi();
  });

  Future<ProviderContainer> createContainer({
    Map<String, Object> initialPrefs = const <String, Object>{},
  }) async {
    SharedPreferences.setMockInitialValues(initialPrefs);
    prefs = await SharedPreferences.getInstance();

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
        kodiApiProvider.overrideWithValue(mockKodiApi),
        currentProfileProvider.overrideWithValue(testProfile),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('KodiSettingsState', () {
    test('defaults', () {
      const KodiSettingsState state = KodiSettingsState();
      expect(state.enabled, isFalse);
      expect(state.host, isEmpty);
      expect(state.port, kodiDefaultPort);
      expect(state.username, isEmpty);
      expect(state.password, isEmpty);
      expect(state.syncIntervalSeconds, kodiDefaultSyncIntervalSeconds);
      expect(state.importRatings, isFalse);
      expect(state.addUnmatchedToWishlist, isTrue);
      expect(state.lastSyncTimestamp, isNull);
    });

    test('hasConnection true when host is non-empty', () {
      const KodiSettingsState state = KodiSettingsState(host: '192.168.1.10');
      expect(state.hasConnection, isTrue);
    });

    test('hasConnection false when host is empty', () {
      const KodiSettingsState state = KodiSettingsState();
      expect(state.hasConnection, isFalse);
    });

    test('copyWith preserves fields', () {
      const KodiSettingsState original = KodiSettingsState(
        enabled: true,
        host: '10.0.0.1',
        port: 9090,
        username: 'user',
        password: 'pass',
        syncIntervalSeconds: 300,
        importRatings: true,
        addUnmatchedToWishlist: false,
        lastSyncTimestamp: '2026-04-16T12:00:00',
      );

      final KodiSettingsState copy = original.copyWith();
      expect(copy.enabled, isTrue);
      expect(copy.host, '10.0.0.1');
      expect(copy.port, 9090);
      expect(copy.username, 'user');
      expect(copy.password, 'pass');
      expect(copy.syncIntervalSeconds, 300);
      expect(copy.importRatings, isTrue);
      expect(copy.addUnmatchedToWishlist, isFalse);
      expect(copy.lastSyncTimestamp, '2026-04-16T12:00:00');
    });

    test('copyWith overrides fields', () {
      const KodiSettingsState original = KodiSettingsState(host: '10.0.0.1');
      final KodiSettingsState copy = original.copyWith(
        enabled: true,
        host: '10.0.0.2',
        port: 9999,
      );
      expect(copy.enabled, isTrue);
      expect(copy.host, '10.0.0.2');
      expect(copy.port, 9999);
    });

    test('copyWith clearLastSync nullifies lastSyncTimestamp', () {
      const KodiSettingsState original = KodiSettingsState(
        lastSyncTimestamp: '2026-04-16T12:00:00',
      );
      final KodiSettingsState copy = original.copyWith(clearLastSync: true);
      expect(copy.lastSyncTimestamp, isNull);
    });
  });

  group('KodiSettingsKeys', () {
    test('generates per-profile keys', () {
      expect(
        KodiSettingsKeys.enabled('default'),
        'kodi_enabled_default',
      );
      expect(
        KodiSettingsKeys.host('my-profile'),
        'kodi_host_my-profile',
      );
      expect(
        KodiSettingsKeys.port('p1'),
        'kodi_port_p1',
      );
      expect(
        KodiSettingsKeys.username('p1'),
        'kodi_username_p1',
      );
      expect(
        KodiSettingsKeys.password('p1'),
        'kodi_password_p1',
      );
      expect(
        KodiSettingsKeys.syncIntervalSeconds('p1'),
        'kodi_sync_interval_seconds_p1',
      );
      expect(
        KodiSettingsKeys.importRatings('p1'),
        'kodi_import_ratings_p1',
      );
      expect(
        KodiSettingsKeys.addUnmatchedToWishlist('p1'),
        'kodi_add_unmatched_to_wishlist_p1',
      );
      expect(
        KodiSettingsKeys.lastSyncTimestamp('p1'),
        'kodi_last_sync_timestamp_p1',
      );
    });
  });

  group('KodiSettingsNotifier', () {
    group('build', () {
      test('loads defaults when prefs empty', () async {
        final ProviderContainer container = await createContainer();
        final KodiSettingsState state =
            container.read(kodiSettingsProvider);

        expect(state.enabled, isFalse);
        expect(state.host, isEmpty);
        expect(state.port, kodiDefaultPort);
        expect(state.username, isEmpty);
        expect(state.password, isEmpty);
        expect(state.syncIntervalSeconds, kodiDefaultSyncIntervalSeconds);
        expect(state.importRatings, isFalse);
        expect(state.addUnmatchedToWishlist, isTrue);
        expect(state.lastSyncTimestamp, isNull);

        verifyNever(() => mockKodiApi.setConnection(
              host: any(named: 'host'),
              port: any(named: 'port'),
              username: any(named: 'username'),
              password: any(named: 'password'),
            ));
      });

      test('loads saved values and syncs KodiApi', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            'kodi_enabled_$profileId': true,
            'kodi_host_$profileId': '192.168.1.100',
            'kodi_port_$profileId': 9090,
            'kodi_username_$profileId': 'admin',
            'kodi_password_$profileId': 'secret',
            'kodi_sync_interval_seconds_$profileId': 300,
            'kodi_import_ratings_$profileId': true,
            'kodi_add_unmatched_to_wishlist_$profileId': false,
            'kodi_last_sync_timestamp_$profileId': '2026-04-16T10:00:00',
          },
        );

        final KodiSettingsState state =
            container.read(kodiSettingsProvider);

        expect(state.enabled, isTrue);
        expect(state.host, '192.168.1.100');
        expect(state.port, 9090);
        expect(state.username, 'admin');
        expect(state.password, 'secret');
        expect(state.syncIntervalSeconds, 300);
        expect(state.importRatings, isTrue);
        expect(state.addUnmatchedToWishlist, isFalse);
        expect(state.lastSyncTimestamp, '2026-04-16T10:00:00');

        verify(() => mockKodiApi.setConnection(
              host: '192.168.1.100',
              port: 9090,
              username: 'admin',
              password: 'secret',
            )).called(1);
      });

      test('does not call setConnection when host empty', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            'kodi_enabled_$profileId': true,
            'kodi_port_$profileId': 9090,
          },
        );

        final KodiSettingsState state =
            container.read(kodiSettingsProvider);
        expect(state.enabled, isTrue);
        expect(state.host, isEmpty);

        verifyNever(() => mockKodiApi.setConnection(
              host: any(named: 'host'),
              port: any(named: 'port'),
              username: any(named: 'username'),
              password: any(named: 'password'),
            ));
      });

      test('passes null username/password when empty', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            'kodi_host_$profileId': '10.0.0.1',
          },
        );

        // Trigger lazy provider build.
        container.read(kodiSettingsProvider);

        verify(() => mockKodiApi.setConnection(
              host: '10.0.0.1',
              port: kodiDefaultPort,
              username: null,
              password: null,
            )).called(1);
      });
    });

    group('setEnabled', () {
      test('persists and updates state', () async {
        final ProviderContainer container = await createContainer();
        await container.read(kodiSettingsProvider.notifier).setEnabled(
              enabled: true,
            );

        expect(container.read(kodiSettingsProvider).enabled, isTrue);
        expect(prefs.getBool('kodi_enabled_$profileId'), isTrue);
      });
    });

    group('setHost', () {
      test('persists trimmed host and syncs KodiApi', () async {
        final ProviderContainer container = await createContainer();
        await container
            .read(kodiSettingsProvider.notifier)
            .setHost('  192.168.1.50  ');

        expect(
          container.read(kodiSettingsProvider).host,
          '192.168.1.50',
        );
        expect(
          prefs.getString('kodi_host_$profileId'),
          '192.168.1.50',
        );

        verify(() => mockKodiApi.setConnection(
              host: '192.168.1.50',
              port: kodiDefaultPort,
              username: null,
              password: null,
            )).called(1);
      });

      test('clears host and calls clearConnection on empty', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            'kodi_host_$profileId': '10.0.0.1',
          },
        );

        // Reset mock call count from build()
        reset(mockKodiApi);

        await container.read(kodiSettingsProvider.notifier).setHost('  ');

        expect(container.read(kodiSettingsProvider).host, isEmpty);
        expect(prefs.getString('kodi_host_$profileId'), isNull);

        verify(() => mockKodiApi.clearConnection()).called(1);
      });
    });

    group('setPort', () {
      test('persists and syncs KodiApi', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            'kodi_host_$profileId': '10.0.0.1',
          },
        );

        reset(mockKodiApi);

        await container.read(kodiSettingsProvider.notifier).setPort(9090);

        expect(container.read(kodiSettingsProvider).port, 9090);
        expect(prefs.getInt('kodi_port_$profileId'), 9090);

        verify(() => mockKodiApi.setConnection(
              host: '10.0.0.1',
              port: 9090,
              username: null,
              password: null,
            )).called(1);
      });
    });

    group('setUsername', () {
      test('persists trimmed username', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            'kodi_host_$profileId': '10.0.0.1',
          },
        );

        await container
            .read(kodiSettingsProvider.notifier)
            .setUsername(' kodi ');

        expect(container.read(kodiSettingsProvider).username, 'kodi');
        expect(prefs.getString('kodi_username_$profileId'), 'kodi');
      });

      test('removes pref on empty string', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            'kodi_host_$profileId': '10.0.0.1',
            'kodi_username_$profileId': 'admin',
          },
        );

        await container.read(kodiSettingsProvider.notifier).setUsername('');

        expect(container.read(kodiSettingsProvider).username, isEmpty);
        expect(prefs.getString('kodi_username_$profileId'), isNull);
      });
    });

    group('setPassword', () {
      test('persists password (not trimmed)', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            'kodi_host_$profileId': '10.0.0.1',
          },
        );

        await container
            .read(kodiSettingsProvider.notifier)
            .setPassword('my pass');

        expect(container.read(kodiSettingsProvider).password, 'my pass');
        expect(prefs.getString('kodi_password_$profileId'), 'my pass');
      });

      test('removes pref on empty string', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            'kodi_host_$profileId': '10.0.0.1',
            'kodi_password_$profileId': 'secret',
          },
        );

        await container.read(kodiSettingsProvider.notifier).setPassword('');

        expect(container.read(kodiSettingsProvider).password, isEmpty);
        expect(prefs.getString('kodi_password_$profileId'), isNull);
      });
    });

    group('setSyncIntervalSeconds', () {
      test('persists and updates state', () async {
        final ProviderContainer container = await createContainer();
        await container
            .read(kodiSettingsProvider.notifier)
            .setSyncIntervalSeconds(300);

        expect(
          container.read(kodiSettingsProvider).syncIntervalSeconds,
          300,
        );
        expect(
          prefs.getInt('kodi_sync_interval_seconds_$profileId'),
          300,
        );
      });
    });

    group('setImportRatings', () {
      test('persists and updates state', () async {
        final ProviderContainer container = await createContainer();
        await container
            .read(kodiSettingsProvider.notifier)
            .setImportRatings(enabled: true);

        expect(
          container.read(kodiSettingsProvider).importRatings,
          isTrue,
        );
        expect(
          prefs.getBool('kodi_import_ratings_$profileId'),
          isTrue,
        );
      });
    });

    group('setAddUnmatchedToWishlist', () {
      test('persists and updates state', () async {
        final ProviderContainer container = await createContainer();
        await container
            .read(kodiSettingsProvider.notifier)
            .setAddUnmatchedToWishlist(enabled: false);

        expect(
          container.read(kodiSettingsProvider).addUnmatchedToWishlist,
          isFalse,
        );
        expect(
          prefs.getBool('kodi_add_unmatched_to_wishlist_$profileId'),
          isFalse,
        );
      });
    });

    group('setLastSyncTimestamp', () {
      test('persists and updates state', () async {
        final ProviderContainer container = await createContainer();
        await container
            .read(kodiSettingsProvider.notifier)
            .setLastSyncTimestamp('2026-04-16T15:00:00');

        expect(
          container.read(kodiSettingsProvider).lastSyncTimestamp,
          '2026-04-16T15:00:00',
        );
        expect(
          prefs.getString('kodi_last_sync_timestamp_$profileId'),
          '2026-04-16T15:00:00',
        );
      });
    });

    group('clearLastSyncTimestamp', () {
      test('removes pref and nullifies state', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            'kodi_last_sync_timestamp_$profileId': '2026-04-16T10:00:00',
          },
        );

        expect(
          container.read(kodiSettingsProvider).lastSyncTimestamp,
          '2026-04-16T10:00:00',
        );

        await container
            .read(kodiSettingsProvider.notifier)
            .clearLastSyncTimestamp();

        expect(
          container.read(kodiSettingsProvider).lastSyncTimestamp,
          isNull,
        );
        expect(
          prefs.getString('kodi_last_sync_timestamp_$profileId'),
          isNull,
        );
      });
    });

    group('clearAll', () {
      test('removes all prefs and resets state', () async {
        final ProviderContainer container = await createContainer(
          initialPrefs: <String, Object>{
            'kodi_enabled_$profileId': true,
            'kodi_host_$profileId': '10.0.0.1',
            'kodi_port_$profileId': 9090,
            'kodi_username_$profileId': 'admin',
            'kodi_password_$profileId': 'secret',
            'kodi_sync_interval_seconds_$profileId': 300,
            'kodi_import_ratings_$profileId': true,
            'kodi_add_unmatched_to_wishlist_$profileId': false,
            'kodi_last_sync_timestamp_$profileId': '2026-04-16T10:00:00',
          },
        );

        reset(mockKodiApi);

        await container.read(kodiSettingsProvider.notifier).clearAll();

        final KodiSettingsState state =
            container.read(kodiSettingsProvider);
        expect(state.enabled, isFalse);
        expect(state.host, isEmpty);
        expect(state.port, kodiDefaultPort);
        expect(state.username, isEmpty);
        expect(state.password, isEmpty);
        expect(state.syncIntervalSeconds, kodiDefaultSyncIntervalSeconds);
        expect(state.importRatings, isFalse);
        expect(state.addUnmatchedToWishlist, isTrue);
        expect(state.lastSyncTimestamp, isNull);

        verify(() => mockKodiApi.clearConnection()).called(1);

        // Verify all prefs removed
        expect(prefs.getBool('kodi_enabled_$profileId'), isNull);
        expect(prefs.getString('kodi_host_$profileId'), isNull);
        expect(prefs.getInt('kodi_port_$profileId'), isNull);
        expect(prefs.getString('kodi_username_$profileId'), isNull);
        expect(prefs.getString('kodi_password_$profileId'), isNull);
        expect(
          prefs.getInt('kodi_sync_interval_seconds_$profileId'),
          isNull,
        );
        expect(prefs.getBool('kodi_import_ratings_$profileId'), isNull);
        expect(
          prefs.getBool('kodi_add_unmatched_to_wishlist_$profileId'),
          isNull,
        );
        expect(
          prefs.getString('kodi_last_sync_timestamp_$profileId'),
          isNull,
        );
      });
    });

    group('profile isolation', () {
      test('different profiles read different keys', () async {
        const String otherProfileId = 'other-profile';
        final Profile otherProfile = Profile(
          id: otherProfileId,
          name: 'Other',
          color: '#FF0000',
          createdAt: DateTime(2026),
        );

        SharedPreferences.setMockInitialValues(<String, Object>{
          'kodi_host_$profileId': '10.0.0.1',
          'kodi_host_$otherProfileId': '10.0.0.2',
        });
        prefs = await SharedPreferences.getInstance();

        // Container for test-profile
        final ProviderContainer container1 = ProviderContainer(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
            kodiApiProvider.overrideWithValue(mockKodiApi),
            currentProfileProvider.overrideWithValue(testProfile),
          ],
        );
        addTearDown(container1.dispose);

        // Container for other-profile
        final ProviderContainer container2 = ProviderContainer(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
            kodiApiProvider.overrideWithValue(mockKodiApi),
            currentProfileProvider.overrideWithValue(otherProfile),
          ],
        );
        addTearDown(container2.dispose);

        expect(container1.read(kodiSettingsProvider).host, '10.0.0.1');
        expect(container2.read(kodiSettingsProvider).host, '10.0.0.2');
      });
    });
  });
}
