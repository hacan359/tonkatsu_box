import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/utils/date_format_preset.dart';

void main() {
  group('DateFormatPreset', () {
    group('fromId', () {
      test('should return matching preset for known id', () {
        expect(
          DateFormatPreset.fromId('month_day_year'),
          DateFormatPreset.monthDayYear,
        );
        expect(DateFormatPreset.fromId('iso'), DateFormatPreset.iso);
        expect(DateFormatPreset.fromId('dmy_dot'), DateFormatPreset.dmyDot);
        expect(DateFormatPreset.fromId('mdy_slash'), DateFormatPreset.mdySlash);
        expect(DateFormatPreset.fromId('dmy_word'), DateFormatPreset.dmyWord);
      });

      test('should fall back to monthDayYear for unknown id', () {
        expect(
          DateFormatPreset.fromId('bogus'),
          DateFormatPreset.monthDayYear,
        );
      });

      test('should fall back to monthDayYear for null id', () {
        expect(
          DateFormatPreset.fromId(null),
          DateFormatPreset.monthDayYear,
        );
      });
    });

    group('format', () {
      final DateTime sample = DateTime(2026, 5, 25);

      test('monthDayYear preset produces MMM d, yyyy', () {
        expect(
          DateFormatPreset.monthDayYear.format(sample, locale: 'en_US'),
          'May 25, 2026',
        );
      });

      test('iso preset produces yyyy-MM-dd', () {
        expect(
          DateFormatPreset.iso.format(sample, locale: 'en_US'),
          '2026-05-25',
        );
      });

      test('dmyDot preset produces dd.MM.yyyy', () {
        expect(
          DateFormatPreset.dmyDot.format(sample, locale: 'en_US'),
          '25.05.2026',
        );
      });

      test('mdySlash preset produces MM/dd/yyyy', () {
        expect(
          DateFormatPreset.mdySlash.format(sample, locale: 'en_US'),
          '05/25/2026',
        );
      });

      test('dmyWord preset includes localized month name', () {
        final String formatted =
            DateFormatPreset.dmyWord.format(sample, locale: 'en_US');
        expect(formatted, contains('25'));
        expect(formatted, contains('2026'));
        expect(formatted, contains('May'));
      });
    });
  });
}
