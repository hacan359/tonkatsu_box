import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xerabora/core/database/dao/canvas_dao.dart';

import '../../../helpers/mocks.dart';

void main() {
  late TransactionMockDatabase mockDb;
  late MockTransaction mockTxn;
  late MockBatch mockBatch;
  late CanvasDao dao;

  setUp(() {
    mockDb = TransactionMockDatabase();
    mockTxn = MockTransaction();
    mockBatch = MockBatch();
    dao = CanvasDao(() async => mockDb);
  });

  group('CanvasDao', () {
    // ==================== Canvas Items ====================

    group('getCanvasItems', () {
      test('returns items for collection excluding per-item', () async {
        when(
          () => mockDb.query(
            'canvas_items',
            where: 'collection_id = ? AND collection_item_id IS NULL',
            whereArgs: <Object?>[1],
            orderBy: 'z_index ASC',
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'id': 10, 'collection_id': 1},
          ],
        );

        final List<Map<String, dynamic>> result =
            await dao.getCanvasItems(1);

        expect(result.length, 1);
        expect(result.first['id'], 10);
      });
    });

    group('insertCanvasItem', () {
      test('inserts and returns id', () async {
        final Map<String, dynamic> data = <String, dynamic>{
          'collection_id': 1,
          'item_type': 'game',
        };
        when(() => mockDb.insert('canvas_items', data))
            .thenAnswer((_) async => 42);

        final int id = await dao.insertCanvasItem(data);

        expect(id, 42);
      });
    });

    group('updateCanvasItem', () {
      test('updates by id', () async {
        final Map<String, dynamic> data = <String, dynamic>{'x': 100.0};
        when(
          () => mockDb.update(
            'canvas_items',
            data,
            where: 'id = ?',
            whereArgs: <Object?>[10],
          ),
        ).thenAnswer((_) async => 1);

        await dao.updateCanvasItem(10, data);

        verify(
          () => mockDb.update(
            'canvas_items',
            data,
            where: 'id = ?',
            whereArgs: <Object?>[10],
          ),
        ).called(1);
      });
    });

    group('deleteCanvasItem', () {
      test('deletes by id', () async {
        when(
          () => mockDb.delete(
            'canvas_items',
            where: 'id = ?',
            whereArgs: <Object?>[10],
          ),
        ).thenAnswer((_) async => 1);

        await dao.deleteCanvasItem(10);

        verify(
          () => mockDb.delete(
            'canvas_items',
            where: 'id = ?',
            whereArgs: <Object?>[10],
          ),
        ).called(1);
      });
    });

    group('deleteCanvasItemByRef', () {
      test('deletes by collection, type and ref', () async {
        when(
          () => mockDb.delete(
            'canvas_items',
            where: 'collection_id = ? AND item_type = ? AND item_ref_id = ?'
                ' AND collection_item_id IS NULL',
            whereArgs: <Object?>[1, 'game', 100],
          ),
        ).thenAnswer((_) async => 1);

        await dao.deleteCanvasItemByRef(1, 'game', 100);

        verify(
          () => mockDb.delete(
            'canvas_items',
            where: 'collection_id = ? AND item_type = ? AND item_ref_id = ?'
                ' AND collection_item_id IS NULL',
            whereArgs: <Object?>[1, 'game', 100],
          ),
        ).called(1);
      });
    });

    group('deleteCanvasItemByCollectionItemId', () {
      test('deletes by collection and collection_item_id', () async {
        when(
          () => mockDb.delete(
            'canvas_items',
            where: 'collection_id = ? AND collection_item_id = ?',
            whereArgs: <Object?>[1, 50],
          ),
        ).thenAnswer((_) async => 1);

        await dao.deleteCanvasItemByCollectionItemId(1, 50);

        verify(
          () => mockDb.delete(
            'canvas_items',
            where: 'collection_id = ? AND collection_item_id = ?',
            whereArgs: <Object?>[1, 50],
          ),
        ).called(1);
      });
    });

    group('deleteCanvasItemsByCollection', () {
      test('deletes collection items excluding per-item', () async {
        when(
          () => mockDb.delete(
            'canvas_items',
            where: 'collection_id = ? AND collection_item_id IS NULL',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 5);

        await dao.deleteCanvasItemsByCollection(1);

        verify(
          () => mockDb.delete(
            'canvas_items',
            where: 'collection_id = ? AND collection_item_id IS NULL',
            whereArgs: <Object?>[1],
          ),
        ).called(1);
      });
    });

    group('getCanvasItemCount', () {
      test('returns count for collection', () async {
        when(
          () => mockDb.rawQuery(
            'SELECT COUNT(*) as count FROM canvas_items'
            ' WHERE collection_id = ? AND collection_item_id IS NULL',
            <Object?>[1],
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'count': 7},
          ],
        );

        expect(await dao.getCanvasItemCount(1), 7);
      });
    });

    // ==================== Batch Operations ====================

    group('insertCanvasItemsBatch', () {
      test('returns empty list for empty input', () async {
        final List<int> result =
            await dao.insertCanvasItemsBatch(<Map<String, dynamic>>[]);

        expect(result, isEmpty);
        verifyNever(() => mockTxn.batch());
      });

      test('inserts items in batch and returns IDs', () async {
        mockDb.stubTransaction(mockTxn);
        when(() => mockTxn.batch()).thenReturn(mockBatch);
        when(() => mockBatch.insert(any(), any())).thenReturn(null);
        when(() => mockBatch.commit())
            .thenAnswer((_) async => <Object?>[10, 11, 12]);

        final List<Map<String, dynamic>> items = <Map<String, dynamic>>[
          <String, dynamic>{'collection_id': 1, 'item_type': 'game'},
          <String, dynamic>{'collection_id': 1, 'item_type': 'movie'},
          <String, dynamic>{'collection_id': 1, 'item_type': 'tv_show'},
        ];

        final List<int> ids = await dao.insertCanvasItemsBatch(items);

        expect(ids, <int>[10, 11, 12]);
        verify(() => mockBatch.insert('canvas_items', items[0])).called(1);
        verify(() => mockBatch.insert('canvas_items', items[1])).called(1);
        verify(() => mockBatch.insert('canvas_items', items[2])).called(1);
        verify(() => mockBatch.commit()).called(1);
      });
    });

    group('deleteCanvasItemsBatch', () {
      test('does nothing for empty list', () async {
        await dao.deleteCanvasItemsBatch(<int>[]);

        verifyNever(() => mockTxn.batch());
      });

      test('deletes items in batch', () async {
        mockDb.stubTransaction(mockTxn);
        when(() => mockTxn.batch()).thenReturn(mockBatch);
        when(
          () => mockBatch.delete(
            any(),
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'),
          ),
        ).thenReturn(null);
        when(() => mockBatch.commit(noResult: true))
            .thenAnswer((_) async => <Object?>[]);

        await dao.deleteCanvasItemsBatch(<int>[10, 20, 30]);

        verify(
          () => mockBatch.delete(
            'canvas_items',
            where: 'id = ?',
            whereArgs: <Object?>[10],
          ),
        ).called(1);
        verify(
          () => mockBatch.delete(
            'canvas_items',
            where: 'id = ?',
            whereArgs: <Object?>[20],
          ),
        ).called(1);
        verify(
          () => mockBatch.delete(
            'canvas_items',
            where: 'id = ?',
            whereArgs: <Object?>[30],
          ),
        ).called(1);
        verify(() => mockBatch.commit(noResult: true)).called(1);
      });
    });

    // ==================== Canvas Viewport ====================

    group('getCanvasViewport', () {
      test('returns null when not found', () async {
        when(
          () => mockDb.query(
            'canvas_viewport',
            where: 'collection_id = ?',
            whereArgs: <Object?>[1],
            limit: 1,
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        expect(await dao.getCanvasViewport(1), isNull);
      });

      test('returns viewport when found', () async {
        final Map<String, dynamic> row = <String, dynamic>{
          'collection_id': 1,
          'scale': 1.5,
          'offset_x': 100.0,
          'offset_y': 200.0,
        };
        when(
          () => mockDb.query(
            'canvas_viewport',
            where: 'collection_id = ?',
            whereArgs: <Object?>[1],
            limit: 1,
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[row]);

        final Map<String, dynamic>? result = await dao.getCanvasViewport(1);

        expect(result, isNotNull);
        expect(result!['scale'], 1.5);
      });
    });

    group('upsertCanvasViewport', () {
      test('inserts or replaces viewport', () async {
        when(
          () => mockDb.insert(
            'canvas_viewport',
            any(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          ),
        ).thenAnswer((_) async => 1);

        await dao.upsertCanvasViewport(
          collectionId: 1,
          scale: 1.5,
          offsetX: 100.0,
          offsetY: 200.0,
        );

        verify(
          () => mockDb.insert(
            'canvas_viewport',
            <String, dynamic>{
              'collection_id': 1,
              'scale': 1.5,
              'offset_x': 100.0,
              'offset_y': 200.0,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          ),
        ).called(1);
      });
    });

    // ==================== Canvas Connections ====================

    group('getCanvasConnections', () {
      test('returns connections excluding per-item', () async {
        when(
          () => mockDb.query(
            'canvas_connections',
            where: 'collection_id = ? AND collection_item_id IS NULL',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'id': 5, 'from_item_id': 10, 'to_item_id': 20},
          ],
        );

        final List<Map<String, dynamic>> result =
            await dao.getCanvasConnections(1);

        expect(result.length, 1);
      });
    });

    group('insertCanvasConnection', () {
      test('inserts and returns id', () async {
        final Map<String, dynamic> data = <String, dynamic>{
          'collection_id': 1,
          'from_item_id': 10,
          'to_item_id': 20,
        };
        when(() => mockDb.insert('canvas_connections', data))
            .thenAnswer((_) async => 5);

        final int id = await dao.insertCanvasConnection(data);

        expect(id, 5);
      });
    });

    group('updateCanvasConnection', () {
      test('updates by id', () async {
        final Map<String, dynamic> data = <String, dynamic>{'label': 'test'};
        when(
          () => mockDb.update(
            'canvas_connections',
            data,
            where: 'id = ?',
            whereArgs: <Object?>[5],
          ),
        ).thenAnswer((_) async => 1);

        await dao.updateCanvasConnection(5, data);

        verify(
          () => mockDb.update(
            'canvas_connections',
            data,
            where: 'id = ?',
            whereArgs: <Object?>[5],
          ),
        ).called(1);
      });
    });

    group('deleteCanvasConnection', () {
      test('deletes by id', () async {
        when(
          () => mockDb.delete(
            'canvas_connections',
            where: 'id = ?',
            whereArgs: <Object?>[5],
          ),
        ).thenAnswer((_) async => 1);

        await dao.deleteCanvasConnection(5);

        verify(
          () => mockDb.delete(
            'canvas_connections',
            where: 'id = ?',
            whereArgs: <Object?>[5],
          ),
        ).called(1);
      });
    });

    group('deleteCanvasConnectionsByCollection', () {
      test('deletes connections excluding per-item', () async {
        when(
          () => mockDb.delete(
            'canvas_connections',
            where: 'collection_id = ? AND collection_item_id IS NULL',
            whereArgs: <Object?>[1],
          ),
        ).thenAnswer((_) async => 3);

        await dao.deleteCanvasConnectionsByCollection(1);

        verify(
          () => mockDb.delete(
            'canvas_connections',
            where: 'collection_id = ? AND collection_item_id IS NULL',
            whereArgs: <Object?>[1],
          ),
        ).called(1);
      });
    });

    // ==================== Game Canvas ====================

    group('getGameCanvasItems', () {
      test('returns items by collection_item_id', () async {
        when(
          () => mockDb.query(
            'canvas_items',
            where: 'collection_item_id = ?',
            whereArgs: <Object?>[50],
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        final List<Map<String, dynamic>> result =
            await dao.getGameCanvasItems(50);

        expect(result, isEmpty);
      });
    });

    group('getGameCanvasItemCount', () {
      test('returns count by collection_item_id', () async {
        when(
          () => mockDb.rawQuery(
            'SELECT COUNT(*) as cnt FROM canvas_items '
            'WHERE collection_item_id = ?',
            <Object?>[50],
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{'cnt': 3},
          ],
        );

        expect(await dao.getGameCanvasItemCount(50), 3);
      });
    });

    group('getGameCanvasConnections', () {
      test('returns connections by collection_item_id', () async {
        when(
          () => mockDb.query(
            'canvas_connections',
            where: 'collection_item_id = ?',
            whereArgs: <Object?>[50],
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        final List<Map<String, dynamic>> result =
            await dao.getGameCanvasConnections(50);

        expect(result, isEmpty);
      });
    });

    group('getGameCanvasViewport', () {
      test('returns null when not found', () async {
        when(
          () => mockDb.query(
            'game_canvas_viewport',
            where: 'collection_item_id = ?',
            whereArgs: <Object?>[50],
          ),
        ).thenAnswer((_) async => <Map<String, dynamic>>[]);

        expect(await dao.getGameCanvasViewport(50), isNull);
      });

      test('returns viewport when found', () async {
        when(
          () => mockDb.query(
            'game_canvas_viewport',
            where: 'collection_item_id = ?',
            whereArgs: <Object?>[50],
          ),
        ).thenAnswer(
          (_) async => <Map<String, dynamic>>[
            <String, dynamic>{
              'collection_item_id': 50,
              'scale': 2.0,
              'offset_x': 50.0,
              'offset_y': 60.0,
            },
          ],
        );

        final Map<String, dynamic>? result =
            await dao.getGameCanvasViewport(50);

        expect(result, isNotNull);
        expect(result!['scale'], 2.0);
      });
    });

    group('upsertGameCanvasViewport', () {
      test('executes INSERT OR REPLACE', () async {
        when(
          () => mockDb.execute(
            'INSERT OR REPLACE INTO game_canvas_viewport '
            '(collection_item_id, scale, offset_x, offset_y) '
            'VALUES (?, ?, ?, ?)',
            <Object?>[50, 2.0, 50.0, 60.0],
          ),
        ).thenAnswer((_) async {});

        await dao.upsertGameCanvasViewport(
          collectionItemId: 50,
          scale: 2.0,
          offsetX: 50.0,
          offsetY: 60.0,
        );

        verify(
          () => mockDb.execute(
            'INSERT OR REPLACE INTO game_canvas_viewport '
            '(collection_item_id, scale, offset_x, offset_y) '
            'VALUES (?, ?, ?, ?)',
            <Object?>[50, 2.0, 50.0, 60.0],
          ),
        ).called(1);
      });
    });

    group('deleteGameCanvasItems', () {
      test('deletes by collection_item_id', () async {
        when(
          () => mockDb.delete(
            'canvas_items',
            where: 'collection_item_id = ?',
            whereArgs: <Object?>[50],
          ),
        ).thenAnswer((_) async => 2);

        await dao.deleteGameCanvasItems(50);

        verify(
          () => mockDb.delete(
            'canvas_items',
            where: 'collection_item_id = ?',
            whereArgs: <Object?>[50],
          ),
        ).called(1);
      });
    });

    group('deleteGameCanvasConnections', () {
      test('deletes by collection_item_id', () async {
        when(
          () => mockDb.delete(
            'canvas_connections',
            where: 'collection_item_id = ?',
            whereArgs: <Object?>[50],
          ),
        ).thenAnswer((_) async => 1);

        await dao.deleteGameCanvasConnections(50);

        verify(
          () => mockDb.delete(
            'canvas_connections',
            where: 'collection_item_id = ?',
            whereArgs: <Object?>[50],
          ),
        ).called(1);
      });
    });

    group('deleteGameCanvasViewport', () {
      test('deletes by collection_item_id', () async {
        when(
          () => mockDb.delete(
            'game_canvas_viewport',
            where: 'collection_item_id = ?',
            whereArgs: <Object?>[50],
          ),
        ).thenAnswer((_) async => 1);

        await dao.deleteGameCanvasViewport(50);

        verify(
          () => mockDb.delete(
            'game_canvas_viewport',
            where: 'collection_item_id = ?',
            whereArgs: <Object?>[50],
          ),
        ).called(1);
      });
    });
  });
}
