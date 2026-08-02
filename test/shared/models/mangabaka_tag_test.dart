import 'package:core/models/mangabaka_tag.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MangaBakaTag', () {
    test('fromJson maps API fields', () {
      final MangaBakaTag tag = MangaBakaTag.fromJson(<String, dynamic>{
        'id': 746,
        'parent_id': 1142,
        'name': 'Calligraphy',
        'name_path': 'Activities/Arts & Crafts/Calligraphy',
        'description': 'desc',
        'is_spoiler': true,
        'is_genre': false,
        'content_rating': 'safe',
        'series_count': 12,
        'level': 2,
      });
      expect(tag.id, 746);
      expect(tag.parentId, 1142);
      expect(tag.name, 'Calligraphy');
      expect(tag.isSpoiler, isTrue);
      expect(tag.seriesCount, 12);
      expect(tag.level, 2);
    });

    test('fromJson tolerates missing optional flags', () {
      final MangaBakaTag tag = MangaBakaTag.fromJson(<String, dynamic>{
        'id': 1,
        'name': 'X',
      });
      expect(tag.isSpoiler, isFalse);
      expect(tag.isGenre, isFalse);
      expect(tag.seriesCount, 0);
    });

    test('db round-trip preserves fields', () {
      const MangaBakaTag original = MangaBakaTag(
        id: 5,
        name: 'Magic',
        parentId: 2,
        namePath: 'Themes/Magic',
        isSpoiler: true,
        isGenre: true,
        contentRating: 'explicit',
        seriesCount: 99,
        level: 1,
        updatedAt: 1000,
      );
      final MangaBakaTag back = MangaBakaTag.fromDb(original.toDb());
      expect(back.id, original.id);
      expect(back.name, original.name);
      expect(back.parentId, original.parentId);
      expect(back.namePath, original.namePath);
      expect(back.isSpoiler, original.isSpoiler);
      expect(back.isGenre, original.isGenre);
      expect(back.contentRating, original.contentRating);
      expect(back.seriesCount, original.seriesCount);
      expect(back.level, original.level);
    });

    test('isAdult reflects content_rating', () {
      const MangaBakaTag explicit =
          MangaBakaTag(id: 1, name: 'X', contentRating: 'explicit');
      const MangaBakaTag safe =
          MangaBakaTag(id: 2, name: 'Y', contentRating: 'safe');
      expect(explicit.isAdult, isTrue);
      expect(safe.isAdult, isFalse);
    });
  });
}
