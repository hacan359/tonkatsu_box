import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonkatsu_box/core/services/storage_root.dart';

void main() {
  late Directory tempDir;
  late String defaultDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('storage_root_test');
    defaultDir = p.join(tempDir.path, 'default_root');
    await Directory(defaultDir).create(recursive: true);
    StorageRoot.defaultPathProvider = () async => defaultDir;
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() async {
    StorageRoot.defaultPathProvider = null;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('StorageRoot', () {
    group('resolve', () {
      test('returns default path when no custom dir is set', () async {
        final StorageRootResolution result = await StorageRoot.resolve();

        expect(result.path, defaultDir);
        expect(result.isCustom, isFalse);
        expect(result.fellBack, isFalse);
      });

      test('returns custom dir when set and holding data', () async {
        final String customDir = p.join(tempDir.path, 'custom_root');
        await Directory(customDir).create(recursive: true);
        await File(p.join(customDir, 'tonkatsu_box.db')).writeAsString('db');
        SharedPreferences.setMockInitialValues(<String, Object>{
          StorageRoot.prefsKey: customDir,
        });

        final StorageRootResolution result = await StorageRoot.resolve();

        expect(result.path, customDir);
        expect(result.isCustom, isTrue);
        expect(result.fellBack, isFalse);
      });

      test('accepts a custom dir with a profiles.json layout', () async {
        final String customDir = p.join(tempDir.path, 'custom_root');
        await Directory(customDir).create(recursive: true);
        await File(p.join(customDir, 'profiles.json')).writeAsString('{}');
        SharedPreferences.setMockInitialValues(<String, Object>{
          StorageRoot.prefsKey: customDir,
        });

        final StorageRootResolution result = await StorageRoot.resolve();

        expect(result.path, customDir);
        expect(result.isCustom, isTrue);
      });

      test('falls back to default when custom dir exists but is empty',
          () async {
        final String customDir = p.join(tempDir.path, 'custom_root');
        await Directory(customDir).create(recursive: true);
        SharedPreferences.setMockInitialValues(<String, Object>{
          StorageRoot.prefsKey: customDir,
        });

        final StorageRootResolution result = await StorageRoot.resolve();

        expect(result.path, defaultDir);
        expect(result.isCustom, isFalse);
        expect(result.fellBack, isTrue);
      });

      test('falls back to default when custom dir is missing', () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          StorageRoot.prefsKey: p.join(tempDir.path, 'gone'),
        });

        final StorageRootResolution result = await StorageRoot.resolve();

        expect(result.path, defaultDir);
        expect(result.isCustom, isFalse);
        expect(result.fellBack, isTrue);
      });

      test('treats empty pref value as unset', () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          StorageRoot.prefsKey: '',
        });

        final StorageRootResolution result = await StorageRoot.resolve();

        expect(result.path, defaultDir);
        expect(result.isCustom, isFalse);
        expect(result.fellBack, isFalse);
      });
    });

    group('setCustomDir / clearCustomDir', () {
      test('round-trips through preferences', () async {
        final String customDir = p.join(tempDir.path, 'custom_root');
        await Directory(customDir).create(recursive: true);
        await File(p.join(customDir, 'tonkatsu_box.db')).writeAsString('db');

        await StorageRoot.setCustomDir(customDir);
        expect(await StorageRoot.customDir(), customDir);
        expect((await StorageRoot.resolve()).path, customDir);

        await StorageRoot.clearCustomDir();
        expect(await StorageRoot.customDir(), isNull);
        expect((await StorageRoot.resolve()).path, defaultDir);
      });
    });

    group('hasData', () {
      test('returns false for a missing directory', () {
        expect(StorageRoot.hasData(p.join(tempDir.path, 'missing')), isFalse);
      });

      test('returns false for an empty directory', () {
        expect(StorageRoot.hasData(tempDir.path), isFalse);
      });

      test('returns true when a database file is present', () async {
        await File(p.join(tempDir.path, 'tonkatsu_box.db'))
            .writeAsString('db');

        expect(StorageRoot.hasData(tempDir.path), isTrue);
      });

      test('returns true when profiles.json is present', () async {
        await File(p.join(tempDir.path, 'profiles.json')).writeAsString('{}');

        expect(StorageRoot.hasData(tempDir.path), isTrue);
      });
    });

    group('isWritable', () {
      test('returns true for a writable directory', () async {
        expect(await StorageRoot.isWritable(tempDir.path), isTrue);
      });

      test('returns false for a non-existent directory', () async {
        expect(
          await StorageRoot.isWritable(p.join(tempDir.path, 'missing')),
          isFalse,
        );
      });

      test('does not leave the probe file behind', () async {
        await StorageRoot.isWritable(tempDir.path);

        final List<FileSystemEntity> entries =
            Directory(tempDir.path).listSync();
        expect(
          entries.where((FileSystemEntity e) =>
              p.basename(e.path).contains('probe')),
          isEmpty,
        );
      });
    });

    group('copyDataTo', () {
      test('copies profiles.json and per-profile DB files', () async {
        final String source = p.join(tempDir.path, 'source');
        final String target = p.join(tempDir.path, 'target');
        await File(p.join(source, 'profiles.json'))
            .create(recursive: true)
            .then((File f) => f.writeAsString('{"profiles": []}'));
        final String profileDir = p.join(source, 'profiles', 'default');
        await File(p.join(profileDir, 'tonkatsu_box.db'))
            .create(recursive: true)
            .then((File f) => f.writeAsString('db'));
        await File(p.join(profileDir, 'tonkatsu_box.db-wal'))
            .writeAsString('wal');

        await StorageRoot.copyDataTo(source, target);

        expect(
          File(p.join(target, 'profiles.json')).existsSync(),
          isTrue,
        );
        expect(
          File(p.join(target, 'profiles', 'default', 'tonkatsu_box.db'))
              .readAsStringSync(),
          'db',
        );
        expect(
          File(p.join(target, 'profiles', 'default', 'tonkatsu_box.db-wal'))
              .readAsStringSync(),
          'wal',
        );
      });

      test('skips image_cache contents', () async {
        final String source = p.join(tempDir.path, 'source');
        final String target = p.join(tempDir.path, 'target');
        await File(p.join(source, 'profiles.json'))
            .create(recursive: true)
            .then((File f) => f.writeAsString('{}'));
        final String profileDir = p.join(source, 'profiles', 'default');
        await File(p.join(profileDir, 'tonkatsu_box.db'))
            .create(recursive: true)
            .then((File f) => f.writeAsString('db'));
        await File(p.join(profileDir, 'image_cache', 'poster', 'a.jpg'))
            .create(recursive: true)
            .then((File f) => f.writeAsString('img'));

        await StorageRoot.copyDataTo(source, target);

        expect(
          Directory(p.join(target, 'profiles', 'default', 'image_cache'))
              .existsSync(),
          isFalse,
        );
      });

      test('copies a root-level DB when profiles are not initialised',
          () async {
        final String source = p.join(tempDir.path, 'source');
        final String target = p.join(tempDir.path, 'target');
        await File(p.join(source, 'tonkatsu_box.db'))
            .create(recursive: true)
            .then((File f) => f.writeAsString('db'));

        await StorageRoot.copyDataTo(source, target);

        expect(
          File(p.join(target, 'tonkatsu_box.db')).readAsStringSync(),
          'db',
        );
        expect(
          File(p.join(target, 'profiles.json')).existsSync(),
          isFalse,
        );
      });

      test('tolerates a source with no database at all', () async {
        final String source = p.join(tempDir.path, 'source');
        final String target = p.join(tempDir.path, 'target');
        await Directory(source).create(recursive: true);

        await StorageRoot.copyDataTo(source, target);

        expect(Directory(target).existsSync(), isTrue);
        expect(Directory(target).listSync(), isEmpty);
      });
    });
  });
}
