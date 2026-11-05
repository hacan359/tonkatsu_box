import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:tonkatsu_box/core/services/image_extension.dart';
import 'package:tonkatsu_box/core/services/wallpaper_service.dart';

void main() {
  late Directory tmp;
  late String wallpaperDir;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('wallpaper_test_');
    wallpaperDir = p.join(tmp.path, WallpaperService.folderName);
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  File source(String name) =>
      File(p.join(tmp.path, name))..writeAsBytesSync(<int>[1, 2, 3]);

  WallpaperService service(String? picked) => WallpaperService(
    resolveDir: () async => wallpaperDir,
    pickImage: (String _) async => picked,
  );

  group('WallpaperService', () {
    group('pickAndSave', () {
      test('should return null when the picker is cancelled', () async {
        expect(await service(null).pickAndSave(dialogTitle: 't'), isNull);
        expect(Directory(wallpaperDir).existsSync(), isFalse);
      });

      test('should copy the image into the wallpaper folder', () async {
        final File original = source('photo.JPG');

        final String? saved = await service(
          original.path,
        ).pickAndSave(dialogTitle: 't');

        expect(saved, isNotNull);
        expect(p.isWithin(wallpaperDir, saved!), isTrue);
        expect(p.extension(saved), '.jpg');
        expect(File(saved).readAsBytesSync(), <int>[1, 2, 3]);
        expect(original.existsSync(), isTrue);
      });

      test(
        'should delete the previous copy only after a successful copy',
        () async {
          final WallpaperService first = service(source('a.png').path);
          final String old = (await first.pickAndSave(dialogTitle: 't'))!;

          final String? saved = await service(
            source('b.png').path,
          ).pickAndSave(dialogTitle: 't', oldPath: old);

          expect(File(old).existsSync(), isFalse);
          expect(File(saved!).existsSync(), isTrue);
        },
      );

      test(
        'should throw and keep the previous copy when the copy fails',
        () async {
          final String old = (await service(
            source('a.png').path,
          ).pickAndSave(dialogTitle: 't'))!;

          await expectLater(
            service(
              p.join(tmp.path, 'missing.png'),
            ).pickAndSave(dialogTitle: 't', oldPath: old),
            throwsA(isA<WallpaperSaveException>()),
          );
          expect(File(old).existsSync(), isTrue);
        },
      );
    });

    group('delete', () {
      test('should never delete a file outside the wallpaper folder', () async {
        final File outside = source('keep.png');

        await service(null).delete(outside.path);

        expect(outside.existsSync(), isTrue);
      });

      test('should ignore null and missing paths', () async {
        await service(null).delete(null);
        await service(null).delete(p.join(wallpaperDir, 'gone.png'));
      });
    });
  });

  group('sanitizeImageExtension', () {
    test('should keep known image extensions case-insensitively', () {
      expect(sanitizeImageExtension('WEBP'), 'webp');
    });

    test('should fall back to png for unknown or crafted extensions', () {
      expect(sanitizeImageExtension('exe'), 'png');
      expect(sanitizeImageExtension(''), 'png');
      expect(sanitizeImageExtension('../jpg'), 'jpg');
    });
  });
}
