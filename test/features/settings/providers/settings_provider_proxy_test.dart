import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/core/api/igdb_api.dart';
import 'package:tonkatsu_box/core/api/steamgriddb_api.dart';
import 'package:tonkatsu_box/core/api/tmdb_api.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/core/services/api_key_initializer.dart';
import 'package:tonkatsu_box/core/services/app_proxy_config.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late SharedPreferences prefs;

  Future<SettingsNotifier> createNotifier({
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
    return container.read(settingsNotifierProvider.notifier);
  }

  tearDown(() => AppProxyConfig.current = const AppProxyConfig.disabled());

  group('SettingsNotifier', () {
    group('build', () {
      test('should leave the proxy off when nothing is stored', () async {
        final SettingsNotifier notifier = await createNotifier();

        expect(notifier.state.proxyEnabled, isFalse);
        expect(notifier.state.proxyHost, AppProxyConfig.defaultHost);
        expect(notifier.state.proxyPort, AppProxyConfig.defaultPort);
        expect(AppProxyConfig.current.enabled, isFalse);
      });

      test('should apply the stored proxy before any request', () async {
        final SettingsNotifier notifier = await createNotifier(
          initialPrefs: <String, Object>{
            SettingsKeys.proxyEnabled: true,
            SettingsKeys.proxyHost: 'proxy.lan.example.com',
            SettingsKeys.proxyPort: 8118,
          },
        );

        expect(notifier.state.proxyEnabled, isTrue);
        expect(AppProxyConfig.current.enabled, isTrue);
        expect(AppProxyConfig.current.host, 'proxy.lan.example.com');
        expect(AppProxyConfig.current.port, 8118);
      });
    });

    group('setProxyEnabled', () {
      test('should persist the flag and switch the live config', () async {
        final SettingsNotifier notifier = await createNotifier();

        await notifier.setProxyEnabled(enabled: true);

        expect(prefs.getBool(SettingsKeys.proxyEnabled), isTrue);
        expect(notifier.state.proxyEnabled, isTrue);
        expect(AppProxyConfig.current.enabled, isTrue);
      });
    });

    group('setProxyHost', () {
      test('should trim, persist and apply a valid host', () async {
        final SettingsNotifier notifier = await createNotifier();

        final bool saved = await notifier.setProxyHost(' 10.8.0.1 ');

        expect(saved, isTrue);
        expect(prefs.getString(SettingsKeys.proxyHost), '10.8.0.1');
        expect(AppProxyConfig.current.host, '10.8.0.1');
      });

      test('should reject a malformed host and keep the old one', () async {
        final SettingsNotifier notifier = await createNotifier();

        final bool saved = await notifier.setProxyHost('http://10.8.0.1');

        expect(saved, isFalse);
        expect(prefs.getString(SettingsKeys.proxyHost), isNull);
        expect(notifier.state.proxyHost, AppProxyConfig.defaultHost);
      });

      test('should reject an empty host', () async {
        final SettingsNotifier notifier = await createNotifier();

        expect(await notifier.setProxyHost('   '), isFalse);
      });
    });

    group('setProxyPort', () {
      test('should persist and apply a valid port', () async {
        final SettingsNotifier notifier = await createNotifier();

        final bool saved = await notifier.setProxyPort(8118);

        expect(saved, isTrue);
        expect(prefs.getInt(SettingsKeys.proxyPort), 8118);
        expect(AppProxyConfig.current.port, 8118);
      });

      test('should reject a port out of range and keep the old one', () async {
        final SettingsNotifier notifier = await createNotifier();

        expect(await notifier.setProxyPort(0), isFalse);
        expect(await notifier.setProxyPort(70000), isFalse);
        expect(prefs.getInt(SettingsKeys.proxyPort), isNull);
        expect(notifier.state.proxyPort, AppProxyConfig.defaultPort);
      });
    });
  });
}
