import 'dart:convert';

import 'package:core/models/anime.dart';
import 'package:core/models/book.dart';
import 'package:core/models/canvas_item.dart';
import 'package:core/models/custom_media.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/manga.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/movie.dart';
import 'package:core/models/tv_show.dart';
import 'package:core/models/visual_novel.dart';
import 'package:test/test.dart';
import 'package:core/models/image_type.dart';

import 'package:core/testing/builders.dart';

void main() {
  group('CanvasItemType', () {
    test('should have correct string values', () {
      expect(CanvasItemType.game.value, 'game');
      expect(CanvasItemType.text.value, 'text');
      expect(CanvasItemType.image.value, 'image');
      expect(CanvasItemType.link.value, 'link');
      expect(CanvasItemType.animation.value, 'animation');
      expect(CanvasItemType.visualNovel.value, 'visual_novel');
    });

    test('fromString should return correct type', () {
      expect(CanvasItemType.fromString('game'), CanvasItemType.game);
      expect(CanvasItemType.fromString('text'), CanvasItemType.text);
      expect(CanvasItemType.fromString('image'), CanvasItemType.image);
      expect(CanvasItemType.fromString('link'), CanvasItemType.link);
      expect(CanvasItemType.fromString('visual_novel'),
          CanvasItemType.visualNovel);
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

    test('fromMediaType should return visualNovel for MediaType.visualNovel',
        () {
      expect(
        CanvasItemType.fromMediaType(MediaType.visualNovel),
        CanvasItemType.visualNovel,
      );
    });

    test('isMediaItem should return true for animation', () {
      expect(CanvasItemType.animation.isMediaItem, isTrue);
    });

    test('isMediaItem should return true for visualNovel', () {
      expect(CanvasItemType.visualNovel.isMediaItem, isTrue);
    });

    // Guards the single-source-of-truth contract: the media subset of
    // CanvasItemType must mirror MediaType exactly (same string values), so
    // adding a MediaType without a matching CanvasItemType is caught here.
    test('media subset mirrors MediaType values', () {
      final Set<String> mediaTypeValues =
          MediaType.values.map((MediaType t) => t.value).toSet();
      final Set<String> canvasMediaValues = CanvasItemType.values
          .where((CanvasItemType t) => t.isMediaItem)
          .map((CanvasItemType t) => t.value)
          .toSet();
      expect(canvasMediaValues, mediaTypeValues);
    });

    test('fromMediaType preserves the value for every MediaType', () {
      for (final MediaType mediaType in MediaType.values) {
        expect(
          CanvasItemType.fromMediaType(mediaType).value,
          mediaType.value,
        );
      }
    });
  });

  group('CanvasItem', () {
    // Local date differs from the shared testDate helper.
    final DateTime testDate = DateTime(2024, 6, 15, 12, 0, 0);
    final int testTimestamp = testDate.millisecondsSinceEpoch ~/ 1000;

    test('should create with required parameters', () {
      final CanvasItem item = createTestCanvasItem(
        collectionId: 10,
        x: 50.0,
        createdAt: testDate,
      );

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
      final CanvasItem item = createTestCanvasItem(
        collectionId: 10,
        itemType: CanvasItemType.text,
        itemRefId: null,
        x: 50.0,
        data: <String, dynamic>{'content': 'Hello', 'fontSize': 16},
        createdAt: testDate,
      );

      expect(item.data, isNotNull);
      expect(item.data!['content'], 'Hello');
      expect(item.data!['fontSize'], 16);
    });

    test('should create with collectionItemId', () {
      final CanvasItem item = createTestCanvasItem(
        collectionId: 10,
        collectionItemId: 42,
        x: 50.0,
        createdAt: testDate,
      );

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
        final CanvasItem item = createTestCanvasItem(
          collectionId: 10,
          x: 50.0,
          createdAt: testDate,
        );
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
        final CanvasItem item = createTestCanvasItem(
          collectionId: 10,
          itemType: CanvasItemType.text,
          x: 50.0,
          data: <String, dynamic>{'content': 'Hello'},
          createdAt: testDate,
        );
        final Map<String, dynamic> db = item.toDb();

        expect(db['data'], isA<String>());
        final Map<String, dynamic> parsed =
            json.decode(db['data'] as String) as Map<String, dynamic>;
        expect(parsed['content'], 'Hello');
      });

      test('should omit id when id is 0 (new item)', () {
        final CanvasItem item = createTestCanvasItem(
          id: 0,
          collectionId: 10,
          x: 50.0,
          createdAt: testDate,
        );
        final Map<String, dynamic> db = item.toDb();

        expect(db.containsKey('id'), false);
      });

      test('should serialize collectionItemId to database map', () {
        final CanvasItem item = createTestCanvasItem(
          collectionId: 10,
          collectionItemId: 42,
          x: 50.0,
          createdAt: testDate,
        );
        final Map<String, dynamic> db = item.toDb();

        expect(db['collection_item_id'], 42);
      });

      test('should serialize null collectionItemId', () {
        final CanvasItem item = createTestCanvasItem(
          collectionId: 10,
          x: 50.0,
          createdAt: testDate,
        );
        final Map<String, dynamic> db = item.toDb();

        expect(db.containsKey('collection_item_id'), true);
        expect(db['collection_item_id'], isNull);
      });
    });

    group('toExport', () {
      test('should serialize for export', () {
        final CanvasItem item = createTestCanvasItem(
          collectionId: 10,
          x: 50.0,
          createdAt: testDate,
        );
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
        final CanvasItem item = createTestCanvasItem(
          collectionId: 10,
          x: 50.0,
          data: <String, dynamic>{'content': 'Test'},
          createdAt: testDate,
        );
        final Map<String, dynamic> jsonMap = item.toExport();

        expect(jsonMap['data'], isA<Map<String, dynamic>>());
        expect((jsonMap['data'] as Map<String, dynamic>)['content'], 'Test');
      });

      test('should include collectionItemId in export', () {
        final CanvasItem item = createTestCanvasItem(
          collectionId: 10,
          collectionItemId: 42,
          x: 50.0,
          createdAt: testDate,
        );
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
        final CanvasItem original = createTestCanvasItem(
          collectionId: 10,
          x: 50.0,
          createdAt: testDate,
        );
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
        final CanvasItem original = createTestCanvasItem(
          collectionId: 10,
          x: 50.0,
          createdAt: testDate,
        );
        final CanvasItem copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.x, original.x);
        expect(copy.y, original.y);
        expect(copy.zIndex, original.zIndex);
      });

      test('should copy with changed collectionItemId', () {
        final CanvasItem original = createTestCanvasItem(
          collectionId: 10,
          collectionItemId: 10,
          x: 50.0,
          createdAt: testDate,
        );
        final CanvasItem copy = original.copyWith(collectionItemId: 99);

        expect(copy.collectionItemId, 99);
        expect(original.collectionItemId, 10);
      });
    });

    group('equality', () {
      test('should be equal when id matches', () {
        final CanvasItem item1 = createTestCanvasItem(
          id: 1,
          collectionId: 10,
          x: 0,
          createdAt: testDate,
        );
        final CanvasItem item2 = createTestCanvasItem(
          id: 1,
          collectionId: 10,
          x: 100,
          createdAt: testDate,
        );

        expect(item1, equals(item2));
        expect(item1.hashCode, item2.hashCode);
      });

      test('should be equal to identical object', () {
        final CanvasItem item = createTestCanvasItem(
          id: 1,
          collectionId: 10,
          x: 50.0,
          createdAt: testDate,
        );

        expect(item == item, true);
      });

      test('should not be equal when id differs', () {
        final CanvasItem item1 = createTestCanvasItem(
          id: 1,
          collectionId: 10,
          x: 50.0,
          createdAt: testDate,
        );
        final CanvasItem item2 = createTestCanvasItem(
          id: 2,
          collectionId: 10,
          x: 50.0,
          createdAt: testDate,
        );

        expect(item1, isNot(equals(item2)));
      });

      test('should not be equal to non-CanvasItem object', () {
        final CanvasItem item = createTestCanvasItem(
          id: 1,
          collectionId: 10,
          x: 50.0,
          createdAt: testDate,
        );

        expect(item == Object(), false);
      });
    });

    test('toString should contain type and position', () {
      final CanvasItem item = createTestCanvasItem(
        collectionId: 10,
        x: 50.0,
        createdAt: testDate,
      );
      final String str = item.toString();

      expect(str, contains('id: 1'));
      expect(str, contains('type: game'));
      expect(str, contains('x: 50.0'));
      expect(str, contains('y: 100.0'));
    });

    group('visualNovel media accessors', () {
      const VisualNovel testVn = VisualNovel(
        id: 'v123',
        title: 'Steins;Gate',
        imageUrl: 'https://example.com/sg.jpg',
      );

      test('mediaTitle should return visualNovel title', () {
        final CanvasItem item = CanvasItem(
          id: 1,
          collectionId: 10,
          itemType: CanvasItemType.visualNovel,
          itemRefId: 123,
          x: 0,
          y: 0,
          createdAt: testDate,
          visualNovel: testVn,
        );
        expect(item.mediaTitle, 'Steins;Gate');
      });

      test('mediaTitle should return null when visualNovel is null', () {
        final CanvasItem item = CanvasItem(
          id: 1,
          collectionId: 10,
          itemType: CanvasItemType.visualNovel,
          itemRefId: 123,
          x: 0,
          y: 0,
          createdAt: testDate,
        );
        expect(item.mediaTitle, isNull);
      });

      test('mediaThumbnailUrl should return visualNovel imageUrl', () {
        final CanvasItem item = CanvasItem(
          id: 1,
          collectionId: 10,
          itemType: CanvasItemType.visualNovel,
          itemRefId: 123,
          x: 0,
          y: 0,
          createdAt: testDate,
          visualNovel: testVn,
        );
        expect(item.mediaThumbnailUrl, 'https://example.com/sg.jpg');
      });

      test('mediaImageType should return ImageType.vnCover', () {
        final CanvasItem item = CanvasItem(
          id: 1,
          collectionId: 10,
          itemType: CanvasItemType.visualNovel,
          itemRefId: 123,
          x: 0,
          y: 0,
          createdAt: testDate,
        );
        expect(item.mediaImageType, ImageType.vnCover);
      });

      test('mediaCacheId should return itemRefId as string', () {
        final CanvasItem item = CanvasItem(
          id: 1,
          collectionId: 10,
          itemType: CanvasItemType.visualNovel,
          itemRefId: 456,
          x: 0,
          y: 0,
          createdAt: testDate,
        );
        expect(item.mediaCacheId, '456');
      });

      test('mediaCacheId should return 0 when itemRefId is null', () {
        final CanvasItem item = CanvasItem(
          id: 1,
          collectionId: 10,
          itemType: CanvasItemType.visualNovel,
          x: 0,
          y: 0,
          createdAt: testDate,
        );
        expect(item.mediaCacheId, '0');
      });

      test('mediaCacheId should namespace anime covers by source', () {
        final CanvasItem item = CanvasItem(
          id: 1,
          collectionId: 10,
          itemType: CanvasItemType.anime,
          x: 0,
          y: 0,
          createdAt: testDate,
          anime: createTestAnime(id: 123, source: DataSource.kitsu),
        );
        expect(item.mediaCacheId, 'kitsu_123');
      });

      test('mediaCacheId should use the anilist namespace by default', () {
        final CanvasItem item = CanvasItem(
          id: 1,
          collectionId: 10,
          itemType: CanvasItemType.anime,
          x: 0,
          y: 0,
          createdAt: testDate,
          anime: createTestAnime(id: 123),
        );
        expect(item.mediaCacheId, 'anilist_123');
      });

      test('asMediaType should return MediaType.visualNovel', () {
        final CanvasItem item = CanvasItem(
          id: 1,
          collectionId: 10,
          itemType: CanvasItemType.visualNovel,
          x: 0,
          y: 0,
          createdAt: testDate,
        );
        expect(item.asMediaType, MediaType.visualNovel);
      });
    });

    group('copyWith visualNovel', () {
      test('should copy with visualNovel field', () {
        const VisualNovel vn = VisualNovel(
          id: 'v111',
          title: 'Original VN',
        );
        final CanvasItem original = CanvasItem(
          id: 1,
          collectionId: 10,
          itemType: CanvasItemType.visualNovel,
          itemRefId: 111,
          x: 0,
          y: 0,
          createdAt: testDate,
          visualNovel: vn,
        );

        const VisualNovel newVn = VisualNovel(
          id: 'v222',
          title: 'Updated VN',
        );
        final CanvasItem copy = original.copyWith(visualNovel: newVn);

        expect(copy.visualNovel?.title, 'Updated VN');
        expect(original.visualNovel?.title, 'Original VN');
      });

      test('should preserve visualNovel when not specified', () {
        const VisualNovel vn = VisualNovel(
          id: 'v333',
          title: 'Preserved VN',
        );
        final CanvasItem original = CanvasItem(
          id: 1,
          collectionId: 10,
          itemType: CanvasItemType.visualNovel,
          itemRefId: 333,
          x: 0,
          y: 0,
          createdAt: testDate,
          visualNovel: vn,
        );

        final CanvasItem copy = original.copyWith(x: 100);

        expect(copy.visualNovel?.title, 'Preserved VN');
        expect(copy.x, 100);
      });
    });

    group('overrideName', () {
      test('mediaTitle returns override when set', () {
        final CanvasItem item = CanvasItem(
          id: 1,
          collectionId: 10,
          itemType: CanvasItemType.game,
          itemRefId: 100,
          x: 0,
          y: 0,
          createdAt: testDate,
          game: createTestGame(name: 'Final Fantasy VII Remake'),
          overrideName: 'FF7R',
        );
        expect(item.mediaTitle, 'FF7R');
      });

      test('mediaTitle falls back to cached name when override is null', () {
        final CanvasItem item = CanvasItem(
          id: 1,
          collectionId: 10,
          itemType: CanvasItemType.game,
          itemRefId: 100,
          x: 0,
          y: 0,
          createdAt: testDate,
          game: createTestGame(name: 'Final Fantasy VII Remake'),
        );
        expect(item.mediaTitle, 'Final Fantasy VII Remake');
      });

      test('fromDb reads override_name from joined column', () {
        final CanvasItem item = CanvasItem.fromDb(<String, dynamic>{
          'id': 1,
          'collection_id': 10,
          'item_type': 'game',
          'item_ref_id': 100,
          'x': 0,
          'y': 0,
          'created_at': testDate.millisecondsSinceEpoch ~/ 1000,
          'override_name': 'FF7R',
        });
        expect(item.overrideName, 'FF7R');
      });

      test('copyWith preserves overrideName when enrichment runs', () {
        final CanvasItem original = CanvasItem(
          id: 1,
          collectionId: 10,
          itemType: CanvasItemType.game,
          itemRefId: 100,
          x: 0,
          y: 0,
          createdAt: testDate,
          overrideName: 'FF7R',
        );
        final CanvasItem enriched = original.copyWith(
          game: createTestGame(name: 'Final Fantasy VII Remake'),
        );
        expect(enriched.overrideName, 'FF7R');
        expect(enriched.mediaTitle, 'FF7R');
      });

      test('copyWith with clearOverrideName drops the override', () {
        final CanvasItem original = CanvasItem(
          id: 1,
          collectionId: 10,
          itemType: CanvasItemType.game,
          itemRefId: 100,
          x: 0,
          y: 0,
          createdAt: testDate,
          overrideName: 'FF7R',
          game: createTestGame(name: 'Final Fantasy VII Remake'),
        );
        final CanvasItem cleared = original.copyWith(clearOverrideName: true);
        expect(cleared.overrideName, isNull);
        expect(cleared.mediaTitle, 'Final Fantasy VII Remake');
      });
    });

    group('media accessors per item type', () {
      CanvasItem itemOf(
        CanvasItemType type, {
        Manga? manga,
        Anime? anime,
        Book? book,
        CustomMedia? customMedia,
        TvShow? tvShow,
        Movie? movie,
      }) =>
          CanvasItem(
            id: 1,
            collectionId: 10,
            itemType: type,
            itemRefId: 1,
            x: 0,
            y: 0,
            createdAt: testDate,
            manga: manga,
            anime: anime,
            book: book,
            customMedia: customMedia,
            tvShow: tvShow,
            movie: movie,
          );

      group('manga', () {
        test('exposes title, cover and image type', () {
          final CanvasItem item = itemOf(
            CanvasItemType.manga,
            manga: createTestManga(
              title: 'Berserk',
              coverUrl: 'https://example.com/berserk.jpg',
            ),
          );

          expect(item.mediaTitle, 'Berserk');
          expect(item.mediaThumbnailUrl, 'https://example.com/berserk.jpg');
          expect(item.mediaImageType, ImageType.mangaCover);
          expect(item.asMediaType, MediaType.manga);
        });

        test('namespaces the cache id by source', () {
          final CanvasItem anilist = itemOf(
            CanvasItemType.manga,
            manga: createTestManga(id: 42),
          );
          final CanvasItem mangadex = itemOf(
            CanvasItemType.manga,
            manga: createTestManga(id: 42, source: DataSource.mangadex),
          );

          expect(anilist.mediaCacheId, isNot(mangadex.mediaCacheId));
          expect(anilist.mediaCacheId, contains('42'));
        });

        test('falls back to a zero cache id when the join is missing', () {
          expect(itemOf(CanvasItemType.manga).mediaTitle, isNull);
          expect(itemOf(CanvasItemType.manga).mediaThumbnailUrl, isNull);
          expect(itemOf(CanvasItemType.manga).mediaCacheId, contains('0'));
        });
      });

      group('anime', () {
        test('exposes title, cover and image type', () {
          final CanvasItem item = itemOf(
            CanvasItemType.anime,
            anime: createTestAnime(
              title: 'Cowboy Bebop',
              coverUrl: 'https://example.com/bebop.jpg',
            ),
          );

          expect(item.mediaTitle, 'Cowboy Bebop');
          expect(item.mediaThumbnailUrl, 'https://example.com/bebop.jpg');
          expect(item.mediaImageType, ImageType.animeCover);
          expect(item.asMediaType, MediaType.anime);
        });

        test('returns nulls when the join is missing', () {
          expect(itemOf(CanvasItemType.anime).mediaTitle, isNull);
          expect(itemOf(CanvasItemType.anime).mediaThumbnailUrl, isNull);
        });
      });

      group('book', () {
        test('exposes title, cover and image type', () {
          final CanvasItem item = itemOf(
            CanvasItemType.book,
            book: createTestBook(
              title: 'Dune',
              coverUrl: 'https://example.com/dune.jpg',
            ),
          );

          expect(item.mediaTitle, 'Dune');
          expect(item.mediaThumbnailUrl, 'https://example.com/dune.jpg');
          expect(item.mediaImageType, ImageType.bookCover);
          expect(item.asMediaType, MediaType.book);
        });

        test('namespaces the cache id by source', () {
          final CanvasItem openLibrary = itemOf(
            CanvasItemType.book,
            book: createTestBook(id: '42'),
          );
          final CanvasItem fantlab = itemOf(
            CanvasItemType.book,
            book: createTestBook(id: '42', source: DataSource.fantlab),
          );

          expect(openLibrary.mediaCacheId, isNot(fantlab.mediaCacheId));
        });

        test('returns nulls when the join is missing', () {
          expect(itemOf(CanvasItemType.book).mediaTitle, isNull);
          expect(itemOf(CanvasItemType.book).mediaThumbnailUrl, isNull);
        });
      });

      group('custom', () {
        test('exposes title, cover and image type', () {
          final CanvasItem item = itemOf(
            CanvasItemType.custom,
            customMedia: const CustomMedia(
              id: 3,
              title: 'My card',
              coverUrl: 'https://example.com/card.jpg',
            ),
          );

          expect(item.mediaTitle, 'My card');
          expect(item.mediaThumbnailUrl, 'https://example.com/card.jpg');
          expect(item.mediaImageType, ImageType.customCover);
          expect(item.mediaCacheId, '3');
        });

        test('asMediaType borrows the display type when set', () {
          final CanvasItem item = itemOf(
            CanvasItemType.custom,
            customMedia: const CustomMedia(
              id: 3,
              title: 'My card',
              displayType: MediaType.manga,
            ),
          );

          expect(item.asMediaType, MediaType.manga);
        });

        test('asMediaType stays custom without a display type', () {
          final CanvasItem item = itemOf(
            CanvasItemType.custom,
            customMedia: const CustomMedia(id: 3, title: 'My card'),
          );

          expect(item.asMediaType, MediaType.custom);
        });

        test('cache id is 0 when the join is missing', () {
          expect(itemOf(CanvasItemType.custom).mediaCacheId, '0');
        });
      });

      group('tvShow', () {
        test('namespaces the cache id, unlike a bare tmdb id', () {
          final CanvasItem item = itemOf(
            CanvasItemType.tvShow,
            tvShow: createTestTvShow(tmdbId: 77),
          );

          expect(item.mediaCacheId, contains('77'));
          expect(item.asMediaType, MediaType.tvShow);
        });
      });

      group('animation', () {
        test('prefers the tv show over the movie when both are joined', () {
          final CanvasItem item = itemOf(
            CanvasItemType.animation,
            tvShow: createTestTvShow(
              tmdbId: 77,
              title: 'Show',
              posterUrl: 'https://example.com/show.jpg',
            ),
            movie: createTestMovie(tmdbId: 88, title: 'Movie'),
          );

          expect(item.mediaTitle, 'Movie');
          expect(item.mediaImageType, ImageType.tvShowPoster);
          expect(item.mediaCacheId, '77');
        });

        test('falls back to the movie when no tv show is joined', () {
          final CanvasItem item = itemOf(
            CanvasItemType.animation,
            movie: createTestMovie(tmdbId: 88, title: 'Movie'),
          );

          expect(item.mediaTitle, 'Movie');
          expect(item.mediaImageType, ImageType.moviePoster);
          expect(item.mediaCacheId, '88');
        });
      });
    });
  });
}
