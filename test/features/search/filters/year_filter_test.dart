import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/features/search/filters/year_filter.dart';
import 'package:xerabora/features/search/models/search_source.dart';
import 'package:xerabora/l10n/app_localizations.dart';

class MockWidgetRef extends Mock implements WidgetRef {}

class MockS extends Mock implements S {}

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

    test('options contains individual years from current to 2000', () async {
      final List<FilterOption> options = await filter.options(ref, mockL);

      final int currentYear = DateTime.now().year;
      final int expectedYearCount = currentYear - 2000 + 1;

      // Первые N элементов — отдельные годы
      for (int i = 0; i < expectedYearCount; i++) {
        final int expectedYear = currentYear - i;
        expect(options[i].id, expectedYear.toString());
        expect(options[i].value, expectedYear);
      }
    });

    test('options ends with decades 1990s, 1980s, 1970s', () async {
      final List<FilterOption> options = await filter.options(ref, mockL);

      final int len = options.length;

      // Последние 3 — декады
      expect(options[len - 3].id, '1990s');
      expect(options[len - 3].label, '1990s');
      expect(options[len - 3].value, (1990, 1999));

      expect(options[len - 2].id, '1980s');
      expect(options[len - 2].label, '1980s');
      expect(options[len - 2].value, (1980, 1989));

      expect(options[len - 1].id, '1970s');
      expect(options[len - 1].label, '1970s');
      expect(options[len - 1].value, (1970, 1979));
    });

    test('total options count is correct', () async {
      final List<FilterOption> options = await filter.options(ref, mockL);

      final int currentYear = DateTime.now().year;
      final int yearCount = currentYear - 2000 + 1;
      const int decadeCount = 3;

      expect(options.length, yearCount + decadeCount);
    });

    test('year 2000 is included in individual years', () async {
      final List<FilterOption> options = await filter.options(ref, mockL);

      final Iterable<FilterOption> year2000 =
          options.where((FilterOption o) => o.id == '2000');
      expect(year2000, hasLength(1));
      expect(year2000.first.value, 2000);
    });

    test('decade values are record tuples', () async {
      final List<FilterOption> options = await filter.options(ref, mockL);

      final FilterOption decade90 =
          options.firstWhere((FilterOption o) => o.id == '1990s');
      final (int, int) value = decade90.value! as (int, int);
      expect(value.$1, 1990);
      expect(value.$2, 1999);
    });
  });
}
