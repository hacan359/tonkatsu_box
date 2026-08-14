import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/widgets/hero_image.dart';

void main() {
  group('heroImageProviderFor', () {
    test('should return a FileImage for a filesystem path on io', () {
      final ImageProvider provider =
          heroImageProviderFor('/data/collections/hero_1_2.jpg');

      expect(provider, isA<FileImage>());
      expect(
        (provider as FileImage).file.path,
        '/data/collections/hero_1_2.jpg',
      );
    });
  });
}
