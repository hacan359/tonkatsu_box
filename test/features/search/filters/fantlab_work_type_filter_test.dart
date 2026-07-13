import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/features/search/filters/fantlab_work_type_filter.dart';
import 'package:tonkatsu_box/features/search/models/search_source.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('FantlabWorkTypeFilter', () {
    late FantlabWorkTypeFilter filter;
    late MockS mockL;

    setUp(() {
      filter = FantlabWorkTypeFilter();
      mockL = MockS();
      when(() => mockL.type).thenReturn('Type');
      when(() => mockL.fantlabTypeNovel).thenReturn('Novel');
      when(() => mockL.fantlabTypeNovella).thenReturn('Novella');
      when(() => mockL.fantlabTypeShortStory).thenReturn('Short story');
      when(() => mockL.fantlabTypeCycle).thenReturn('Cycle');
    });

    test('key is "work_type"', () {
      expect(filter.key, 'work_type');
    });

    test('cacheKey is provider-scoped to avoid clashing with other sources',
        () {
      expect(filter.cacheKey, 'work_type_fantlab');
    });

    test('allOption resets the filter with a null value', () {
      final FilterOption all = filter.allOption;

      expect(all.id, 'all');
      expect(all.value, isNull);
    });

    test('options exposes the four Fantlab work types', () async {
      final MockWidgetRef ref = MockWidgetRef();

      final List<FilterOption> options = await filter.options(ref, mockL);

      expect(options, hasLength(4));
    });

    test('option ids map to Fantlab name_eng values', () async {
      final MockWidgetRef ref = MockWidgetRef();

      final List<FilterOption> options = await filter.options(ref, mockL);

      expect(
        options.map((FilterOption o) => o.id).toList(),
        <String>['novel', 'story', 'shortstory', 'cycle'],
      );
      expect(
        options.map((FilterOption o) => o.value).toList(),
        <Object?>['novel', 'story', 'shortstory', 'cycle'],
      );
    });

    test('options labels come from localization', () async {
      final MockWidgetRef ref = MockWidgetRef();

      final List<FilterOption> options = await filter.options(ref, mockL);

      expect(options[0].label, 'Novel');
      expect(options[1].label, 'Novella');
    });
  });
}
