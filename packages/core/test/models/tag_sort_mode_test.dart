import 'package:core/models/tag.dart';
import 'package:core/models/tag_sort_mode.dart';
import 'package:core/testing/builders.dart';
import 'package:test/test.dart';

Tag _tag(int id, String name) =>
    createTestTag(id: id, name: name, sortOrder: id);

void main() {
  group('TagSortMode', () {
    group('fromString', () {
      test('resolves every stored value', () {
        for (final TagSortMode mode in TagSortMode.values) {
          expect(TagSortMode.fromString(mode.value), mode);
        }
      });

      test('falls back to manual on an unknown value', () {
        expect(TagSortMode.fromString('bogus'), TagSortMode.manual);
        expect(TagSortMode.fromString(''), TagSortMode.manual);
      });
    });

    group('apply', () {
      final List<Tag> tags = <Tag>[
        _tag(1, 'zebra'),
        _tag(2, 'Action'),
        _tag(3, 'indie'),
      ];

      test('manual keeps the incoming order', () {
        expect(TagSortMode.manual.apply(tags), same(tags));
      });

      test('alphaAsc sorts case-insensitively without mutating the input', () {
        final List<Tag> sorted = TagSortMode.alphaAsc.apply(tags);
        expect(
          sorted.map((Tag t) => t.name).toList(),
          <String>['Action', 'indie', 'zebra'],
        );
        expect(tags.first.name, 'zebra');
      });

      test('alphaDesc reverses the alphabetical order', () {
        final List<Tag> sorted = TagSortMode.alphaDesc.apply(tags);
        expect(
          sorted.map((Tag t) => t.name).toList(),
          <String>['zebra', 'indie', 'Action'],
        );
      });

      test('handles an empty list', () {
        expect(TagSortMode.alphaAsc.apply(<Tag>[]), isEmpty);
      });
    });
  });
}
