import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/showcase/utils/tmdb_region.dart';

void main() {
  group('tmdbRegionFromLanguage', () {
    test('takes the region subtag, upper-cased', () {
      expect(tmdbRegionFromLanguage('ru-RU'), 'RU');
      expect(tmdbRegionFromLanguage('pt-br'), 'BR');
      expect(tmdbRegionFromLanguage('en-US'), 'US');
    });

    test('returns null for a bare language tag', () {
      expect(tmdbRegionFromLanguage('en'), isNull);
      expect(tmdbRegionFromLanguage(''), isNull);
    });

    test('returns null for a script subtag', () {
      expect(tmdbRegionFromLanguage('zh-Hans'), isNull);
    });
  });
}
