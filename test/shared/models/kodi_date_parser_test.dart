// Тесты для parseKodiDateTime.

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/kodi_date_parser.dart';

void main() {
  group('parseKodiDateTime', () {
    test('null → null', () {
      expect(parseKodiDateTime(null), isNull);
    });

    test('пустая строка → null', () {
      expect(parseKodiDateTime(''), isNull);
    });

    test('строка из пробелов → null', () {
      expect(parseKodiDateTime('   '), isNull);
    });

    test('Kodi-формат YYYY-MM-DD HH:MM:SS', () {
      final DateTime? result = parseKodiDateTime('2026-04-12 22:30:11');
      expect(result, DateTime(2026, 4, 12, 22, 30, 11));
    });

    test('ISO 8601-like с T', () {
      final DateTime? result = parseKodiDateTime('2026-04-12T22:30:11');
      expect(result, DateTime(2026, 4, 12, 22, 30, 11));
    });

    test('невалидный формат → null', () {
      expect(parseKodiDateTime('not a date'), isNull);
    });

    test('только дата (без времени) → корректный DateTime', () {
      final DateTime? result = parseKodiDateTime('2026-04-12');
      expect(result, DateTime(2026, 4, 12));
    });
  });
}
