import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:tonkatsu_box/core/services/collection_hero_service.dart';

void main() {
  late Directory tempDir;
  late String legacyDir;
  late String newDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hero_migrate_test');
    legacyDir = p.join(tempDir.path, 'legacy');
    newDir = p.join(tempDir.path, 'new');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> writeFile(String path, String content) async {
    await File(path).create(recursive: true);
    await File(path).writeAsString(content);
  }

  group('CollectionHeroService.migrateLegacyHeroImages', () {
    test('moves hero files from legacy into the new dir', () async {
      await writeFile(p.join(legacyDir, 'hero_1_0.png'), 'a');
      await Directory(newDir).create(recursive: true);

      await CollectionHeroService.migrateLegacyHeroImages(
        legacyDir: legacyDir,
        newDir: newDir,
      );

      expect(File(p.join(newDir, 'hero_1_0.png')).readAsStringSync(), 'a');
      expect(File(p.join(legacyDir, 'hero_1_0.png')).existsSync(), isFalse);
    });

    test('does not clobber a file already present in the new dir', () async {
      await writeFile(p.join(legacyDir, 'hero_1_0.png'), 'old');
      await writeFile(p.join(newDir, 'hero_1_0.png'), 'new');

      await CollectionHeroService.migrateLegacyHeroImages(
        legacyDir: legacyDir,
        newDir: newDir,
      );

      expect(File(p.join(newDir, 'hero_1_0.png')).readAsStringSync(), 'new');
    });

    test('ignores files that are not hero images', () async {
      await writeFile(p.join(legacyDir, 'other.txt'), 'x');
      await Directory(newDir).create(recursive: true);

      await CollectionHeroService.migrateLegacyHeroImages(
        legacyDir: legacyDir,
        newDir: newDir,
      );

      expect(File(p.join(newDir, 'other.txt')).existsSync(), isFalse);
      expect(File(p.join(legacyDir, 'other.txt')).existsSync(), isTrue);
    });

    test('removes the legacy dir once drained', () async {
      await writeFile(p.join(legacyDir, 'hero_1_0.png'), 'a');
      await Directory(newDir).create(recursive: true);

      await CollectionHeroService.migrateLegacyHeroImages(
        legacyDir: legacyDir,
        newDir: newDir,
      );

      expect(Directory(legacyDir).existsSync(), isFalse);
    });

    test('is a no-op when the legacy dir is absent', () async {
      await Directory(newDir).create(recursive: true);

      await CollectionHeroService.migrateLegacyHeroImages(
        legacyDir: legacyDir,
        newDir: newDir,
      );

      expect(Directory(newDir).listSync(), isEmpty);
    });

    test('is a no-op when legacy equals new', () async {
      await writeFile(p.join(legacyDir, 'hero_1_0.png'), 'a');

      await CollectionHeroService.migrateLegacyHeroImages(
        legacyDir: legacyDir,
        newDir: legacyDir,
      );

      expect(File(p.join(legacyDir, 'hero_1_0.png')).readAsStringSync(), 'a');
    });
  });
}
