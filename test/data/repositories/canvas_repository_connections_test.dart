import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/data/repositories/canvas_repository.dart';
import 'package:xerabora/shared/models/canvas_connection.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  group('CanvasRepository — Connections', () {
    late MockDatabaseService mockDb;
    late CanvasRepository repository;

    final DateTime testDate = DateTime(2024, 6, 15, 12, 0, 0);
    final int testTimestamp = testDate.millisecondsSinceEpoch ~/ 1000;

    setUp(() {
      mockDb = MockDatabaseService();
      repository = CanvasRepository(db: mockDb);
    });

    group('getConnections', () {
      test('should return list of connections from database', () async {
        final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'collection_id': 10,
            'from_item_id': 100,
            'to_item_id': 200,
            'label': 'depends on',
            'color': '#FF0000',
            'style': 'arrow',
            'created_at': testTimestamp,
          },
          <String, dynamic>{
            'id': 2,
            'collection_id': 10,
            'from_item_id': 200,
            'to_item_id': 300,
            'label': null,
            'color': '#666666',
            'style': 'solid',
            'created_at': testTimestamp,
          },
        ];

        when(() => mockDb.getCanvasConnections(10))
            .thenAnswer((_) async => rows);

        final List<CanvasConnection> result =
            await repository.getConnections(10);

        expect(result.length, 2);
        expect(result[0].id, 1);
        expect(result[0].fromItemId, 100);
        expect(result[0].toItemId, 200);
        expect(result[0].label, 'depends on');
        expect(result[0].style, ConnectionStyle.arrow);
        expect(result[1].id, 2);
        expect(result[1].label, isNull);
        verify(() => mockDb.getCanvasConnections(10)).called(1);
      });

      test('should return empty list when no connections', () async {
        when(() => mockDb.getCanvasConnections(10))
            .thenAnswer((_) async => <Map<String, dynamic>>[]);

        final List<CanvasConnection> result =
            await repository.getConnections(10);

        expect(result, isEmpty);
      });
    });

    group('createConnection', () {
      test('should insert and return connection with id', () async {
        final CanvasConnection conn = CanvasConnection(
          id: 0,
          collectionId: 10,
          fromItemId: 100,
          toItemId: 200,
          label: 'test',
          color: '#FF0000',
          style: ConnectionStyle.arrow,
          createdAt: testDate,
        );

        when(() => mockDb.insertCanvasConnection(any()))
            .thenAnswer((_) async => 42);

        final CanvasConnection result =
            await repository.createConnection(conn);

        expect(result.id, 42);
        expect(result.fromItemId, 100);
        expect(result.toItemId, 200);
        expect(result.label, 'test');

        final Map<String, dynamic> captured =
            verify(() => mockDb.insertCanvasConnection(captureAny()))
                .captured
                .first as Map<String, dynamic>;
        expect(captured['collection_id'], 10);
        expect(captured['from_item_id'], 100);
        expect(captured['to_item_id'], 200);
        expect(captured['label'], 'test');
        expect(captured['color'], '#FF0000');
        expect(captured['style'], 'arrow');
      });
    });

    group('updateConnection', () {
      test('should update label, color and style', () async {
        final CanvasConnection conn = CanvasConnection(
          id: 5,
          collectionId: 10,
          fromItemId: 100,
          toItemId: 200,
          label: 'updated',
          color: '#00FF00',
          style: ConnectionStyle.dashed,
          createdAt: testDate,
        );

        when(() => mockDb.updateCanvasConnection(any(), any()))
            .thenAnswer((_) async {});

        await repository.updateConnection(conn);

        final Map<String, dynamic> captured =
            verify(() => mockDb.updateCanvasConnection(5, captureAny()))
                .captured
                .first as Map<String, dynamic>;
        expect(captured['label'], 'updated');
        expect(captured['color'], '#00FF00');
        expect(captured['style'], 'dashed');
        expect(captured.containsKey('id'), isFalse);
        expect(captured.containsKey('collection_id'), isFalse);
      });

      test('should handle null label', () async {
        final CanvasConnection conn = CanvasConnection(
          id: 5,
          collectionId: 10,
          fromItemId: 100,
          toItemId: 200,
          color: '#666666',
          createdAt: testDate,
        );

        when(() => mockDb.updateCanvasConnection(any(), any()))
            .thenAnswer((_) async {});

        await repository.updateConnection(conn);

        final Map<String, dynamic> captured =
            verify(() => mockDb.updateCanvasConnection(5, captureAny()))
                .captured
                .first as Map<String, dynamic>;
        expect(captured['label'], isNull);
      });
    });

    group('deleteConnection', () {
      test('should delete connection by id', () async {
        when(() => mockDb.deleteCanvasConnection(5))
            .thenAnswer((_) async {});

        await repository.deleteConnection(5);

        verify(() => mockDb.deleteCanvasConnection(5)).called(1);
      });
    });
  });
}
