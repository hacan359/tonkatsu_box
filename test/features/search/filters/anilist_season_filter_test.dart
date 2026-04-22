import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/features/search/filters/anilist_season_filter.dart';
import 'package:xerabora/features/search/models/search_source.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('AniListSeasonFilter', () {
    late AniListSeasonFilter filter;
    late MockS mockL;

    setUp(() {
      filter = AniListSeasonFilter();
      mockL = MockS();
      when(() => mockL.browseFilterSeason).thenReturn('Season');
      when(() => mockL.seasonWinter).thenReturn('Winter');
      when(() => mockL.seasonSpring).thenReturn('Spring');
      when(() => mockL.seasonSummer).thenReturn('Summer');
      when(() => mockL.seasonFall).thenReturn('Fall');
    });

    test('key is "season" — binds to AniList MediaSeason', () {
      expect(filter.key, 'season');
    });

    test('allOption clears the filter', () {
      expect(filter.allOption.value, isNull);
    });

    test('options cover WINTER/SPRING/SUMMER/FALL in calendar order',
        () async {
      final MockWidgetRef ref = MockWidgetRef();
      final List<FilterOption> opts = await filter.options(ref, mockL);

      expect(opts.map((FilterOption o) => o.value).toList(),
          <String>['WINTER', 'SPRING', 'SUMMER', 'FALL']);
    });
  });
}
