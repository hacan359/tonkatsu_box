// Тесты для KodiApplicationInfo.

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/kodi_application_info.dart';

void main() {
  group('KodiApplicationInfo.fromJson', () {
    test('полный ответ', () {
      final KodiApplicationInfo info =
          KodiApplicationInfo.fromJson(<String, dynamic>{
        'version': <String, dynamic>{
          'major': 21,
          'minor': 0,
          'tag': 'stable',
        },
        'name': 'Kodi',
      });

      expect(info.versionMajor, 21);
      expect(info.versionMinor, 0);
      expect(info.versionTag, 'stable');
      expect(info.name, 'Kodi');
    });

    test('без version → нули', () {
      final KodiApplicationInfo info = KodiApplicationInfo.fromJson(
        <String, dynamic>{'name': 'Kodi'},
      );
      expect(info.versionMajor, 0);
      expect(info.versionMinor, 0);
      expect(info.versionTag, isNull);
    });
  });

  group('versionString', () {
    test('stable → только "major.minor"', () {
      const KodiApplicationInfo info = KodiApplicationInfo(
        versionMajor: 21,
        versionMinor: 0,
        versionTag: 'stable',
      );
      expect(info.versionString, '21.0');
    });

    test('без tag → только "major.minor"', () {
      const KodiApplicationInfo info = KodiApplicationInfo(
        versionMajor: 20,
        versionMinor: 5,
      );
      expect(info.versionString, '20.5');
    });

    test('beta → с суффиксом', () {
      const KodiApplicationInfo info = KodiApplicationInfo(
        versionMajor: 22,
        versionMinor: 0,
        versionTag: 'beta',
      );
      expect(info.versionString, '22.0 beta');
    });
  });
}
