import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/features/search/filters/min_rating_filter.dart';
import 'package:xerabora/features/search/models/search_source.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('MinRatingFilter', () {
    late MinRatingFilter filter;
    late MockS mockL;

    setUp(() {
      filter = MinRatingFilter();
      mockL = MockS();
      when(() => mockL.browseFilterMinRating).thenReturn('Min rating');
    });

    test('key is "minRating" — binds to TMDB vote_average.gte', () {
      expect(filter.key, 'minRating');
    });

    test('single-select — only one threshold active at a time', () {
      expect(filter.multiSelect, isFalse);
    });

    test('allOption carries null value so the filter can be cleared', () {
      expect(filter.allOption.value, isNull);
    });

    test('options expose 6+/7+/8+/9+ with double values in TMDB 0-10 scale',
        () async {
      final MockWidgetRef ref = MockWidgetRef();
      final List<FilterOption> opts = await filter.options(ref, mockL);

      expect(opts, hasLength(4));
      expect(opts.map((FilterOption o) => o.id).toList(),
          <String>['6', '7', '8', '9']);
      expect(opts.map((FilterOption o) => o.value).toList(),
          <double>[6.0, 7.0, 8.0, 9.0]);
    });
  });
}
