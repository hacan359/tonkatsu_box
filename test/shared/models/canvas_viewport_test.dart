import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/canvas_viewport.dart';

void main() {
  group('CanvasViewport', () {
    test('should create with default values', () {
      const CanvasViewport viewport = CanvasViewport(collectionId: 1);

      expect(viewport.collectionId, 1);
      expect(viewport.scale, 1.0);
      expect(viewport.offsetX, 0.0);
      expect(viewport.offsetY, 0.0);
    });

    test('should create with custom values', () {
      const CanvasViewport viewport = CanvasViewport(
        collectionId: 5,
        scale: 1.5,
        offsetX: -100.0,
        offsetY: -200.0,
      );

      expect(viewport.collectionId, 5);
      expect(viewport.scale, 1.5);
      expect(viewport.offsetX, -100.0);
      expect(viewport.offsetY, -200.0);
    });

    test('defaultValue should have zero collectionId and default scale', () {
      expect(CanvasViewport.defaultValue.collectionId, 0);
      expect(CanvasViewport.defaultValue.scale, 1.0);
      expect(CanvasViewport.defaultValue.offsetX, 0.0);
      expect(CanvasViewport.defaultValue.offsetY, 0.0);
    });

    group('fromDb', () {
      test('should parse from database row', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'collection_id': 3,
          'scale': 2.0,
          'offset_x': -50.0,
          'offset_y': -75.0,
        };

        final CanvasViewport viewport = CanvasViewport.fromDb(row);

        expect(viewport.collectionId, 3);
        expect(viewport.scale, 2.0);
        expect(viewport.offsetX, -50.0);
        expect(viewport.offsetY, -75.0);
      });

      test('should use defaults for null values', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'collection_id': 1,
          'scale': null,
          'offset_x': null,
          'offset_y': null,
        };

        final CanvasViewport viewport = CanvasViewport.fromDb(row);

        expect(viewport.scale, 1.0);
        expect(viewport.offsetX, 0.0);
        expect(viewport.offsetY, 0.0);
      });

      test('should handle integer values for scale and offset', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'collection_id': 1,
          'scale': 2,
          'offset_x': -50,
          'offset_y': 100,
        };

        final CanvasViewport viewport = CanvasViewport.fromDb(row);

        expect(viewport.scale, 2.0);
        expect(viewport.offsetX, -50.0);
        expect(viewport.offsetY, 100.0);
      });
    });

    group('fromJson', () {
      test('should parse from export JSON', () {
        final Map<String, dynamic> jsonMap = <String, dynamic>{
          'scale': 1.5,
          'offsetX': -100.0,
          'offsetY': -200.0,
        };

        final CanvasViewport viewport =
            CanvasViewport.fromJson(jsonMap, collectionId: 7);

        expect(viewport.collectionId, 7);
        expect(viewport.scale, 1.5);
        expect(viewport.offsetX, -100.0);
        expect(viewport.offsetY, -200.0);
      });

      test('should use defaults for missing fields', () {
        final CanvasViewport viewport =
            CanvasViewport.fromJson(<String, dynamic>{});

        expect(viewport.collectionId, 0);
        expect(viewport.scale, 1.0);
        expect(viewport.offsetX, 0.0);
        expect(viewport.offsetY, 0.0);
      });
    });

    group('toDb', () {
      test('should serialize to database map', () {
        const CanvasViewport viewport = CanvasViewport(
          collectionId: 3,
          scale: 1.5,
          offsetX: -100.0,
          offsetY: -200.0,
        );

        final Map<String, dynamic> db = viewport.toDb();

        expect(db['collection_id'], 3);
        expect(db['scale'], 1.5);
        expect(db['offset_x'], -100.0);
        expect(db['offset_y'], -200.0);
      });
    });

    group('toJson', () {
      test('should serialize for export', () {
        const CanvasViewport viewport = CanvasViewport(
          collectionId: 3,
          scale: 1.5,
          offsetX: -100.0,
          offsetY: -200.0,
        );

        final Map<String, dynamic> jsonMap = viewport.toJson();

        expect(jsonMap['scale'], 1.5);
        expect(jsonMap['offsetX'], -100.0);
        expect(jsonMap['offsetY'], -200.0);
        expect(jsonMap.containsKey('collection_id'), false);
      });
    });

    group('copyWith', () {
      test('should create copy with changed fields', () {
        const CanvasViewport original = CanvasViewport(
          collectionId: 1,
          scale: 1.0,
          offsetX: 0.0,
          offsetY: 0.0,
        );

        final CanvasViewport copy = original.copyWith(
          scale: 2.5,
          offsetX: -300.0,
        );

        expect(copy.collectionId, 1);
        expect(copy.scale, 2.5);
        expect(copy.offsetX, -300.0);
        expect(copy.offsetY, 0.0);
      });

      test('should keep original values when not specified', () {
        const CanvasViewport original = CanvasViewport(
          collectionId: 5,
          scale: 1.5,
          offsetX: -100.0,
          offsetY: -200.0,
        );

        final CanvasViewport copy = original.copyWith();

        expect(copy.collectionId, original.collectionId);
        expect(copy.scale, original.scale);
        expect(copy.offsetX, original.offsetX);
        expect(copy.offsetY, original.offsetY);
      });
    });

    group('equality', () {
      test('should be equal when collectionId matches', () {
        const CanvasViewport v1 = CanvasViewport(
          collectionId: 1,
          scale: 1.0,
        );
        const CanvasViewport v2 = CanvasViewport(
          collectionId: 1,
          scale: 2.0,
        );

        expect(v1, equals(v2));
        expect(v1.hashCode, v2.hashCode);
      });

      test('should be equal to identical object', () {
        const CanvasViewport viewport = CanvasViewport(collectionId: 1);

        expect(viewport == viewport, true);
      });

      test('should not be equal when collectionId differs', () {
        const CanvasViewport v1 = CanvasViewport(collectionId: 1);
        const CanvasViewport v2 = CanvasViewport(collectionId: 2);

        expect(v1, isNot(equals(v2)));
      });

      test('should not be equal to non-CanvasViewport object', () {
        const CanvasViewport viewport = CanvasViewport(collectionId: 1);

        expect(viewport == Object(), false);
      });
    });

    test('toString should contain collection id and scale', () {
      const CanvasViewport viewport = CanvasViewport(
        collectionId: 3,
        scale: 1.5,
        offsetX: -100.0,
        offsetY: -200.0,
      );

      final String str = viewport.toString();

      expect(str, contains('collectionId: 3'));
      expect(str, contains('scale: 1.5'));
      expect(str, contains('-100.0'));
      expect(str, contains('-200.0'));
    });
  });
}
