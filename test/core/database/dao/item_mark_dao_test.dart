import 'package:core/database/migrations/migration_v53.dart';
import 'package:core/models/item_mark.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tonkatsu_box/core/database/dao/item_mark_dao.dart';

void main() {
  sqfliteFfiInit();
  final DatabaseFactory factory = databaseFactoryFfi;

  late Database db;
  late ItemMarkDao dao;

  setUp(() async {
    // Foreign keys are left OFF so the DAO can be tested without seeding the
    // referenced collection_items table.
    db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 53,
        onCreate: (Database d, int _) async => MigrationV53().migrate(d),
      ),
    );
    dao = ItemMarkDao(() async => db);
  });

  tearDown(() async => db.close());

  group('ItemMarkDao', () {
    const int itemId = 1;

    group('setFavorite', () {
      test('creates a row and returns it via getMarksForItem', () async {
        await dao.setFavorite(itemId, kUnitEpisode, 1, 3, isFavorite: true);
        final List<ItemMark> marks = await dao.getMarksForItem(itemId);
        expect(marks, hasLength(1));
        expect(marks.single.isFavorite, isTrue);
        expect(marks.single.likedAt, isNotNull);
      });

      test('unliking an otherwise-empty mark deletes the row', () async {
        await dao.setFavorite(itemId, kUnitEpisode, 1, 3, isFavorite: true);
        await dao.setFavorite(itemId, kUnitEpisode, 1, 3, isFavorite: false);
        expect(await dao.getMarksForItem(itemId), isEmpty);
      });

      test('unliking keeps the row when a note remains', () async {
        await dao.setComment(itemId, kUnitEpisode, 1, 3, 'note');
        await dao.setFavorite(itemId, kUnitEpisode, 1, 3, isFavorite: true);
        await dao.setFavorite(itemId, kUnitEpisode, 1, 3, isFavorite: false);
        final List<ItemMark> marks = await dao.getMarksForItem(itemId);
        expect(marks, hasLength(1));
        expect(marks.single.isFavorite, isFalse);
        expect(marks.single.userComment, 'note');
      });

      test('re-liking preserves the original liked_at', () async {
        await dao.setFavorite(itemId, kUnitEpisode, 1, 3, isFavorite: true);
        final DateTime? first =
            (await dao.getMarksForItem(itemId)).single.likedAt;
        await dao.setComment(itemId, kUnitEpisode, 1, 3, 'note');
        final DateTime? afterComment =
            (await dao.getMarksForItem(itemId)).single.likedAt;
        expect(afterComment, first);
      });
    });

    group('setComment', () {
      test('merges with an existing like', () async {
        await dao.setFavorite(itemId, kUnitEpisode, 1, 3, isFavorite: true);
        await dao.setComment(itemId, kUnitEpisode, 1, 3, 'good');
        final ItemMark mark = (await dao.getMarksForItem(itemId)).single;
        expect(mark.isFavorite, isTrue);
        expect(mark.userComment, 'good');
      });

      test('blank comment on a like-only mark keeps the like', () async {
        await dao.setFavorite(itemId, kUnitEpisode, 1, 3, isFavorite: true);
        await dao.setComment(itemId, kUnitEpisode, 1, 3, '   ');
        final ItemMark mark = (await dao.getMarksForItem(itemId)).single;
        expect(mark.isFavorite, isTrue);
        expect(mark.userComment, isNull);
      });

      test('clearing the note on a note-only mark deletes the row', () async {
        await dao.setComment(itemId, kUnitEpisode, 1, 3, 'temp');
        await dao.setComment(itemId, kUnitEpisode, 1, 3, null);
        expect(await dao.getMarksForItem(itemId), isEmpty);
      });

      test('trims stored comments', () async {
        await dao.setComment(itemId, kUnitEpisode, 1, 3, '  spaced  ');
        expect(
          (await dao.getMarksForItem(itemId)).single.userComment,
          'spaced',
        );
      });
    });

    group('deleteMark', () {
      test('removes a mark unconditionally', () async {
        await dao.setFavorite(itemId, kUnitSeason, 2, 0, isFavorite: true);
        await dao.deleteMark(itemId, kUnitSeason, 2, 0);
        expect(await dao.getMarksForItem(itemId), isEmpty);
      });
    });

    group('unique key', () {
      test('same coordinates upsert into one row', () async {
        await dao.setFavorite(itemId, kUnitEpisode, 1, 3, isFavorite: true);
        await dao.setComment(itemId, kUnitEpisode, 1, 3, 'a');
        await dao.setComment(itemId, kUnitEpisode, 1, 3, 'b');
        final List<ItemMark> marks = await dao.getMarksForItem(itemId);
        expect(marks, hasLength(1));
        expect(marks.single.userComment, 'b');
      });

      test('different coordinates are distinct rows', () async {
        await dao.setFavorite(itemId, kUnitEpisode, 1, 3, isFavorite: true);
        await dao.setFavorite(itemId, kUnitEpisode, 1, 4, isFavorite: true);
        await dao.setFavorite(itemId, kUnitSeason, 1, 0, isFavorite: true);
        expect(await dao.getMarksForItem(itemId), hasLength(3));
      });
    });

    group('insertMarks', () {
      test('inserts imported marks verbatim in one batch', () async {
        final ItemMark mark = ItemMark(
          id: 0,
          itemId: itemId,
          unitType: kUnitChapter,
          parentNumber: 0,
          unitNumber: 45,
          isFavorite: true,
          userComment: 'imported',
          likedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(1700000005000),
        );
        await dao.insertMarks(<ItemMark>[mark]);
        final ItemMark restored = (await dao.getMarksForItem(itemId)).single;
        expect(restored.userComment, 'imported');
        expect(restored.unitNumber, 45);
        expect(restored.likedAt,
            DateTime.fromMillisecondsSinceEpoch(1700000000000));
      });

      test('empty list is a no-op', () async {
        await dao.insertMarks(const <ItemMark>[]);
        expect(await dao.getMarksForItem(itemId), isEmpty);
      });
    });

    group('getMarksForItems', () {
      test('returns marks only for the requested items', () async {
        await dao.setFavorite(1, kUnitEpisode, 1, 1, isFavorite: true);
        await dao.setFavorite(2, kUnitEpisode, 1, 1, isFavorite: true);
        await dao.setFavorite(3, kUnitEpisode, 1, 1, isFavorite: true);
        final List<ItemMark> marks =
            await dao.getMarksForItems(<int>[1, 2]);
        expect(marks, hasLength(2));
        expect(
          marks.map((ItemMark m) => m.itemId),
          unorderedEquals(<int>[1, 2]),
        );
      });

      test('empty id list returns empty without querying', () async {
        expect(await dao.getMarksForItems(const <int>[]), isEmpty);
      });

      test('handles id lists larger than one query chunk', () async {
        await dao.insertMarks(<ItemMark>[
          for (int i = 1; i <= 600; i++)
            ItemMark(
              id: 0,
              itemId: i,
              unitType: kUnitEpisode,
              parentNumber: 1,
              unitNumber: 1,
              isFavorite: true,
              updatedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
            ),
        ]);
        final List<ItemMark> marks = await dao.getMarksForItems(
          <int>[for (int i = 1; i <= 600; i++) i],
        );
        expect(marks, hasLength(600));
      });
    });

    group('setFavorite/setComment return value', () {
      test('returns the merged mark on write', () async {
        final ItemMark? merged =
            await dao.setFavorite(itemId, kUnitEpisode, 1, 3,
                isFavorite: true);
        expect(merged, isNotNull);
        expect(merged!.isFavorite, isTrue);
        final ItemMark? withNote =
            await dao.setComment(itemId, kUnitEpisode, 1, 3, 'good');
        expect(withNote!.isFavorite, isTrue);
        expect(withNote.userComment, 'good');
      });

      test('returns null when the row is deleted', () async {
        await dao.setFavorite(itemId, kUnitEpisode, 1, 3, isFavorite: true);
        final ItemMark? gone =
            await dao.setFavorite(itemId, kUnitEpisode, 1, 3,
                isFavorite: false);
        expect(gone, isNull);
      });
    });

    group('export/import round-trip', () {
      test('marks survive serialization and re-anchor to a new item id',
          () async {
        const int oldItemId = 7;
        const int newItemId = 12;
        await dao.setFavorite(oldItemId, kUnitEpisode, 2, 5, isFavorite: true);
        await dao.setComment(oldItemId, kUnitEpisode, 2, 5, 'loved it');
        await dao.setComment(oldItemId, kUnitChapter, 0, 45, 'cliffhanger');

        // Export (nested, no item_id) then import under a fresh id.
        final List<Map<String, dynamic>> exported =
            (await dao.getMarksForItem(oldItemId))
                .map((ItemMark m) => m.toExport())
                .toList();
        await dao.insertMarks(<ItemMark>[
          for (final Map<String, dynamic> json in exported)
            ItemMark.fromExport(json, itemId: newItemId),
        ]);

        final List<ItemMark> restored = await dao.getMarksForItem(newItemId);
        expect(restored, hasLength(2));
        final ItemMark episode = restored
            .firstWhere((ItemMark m) => m.unitType == kUnitEpisode);
        expect(episode.itemId, newItemId);
        expect(episode.isFavorite, isTrue);
        expect(episode.userComment, 'loved it');
        expect(episode.parentNumber, 2);
        expect(episode.unitNumber, 5);
      });
    });
  });
}
