import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/core/services/whats_new_service.dart';

const String _changelog = '''
# Changelog

## [Unreleased]

### Added

- **Unreleased topic**

## [0.40.0] - 2026-07-20

### Added

- **New banner cards**

  Poster cards got a bottom banner with title and progress.

  * lib/shared/widgets/media_poster_card.dart (Foo.bar): details that
    span a second indented line.
  * lib/other.dart: more details.

### Fixed

- **Crash on import**

## [0.39.0] - 2026-07-01

### Added

- **Old topic**
''';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
  });

  WhatsNewService buildService({
    String version = '0.40.0',
    Future<String> Function()? loader,
  }) {
    return WhatsNewService(
      prefs: prefs,
      currentVersionOverride: version,
      changelogLoader: loader ?? () async => _changelog,
    );
  }

  group('WhatsNewService', () {
    group('extractSection', () {
      test('should return only the requested version section', () {
        final String? section =
            WhatsNewService.extractSection(_changelog, '0.40.0');

        expect(section, isNotNull);
        expect(section, contains('New banner cards'));
        expect(section, contains('Crash on import'));
        expect(section, isNot(contains('Unreleased topic')));
        expect(section, isNot(contains('Old topic')));
      });

      test('should handle the last section running to EOF', () {
        final String? section =
            WhatsNewService.extractSection(_changelog, '0.39.0');

        expect(section, contains('Old topic'));
      });

      test('should return null when the version has no section', () {
        expect(
          WhatsNewService.extractSection(_changelog, '9.9.9'),
          isNull,
        );
      });
    });

    group('simplifyForDisplay', () {
      test('should strip file bullets with their continuation lines', () {
        final String section =
            WhatsNewService.extractSection(_changelog, '0.40.0')!;
        final String body = WhatsNewService.simplifyForDisplay(section);

        expect(body, isNot(contains('media_poster_card.dart')));
        expect(body, isNot(contains('span a second indented line')));
        expect(body, isNot(contains('lib/other.dart')));
      });

      test('should keep topics and prose, convert headers and bullets', () {
        final String section =
            WhatsNewService.extractSection(_changelog, '0.40.0')!;
        final String body = WhatsNewService.simplifyForDisplay(section);

        expect(body, contains('**Added**'));
        expect(body, contains('**Fixed**'));
        expect(body, contains('• **New banner cards**'));
        expect(body, contains('bottom banner with title and progress'));
        expect(body, isNot(contains('\n\n\n')));
      });
    });

    group('pendingWhatsNew', () {
      test('should stay silent and remember the version on first run',
          () async {
        final WhatsNewContent? content =
            await buildService().pendingWhatsNew();

        expect(content, isNull);
        expect(prefs.getString('changelog_seen_version'), '0.40.0');
      });

      test('should return null when the version was already seen', () async {
        await prefs.setString('changelog_seen_version', '0.40.0');
        bool loaderCalled = false;

        final WhatsNewContent? content = await buildService(
          loader: () async {
            loaderCalled = true;
            return _changelog;
          },
        ).pendingWhatsNew();

        expect(content, isNull);
        expect(loaderCalled, isFalse);
      });

      test('should return the section after a version change', () async {
        await prefs.setString('changelog_seen_version', '0.39.0');

        final WhatsNewContent? content =
            await buildService().pendingWhatsNew();

        expect(content, isNotNull);
        expect(content!.version, '0.40.0');
        expect(content.body, contains('New banner cards'));
        // Not marked seen until the dialog is actually closed.
        expect(prefs.getString('changelog_seen_version'), '0.39.0');
      });

      test('should mark seen silently when the version has no section',
          () async {
        await prefs.setString('changelog_seen_version', '0.39.0');

        final WhatsNewContent? content =
            await buildService(version: '9.9.9').pendingWhatsNew();

        expect(content, isNull);
        expect(prefs.getString('changelog_seen_version'), '9.9.9');
      });

      test('should return null and keep state when the changelog fails to load',
          () async {
        await prefs.setString('changelog_seen_version', '0.39.0');

        final WhatsNewContent? content = await buildService(
          loader: () async => throw Exception('asset missing'),
        ).pendingWhatsNew();

        expect(content, isNull);
        expect(prefs.getString('changelog_seen_version'), '0.39.0');
      });
    });

    group('markSeen', () {
      test('should persist the version', () async {
        await buildService().markSeen('0.41.0');

        expect(prefs.getString('changelog_seen_version'), '0.41.0');
      });
    });
  });
}
