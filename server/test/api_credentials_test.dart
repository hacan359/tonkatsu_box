import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tonkatsu_server/src/api_credentials.dart';

void main() {
  late Directory dataDir;

  setUp(() {
    dataDir = Directory.systemTemp.createTempSync('tonkatsu_keys');
  });

  tearDown(() {
    if (dataDir.existsSync()) dataDir.deleteSync(recursive: true);
  });

  void writeKeys(String content) {
    File(p.join(dataDir.path, 'keys.json')).writeAsStringSync(content);
  }

  group('ApiCredentials.load', () {
    test('should report nothing configured without a keys file', () {
      final ApiCredentials credentials =
          ApiCredentials.load(dataDir: dataDir.path);

      expect(credentials.has(CredentialNames.tmdb), isFalse);
      expect(credentials.values, isEmpty);
    });

    test('should read values from the keys file', () {
      writeKeys(jsonEncode(<String, String>{CredentialNames.tmdb: 'from-file'}));

      final ApiCredentials credentials =
          ApiCredentials.load(dataDir: dataDir.path);

      expect(credentials[CredentialNames.tmdb], 'from-file');
    });

    test('should let the environment override the keys file', () {
      writeKeys(jsonEncode(<String, String>{CredentialNames.tmdb: 'from-file'}));

      final ApiCredentials credentials = ApiCredentials.load(
        dataDir: dataDir.path,
        env: <String, String>{'TONKATSU_KEY_TMDB': 'from-env'},
      );

      expect(credentials[CredentialNames.tmdb], 'from-env');
    });

    test('should ignore an empty value rather than send an empty key', () {
      final ApiCredentials credentials = ApiCredentials.load(
        env: <String, String>{'TONKATSU_KEY_TMDB': ''},
      );

      expect(credentials[CredentialNames.tmdb], isNull);
      expect(credentials.has(CredentialNames.tmdb), isFalse);
    });

    test('should refuse a keys file that is not JSON', () {
      writeKeys('{not json');

      expect(
        () => ApiCredentials.load(dataDir: dataDir.path),
        throwsA(isA<ApiCredentialsException>()),
      );
    });

    test('should refuse a keys file that is not an object', () {
      writeKeys(jsonEncode(<String>['tmdb']));

      expect(
        () => ApiCredentials.load(dataDir: dataDir.path),
        throwsA(isA<ApiCredentialsException>()),
      );
    });

    test('should expose a stored value so the settings screen can show it', () {
      writeKeys(jsonEncode(<String, String>{CredentialNames.tmdb: 'tmdb-value-42'}));

      final ApiCredentials credentials =
          ApiCredentials.load(dataDir: dataDir.path);

      expect(credentials.values[CredentialNames.tmdb], 'tmdb-value-42');
    });
  });
}
