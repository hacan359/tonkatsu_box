import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/search/filters/year_filter.dart';
import 'package:xerabora/features/search/models/search_source.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('YearFilter', () {
    late YearFilter filter;
    late MockWidgetRef ref;
    late MockS mockL;

    setUp(() {
      filter = YearFilter();
      ref = MockWidgetRef();
      mockL = MockS();
    });

    test('key is "year"', () {
      expect(filter.key, 'year');
    });

    test('allOption has id "any" and null value', () {
      final FilterOption all = filter.allOption;

      expect(all.id, 'any');
      expect(all.label, 'Any');
      expect(all.value, isNull);
    });

    test('options starts with current year', () async {
      final List<FilterOption> options = await filter.options(ref, mockL);

      final int currentYear = DateTime.now().year;
      expect(options.first.id, currentYear.toString());
      expect(options.first.label, currentYear.toString());
      expect(options.first.value, currentYear);
    });

    test('options contains individual years from current down to 1980',
        () async {
      final List<FilterOption> options = await filter.options(ref, mockL);

      final int currentYear = DateTime.now().year;
      final int expectedYearCount = currentYear - 1980 + 1;

      for (int i = 0; i < expectedYearCount; i++) {
        final int expectedYear = currentYear - i;
        expect(options[i].id, expectedYear.toString());
        expect(options[i].value, expectedYear);
      }
    });

    test('options ends with decades 1970s and 1960s', () async {
      final List<FilterOption> options = await filter.options(ref, mockL);

      final int len = options.length;

      expect(options[len - 2].id, '1970s');
      expect(options[len - 2].label, '1970s');
      expect(options[len - 2].value, (1970, 1979));

      expect(options[len - 1].id, '1960s');
      expect(options[len - 1].label, '1960s');
      expect(options[len - 1].value, (1960, 1969));
    });

    test('total options count is correct', () async {
      final List<FilterOption> options = await filter.options(ref, mockL);

      final int currentYear = DateTime.now().year;
      final int yearCount = currentYear - 1980 + 1;
      const int decadeCount = 2;

      expect(options.length, yearCount + decadeCount);
    });

    test('year 1980 is included in individual years (retro boundary)',
        () async {
      final List<FilterOption> options = await filter.options(ref, mockL);

      final Iterable<FilterOption> year1980 =
          options.where((FilterOption o) => o.id == '1980');
      expect(year1980, hasLength(1));
      expect(year1980.first.value, 1980);
    });

    test('decade values are record tuples', () async {
      final List<FilterOption> options = await filter.options(ref, mockL);

      final FilterOption decade60 =
          options.firstWhere((FilterOption o) => o.id == '1960s');
      final (int, int) value = decade60.value! as (int, int);
      expect(value.$1, 1960);
      expect(value.$2, 1969);
    });

    test('is searchable — list is long enough to benefit from a search box',
        () {
      expect(filter.searchable, isTrue);
    });
  });
}
