import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/core/services/app_http_overrides.dart';

void main() {
  group('AppHttpOverrides', () {
    test('createHttpClient sets the descriptive User-Agent', () {
      final HttpClient client =
          AppHttpOverrides().createHttpClient(null);
      addTearDown(() => client.close(force: true));

      expect(client.userAgent, AppHttpOverrides.userAgent);
    });

    test('userAgent identifies the app and a contact URL', () {
      expect(AppHttpOverrides.userAgent, contains('TonkatsuBox'));
      expect(AppHttpOverrides.userAgent, contains('github.com'));
      expect(AppHttpOverrides.userAgent, isNot(contains('Dart/')));
    });
  });
}
