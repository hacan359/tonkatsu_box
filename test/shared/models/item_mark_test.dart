import 'package:core/models/item_mark.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ItemMark', () {
    ItemMark buildMark({
      int id = 5,
      int itemId = 42,
      String unitType = kUnitEpisode,
      int parentNumber = 1,
      int unitNumber = 3,
      bool isFavorite = true,
      String? userComment = 'great episode',
      DateTime? likedAt,
      DateTime? updatedAt,
    }) {
      return ItemMark(
        id: id,
        itemId: itemId,
        unitType: unitType,
        parentNumber: parentNumber,
        unitNumber: unitNumber,
        isFavorite: isFavorite,
        userComment: userComment,
        likedAt: likedAt ?? DateTime.fromMillisecondsSinceEpoch(1700000000000),
        updatedAt:
            updatedAt ?? DateTime.fromMillisecondsSinceEpoch(1700000005000),
      );
    }

    group('fromDb / toDb', () {
      test('toDb omits id and encodes booleans/timestamps as ints', () {
        final Map<String, dynamic> row = buildMark().toDb();
        expect(row.containsKey('id'), isFalse);
        expect(row['item_id'], 42);
        expect(row['unit_type'], kUnitEpisode);
        expect(row['parent_number'], 1);
        expect(row['unit_number'], 3);
        expect(row['is_favorite'], 1);
        expect(row['user_comment'], 'great episode');
        expect(row['liked_at'], 1700000000000);
        expect(row['updated_at'], 1700000005000);
      });

      test('fromDb round-trips a persisted row', () {
        final ItemMark original = buildMark();
        final Map<String, dynamic> row = original.toDb()..['id'] = 5;
        final ItemMark restored = ItemMark.fromDb(row);
        expect(restored, original); // equality is identity-based
        expect(restored.id, 5);
        expect(restored.isFavorite, isTrue);
        expect(restored.userComment, 'great episode');
        expect(restored.likedAt, original.likedAt);
        expect(restored.updatedAt, original.updatedAt);
      });

      test('fromDb tolerates null liked_at', () {
        final Map<String, dynamic> row = buildMark(
          isFavorite: false,
          likedAt: null,
        ).toDb()
          ..['id'] = 1
          ..['liked_at'] = null;
        final ItemMark restored = ItemMark.fromDb(row);
        expect(restored.likedAt, isNull);
        expect(restored.isFavorite, isFalse);
      });
    });

    group('export round-trip', () {
      test('toExport uses seconds and drops id/item_id', () {
        final Map<String, dynamic> json = buildMark().toExport();
        expect(json.containsKey('id'), isFalse);
        expect(json.containsKey('item_id'), isFalse);
        expect(json['liked_at'], 1700000000);
        expect(json['updated_at'], 1700000005);
        expect(json['is_favorite'], 1);
      });

      test('fromExport re-anchors to the supplied itemId', () {
        final Map<String, dynamic> json = buildMark().toExport();
        final ItemMark restored = ItemMark.fromExport(json, itemId: 99);
        expect(restored.itemId, 99);
        expect(restored.unitType, kUnitEpisode);
        expect(restored.parentNumber, 1);
        expect(restored.unitNumber, 3);
        expect(restored.isFavorite, isTrue);
        expect(restored.userComment, 'great episode');
        expect(
          restored.likedAt,
          DateTime.fromMillisecondsSinceEpoch(1700000000000),
        );
      });
    });

    group('hasContent', () {
      test('true when favorite', () {
        expect(buildMark(isFavorite: true, userComment: null).hasContent,
            isTrue);
      });

      test('true when non-empty note', () {
        expect(buildMark(isFavorite: false, userComment: 'x').hasContent,
            isTrue);
      });

      test('false when no like and blank note', () {
        expect(buildMark(isFavorite: false, userComment: '   ').hasContent,
            isFalse);
        expect(buildMark(isFavorite: false, userComment: null).hasContent,
            isFalse);
      });
    });

    group('displayNumber', () {
      test('uses unitNumber for episode/chapter', () {
        expect(buildMark(unitType: kUnitEpisode).displayNumber, 3);
        expect(
          buildMark(unitType: kUnitChapter, unitNumber: 45).displayNumber,
          45,
        );
      });

      test('uses parentNumber for season/volume', () {
        expect(
          buildMark(unitType: kUnitSeason, parentNumber: 2, unitNumber: 0)
              .displayNumber,
          2,
        );
        expect(
          buildMark(unitType: kUnitVolume, parentNumber: 7, unitNumber: 0)
              .displayNumber,
          7,
        );
      });
    });

    group('equality', () {
      test('equal by (itemId, unitType, parent, unit), ignoring content', () {
        final ItemMark a = buildMark(isFavorite: true, userComment: 'a');
        final ItemMark b = buildMark(isFavorite: false, userComment: 'b');
        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('differs when coordinates differ', () {
        expect(buildMark(unitNumber: 3), isNot(buildMark(unitNumber: 4)));
      });
    });

    group('copyWith', () {
      test('clearUserComment / clearLikedAt null out fields', () {
        final ItemMark m = buildMark();
        final ItemMark cleared =
            m.copyWith(clearUserComment: true, clearLikedAt: true);
        expect(cleared.userComment, isNull);
        expect(cleared.likedAt, isNull);
      });
    });
  });

  group('unitCoordsFor', () {
    test('season/volume -> parent number', () {
      expect(unitCoordsFor(kUnitSeason, 2), (parent: 2, unit: 0));
      expect(unitCoordsFor(kUnitVolume, 7), (parent: 7, unit: 0));
    });

    test('everything else -> unit number', () {
      expect(unitCoordsFor(kUnitEpisode, 5), (parent: 0, unit: 5));
      expect(unitCoordsFor(kUnitChapter, 45), (parent: 0, unit: 45));
      expect(unitCoordsFor('arc', 3), (parent: 0, unit: 3));
    });
  });
}
