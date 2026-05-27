import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/shared/utils/duration_formatter.dart';

import '../../helpers/test_helpers.dart';

void main() {
  // The exact localized wording is not asserted (that would couple to copy);
  // instead we verify which bucket is chosen and the computed unit count.
  group('formatDuration', () {
    late MockS s;

    setUp(() {
      s = MockS();
      when(() => s.durationLessThanDay).thenReturn('LT_DAY');
      when(() => s.durationOneDay).thenReturn('ONE_DAY');
      when(() => s.durationDays(any())).thenReturn('DAYS');
      when(() => s.durationWeeks(any())).thenReturn('WEEKS');
      when(() => s.durationMonths(any())).thenReturn('MONTHS');
      when(() => s.durationYears(any())).thenReturn('YEARS');
    });

    test('0 days -> less than a day', () {
      expect(formatDuration(Duration.zero, s), 'LT_DAY');
      verify(() => s.durationLessThanDay).called(1);
    });

    test('1 day -> single-day form', () {
      expect(formatDuration(const Duration(days: 1), s), 'ONE_DAY');
    });

    test('under a week -> days with exact count', () {
      expect(formatDuration(const Duration(days: 3), s), 'DAYS');
      verify(() => s.durationDays(3)).called(1);
    });

    test('a week or more -> weeks, rounded', () {
      formatDuration(const Duration(days: 14), s);
      verify(() => s.durationWeeks(2)).called(1);

      formatDuration(const Duration(days: 20), s); // 20/7 = 2.857 -> 3
      verify(() => s.durationWeeks(3)).called(1);
    });

    test('a month or more -> months, rounded', () {
      formatDuration(const Duration(days: 60), s);
      verify(() => s.durationMonths(2)).called(1);
    });

    test('a year or more -> years with one decimal', () {
      formatDuration(const Duration(days: 400), s); // 400/365 = 1.095 -> "1.1"
      verify(() => s.durationYears('1.1')).called(1);
    });

    test('boundary: 6 days is still days, 7 days flips to weeks', () {
      formatDuration(const Duration(days: 6), s);
      verify(() => s.durationDays(6)).called(1);

      formatDuration(const Duration(days: 7), s);
      verify(() => s.durationWeeks(1)).called(1);
    });
  });

  group('formatCompletionTime', () {
    test('wraps the formatted duration with the completion prefix', () {
      final MockS s = MockS();
      when(() => s.durationWeeks(any())).thenReturn('2 weeks');
      when(() => s.activityDatesCompletionTime(any()))
          .thenReturn('Completed in 2 weeks');

      final String result = formatCompletionTime(const Duration(days: 14), s);

      expect(result, 'Completed in 2 weeks');
      verify(() => s.activityDatesCompletionTime('2 weeks')).called(1);
    });
  });
}
