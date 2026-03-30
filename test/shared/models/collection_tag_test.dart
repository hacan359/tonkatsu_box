import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/collection_tag.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('CollectionTag', () {
    group('fromDb', () {
      test('должен создавать из записи БД', () {
        final CollectionTag tag = CollectionTag.fromDb(<String, dynamic>{
          'id': 1,
          'collection_id': 5,
          'name': 'RPG',
          'color': 4294198070,
          'sort_order': 2,
          'created_at': 1700000000,
        });

        expect(tag.id, 1);
        expect(tag.collectionId, 5);
        expect(tag.name, 'RPG');
        expect(tag.color, 4294198070);
        expect(tag.sortOrder, 2);
        expect(tag.createdAt, 1700000000);
      });

      test('должен обрабатывать null color и sort_order', () {
        final CollectionTag tag = CollectionTag.fromDb(<String, dynamic>{
          'id': 2,
          'collection_id': 1,
          'name': 'Action',
          'color': null,
          'sort_order': null,
          'created_at': 1700000000,
        });

        expect(tag.color, isNull);
        expect(tag.sortOrder, 0);
      });
    });

    group('fromExport', () {
      test('должен создавать из экспортных данных', () {
        final CollectionTag tag = CollectionTag.fromExport(<String, dynamic>{
          'name': 'Favorites',
          'color': 4278190080,
          'sort_order': 1,
        });

        expect(tag.name, 'Favorites');
        expect(tag.color, 4278190080);
        expect(tag.sortOrder, 1);
        expect(tag.id, 0);
        expect(tag.collectionId, 0);
      });

      test('должен обрабатывать минимальные данные', () {
        final CollectionTag tag = CollectionTag.fromExport(<String, dynamic>{
          'name': 'Test',
        });

        expect(tag.name, 'Test');
        expect(tag.color, isNull);
        expect(tag.sortOrder, 0);
      });
    });

    group('toDb', () {
      test('должен сериализовать все поля', () {
        final CollectionTag tag = createTestCollectionTag(
          id: 3,
          collectionId: 7,
          name: 'Strategy',
          color: 4294198070,
          sortOrder: 1,
          createdAt: 1700000000,
        );

        final Map<String, dynamic> db = tag.toDb();
        expect(db['id'], 3);
        expect(db['collection_id'], 7);
        expect(db['name'], 'Strategy');
        expect(db['color'], 4294198070);
        expect(db['sort_order'], 1);
        expect(db['created_at'], 1700000000);
      });
    });

    group('toExport', () {
      test('должен экспортировать name, color, sort_order', () {
        final CollectionTag tag = createTestCollectionTag(
          name: 'Puzzle',
          color: 4278255360,
          sortOrder: 5,
        );

        final Map<String, dynamic> exported = tag.toExport();
        expect(exported['name'], 'Puzzle');
        expect(exported['color'], 4278255360);
        expect(exported['sort_order'], 5);
        expect(exported.containsKey('id'), isFalse);
        expect(exported.containsKey('collection_id'), isFalse);
        expect(exported.containsKey('created_at'), isFalse);
      });
    });

    group('round-trip fromDb → toDb', () {
      test('должен быть идемпотентным', () {
        final Map<String, dynamic> original = <String, dynamic>{
          'id': 10,
          'collection_id': 3,
          'name': 'Horror',
          'color': null,
          'sort_order': 0,
          'created_at': 1700000000,
        };

        final CollectionTag tag = CollectionTag.fromDb(original);
        final Map<String, dynamic> result = tag.toDb();

        expect(result['id'], original['id']);
        expect(result['collection_id'], original['collection_id']);
        expect(result['name'], original['name']);
        expect(result['color'], original['color']);
        expect(result['sort_order'], original['sort_order']);
        expect(result['created_at'], original['created_at']);
      });
    });

    group('copyWith', () {
      test('должен копировать с изменённым name', () {
        final CollectionTag original = createTestCollectionTag(name: 'Old');
        final CollectionTag copy = original.copyWith(name: 'New');
        expect(copy.name, 'New');
        expect(copy.id, original.id);
        expect(copy.collectionId, original.collectionId);
      });

      test('должен копировать с изменённым color', () {
        final CollectionTag original = createTestCollectionTag();
        final CollectionTag copy = original.copyWith(color: 4294198070);
        expect(copy.color, 4294198070);
      });

      test('должен очищать color через clearColor', () {
        final CollectionTag original =
            createTestCollectionTag(color: 4294198070);
        final CollectionTag copy = original.copyWith(clearColor: true);
        expect(copy.color, isNull);
      });

      test('должен сохранять все поля без изменений', () {
        final CollectionTag original = createTestCollectionTag(
          id: 5,
          collectionId: 3,
          name: 'Test',
          color: 4278190080,
          sortOrder: 2,
          createdAt: 1700000000,
        );
        final CollectionTag copy = original.copyWith();
        expect(copy.id, original.id);
        expect(copy.collectionId, original.collectionId);
        expect(copy.name, original.name);
        expect(copy.color, original.color);
        expect(copy.sortOrder, original.sortOrder);
        expect(copy.createdAt, original.createdAt);
      });
    });
  });
}
