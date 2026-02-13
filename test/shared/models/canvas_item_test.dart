import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/canvas_item.dart';
import 'package:xerabora/shared/models/media_type.dart';

void main() {
  group('CanvasItemType', () {
    test('should have correct string values', () {
      expect(CanvasItemType.game.value, 'game');
      expect(CanvasItemType.text.value, 'text');
      expect(CanvasItemType.image.value, 'image');
      expect(CanvasItemType.link.value, 'link');
      expect(CanvasItemType.animation.value, 'animation');
    });

    test('fromString should return correct type', () {
      expect(CanvasItemType.fromString('game'), CanvasItemType.game);
      expect(CanvasItemType.fromString('text'), CanvasItemType.text);
      expect(CanvasItemType.fromString('image'), CanvasItemType.image);
      expect(CanvasItemType.fromString('link'), CanvasItemType.link);
    });

    test('fromString should return game for unknown value', () {
      expect(CanvasItemType.fromString('unknown'), CanvasItemType.game);
      expect(CanvasItemType.fromString(''), CanvasItemType.game);
    });

    test('fromMediaType should return animation for MediaType.animation', () {
      expect(
        CanvasItemType.fromMediaType(MediaType.animation),
        CanvasItemType.animation,
      );
    });

    test('isMediaItem should return true for animation', () {
      expect(CanvasItemType.animation.isMediaItem, isTrue);
    });
  });

  group('CanvasItem', () {
    final DateTime testDate = DateTime(2024, 6, 15, 12, 0, 0);
    final int testTimestamp = testDate.millisecondsSinceEpoch ~/ 1000;

    CanvasItem createTestItem({
      int id = 1,
      int collectionId = 10,
      int? collectionItemId,
      CanvasItemType itemType = CanvasItemType.game,
      int? itemRefId = 100,
      double x = 50.0,
      double y = 100.0,
      double? width = 160.0,
      double? height = 220.0,
      int zIndex = 0,
      Map<String, dynamic>? data,
    }) {
      return CanvasItem(
        id: id,
        collectionId: collectionId,
        collectionItemId: collectionItemId,
        itemType: itemType,
        itemRefId: itemRefId,
        x: x,
        y: y,
        width: width,
        height: height,
        zIndex: zIndex,
        data: data,
        createdAt: testDate,
      );
    }

    test('should create with required parameters', () {
      final CanvasItem item = createTestItem();

      expect(item.id, 1);
      expect(item.collectionId, 10);
      expect(item.itemType, CanvasItemType.game);
      expect(item.itemRefId, 100);
      expect(item.x, 50.0);
      expect(item.y, 100.0);
      expect(item.width, 160.0);
      expect(item.height, 220.0);
      expect(item.zIndex, 0);
      expect(item.data, isNull);
      expect(item.game, isNull);
      expect(item.createdAt, testDate);
    });

    test('should create with data map', () {
      final CanvasItem item = createTestItem(
        itemType: CanvasItemType.text,
        itemRefId: null,
        data: <String, dynamic>{'content': 'Hello', 'fontSize': 16},
      );

      expect(item.data, isNotNull);
      expect(item.data!['content'], 'Hello');
      expect(item.data!['fontSize'], 16);
    });

    test('should create with collectionItemId', () {
      final CanvasItem item = createTestItem(collectionItemId: 42);

      expect(item.collectionItemId, 42);
      expect(item.id, 1);
      expect(item.collectionId, 10);
    });

    group('fromDb', () {
      test('should parse game item from database row', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 1,
          'collection_id': 10,
          'item_type': 'game',
          'item_ref_id': 100,
          'x': 50.0,
          'y': 100.0,
          'width': 160.0,
          'height': 220.0,
          'z_index': 3,
          'data': null,
          'created_at': testTimestamp,
        };

        final CanvasItem item = CanvasItem.fromDb(row);

        expect(item.id, 1);
        expect(item.collectionId, 10);
        expect(item.itemType, CanvasItemType.game);
        expect(item.itemRefId, 100);
        expect(item.x, 50.0);
        expect(item.y, 100.0);
        expect(item.width, 160.0);
        expect(item.height, 220.0);
        expect(item.zIndex, 3);
        expect(item.data, isNull);
      });

      test('should parse item with JSON data', () {
        final Map<String, dynamic> dataMap = <String, dynamic>{
          'content': 'Test text',
          'fontSize': 14,
        };
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 2,
          'collection_id': 10,
          'item_type': 'text',
          'item_ref_id': null,
          'x': 200.0,
          'y': 300.0,
          'width': null,
          'height': null,
          'z_index': null,
          'data': json.encode(dataMap),
          'created_at': testTimestamp,
        };

        final CanvasItem item = CanvasItem.fromDb(row);

        expect(item.itemType, CanvasItemType.text);
        expect(item.itemRefId, isNull);
        expect(item.width, isNull);
        expect(item.zIndex, 0);
        expect(item.data, isNotNull);
        expect(item.data!['content'], 'Test text');
        expect(item.data!['fontSize'], 14);
      });

      test('should handle empty string data', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 3,
          'collection_id': 10,
          'item_type': 'text',
          'item_ref_id': null,
          'x': 0.0,
          'y': 0.0,
          'width': null,
          'height': null,
          'z_index': 0,
          'data': '',
          'created_at': testTimestamp,
        };

        final CanvasItem item = CanvasItem.fromDb(row);

        expect(item.data, isNull);
      });

      test('should handle integer x and y values', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 1,
          'collection_id': 10,
          'item_type': 'game',
          'item_ref_id': 100,
          'x': 50,
          'y': 100,
          'width': null,
          'height': null,
          'z_index': 0,
          'data': null,
          'created_at': testTimestamp,
        };

        final CanvasItem item = CanvasItem.fromDb(row);
        expect(item.x, 50.0);
        expect(item.y, 100.0);
      });

      test('should parse collectionItemId from database row', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 1,
          'collection_id': 10,
          'collection_item_id': 42,
          'item_type': 'game',
          'item_ref_id': 100,
          'x': 50.0,
          'y': 100.0,
          'width': 160.0,
          'height': 220.0,
          'z_index': 0,
          'data': null,
          'created_at': testTimestamp,
        };

        final CanvasItem item = CanvasItem.fromDb(row);

        expect(item.collectionItemId, 42);
      });

      test('should handle null collectionItemId', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 1,
          'collection_id': 10,
          'collection_item_id': null,
          'item_type': 'game',
          'item_ref_id': 100,
          'x': 50.0,
          'y': 100.0,
          'width': null,
          'height': null,
          'z_index': 0,
          'data': null,
          'created_at': testTimestamp,
        };

        final CanvasItem item = CanvasItem.fromDb(row);

        expect(item.collectionItemId, isNull);
      });
    });

    group('toDb', () {
      test('should serialize game item to database map', () {
        final CanvasItem item = createTestItem();
        final Map<String, dynamic> db = item.toDb();

        expect(db['id'], 1);
        expect(db['collection_id'], 10);
        expect(db['item_type'], 'game');
        expect(db['item_ref_id'], 100);
        expect(db['x'], 50.0);
        expect(db['y'], 100.0);
        expect(db['width'], 160.0);
        expect(db['height'], 220.0);
        expect(db['z_index'], 0);
        expect(db['data'], isNull);
        expect(db['created_at'], testTimestamp);
      });

      test('should serialize data map as JSON string', () {
        final CanvasItem item = createTestItem(
          itemType: CanvasItemType.text,
          data: <String, dynamic>{'content': 'Hello'},
        );
        final Map<String, dynamic> db = item.toDb();

        expect(db['data'], isA<String>());
        final Map<String, dynamic> parsed =
            json.decode(db['data'] as String) as Map<String, dynamic>;
        expect(parsed['content'], 'Hello');
      });

      test('should omit id when id is 0 (new item)', () {
        final CanvasItem item = createTestItem(id: 0);
        final Map<String, dynamic> db = item.toDb();

        expect(db.containsKey('id'), false);
      });

      test('should serialize collectionItemId to database map', () {
        final CanvasItem item = createTestItem(collectionItemId: 42);
        final Map<String, dynamic> db = item.toDb();

        expect(db['collection_item_id'], 42);
      });

      test('should serialize null collectionItemId', () {
        final CanvasItem item = createTestItem();
        final Map<String, dynamic> db = item.toDb();

        expect(db.containsKey('collection_item_id'), true);
        expect(db['collection_item_id'], isNull);
      });
    });

    group('toExport', () {
      test('should serialize for export', () {
        final CanvasItem item = createTestItem();
        final Map<String, dynamic> jsonMap = item.toExport();

        expect(jsonMap['id'], 1);
        expect(jsonMap['type'], 'game');
        expect(jsonMap['refId'], 100);
        expect(jsonMap['x'], 50.0);
        expect(jsonMap['y'], 100.0);
        expect(jsonMap['width'], 160.0);
        expect(jsonMap['height'], 220.0);
        expect(jsonMap['z_index'], 0);
        expect(jsonMap['data'], isNull);
        expect(jsonMap['created_at'], testTimestamp);
      });

      test('should include data map in export', () {
        final CanvasItem item = createTestItem(
          data: <String, dynamic>{'content': 'Test'},
        );
        final Map<String, dynamic> jsonMap = item.toExport();

        expect(jsonMap['data'], isA<Map<String, dynamic>>());
        expect((jsonMap['data'] as Map<String, dynamic>)['content'], 'Test');
      });

      test('should include collectionItemId in export', () {
        final CanvasItem item = createTestItem(collectionItemId: 42);
        final Map<String, dynamic> jsonMap = item.toExport();

        expect(jsonMap['collection_item_id'], 42);
      });
    });

    group('fromExport', () {
      test('should parse from export JSON', () {
        final Map<String, dynamic> jsonMap = <String, dynamic>{
          'id': 5,
          'type': 'image',
          'refId': null,
          'x': 400,
          'y': 100,
          'width': 500,
          'height': 400,
          'data': <String, dynamic>{
            'url': 'https://example.com/image.png',
          },
        };

        final CanvasItem item = CanvasItem.fromExport(jsonMap);

        expect(item.id, 5);
        expect(item.itemType, CanvasItemType.image);
        expect(item.itemRefId, isNull);
        expect(item.x, 400.0);
        expect(item.y, 100.0);
        expect(item.data!['url'], 'https://example.com/image.png');
      });

      test('should use defaults for missing fields', () {
        final Map<String, dynamic> jsonMap = <String, dynamic>{
          'x': 0,
          'y': 0,
        };

        final CanvasItem item = CanvasItem.fromExport(jsonMap);

        expect(item.id, 0);
        expect(item.collectionId, 0);
        expect(item.itemType, CanvasItemType.game);
        expect(item.zIndex, 0);
      });

      test('should parse created_at from JSON when present', () {
        final int timestamp = testDate.millisecondsSinceEpoch ~/ 1000;
        final Map<String, dynamic> jsonMap = <String, dynamic>{
          'x': 0,
          'y': 0,
          'created_at': timestamp,
        };

        final CanvasItem item = CanvasItem.fromExport(jsonMap);

        expect(
          item.createdAt,
          DateTime.fromMillisecondsSinceEpoch(timestamp * 1000),
        );
      });

      test('should parse collectionItemId from JSON', () {
        final Map<String, dynamic> jsonMap = <String, dynamic>{
          'id': 5,
          'collection_id': 10,
          'collection_item_id': 42,
          'type': 'game',
          'x': 50,
          'y': 100,
        };

        final CanvasItem item = CanvasItem.fromExport(jsonMap);

        expect(item.collectionItemId, 42);
      });
    });

    group('copyWith', () {
      test('should create copy with changed fields', () {
        final CanvasItem original = createTestItem();
        final CanvasItem copy = original.copyWith(
          x: 200.0,
          y: 300.0,
          zIndex: 5,
        );

        expect(copy.id, original.id);
        expect(copy.collectionId, original.collectionId);
        expect(copy.x, 200.0);
        expect(copy.y, 300.0);
        expect(copy.zIndex, 5);
        expect(copy.itemType, original.itemType);
      });

      test('should keep original values when not specified', () {
        final CanvasItem original = createTestItem();
        final CanvasItem copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.x, original.x);
        expect(copy.y, original.y);
        expect(copy.zIndex, original.zIndex);
      });

      test('should copy with changed collectionItemId', () {
        final CanvasItem original = createTestItem(collectionItemId: 10);
        final CanvasItem copy = original.copyWith(collectionItemId: 99);

        expect(copy.collectionItemId, 99);
        expect(original.collectionItemId, 10);
      });
    });

    group('equality', () {
      test('should be equal when id matches', () {
        final CanvasItem item1 = createTestItem(id: 1, x: 0);
        final CanvasItem item2 = createTestItem(id: 1, x: 100);

        expect(item1, equals(item2));
        expect(item1.hashCode, item2.hashCode);
      });

      test('should be equal to identical object', () {
        final CanvasItem item = createTestItem(id: 1);

        expect(item == item, true);
      });

      test('should not be equal when id differs', () {
        final CanvasItem item1 = createTestItem(id: 1);
        final CanvasItem item2 = createTestItem(id: 2);

        expect(item1, isNot(equals(item2)));
      });

      test('should not be equal to non-CanvasItem object', () {
        final CanvasItem item = createTestItem(id: 1);

        expect(item == Object(), false);
      });
    });

    test('toString should contain type and position', () {
      final CanvasItem item = createTestItem();
      final String str = item.toString();

      expect(str, contains('id: 1'));
      expect(str, contains('type: game'));
      expect(str, contains('x: 50.0'));
      expect(str, contains('y: 100.0'));
    });
  });
}
