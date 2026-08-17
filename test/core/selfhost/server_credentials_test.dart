import 'dart:convert';

import 'package:core/api/credential_names.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/selfhost/server_credentials.dart';
import 'package:tonkatsu_box/features/settings/providers/settings_provider.dart';

List<int> config(Map<String, Object?> body) => utf8.encode(jsonEncode(body));

void main() {
  group('credentialsFromConfig', () {
    test('should rename a prefs key to the name the proxy uses', () {
      final Map<String, String> found = credentialsFromConfig(
        config(<String, Object?>{'tmdb_api_key': 'abc'}),
      );

      expect(found, <String, String>{CredentialNames.tmdb: 'abc'});
    });

    test('should ignore settings that are not credentials', () {
      final Map<String, String> found = credentialsFromConfig(
        config(<String, Object?>{
          'tmdb_api_key': 'abc',
          'theme_mode': 'dark',
          'app_language': 'ru',
        }),
      );

      expect(found.keys, <String>[CredentialNames.tmdb]);
    });

    test('should skip an empty value rather than clear the server', () {
      final Map<String, String> found = credentialsFromConfig(
        config(<String, Object?>{'tmdb_api_key': '', 'ra_username': 'me'}),
      );

      expect(found, <String, String>{CredentialNames.raUsername: 'me'});
    });

    test('should skip a value that is not a string', () {
      final Map<String, String> found = credentialsFromConfig(
        config(<String, Object?>{'tmdb_api_key': 42}),
      );

      expect(found, isEmpty);
    });

    test('should return nothing for a file that is not a config', () {
      expect(credentialsFromConfig(utf8.encode('[1,2,3]')), isEmpty);
    });
  });

  group('kCredentialToConfigKey', () {
    test('should invert the map without losing a name', () {
      expect(kCredentialToConfigKey.length, kConfigKeyToCredential.length);
      kConfigKeyToCredential.forEach((String prefKey, String name) {
        expect(kCredentialToConfigKey[name], prefKey);
      });
    });

    test('should only name credentials the server knows', () {
      expect(
        kConfigKeyToCredential.values.every(CredentialNames.all.contains),
        isTrue,
      );
    });

    test('should spell the ScreenScraper keys the way the prefs do', () {
      // The map repeats the pref names as literals so core stays off the
      // settings layer; these four are the pair the proxy refuses without.
      expect(
        kConfigKeyToCredential[SettingsKeys.screenScraperDevId],
        CredentialNames.ssDevId,
      );
      expect(
        kConfigKeyToCredential[SettingsKeys.screenScraperDevPassword],
        CredentialNames.ssDevPassword,
      );
      expect(
        kConfigKeyToCredential[SettingsKeys.screenScraperSsid],
        CredentialNames.ssSsid,
      );
      expect(
        kConfigKeyToCredential[SettingsKeys.screenScraperSspassword],
        CredentialNames.ssSspassword,
      );
    });
  });
}
