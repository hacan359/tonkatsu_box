import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/core/services/whats_new_service.dart';

const String _notes = '''
# 0.40.0

**Big highlight.** Poster cards got a bottom banner.

- Bullet one
- Bullet two

## Details

Some prose line.

# 0.39.0

- Old bullet
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
      notesLoader: loader ?? () async => _notes,
    );
  }

  group('WhatsNewService', () {
    group('extractSection', () {
      test('should return only the requested version section', () {
        final String? section =
            WhatsNewService.extractSection(_notes, '0.40.0');

        expect(section, isNotNull);
        expect(section, contains('Big highlight'));
        expect(section, contains('Bullet two'));
        expect(section, isNot(contains('Old bullet')));
      });

      test('should handle the last section running to EOF', () {
        final String? section =
            WhatsNewService.extractSection(_notes, '0.39.0');

        expect(section, contains('Old bullet'));
      });

      test('should return null when the version has no section', () {
        expect(WhatsNewService.extractSection(_notes, '9.9.9'), isNull);
      });
    });

    group('formatForDisplay', () {
      test('should convert bullets and sub-headings, keep prose', () {
        final String section =
            WhatsNewService.extractSection(_notes, '0.40.0')!;
        final String body = WhatsNewService.formatForDisplay(section);

        expect(body, contains('• Bullet one'));
        expect(body, contains('**Details**'));
        expect(body, contains('Some prose line.'));
        expect(body, contains('**Big highlight.**'));
        expect(body, isNot(contains('## ')));
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
            return _notes;
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
        expect(content.body, contains('Big highlight'));
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

      test('should return null and keep state when the notes fail to load',
          () async {
        await prefs.setString('changelog_seen_version', '0.39.0');

        final WhatsNewContent? content = await buildService(
          loader: () async => throw Exception('asset missing'),
        ).pendingWhatsNew();

        expect(content, isNull);
        expect(prefs.getString('changelog_seen_version'), '0.39.0');
      });
    });

    group('previewLatest', () {
      test('should return the first section regardless of app version',
          () async {
        await prefs.setString('changelog_seen_version', '0.40.0');

        final WhatsNewContent? content =
            await buildService(version: '0.38.0').previewLatest();

        expect(content, isNotNull);
        expect(content!.version, '0.40.0');
        expect(content.body, contains('Big highlight'));
        // Preview never touches the seen marker.
        expect(prefs.getString('changelog_seen_version'), '0.40.0');
      });

      test('should return null when the file has no version headings',
          () async {
        final WhatsNewContent? content = await buildService(
          loader: () async => 'just prose, no headings',
        ).previewLatest();

        expect(content, isNull);
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
