import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/features/search/filters/igdb_min_rating_filter.dart';
import 'package:xerabora/features/search/models/search_source.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('IgdbMinRatingFilter', () {
    late IgdbMinRatingFilter filter;
    late MockS mockL;

    setUp(() {
      filter = IgdbMinRatingFilter();
      mockL = MockS();
      when(() => mockL.browseFilterMinRating).thenReturn('Min rating');
    });

    test('key is "minRating" — binds to IGDB rating (>=)', () {
      expect(filter.key, 'minRating');
    });

    test('allOption clears the filter', () {
      expect(filter.allOption.value, isNull);
    });

    test('options use UI 1-10 scale (6/7/8/9)', () async {
      final MockWidgetRef ref = MockWidgetRef();
      final List<FilterOption> opts = await filter.options(ref, mockL);

      expect(opts.map((FilterOption o) => o.value).toList(),
          <int>[6, 7, 8, 9]);
    });
  });
}
