// Тесты для ConfigService — экспорт и импорт конфигурации.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/core/services/config_service.dart';
import 'package:xerabora/features/settings/providers/settings_provider.dart';

void main() {
  group('ConfigResult', () {
    test('success должен создать успешный результат', () {
      const ConfigResult result = ConfigResult.success('/path/to/config.json');

      expect(result.success, isTrue);
      expect(result.filePath, equals('/path/to/config.json'));
      expect(result.error, isNull);
      expect(result.isCancelled, isFalse);
    });

    test('failure должен создать неуспешный результат', () {
      const ConfigResult result = ConfigResult.failure('Error message');

      expect(result.success, isFalse);
      expect(result.filePath, isNull);
      expect(result.error, equals('Error message'));
      expect(result.isCancelled, isFalse);
    });

    test('cancelled должен создать отменённый результат', () {
      const ConfigResult result = ConfigResult.cancelled();

      expect(result.success, isFalse);
      expect(result.filePath, isNull);
      expect(result.error, isNull);
      expect(result.isCancelled, isTrue);
    });

    test('isCancelled должен быть false при ошибке', () {
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
      test('должен вернуть пустой конфиг при пустых prefs', () {
        final Map<String, Object> config = sut.collectSettings();

        expect(config['tonkatsu_box_config_version'], equals(configFormatVersion));
        // Только версия, никаких ключей
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

        expect(config.length, equals(9)); // 8 ключей + версия
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

      test('должен обрабатывать num как int для int ключей', () async {
        // JSON decode может вернуть num вместо int
        final int applied = await sut.applySettings(<String, Object?>{
          SettingsKeys.tokenExpires: 1234567890.0, // double from JSON
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

        // Очищаем prefs
        await prefs.clear();
        expect(prefs.getString(SettingsKeys.clientId), isNull);

        // Применяем обратно
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
