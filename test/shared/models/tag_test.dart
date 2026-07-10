import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/models/tag.dart';

void main() {
  group('Tag', () {
    group('fromDb', () {
      test('parses a full row', () {
        final Tag tag = Tag.fromDb(<String, dynamic>{
          'id': 5,
          'name': 'RPG',
          'color': 0xFF112233,
          'text_color': 0xFFFFFFFF,
          'sort_order': 3,
          'created_at': 1700000000,
        });
        expect(tag.id, 5);
        expect(tag.name, 'RPG');
        expect(tag.color, 0xFF112233);
        expect(tag.textColor, 0xFFFFFFFF);
        expect(tag.sortOrder, 3);
        expect(tag.createdAt, 1700000000);
      });

      test('defaults nullable and missing fields', () {
        final Tag tag = Tag.fromDb(<String, dynamic>{
          'id': 1,
          'name': 'Инди',
          'color': null,
          'text_color': null,
          'sort_order': null,
          'created_at': 1700000000,
        });
        expect(tag.color, isNull);
        expect(tag.textColor, isNull);
        expect(tag.sortOrder, 0);
      });
    });

    group('toDb', () {
      test('round-trips through fromDb', () {
        const Tag tag = Tag(
          id: 7,
          name: 'Хоррор',
          color: 0xFF00FF00,
          textColor: 0xFF000000,
          sortOrder: 2,
          createdAt: 1700000500,
        );
        final Tag restored = Tag.fromDb(tag.toDb());
        expect(restored.id, tag.id);
        expect(restored.name, tag.name);
        expect(restored.color, tag.color);
        expect(restored.textColor, tag.textColor);
        expect(restored.sortOrder, tag.sortOrder);
        expect(restored.createdAt, tag.createdAt);
      });
    });

    group('toExport / fromExport', () {
      test('export omits id and created_at, import defaults them', () {
        const Tag tag = Tag(
          id: 7,
          name: 'RPG',
          color: 1,
          textColor: 2,
          sortOrder: 4,
          createdAt: 1700000500,
        );
        final Map<String, dynamic> exported = tag.toExport();
        expect(exported.containsKey('id'), isFalse);
        expect(exported.containsKey('created_at'), isFalse);

        final Tag imported = Tag.fromExport(exported);
        expect(imported.id, 0);
        expect(imported.createdAt, 0);
        expect(imported.name, 'RPG');
        expect(imported.color, 1);
        expect(imported.textColor, 2);
        expect(imported.sortOrder, 4);
      });
    });

    group('findByNameCaseInsensitive', () {
      const List<Tag> tags = <Tag>[
        Tag(id: 1, name: 'RPG', createdAt: 0),
        Tag(id: 2, name: 'Хоррор', createdAt: 0),
      ];

      test('matches Latin and Cyrillic names ignoring case', () {
        expect(Tag.findByNameCaseInsensitive(tags, 'rpg')?.id, 1);
        expect(Tag.findByNameCaseInsensitive(tags, 'хОррОр')?.id, 2);
      });

      test('returns null when absent', () {
        expect(Tag.findByNameCaseInsensitive(tags, 'нет'), isNull);
      });
    });

    group('TagListProjection', () {
      const List<Tag> tags = <Tag>[
        Tag(id: 1, name: 'aaa', createdAt: 0),
        Tag(id: 2, name: 'bbb', createdAt: 0),
        Tag(id: 3, name: 'ccc', createdAt: 0),
      ];

      test('orderedFor keeps display order regardless of set order', () {
        expect(
          tags.orderedFor(<int>{3, 1}).map((Tag t) => t.id).toList(),
          <int>[1, 3],
        );
      });

      test('orderedFor skips unknown ids and handles null/empty', () {
        expect(tags.orderedFor(<int>{99}), isEmpty);
        expect(tags.orderedFor(null), isEmpty);
        expect(tags.orderedFor(<int>{}), isEmpty);
      });

      test('primaryFor returns the first tag in display order', () {
        expect(tags.primaryFor(<int>{3, 2})?.id, 2);
        expect(tags.primaryFor(null), isNull);
        expect(tags.primaryFor(<int>{99}), isNull);
      });
    });

    group('copyWith', () {
      const Tag base = Tag(
        id: 1,
        name: 'RPG',
        color: 1,
        textColor: 2,
        createdAt: 1700000000,
      );

      test('replaces given fields', () {
        final Tag copy = base.copyWith(name: 'JRPG', sortOrder: 9);
        expect(copy.name, 'JRPG');
        expect(copy.sortOrder, 9);
        expect(copy.color, 1);
        expect(copy.textColor, 2);
      });

      test('clearColor and clearTextColor reset to null', () {
        final Tag copy =
            base.copyWith(clearColor: true, clearTextColor: true);
        expect(copy.color, isNull);
        expect(copy.textColor, isNull);
      });

      test('no arguments keeps every field', () {
        final Tag copy = base.copyWith();
        expect(copy.id, base.id);
        expect(copy.name, base.name);
        expect(copy.color, base.color);
        expect(copy.textColor, base.textColor);
        expect(copy.sortOrder, base.sortOrder);
        expect(copy.createdAt, base.createdAt);
      });
    });
  });
}
