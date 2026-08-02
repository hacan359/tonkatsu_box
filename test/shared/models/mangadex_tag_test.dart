import 'package:core/models/mangadex_tag.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MangaDexTag', () {
    test('fromJson reads id, English name and group', () {
      final MangaDexTag tag = MangaDexTag.fromJson(<String, dynamic>{
        'id': '07251805-a27e-4d59-b488-f0bfbec15168',
        'type': 'tag',
        'attributes': <String, dynamic>{
          'name': <String, dynamic>{'en': 'Thriller'},
          'group': 'genre',
        },
      });
      expect(tag.id, '07251805-a27e-4d59-b488-f0bfbec15168');
      expect(tag.name, 'Thriller');
      expect(tag.group, 'genre');
    });

    test('fromJson falls back to the first non-empty localized name', () {
      final MangaDexTag tag = MangaDexTag.fromJson(<String, dynamic>{
        'id': 'x',
        'attributes': <String, dynamic>{
          'name': <String, dynamic>{'ja': 'アクション'},
          'group': 'genre',
        },
      });
      expect(tag.name, 'アクション');
    });

    test('toDb / fromDb round-trip preserves fields', () {
      const MangaDexTag tag =
          MangaDexTag(id: 'u1', name: 'Action', group: 'genre', updatedAt: 42);
      final MangaDexTag back = MangaDexTag.fromDb(tag.toDb());
      expect(back.id, 'u1');
      expect(back.name, 'Action');
      expect(back.group, 'genre');
      expect(back.updatedAt, 42);
    });
  });
}
