import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:tonkatsu_box/core/services/storage_volumes.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('storage_volumes_test');
    StorageVolumes.storageRoot = tempDir.path;
  });

  tearDown(() async {
    StorageVolumes.storageRoot = '/storage';
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('StorageVolumes', () {
    group('detect', () {
      test('finds the primary volume', () async {
        await Directory(p.join(tempDir.path, 'emulated', '0'))
            .create(recursive: true);

        final List<StorageVolume> volumes = StorageVolumes.detect();

        expect(volumes, hasLength(1));
        expect(volumes.first.path, p.join(tempDir.path, 'emulated', '0'));
        expect(volumes.first.isPrimary, isTrue);
      });

      test('finds removable volumes after the primary', () async {
        await Directory(p.join(tempDir.path, 'emulated', '0'))
            .create(recursive: true);
        await Directory(p.join(tempDir.path, 'B1C2-3D4E')).create();
        await Directory(p.join(tempDir.path, 'A1B2-3C4D')).create();

        final List<StorageVolume> volumes = StorageVolumes.detect();

        expect(volumes, hasLength(3));
        expect(volumes.first.isPrimary, isTrue);
        expect(
          volumes.map((StorageVolume v) => p.basename(v.path)).toList(),
          <String>['0', 'A1B2-3C4D', 'B1C2-3D4E'],
        );
        expect(volumes[1].isPrimary, isFalse);
      });

      test('skips the self alias and the emulated container', () async {
        await Directory(p.join(tempDir.path, 'emulated', '0'))
            .create(recursive: true);
        await Directory(p.join(tempDir.path, 'self')).create();

        final List<StorageVolume> volumes = StorageVolumes.detect();

        expect(volumes, hasLength(1));
        expect(volumes.first.isPrimary, isTrue);
      });

      test('ignores plain files under the storage root', () async {
        await Directory(p.join(tempDir.path, 'emulated', '0'))
            .create(recursive: true);
        await File(p.join(tempDir.path, 'mount.log')).writeAsString('x');

        final List<StorageVolume> volumes = StorageVolumes.detect();

        expect(volumes, hasLength(1));
      });

      test('returns empty when the storage root does not exist', () {
        StorageVolumes.storageRoot = p.join(tempDir.path, 'missing');

        expect(StorageVolumes.detect(), isEmpty);
      });
    });
  });
}
