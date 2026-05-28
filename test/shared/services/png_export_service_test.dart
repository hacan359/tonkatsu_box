import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/services/png_export_service.dart';

void main() {
  group('sanitizeFileName', () {
    test('should keep word chars, hyphens, spaces as-is', () {
      expect(sanitizeFileName('My Collection 2024'), 'My Collection 2024');
      expect(sanitizeFileName('top-100'), 'top-100');
    });

    test('should replace path separators and dots with underscore', () {
      expect(sanitizeFileName('../etc/passwd'), '___etc_passwd');
      expect(sanitizeFileName('foo/bar'), 'foo_bar');
      expect(sanitizeFileName('a.b.c'), 'a_b_c');
    });

    test('should replace other punctuation', () {
      expect(sanitizeFileName('A|B?C*'), 'A_B_C_');
    });

    test('should trim leading and trailing whitespace', () {
      expect(sanitizeFileName('  padded  '), 'padded');
    });

    test('should keep Cyrillic letters', () {
      // With \p{L}/\p{N} the regex preserves non-ASCII letters.
      expect(sanitizeFileName('Желаемое'), 'Желаемое');
      expect(sanitizeFileName('Топ 100'), 'Топ 100');
    });

    test('should keep Japanese / CJK letters', () {
      expect(sanitizeFileName('好きなゲーム'), '好きなゲーム');
    });
  });

  group('stripPngExtension', () {
    test('should remove .png suffix case-insensitively', () {
      expect(stripPngExtension('foo.png'), 'foo');
      expect(stripPngExtension('foo.PNG'), 'foo');
      expect(stripPngExtension('image.Png'), 'image');
    });

    test('should leave names without .png suffix untouched', () {
      expect(stripPngExtension('foo'), 'foo');
      expect(stripPngExtension('foo.jpg'), 'foo.jpg');
      expect(stripPngExtension(''), '');
    });
  });

  group('ensurePngExtension', () {
    test('should append .png when missing', () {
      expect(ensurePngExtension('/tmp/foo'), '/tmp/foo.png');
      expect(ensurePngExtension('image'), 'image.png');
    });

    test('should keep .png unchanged regardless of case', () {
      expect(ensurePngExtension('/tmp/foo.png'), '/tmp/foo.png');
      expect(ensurePngExtension('/tmp/foo.PNG'), '/tmp/foo.PNG');
      expect(ensurePngExtension('image.Png'), 'image.Png');
    });

    test('should not strip pre-existing extensions other than png', () {
      // ".jpg" is not ".png" — we still append rather than replace, since the
      // user explicitly typed it. This documents current behaviour.
      expect(ensurePngExtension('image.jpg'), 'image.jpg.png');
    });

    test('should handle empty and minimal paths', () {
      expect(ensurePngExtension(''), '.png');
      expect(ensurePngExtension('.png'), '.png');
    });
  });
}
