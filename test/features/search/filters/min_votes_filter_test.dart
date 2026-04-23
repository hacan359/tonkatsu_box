import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/features/search/filters/min_votes_filter.dart';
import 'package:xerabora/features/search/models/search_source.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('MinVotesFilter', () {
    late MinVotesFilter filter;
    late MockS mockL;

    setUp(() {
      filter = MinVotesFilter();
      mockL = MockS();
      when(() => mockL.browseFilterMinVotes).thenReturn('Min votes');
    });

    test('key is "minVotes" — binds to TMDB vote_count.gte', () {
      expect(filter.key, 'minVotes');
    });

    test('allOption clears the filter (null value)', () {
      expect(filter.allOption.value, isNull);
    });

    test('options expose 100/500/1000/5000 thresholds as ints', () async {
      final MockWidgetRef ref = MockWidgetRef();
      final List<FilterOption> opts = await filter.options(ref, mockL);

      expect(opts.map((FilterOption o) => o.value).toList(),
          <int>[100, 500, 1000, 5000]);
    });
  });
}
