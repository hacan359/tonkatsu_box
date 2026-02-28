import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/search/filters/igdb_platform_filter.dart';
import 'package:xerabora/features/search/models/search_source.dart';

void main() {
  group('IgdbPlatformFilter', () {
    late IgdbPlatformFilter filter;

    setUp(() {
      filter = IgdbPlatformFilter();
    });

    test('key is "platform"', () {
      expect(filter.key, 'platform');
    });

    test('allOption has id "any" and null value', () {
      final FilterOption all = filter.allOption;

      expect(all.id, 'any');
      expect(all.label, 'All');
      expect(all.value, isNull);
    });
  });
}
