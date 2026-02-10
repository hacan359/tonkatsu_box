import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/canvas_connection.dart';

void main() {
  group('ConnectionStyle', () {
    test('should have correct string values', () {
      expect(ConnectionStyle.solid.value, 'solid');
      expect(ConnectionStyle.dashed.value, 'dashed');
      expect(ConnectionStyle.arrow.value, 'arrow');
    });

    test('fromString should return correct style', () {
      expect(ConnectionStyle.fromString('solid'), ConnectionStyle.solid);
      expect(ConnectionStyle.fromString('dashed'), ConnectionStyle.dashed);
      expect(ConnectionStyle.fromString('arrow'), ConnectionStyle.arrow);
    });

    test('fromString should return solid for unknown value', () {
      expect(ConnectionStyle.fromString('unknown'), ConnectionStyle.solid);
      expect(ConnectionStyle.fromString(''), ConnectionStyle.solid);
    });
  });

  group('CanvasConnection', () {
    final DateTime testDate = DateTime(2024, 6, 15, 12, 0, 0);
    final int testTimestamp = testDate.millisecondsSinceEpoch ~/ 1000;

    CanvasConnection createTestConnection({
      int id = 1,
      int collectionId = 10,
      int? collectionItemId,
      int fromItemId = 100,
      int toItemId = 200,
      String? label,
      String color = '#FF0000',
      ConnectionStyle style = ConnectionStyle.solid,
    }) {
      return CanvasConnection(
        id: id,
        collectionId: collectionId,
        collectionItemId: collectionItemId,
        fromItemId: fromItemId,
        toItemId: toItemId,
        label: label,
        color: color,
        style: style,
        createdAt: testDate,
      );
    }

    test('should create with required parameters', () {
      final CanvasConnection conn = createTestConnection();
      expect(conn.id, 1);
      expect(conn.collectionId, 10);
      expect(conn.fromItemId, 100);
      expect(conn.toItemId, 200);
      expect(conn.label, isNull);
      expect(conn.color, '#FF0000');
      expect(conn.style, ConnectionStyle.solid);
      expect(conn.createdAt, testDate);
    });

    test('should create with default color and style', () {
      final CanvasConnection conn = CanvasConnection(
        id: 1,
        collectionId: 10,
        fromItemId: 100,
        toItemId: 200,
        createdAt: testDate,
      );
      expect(conn.color, '#666666');
      expect(conn.style, ConnectionStyle.solid);
      expect(conn.label, isNull);
    });

    test('should create with collectionItemId', () {
      final CanvasConnection conn = createTestConnection(
        collectionItemId: 42,
      );
      expect(conn.collectionItemId, 42);
    });

    group('fromDb', () {
      test('should parse all fields correctly', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 1,
          'collection_id': 10,
          'from_item_id': 100,
          'to_item_id': 200,
          'label': 'depends on',
          'color': '#FF0000',
          'style': 'arrow',
          'created_at': testTimestamp,
        };

        final CanvasConnection conn = CanvasConnection.fromDb(row);
        expect(conn.id, 1);
        expect(conn.collectionId, 10);
        expect(conn.fromItemId, 100);
        expect(conn.toItemId, 200);
        expect(conn.label, 'depends on');
        expect(conn.color, '#FF0000');
        expect(conn.style, ConnectionStyle.arrow);
        expect(conn.createdAt.millisecondsSinceEpoch ~/ 1000, testTimestamp);
      });

      test('should use defaults for null color and style', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 1,
          'collection_id': 10,
          'from_item_id': 100,
          'to_item_id': 200,
          'label': null,
          'color': null,
          'style': null,
          'created_at': testTimestamp,
        };

        final CanvasConnection conn = CanvasConnection.fromDb(row);
        expect(conn.label, isNull);
        expect(conn.color, '#666666');
        expect(conn.style, ConnectionStyle.solid);
      });

      test('should parse dashed style', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 2,
          'collection_id': 10,
          'from_item_id': 100,
          'to_item_id': 200,
          'label': null,
          'color': '#00FF00',
          'style': 'dashed',
          'created_at': testTimestamp,
        };

        final CanvasConnection conn = CanvasConnection.fromDb(row);
        expect(conn.style, ConnectionStyle.dashed);
      });

      test('should parse collectionItemId from database row', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 3,
          'collection_id': 10,
          'collection_item_id': 55,
          'from_item_id': 100,
          'to_item_id': 200,
          'label': null,
          'color': '#FF0000',
          'style': 'solid',
          'created_at': testTimestamp,
        };

        final CanvasConnection conn = CanvasConnection.fromDb(row);
        expect(conn.collectionItemId, 55);
      });

      test('should handle null collectionItemId', () {
        final Map<String, dynamic> row = <String, dynamic>{
          'id': 4,
          'collection_id': 10,
          'collection_item_id': null,
          'from_item_id': 100,
          'to_item_id': 200,
          'label': null,
          'color': '#FF0000',
          'style': 'solid',
          'created_at': testTimestamp,
        };

        final CanvasConnection conn = CanvasConnection.fromDb(row);
        expect(conn.collectionItemId, isNull);
      });
    });

    group('fromExport', () {
      test('should parse all fields correctly', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 1,
          'collection_id': 10,
          'from_item_id': 100,
          'to_item_id': 200,
          'label': 'test label',
          'color': '#0000FF',
          'style': 'dashed',
          'created_at': testTimestamp,
        };

        final CanvasConnection conn =
            CanvasConnection.fromExport(json, collectionId: 10);
        expect(conn.id, 1);
        expect(conn.collectionId, 10);
        expect(conn.fromItemId, 100);
        expect(conn.toItemId, 200);
        expect(conn.label, 'test label');
        expect(conn.color, '#0000FF');
        expect(conn.style, ConnectionStyle.dashed);
      });

      test('should use defaults for missing optional fields', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'from_item_id': 100,
          'to_item_id': 200,
        };

        final CanvasConnection conn = CanvasConnection.fromExport(json);
        expect(conn.id, 0);
        expect(conn.collectionId, 0);
        expect(conn.label, isNull);
        expect(conn.color, '#666666');
        expect(conn.style, ConnectionStyle.solid);
      });

      test('should use current time when created_at is null', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'from_item_id': 100,
          'to_item_id': 200,
          'created_at': null,
        };
        final CanvasConnection conn = CanvasConnection.fromExport(json);
        // Should be close to now
        expect(
          conn.createdAt.difference(DateTime.now()).inSeconds.abs(),
          lessThan(2),
        );
      });

      test('should parse collectionItemId from JSON', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': 5,
          'collection_id': 10,
          'collection_item_id': 33,
          'from_item_id': 100,
          'to_item_id': 200,
          'label': null,
          'color': '#FF0000',
          'style': 'solid',
          'created_at': testTimestamp,
        };

        final CanvasConnection conn = CanvasConnection.fromExport(json);
        expect(conn.collectionItemId, 33);
      });
    });

    group('toDb', () {
      test('should convert all fields', () {
        final CanvasConnection conn = createTestConnection(
          label: 'test',
        );

        final Map<String, dynamic> db = conn.toDb();
        expect(db['id'], 1);
        expect(db['collection_id'], 10);
        expect(db['from_item_id'], 100);
        expect(db['to_item_id'], 200);
        expect(db['label'], 'test');
        expect(db['color'], '#FF0000');
        expect(db['style'], 'solid');
        expect(db['created_at'], testTimestamp);
      });

      test('should omit id when id is 0', () {
        final CanvasConnection conn = createTestConnection(id: 0);
        final Map<String, dynamic> db = conn.toDb();
        expect(db.containsKey('id'), isFalse);
      });

      test('should include null label', () {
        final CanvasConnection conn = createTestConnection();
        final Map<String, dynamic> db = conn.toDb();
        expect(db['label'], isNull);
      });

      test('should serialize collectionItemId to database map', () {
        final CanvasConnection conn = createTestConnection(
          collectionItemId: 77,
        );
        final Map<String, dynamic> db = conn.toDb();
        expect(db['collection_item_id'], 77);
      });
    });

    group('toExport', () {
      test('should convert all fields', () {
        final CanvasConnection conn = createTestConnection(
          label: 'json test',
          style: ConnectionStyle.arrow,
        );

        final Map<String, dynamic> json = conn.toExport();
        expect(json['id'], 1);
        expect(json['from_item_id'], 100);
        expect(json['to_item_id'], 200);
        expect(json['label'], 'json test');
        expect(json['color'], '#FF0000');
        expect(json['style'], 'arrow');
        expect(json['created_at'], testTimestamp);
      });

      test('should not contain collection_id', () {
        final CanvasConnection conn = createTestConnection();
        final Map<String, dynamic> json = conn.toExport();
        expect(json.containsKey('collection_id'), isFalse);
      });

      test('should include collectionItemId in export when set', () {
        final CanvasConnection conn = createTestConnection(
          collectionItemId: 88,
        );
        final Map<String, dynamic> json = conn.toExport();
        expect(json['collection_item_id'], 88);
      });
    });

    group('copyWith', () {
      test('should copy with changed fields', () {
        final CanvasConnection original = createTestConnection();
        final CanvasConnection copy = original.copyWith(
          label: 'new label',
          color: '#00FF00',
          style: ConnectionStyle.dashed,
        );

        expect(copy.id, original.id);
        expect(copy.collectionId, original.collectionId);
        expect(copy.fromItemId, original.fromItemId);
        expect(copy.toItemId, original.toItemId);
        expect(copy.label, 'new label');
        expect(copy.color, '#00FF00');
        expect(copy.style, ConnectionStyle.dashed);
      });

      test('should clear label with clearLabel flag', () {
        final CanvasConnection original = createTestConnection(
          label: 'will be cleared',
        );
        final CanvasConnection copy = original.copyWith(clearLabel: true);

        expect(copy.label, isNull);
      });

      test('clearLabel should take precedence over label', () {
        final CanvasConnection original = createTestConnection(
          label: 'old',
        );
        final CanvasConnection copy = original.copyWith(
          label: 'new',
          clearLabel: true,
        );

        expect(copy.label, isNull);
      });

      test('should keep original values when no changes', () {
        final CanvasConnection original = createTestConnection(
          label: 'keep me',
          color: '#AABBCC',
        );
        final CanvasConnection copy = original.copyWith();

        expect(copy.label, 'keep me');
        expect(copy.color, '#AABBCC');
        expect(copy.style, original.style);
        expect(copy.createdAt, original.createdAt);
      });

      test('should copy with changed id', () {
        final CanvasConnection original = createTestConnection();
        final CanvasConnection copy = original.copyWith(id: 99);
        expect(copy.id, 99);
      });

      test('should copy with all fields changed', () {
        final CanvasConnection original = createTestConnection();
        final DateTime newDate = DateTime(2025, 1, 1);
        final CanvasConnection copy = original.copyWith(
          id: 99,
          collectionId: 20,
          fromItemId: 300,
          toItemId: 400,
          label: 'all changed',
          color: '#000000',
          style: ConnectionStyle.arrow,
          createdAt: newDate,
        );
        expect(copy.id, 99);
        expect(copy.collectionId, 20);
        expect(copy.fromItemId, 300);
        expect(copy.toItemId, 400);
        expect(copy.label, 'all changed');
        expect(copy.color, '#000000');
        expect(copy.style, ConnectionStyle.arrow);
        expect(copy.createdAt, newDate);
      });

      test('should copy with changed collectionItemId', () {
        final CanvasConnection original = createTestConnection(
          collectionItemId: 10,
        );
        final CanvasConnection copy = original.copyWith(
          collectionItemId: 99,
        );
        expect(copy.collectionItemId, 99);
        expect(copy.id, original.id);
        expect(copy.collectionId, original.collectionId);
      });
    });

    group('equality', () {
      test('should be equal when ids match', () {
        final CanvasConnection a = createTestConnection(id: 1);
        final CanvasConnection b = createTestConnection(
          id: 1,
          fromItemId: 999,
          color: '#FFFFFF',
        );
        expect(a, equals(b));
      });

      test('should not be equal when ids differ', () {
        final CanvasConnection a = createTestConnection(id: 1);
        final CanvasConnection b = createTestConnection(id: 2);
        expect(a, isNot(equals(b)));
      });

      test('should have same hashCode for equal ids', () {
        final CanvasConnection a = createTestConnection(id: 5);
        final CanvasConnection b = createTestConnection(id: 5);
        expect(a.hashCode, equals(b.hashCode));
      });

      test('should be equal to itself (identical)', () {
        final CanvasConnection conn = createTestConnection(id: 1);
        expect(conn == conn, isTrue);
      });

      test('should not be equal to non-CanvasConnection object', () {
        final CanvasConnection conn = createTestConnection(id: 1);
        expect(conn == Object(), isFalse);
      });
    });

    test('toString should contain key information', () {
      final CanvasConnection conn = createTestConnection(
        id: 7,
        fromItemId: 10,
        toItemId: 20,
        style: ConnectionStyle.arrow,
      );

      final String str = conn.toString();
      expect(str, contains('7'));
      expect(str, contains('10'));
      expect(str, contains('20'));
      expect(str, contains('arrow'));
    });
  });
}
