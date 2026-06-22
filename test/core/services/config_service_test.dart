import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/core/services/config_service.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';

void main() {
  group('ConfigResult', () {
    test('success should create успешный результат', () {
      const ConfigResult result = ConfigResult.success('/path/to/config.json');

      expect(result.success, isTrue);
      expect(result.filePath, equals('/path/to/config.json'));
      expect(result.error, isNull);
      expect(result.isCancelled, isFalse);
    });

    test('failure should create неуспешный результат', () {
      const ConfigResult result = ConfigResult.failure('Error message');

      expect(result.success, isFalse);
      expect(result.filePath, isNull);
      expect(result.error, equals('Error message'));
      expect(result.isCancelled, isFalse);
    });

    test('cancelled should create отменённый результат', () {
      const ConfigResult result = ConfigResult.cancelled();

      expect(result.success, isFalse);
      expect(result.filePath, isNull);
      expect(result.error, isNull);
      expect(result.isCancelled, isTrue);
    });

    test('isCancelled должен быть false on error', () {
      const ConfigResult result = ConfigResult(
        success: false,
        error: 'Some error',
      );

      expect(result.isCancelled, isFalse);
    });

    test('конструктор с именованными параметрами', () {
      const ConfigResult result = ConfigResult(
        success: true,
        filePath: '/path',
        error: null,
      );

      expect(result.success, isTrue);
      expect(result.filePath, equals('/path'));
    });
  });

  group('ConfigService', () {
    late SharedPreferences prefs;
    late ConfigService sut;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
      sut = ConfigService(prefs: prefs);
    });

    group('collectSettings', () {
      test('should return пустой конфиг when empty prefs', () {
        final Map<String, Object> config = sut.collectSettings();

        expect(config['tonkatsu_box_config_version'], equals(configFormatVersion));
        expect(config.length, equals(1));
      });

      test('должен собрать все string ключи', () async {
        await prefs.setString(SettingsKeys.clientId, 'my_client_id');
        await prefs.setString(SettingsKeys.clientSecret, 'my_secret');
        await prefs.setString(SettingsKeys.accessToken, 'my_token');
        await prefs.setString(SettingsKeys.steamGridDbApiKey, 'sgdb_key');
        await prefs.setString(SettingsKeys.tmdbApiKey, 'tmdb_key');
        await prefs.setString(SettingsKeys.tmdbLanguage, 'en-US');

        final Map<String, Object> config = sut.collectSettings();

        expect(config[SettingsKeys.clientId], equals('my_client_id'));
        expect(config[SettingsKeys.clientSecret], equals('my_secret'));
        expect(config[SettingsKeys.accessToken], equals('my_token'));
        expect(config[SettingsKeys.steamGridDbApiKey], equals('sgdb_key'));
        expect(config[SettingsKeys.tmdbApiKey], equals('tmdb_key'));
        expect(config[SettingsKeys.tmdbLanguage], equals('en-US'));
      });

      test('должен собрать ключи новых источников', () async {
        await prefs.setString(SettingsKeys.comicVineApiKey, 'cv_key');
        await prefs.setString(SettingsKeys.googleBooksApiKey, 'gb_key');
        await prefs.setString(SettingsKeys.screenScraperSsid, 'ss_user');
        await prefs.setString(SettingsKeys.screenScraperSspassword, 'ss_pass');
        await prefs.setString(SettingsKeys.raApiKey, 'ra_key');
        await prefs.setString(SettingsKeys.raUsername, 'ra_user');
        await prefs.setString(SettingsKeys.steamApiKey, 'steam_key');
        await prefs.setString(SettingsKeys.steamId, 'steam_id');
        await prefs.setString(SettingsKeys.aniListUsername, 'anilist_user');

        final Map<String, Object> config = sut.collectSettings();

        expect(config[SettingsKeys.comicVineApiKey], equals('cv_key'));
        expect(config[SettingsKeys.googleBooksApiKey], equals('gb_key'));
        expect(config[SettingsKeys.screenScraperSsid], equals('ss_user'));
        expect(config[SettingsKeys.screenScraperSspassword], equals('ss_pass'));
        expect(config[SettingsKeys.raApiKey], equals('ra_key'));
        expect(config[SettingsKeys.raUsername], equals('ra_user'));
        expect(config[SettingsKeys.steamApiKey], equals('steam_key'));
        expect(config[SettingsKeys.steamId], equals('steam_id'));
        expect(config[SettingsKeys.aniListUsername], equals('anilist_user'));
      });

      test('должен собрать bool ключи (галки)', () async {
        await prefs.setBool(SettingsKeys.steamRememberCredentials, true);
        await prefs.setBool(SettingsKeys.showRecommendations, false);
        await prefs.setBool(SettingsKeys.discordRpcEnabled, true);

        final Map<String, Object> config = sut.collectSettings();

        expect(config[SettingsKeys.steamRememberCredentials], isTrue);
        expect(config[SettingsKeys.showRecommendations], isFalse);
        expect(config[SettingsKeys.discordRpcEnabled], isTrue);
      });

      test('должен собрать int ключи', () async {
        await prefs.setInt(SettingsKeys.tokenExpires, 1234567890);
        await prefs.setInt(SettingsKeys.lastSync, 9876543210);

        final Map<String, Object> config = sut.collectSettings();

        expect(config[SettingsKeys.tokenExpires], equals(1234567890));
        expect(config[SettingsKeys.lastSync], equals(9876543210));
      });

      test('должен собрать все 8 ключей + версию', () async {
        await prefs.setString(SettingsKeys.clientId, 'id');
        await prefs.setString(SettingsKeys.clientSecret, 'secret');
        await prefs.setString(SettingsKeys.accessToken, 'token');
        await prefs.setInt(SettingsKeys.tokenExpires, 100);
        await prefs.setInt(SettingsKeys.lastSync, 200);
        await prefs.setString(SettingsKeys.steamGridDbApiKey, 'sgdb');
        await prefs.setString(SettingsKeys.tmdbApiKey, 'tmdb');
        await prefs.setString(SettingsKeys.tmdbLanguage, 'en-US');

        final Map<String, Object> config = sut.collectSettings();

        expect(config.length, equals(9));
      });

      test('не должен включать неустановленные ключи', () async {
        await prefs.setString(SettingsKeys.clientId, 'only_this');

        final Map<String, Object> config = sut.collectSettings();

        expect(config.containsKey(SettingsKeys.clientId), isTrue);
        expect(config.containsKey(SettingsKeys.clientSecret), isFalse);
        expect(config.containsKey(SettingsKeys.tmdbApiKey), isFalse);
      });

      test('результат должен быть валидным JSON', () async {
        await prefs.setString(SettingsKeys.clientId, 'test_id');
        await prefs.setInt(SettingsKeys.tokenExpires, 42);

        final Map<String, Object> config = sut.collectSettings();
        final String json = jsonEncode(config);
        final Map<String, Object?> decoded =
            jsonDecode(json) as Map<String, Object?>;

        expect(decoded['tonkatsu_box_config_version'], equals(configFormatVersion));
        expect(decoded[SettingsKeys.clientId], equals('test_id'));
        expect(decoded[SettingsKeys.tokenExpires], equals(42));
      });
    });

    group('applySettings', () {
      test('должен применить string настройки', () async {
        final int applied = await sut.applySettings(<String, Object?>{
          SettingsKeys.clientId: 'new_id',
          SettingsKeys.clientSecret: 'new_secret',
          SettingsKeys.tmdbApiKey: 'new_tmdb',
        });

        expect(applied, equals(3));
        expect(prefs.getString(SettingsKeys.clientId), equals('new_id'));
        expect(prefs.getString(SettingsKeys.clientSecret), equals('new_secret'));
        expect(prefs.getString(SettingsKeys.tmdbApiKey), equals('new_tmdb'));
      });

      test('должен применить int настройки', () async {
        final int applied = await sut.applySettings(<String, Object?>{
          SettingsKeys.tokenExpires: 999,
          SettingsKeys.lastSync: 888,
        });

        expect(applied, equals(2));
        expect(prefs.getInt(SettingsKeys.tokenExpires), equals(999));
        expect(prefs.getInt(SettingsKeys.lastSync), equals(888));
      });

      test('должен игнорировать null значения', () async {
        final int applied = await sut.applySettings(<String, Object?>{
          SettingsKeys.clientId: null,
          SettingsKeys.tmdbApiKey: 'valid',
        });

        expect(applied, equals(1));
        expect(prefs.getString(SettingsKeys.clientId), isNull);
        expect(prefs.getString(SettingsKeys.tmdbApiKey), equals('valid'));
      });

      test('должен игнорировать неизвестные ключи', () async {
        final int applied = await sut.applySettings(<String, Object?>{
          'unknown_key': 'value',
          'another_unknown': 42,
        });

        expect(applied, equals(0));
      });

      test('should handle num как int для int ключей', () async {
        // JSON decode may return num rather than int.
        final int applied = await sut.applySettings(<String, Object?>{
          SettingsKeys.tokenExpires: 1234567890.0,
        });

        expect(applied, equals(1));
        expect(prefs.getInt(SettingsKeys.tokenExpires), equals(1234567890));
      });

      test('должен применить все 8 настроек', () async {
        final int applied = await sut.applySettings(<String, Object?>{
          SettingsKeys.clientId: 'id',
          SettingsKeys.clientSecret: 'secret',
          SettingsKeys.accessToken: 'token',
          SettingsKeys.tokenExpires: 100,
          SettingsKeys.lastSync: 200,
          SettingsKeys.steamGridDbApiKey: 'sgdb',
          SettingsKeys.tmdbApiKey: 'tmdb',
          SettingsKeys.tmdbLanguage: 'en-US',
        });

        expect(applied, equals(8));
      });

      test('должен применить ключи новых источников', () async {
        final int applied = await sut.applySettings(<String, Object?>{
          SettingsKeys.comicVineApiKey: 'cv_key',
          SettingsKeys.googleBooksApiKey: 'gb_key',
          SettingsKeys.screenScraperSsid: 'ss_user',
          SettingsKeys.screenScraperSspassword: 'ss_pass',
          SettingsKeys.raApiKey: 'ra_key',
          SettingsKeys.raUsername: 'ra_user',
          SettingsKeys.steamApiKey: 'steam_key',
          SettingsKeys.steamId: 'steam_id',
          SettingsKeys.aniListUsername: 'anilist_user',
        });

        expect(applied, equals(9));
        expect(prefs.getString(SettingsKeys.comicVineApiKey), equals('cv_key'));
        expect(
          prefs.getString(SettingsKeys.screenScraperSspassword),
          equals('ss_pass'),
        );
        expect(prefs.getString(SettingsKeys.raApiKey), equals('ra_key'));
        expect(prefs.getString(SettingsKeys.steamId), equals('steam_id'));
        expect(
          prefs.getString(SettingsKeys.aniListUsername),
          equals('anilist_user'),
        );
      });

      test('должен применить bool ключи (галки)', () async {
        final int applied = await sut.applySettings(<String, Object?>{
          SettingsKeys.steamRememberCredentials: true,
          SettingsKeys.showBlurayOverlay: false,
          SettingsKeys.richCollectionsEnabled: true,
        });

        expect(applied, equals(3));
        expect(prefs.getBool(SettingsKeys.steamRememberCredentials), isTrue);
        expect(prefs.getBool(SettingsKeys.showBlurayOverlay), isFalse);
        expect(prefs.getBool(SettingsKeys.richCollectionsEnabled), isTrue);
      });

      test('bool ключ со значением false должен round-trip-нуться', () async {
        // Регресс: Steam-ключи не «возвращались», потому что флаг
        // steamRememberCredentials (bool) не входил в конфиг.
        await prefs.setBool(SettingsKeys.steamRememberCredentials, true);
        await prefs.setBool(SettingsKeys.showPlatformOverlay, false);

        final Map<String, Object> config = sut.collectSettings();

        await prefs.clear();
        final int applied = await sut.applySettings(config);

        expect(applied, greaterThanOrEqualTo(2));
        expect(prefs.getBool(SettingsKeys.steamRememberCredentials), isTrue);
        expect(prefs.getBool(SettingsKeys.showPlatformOverlay), isFalse);
      });

      test('должен перезаписать существующие значения', () async {
        await prefs.setString(SettingsKeys.clientId, 'old_id');

        await sut.applySettings(<String, Object?>{
          SettingsKeys.clientId: 'new_id',
        });

        expect(prefs.getString(SettingsKeys.clientId), equals('new_id'));
      });

      test('round-trip: collectSettings -> applySettings', () async {
        await prefs.setString(SettingsKeys.clientId, 'rt_id');
        await prefs.setString(SettingsKeys.clientSecret, 'rt_secret');
        await prefs.setInt(SettingsKeys.tokenExpires, 555);
        await prefs.setString(SettingsKeys.tmdbApiKey, 'rt_tmdb');

        final Map<String, Object> config = sut.collectSettings();

        await prefs.clear();
        expect(prefs.getString(SettingsKeys.clientId), isNull);

        final int applied = await sut.applySettings(config);
        expect(applied, equals(4));
        expect(prefs.getString(SettingsKeys.clientId), equals('rt_id'));
        expect(prefs.getString(SettingsKeys.clientSecret), equals('rt_secret'));
        expect(prefs.getInt(SettingsKeys.tokenExpires), equals(555));
        expect(prefs.getString(SettingsKeys.tmdbApiKey), equals('rt_tmdb'));
      });

      test('round-trip через JSON сериализацию', () async {
        await prefs.setString(SettingsKeys.clientId, 'json_id');
        await prefs.setInt(SettingsKeys.tokenExpires, 777);

        final Map<String, Object> config = sut.collectSettings();
        final String json = jsonEncode(config);
        final Map<String, Object?> decoded =
            jsonDecode(json) as Map<String, Object?>;

        await prefs.clear();
        final int applied = await sut.applySettings(decoded);

        expect(applied, equals(2));
        expect(prefs.getString(SettingsKeys.clientId), equals('json_id'));
        expect(prefs.getInt(SettingsKeys.tokenExpires), equals(777));
      });
    });
  });
}
