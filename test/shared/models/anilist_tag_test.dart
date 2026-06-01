import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/shared/models/anilist_tag.dart';

void main() {
  group('AniListTag', () {
    group('fromJson', () {
      test('parses full payload', () {
        final AniListTag tag = AniListTag.fromJson(<String, dynamic>{
          'id': 42,
          'name': 'Time Loop',
          'category': 'Theme-Plot',
          'description': 'Characters relive events.',
          'isAdult': false,
          'isGeneralSpoiler': true,
        });
        expect(tag.id, 42);
        expect(tag.name, 'Time Loop');
        expect(tag.category, 'Theme-Plot');
        expect(tag.description, 'Characters relive events.');
        expect(tag.isAdult, isFalse);
        expect(tag.isGeneralSpoiler, isTrue);
      });

      test('defaults isAdult / isGeneralSpoiler to false when missing', () {
        final AniListTag tag = AniListTag.fromJson(<String, dynamic>{
          'id': 1,
          'name': 'Magic',
        });
        expect(tag.isAdult, isFalse);
        expect(tag.isGeneralSpoiler, isFalse);
        expect(tag.category, isNull);
      });
    });

    group('toDb / fromDb round-trip', () {
      test('preserves all fields and bool encoding', () {
        const AniListTag original = AniListTag(
          id: 7,
          name: 'School',
          category: 'Setting',
          description: 'School setting',
          isAdult: true,
          isGeneralSpoiler: false,
          updatedAt: 1234567,
        );
        final Map<String, dynamic> row = original.toDb();
        expect(row['is_adult'], 1);
        expect(row['is_general_spoiler'], 0);
        final AniListTag back = AniListTag.fromDb(row);
        expect(back.id, original.id);
        expect(back.name, original.name);
        expect(back.category, original.category);
        expect(back.description, original.description);
        expect(back.isAdult, original.isAdult);
        expect(back.isGeneralSpoiler, original.isGeneralSpoiler);
        expect(back.updatedAt, original.updatedAt);
      });

      test('toDb fills updated_at when null', () {
        const AniListTag tag = AniListTag(id: 1, name: 'X');
        final Map<String, dynamic> row = tag.toDb();
        expect(row['updated_at'], isA<int>());
        expect((row['updated_at'] as int) > 0, isTrue);
      });
    });

    group('equality', () {
      test('equal by id', () {
        const AniListTag a = AniListTag(id: 1, name: 'A');
        const AniListTag b = AniListTag(id: 1, name: 'B');
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different id is not equal', () {
        const AniListTag a = AniListTag(id: 1, name: 'A');
        const AniListTag b = AniListTag(id: 2, name: 'A');
        expect(a, isNot(equals(b)));
      });
    });
  });
}
