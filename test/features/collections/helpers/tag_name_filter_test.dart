import 'package:core/models/tag.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/helpers/tag_name_filter.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('filterTagsByName', () {
    final List<Tag> tags = <Tag>[
      createTestTag(id: 1, name: 'RPG'),
      createTestTag(id: 2, name: 'Soulslike'),
      createTestTag(id: 3, name: 'Co-op'),
    ];

    test('should return every tag for an empty or blank query', () {
      expect(filterTagsByName(tags, ''), same(tags));
      expect(filterTagsByName(tags, '   '), same(tags));
    });

    test('should match a substring regardless of case', () {
      final List<Tag> result = filterTagsByName(tags, 'SOULS');

      expect(result.map((Tag t) => t.id), <int>[2]);
    });

    test('should trim the query before matching', () {
      final List<Tag> result = filterTagsByName(tags, '  rpg ');

      expect(result.map((Tag t) => t.id), <int>[1]);
    });

    test('should keep selected tags that do not match', () {
      final List<Tag> result = filterTagsByName(tags, 'co', keepIds: <int>{2});

      expect(result.map((Tag t) => t.id), <int>[2, 3]);
    });

    test('should return an empty list when nothing matches', () {
      expect(filterTagsByName(tags, 'zzz'), isEmpty);
    });

    test('should handle an empty tag list', () {
      expect(filterTagsByName(<Tag>[], 'rpg'), isEmpty);
    });
  });
}
