// Тесты для ApiKeys — ранняя загрузка API ключей из SharedPreferences.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xerabora/core/services/api_key_initializer.dart';

void main() {
  group('ApiKeys', () {
    group('fromPrefs', () {
      group('TMDB', () {
        test('should use user key when present in prefs', () async {
          SharedPreferences.setMockInitialValues(<String, Object>{
            'tmdb_api_key': 'user_tmdb_key',
          });
          final SharedPreferences prefs =
              await SharedPreferences.getInstance();

          final ApiKeys keys = ApiKeys.fromPrefs(prefs);

          expect(keys.tmdbApiKey, equals('user_tmdb_key'));
        });

        test('should return null when user key is empty and no built-in',
            () async {
          SharedPreferences.setMockInitialValues(<String, Object>{
            'tmdb_api_key': '',
          });
          final SharedPreferences prefs =
              await SharedPreferences.getInstance();

          final ApiKeys keys = ApiKeys.fromPrefs(prefs);

          // В тестах ApiDefaults.hasTmdbKey == false
          expect(keys.tmdbApiKey, isNull);
        });

        test('should return null when no key in prefs and no built-in',
            () async {
          SharedPreferences.setMockInitialValues(<String, Object>{});
          final SharedPreferences prefs =
              await SharedPreferences.getInstance();

          final ApiKeys keys = ApiKeys.fromPrefs(prefs);

          expect(keys.tmdbApiKey, isNull);
        });
      });

      group('SteamGridDB', () {
        test('should use user key when present in prefs', () async {
          SharedPreferences.setMockInitialValues(<String, Object>{
            'steamgriddb_api_key': 'user_sgdb_key',
          });
          final SharedPreferences prefs =
              await SharedPreferences.getInstance();

          final ApiKeys keys = ApiKeys.fromPrefs(prefs);

          expect(keys.steamGridDbApiKey, equals('user_sgdb_key'));
        });

        test('should return null when user key is empty and no built-in',
            () async {
          SharedPreferences.setMockInitialValues(<String, Object>{
            'steamgriddb_api_key': '',
          });
          final SharedPreferences prefs =
              await SharedPreferences.getInstance();

          final ApiKeys keys = ApiKeys.fromPrefs(prefs);

          expect(keys.steamGridDbApiKey, isNull);
        });

        test('should return null when no key in prefs and no built-in',
            () async {
          SharedPreferences.setMockInitialValues(<String, Object>{});
          final SharedPreferences prefs =
              await SharedPreferences.getInstance();

          final ApiKeys keys = ApiKeys.fromPrefs(prefs);

          expect(keys.steamGridDbApiKey, isNull);
        });
      });

      group('IGDB', () {
        test('should load client ID and access token from prefs', () async {
          SharedPreferences.setMockInitialValues(<String, Object>{
            'igdb_client_id': 'user_cid',
            'igdb_access_token': 'user_token',
          });
          final SharedPreferences prefs =
              await SharedPreferences.getInstance();

          final ApiKeys keys = ApiKeys.fromPrefs(prefs);

          expect(keys.igdbClientId, equals('user_cid'));
          expect(keys.igdbAccessToken, equals('user_token'));
        });

        test('should return null for empty client ID', () async {
          SharedPreferences.setMockInitialValues(<String, Object>{
            'igdb_client_id': '',
            'igdb_access_token': 'token',
          });
          final SharedPreferences prefs =
              await SharedPreferences.getInstance();

          final ApiKeys keys = ApiKeys.fromPrefs(prefs);

          expect(keys.igdbClientId, isNull);
          expect(keys.igdbAccessToken, equals('token'));
        });

        test('should return null for empty access token', () async {
          SharedPreferences.setMockInitialValues(<String, Object>{
            'igdb_client_id': 'cid',
            'igdb_access_token': '',
          });
          final SharedPreferences prefs =
              await SharedPreferences.getInstance();

          final ApiKeys keys = ApiKeys.fromPrefs(prefs);

          expect(keys.igdbClientId, equals('cid'));
          expect(keys.igdbAccessToken, isNull);
        });

        test('should return null when no IGDB keys in prefs', () async {
          SharedPreferences.setMockInitialValues(<String, Object>{});
          final SharedPreferences prefs =
              await SharedPreferences.getInstance();

          final ApiKeys keys = ApiKeys.fromPrefs(prefs);

          expect(keys.igdbClientId, isNull);
          expect(keys.igdbAccessToken, isNull);
        });
      });

      group('all keys', () {
        test('should load all keys simultaneously', () async {
          SharedPreferences.setMockInitialValues(<String, Object>{
            'tmdb_api_key': 'tmdb_k',
            'steamgriddb_api_key': 'sgdb_k',
            'igdb_client_id': 'igdb_cid',
            'igdb_access_token': 'igdb_tok',
          });
          final SharedPreferences prefs =
              await SharedPreferences.getInstance();

          final ApiKeys keys = ApiKeys.fromPrefs(prefs);

          expect(keys.tmdbApiKey, equals('tmdb_k'));
          expect(keys.steamGridDbApiKey, equals('sgdb_k'));
          expect(keys.igdbClientId, equals('igdb_cid'));
          expect(keys.igdbAccessToken, equals('igdb_tok'));
        });

        test('should return all null when prefs empty', () async {
          SharedPreferences.setMockInitialValues(<String, Object>{});
          final SharedPreferences prefs =
              await SharedPreferences.getInstance();

          final ApiKeys keys = ApiKeys.fromPrefs(prefs);

          expect(keys.tmdbApiKey, isNull);
          expect(keys.steamGridDbApiKey, isNull);
          expect(keys.igdbClientId, isNull);
          expect(keys.igdbAccessToken, isNull);
        });
      });
    });

    group('constructor', () {
      test('should create with default null values', () {
        const ApiKeys keys = ApiKeys();

        expect(keys.tmdbApiKey, isNull);
        expect(keys.steamGridDbApiKey, isNull);
        expect(keys.igdbClientId, isNull);
        expect(keys.igdbAccessToken, isNull);
      });

      test('should create with provided values', () {
        const ApiKeys keys = ApiKeys(
          tmdbApiKey: 'tmdb',
          steamGridDbApiKey: 'sgdb',
          igdbClientId: 'cid',
          igdbAccessToken: 'tok',
        );

        expect(keys.tmdbApiKey, equals('tmdb'));
        expect(keys.steamGridDbApiKey, equals('sgdb'));
        expect(keys.igdbClientId, equals('cid'));
        expect(keys.igdbAccessToken, equals('tok'));
      });
    });
  });
}
