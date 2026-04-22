import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/database/dao/tag_dao.dart';
import 'package:xerabora/shared/models/collection_tag.dart';

import '../../../helpers/mocks.dart';

Map<String, dynamic> _tagRow({
  int id = 1,
  int collectionId = 1,
  String name = 'RPG',
  int? color,
  int sortOrder = 0,
  int createdAt = 1700000000,
}) =>
    <String, dynamic>{
      'id': id,
      'collection_id': collectionId,
      'name': name,
      'color': color,
      'sort_order': sortOrder,
      'created_at': createdAt,
    };

void main() {
  late MockDatabase mockDb;
  late TagDao dao;

  setUp(() {
    mockDb = MockDatabase();
    dao = TagDao(() async => mockDb);
  });

  group('TagDao', () {
    group('findTagByNameCaseInsensitive', () {
      test('returns tag when exact name matches', () async {
        when(
          () => mockDb.query(
            'collection_tags',
            where: 'collection_id = ?',
            whereArgs: <Object?>[1],
            orderBy: 'sort_order ASC, name ASC',
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[_tagRow(name: 'RPG')],
        );

        final CollectionTag? result =
            await dao.findTagByNameCaseInsensitive(1, 'RPG');

        expect(result, isNotNull);
        expect(result!.name, 'RPG');
      });

      test('returns tag regardless of case (ASCII)', () async {
        when(
          () => mockDb.query(
            'collection_tags',
            where: 'collection_id = ?',
            whereArgs: <Object?>[1],
            orderBy: 'sort_order ASC, name ASC',
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[_tagRow(name: 'RPG')],
        );

        expect(
          (await dao.findTagByNameCaseInsensitive(1, 'rpg'))?.name,
          'RPG',
        );
      });

      test('returns tag regardless of case (Cyrillic)', () async {
        when(
          () => mockDb.query(
            'collection_tags',
            where: 'collection_id = ?',
            whereArgs: <Object?>[1],
            orderBy: 'sort_order ASC, name ASC',
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[_tagRow(name: 'РПГ')],
        );

        final CollectionTag? result =
            await dao.findTagByNameCaseInsensitive(1, 'рпг');

        expect(result, isNotNull);
        expect(result!.name, 'РПГ');
      });

      test('returns null when no tag matches', () async {
        when(
          () => mockDb.query(
            'collection_tags',
            where: 'collection_id = ?',
            whereArgs: <Object?>[1],
            orderBy: 'sort_order ASC, name ASC',
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[_tagRow(name: 'Action')],
        );

        expect(
          await dao.findTagByNameCaseInsensitive(1, 'RPG'),
          isNull,
        );
      });

      test('returns null when collection has no tags', () async {
        when(
          () => mockDb.query(
            'collection_tags',
            where: 'collection_id = ?',
            whereArgs: <Object?>[1],
            orderBy: 'sort_order ASC, name ASC',
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        expect(
          await dao.findTagByNameCaseInsensitive(1, 'RPG'),
          isNull,
        );
      });
    });

    group('resolveOrCreateInCollection', () {
      test('returns existing tag id when name matches (case-insensitive)',
          () async {
        when(
          () => mockDb.query(
            'collection_tags',
            where: 'collection_id = ?',
            whereArgs: <Object?>[1],
            orderBy: 'sort_order ASC, name ASC',
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[_tagRow(id: 42, name: 'RPG')],
        );

        final int id = await dao.resolveOrCreateInCollection(
          1,
          'rpg',
          color: 0xFF00FF00,
        );

        expect(id, 42);
        verifyNever(
          () => mockDb.insert('collection_tags', any()),
        );
      });

      test('creates new tag when name not found and returns its id',
          () async {
        when(
          () => mockDb.query(
            'collection_tags',
            where: 'collection_id = ?',
            whereArgs: <Object?>[1],
            orderBy: 'sort_order ASC, name ASC',
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);
        when(
          () => mockDb.insert('collection_tags', any()),
        ).thenAnswer((_) async => 99);

        final int id = await dao.resolveOrCreateInCollection(
          1,
          'Action',
          color: 0xFFFF0000,
        );

        expect(id, 99);
        final Map<String, dynamic> inserted = verify(
          () => mockDb.insert(
            'collection_tags',
            captureAny(),
          ),
        ).captured.single as Map<String, dynamic>;
        expect(inserted['collection_id'], 1);
        expect(inserted['name'], 'Action');
        expect(inserted['color'], 0xFFFF0000);
      });
    });

    group('setItemTag', () {
      test('updates tag_id on collection_items row', () async {
        when(
          () => mockDb.update(
            'collection_items',
            any(),
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
          ),
        ).thenAnswer((_) async => 1);

        await dao.setItemTag(5, 10);

        verify(
          () => mockDb.update(
            'collection_items',
            <String, dynamic>{'tag_id': 10},
            where: 'id = ?',
            whereArgs: <Object?>[5],
          ),
        ).called(1);
      });

      test('accepts null tagId to clear tag', () async {
        when(
          () => mockDb.update(
            'collection_items',
            any(),
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
          ),
        ).thenAnswer((_) async => 1);

        await dao.setItemTag(5, null);

        verify(
          () => mockDb.update(
            'collection_items',
            <String, dynamic>{'tag_id': null},
            where: 'id = ?',
            whereArgs: <Object?>[5],
          ),
        ).called(1);
      });
    });

    group('getTagById', () {
      test('returns tag when row exists', () async {
        when(
          () => mockDb.query(
            'collection_tags',
            where: 'id = ?',
            whereArgs: <Object?>[7],
            limit: 1,
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[_tagRow(id: 7, name: 'RPG')],
        );

        expect((await dao.getTagById(7))?.name, 'RPG');
      });

      test('returns null when row missing', () async {
        when(
          () => mockDb.query(
            'collection_tags',
            where: 'id = ?',
            whereArgs: <Object?>[7],
            limit: 1,
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        expect(await dao.getTagById(7), isNull);
      });
    });
  });
}
