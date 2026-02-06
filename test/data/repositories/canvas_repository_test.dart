import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/database/database_service.dart';
import 'package:xerabora/data/repositories/canvas_repository.dart';
import 'package:xerabora/shared/models/canvas_item.dart';
import 'package:xerabora/shared/models/canvas_viewport.dart';
import 'package:xerabora/shared/models/collection_game.dart';
import 'package:xerabora/shared/models/game.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  group('CanvasRepository', () {
    late MockDatabaseService mockDb;
    late CanvasRepository repository;

    final DateTime testDate = DateTime(2024, 6, 15, 12, 0, 0);
    final int testTimestamp = testDate.millisecondsSinceEpoch ~/ 1000;

    setUp(() {
      mockDb = MockDatabaseService();
      repository = CanvasRepository(db: mockDb);
    });

    group('constants', () {
      test('should have correct default values', () {
        expect(CanvasRepository.defaultCardWidth, 160);
        expect(CanvasRepository.defaultCardHeight, 220);
        expect(CanvasRepository.gridGap, 24);
        expect(CanvasRepository.gridColumns, 5);
      });
    });

    group('getItems', () {
      test('should return list of canvas items from database', () async {
        final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'collection_id': 10,
            'item_type': 'game',
            'item_ref_id': 100,
            'x': 50.0,
            'y': 100.0,
            'width': 160.0,
            'height': 220.0,
            'z_index': 0,
            'data': null,
            'created_at': testTimestamp,
          },
          <String, dynamic>{
            'id': 2,
            'collection_id': 10,
            'item_type': 'text',
            'item_ref_id': null,
            'x': 200.0,
            'y': 300.0,
            'width': null,
            'height': null,
            'z_index': 1,
            'data': '{"content":"Hello"}',
            'created_at': testTimestamp,
          },
        ];

        when(() => mockDb.getCanvasItems(10)).thenAnswer((_) async => rows);

        final List<CanvasItem> result = await repository.getItems(10);

        expect(result.length, 2);
        expect(result[0].id, 1);
        expect(result[0].itemType, CanvasItemType.game);
        expect(result[1].id, 2);
        expect(result[1].itemType, CanvasItemType.text);
        verify(() => mockDb.getCanvasItems(10)).called(1);
      });

      test('should return empty list when no items', () async {
        when(() => mockDb.getCanvasItems(10))
            .thenAnswer((_) async => <Map<String, dynamic>>[]);

        final List<CanvasItem> result = await repository.getItems(10);

        expect(result, isEmpty);
      });
    });

    group('getItemsWithData', () {
      test('should return items with joined game data', () async {
        final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'collection_id': 10,
            'item_type': 'game',
            'item_ref_id': 100,
            'x': 50.0,
            'y': 100.0,
            'width': 160.0,
            'height': 220.0,
            'z_index': 0,
            'data': null,
            'created_at': testTimestamp,
          },
        ];

        const Game testGame = Game(id: 100, name: 'Test Game');

        when(() => mockDb.getCanvasItems(10)).thenAnswer((_) async => rows);
        when(() => mockDb.getGamesByIds(<int>[100]))
            .thenAnswer((_) async => <Game>[testGame]);

        final List<CanvasItem> result = await repository.getItemsWithData(10);

        expect(result.length, 1);
        expect(result[0].game, isNotNull);
        expect(result[0].game!.name, 'Test Game');
        verify(() => mockDb.getGamesByIds(<int>[100])).called(1);
      });

      test('should return empty list when no items', () async {
        when(() => mockDb.getCanvasItems(10))
            .thenAnswer((_) async => <Map<String, dynamic>>[]);

        final List<CanvasItem> result = await repository.getItemsWithData(10);

        expect(result, isEmpty);
      });

      test('should skip game lookup when no game items', () async {
        final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'collection_id': 10,
            'item_type': 'text',
            'item_ref_id': null,
            'x': 50.0,
            'y': 100.0,
            'width': null,
            'height': null,
            'z_index': 0,
            'data': '{"content":"Hello"}',
            'created_at': testTimestamp,
          },
        ];

        when(() => mockDb.getCanvasItems(10)).thenAnswer((_) async => rows);

        final List<CanvasItem> result = await repository.getItemsWithData(10);

        expect(result.length, 1);
        verifyNever(() => mockDb.getGamesByIds(any()));
      });

      test('should handle game items with null itemRefId', () async {
        final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'collection_id': 10,
            'item_type': 'game',
            'item_ref_id': null,
            'x': 50.0,
            'y': 100.0,
            'width': 160.0,
            'height': 220.0,
            'z_index': 0,
            'data': null,
            'created_at': testTimestamp,
          },
        ];

        when(() => mockDb.getCanvasItems(10)).thenAnswer((_) async => rows);

        final List<CanvasItem> result = await repository.getItemsWithData(10);

        expect(result.length, 1);
        expect(result[0].game, isNull);
        verifyNever(() => mockDb.getGamesByIds(any()));
      });

      test('should handle mixed game and non-game items', () async {
        final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'collection_id': 10,
            'item_type': 'game',
            'item_ref_id': 100,
            'x': 50.0,
            'y': 100.0,
            'width': 160.0,
            'height': 220.0,
            'z_index': 0,
            'data': null,
            'created_at': testTimestamp,
          },
          <String, dynamic>{
            'id': 2,
            'collection_id': 10,
            'item_type': 'text',
            'item_ref_id': null,
            'x': 200.0,
            'y': 300.0,
            'width': null,
            'height': null,
            'z_index': 1,
            'data': '{"content":"Hello"}',
            'created_at': testTimestamp,
          },
        ];

        const Game testGame = Game(id: 100, name: 'Test Game');

        when(() => mockDb.getCanvasItems(10)).thenAnswer((_) async => rows);
        when(() => mockDb.getGamesByIds(<int>[100]))
            .thenAnswer((_) async => <Game>[testGame]);

        final List<CanvasItem> result = await repository.getItemsWithData(10);

        expect(result.length, 2);
        expect(result[0].game, isNotNull);
        expect(result[0].game!.name, 'Test Game');
        expect(result[1].game, isNull);
        expect(result[1].itemType, CanvasItemType.text);
      });

      test('should handle missing game in database', () async {
        final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'collection_id': 10,
            'item_type': 'game',
            'item_ref_id': 999,
            'x': 50.0,
            'y': 100.0,
            'width': 160.0,
            'height': 220.0,
            'z_index': 0,
            'data': null,
            'created_at': testTimestamp,
          },
        ];

        when(() => mockDb.getCanvasItems(10)).thenAnswer((_) async => rows);
        when(() => mockDb.getGamesByIds(<int>[999]))
            .thenAnswer((_) async => <Game>[]);

        final List<CanvasItem> result = await repository.getItemsWithData(10);

        expect(result.length, 1);
        expect(result[0].game, isNull);
      });
    });

    group('createItem', () {
      test('should insert item and return with assigned id', () async {
        final CanvasItem item = CanvasItem(
          id: 0,
          collectionId: 10,
          itemType: CanvasItemType.game,
          itemRefId: 100,
          x: 50.0,
          y: 100.0,
          width: 160.0,
          height: 220.0,
          zIndex: 0,
          createdAt: testDate,
        );

        when(() => mockDb.insertCanvasItem(any())).thenAnswer((_) async => 42);

        final CanvasItem result = await repository.createItem(item);

        expect(result.id, 42);
        expect(result.collectionId, 10);
        verify(() => mockDb.insertCanvasItem(any())).called(1);
      });
    });

    group('updateItem', () {
      test('should update item in database without id field', () async {
        final CanvasItem item = CanvasItem(
          id: 5,
          collectionId: 10,
          itemType: CanvasItemType.game,
          itemRefId: 100,
          x: 200.0,
          y: 300.0,
          width: 160.0,
          height: 220.0,
          zIndex: 1,
          createdAt: testDate,
        );

        when(() => mockDb.updateCanvasItem(5, any()))
            .thenAnswer((_) async {});

        await repository.updateItem(item);

        final Map<String, dynamic> captured =
            verify(() => mockDb.updateCanvasItem(5, captureAny()))
                .captured
                .first as Map<String, dynamic>;
        expect(captured.containsKey('id'), false);
        expect(captured['x'], 200.0);
        expect(captured['y'], 300.0);
      });
    });

    group('updateItemPosition', () {
      test('should update only x and y in database', () async {
        when(() => mockDb.updateCanvasItem(5, any()))
            .thenAnswer((_) async {});

        await repository.updateItemPosition(5, x: 300.0, y: 400.0);

        final Map<String, dynamic> captured =
            verify(() => mockDb.updateCanvasItem(5, captureAny()))
                .captured
                .first as Map<String, dynamic>;
        expect(captured, <String, dynamic>{'x': 300.0, 'y': 400.0});
      });
    });

    group('updateItemSize', () {
      test('should update width and height', () async {
        when(() => mockDb.updateCanvasItem(5, any()))
            .thenAnswer((_) async {});

        await repository.updateItemSize(5, width: 200.0, height: 300.0);

        final Map<String, dynamic> captured =
            verify(() => mockDb.updateCanvasItem(5, captureAny()))
                .captured
                .first as Map<String, dynamic>;
        expect(captured['width'], 200.0);
        expect(captured['height'], 300.0);
      });

      test('should update only width when height is null', () async {
        when(() => mockDb.updateCanvasItem(5, any()))
            .thenAnswer((_) async {});

        await repository.updateItemSize(5, width: 200.0);

        final Map<String, dynamic> captured =
            verify(() => mockDb.updateCanvasItem(5, captureAny()))
                .captured
                .first as Map<String, dynamic>;
        expect(captured, <String, dynamic>{'width': 200.0});
      });

      test('should update only height when width is null', () async {
        when(() => mockDb.updateCanvasItem(5, any()))
            .thenAnswer((_) async {});

        await repository.updateItemSize(5, height: 300.0);

        final Map<String, dynamic> captured =
            verify(() => mockDb.updateCanvasItem(5, captureAny()))
                .captured
                .first as Map<String, dynamic>;
        expect(captured, <String, dynamic>{'height': 300.0});
      });

      test('should not call database when both are null', () async {
        await repository.updateItemSize(5);

        verifyNever(() => mockDb.updateCanvasItem(any(), any()));
      });
    });

    group('updateItemData', () {
      test('should encode data as JSON and update database', () async {
        when(() => mockDb.updateCanvasItem(5, any()))
            .thenAnswer((_) async {});

        await repository.updateItemData(
          5,
          <String, dynamic>{'content': 'Hello', 'fontSize': 16.0},
        );

        final Map<String, dynamic> captured =
            verify(() => mockDb.updateCanvasItem(5, captureAny()))
                .captured
                .first as Map<String, dynamic>;
        expect(captured['data'], '{"content":"Hello","fontSize":16.0}');
      });

      test('should set data to null when data is null', () async {
        when(() => mockDb.updateCanvasItem(5, any()))
            .thenAnswer((_) async {});

        await repository.updateItemData(5, null);

        final Map<String, dynamic> captured =
            verify(() => mockDb.updateCanvasItem(5, captureAny()))
                .captured
                .first as Map<String, dynamic>;
        expect(captured['data'], isNull);
      });
    });

    group('updateItemZIndex', () {
      test('should update z_index in database', () async {
        when(() => mockDb.updateCanvasItem(5, any()))
            .thenAnswer((_) async {});

        await repository.updateItemZIndex(5, 10);

        final Map<String, dynamic> captured =
            verify(() => mockDb.updateCanvasItem(5, captureAny()))
                .captured
                .first as Map<String, dynamic>;
        expect(captured, <String, dynamic>{'z_index': 10});
      });
    });

    group('deleteItem', () {
      test('should delete item from database', () async {
        when(() => mockDb.deleteCanvasItem(5)).thenAnswer((_) async {});

        await repository.deleteItem(5);

        verify(() => mockDb.deleteCanvasItem(5)).called(1);
      });
    });

    group('deleteGameItem', () {
      test('should delete game item by collection and igdb id', () async {
        when(() => mockDb.deleteCanvasItemByRef(10, 100))
            .thenAnswer((_) async {});

        await repository.deleteGameItem(10, 100);

        verify(() => mockDb.deleteCanvasItemByRef(10, 100)).called(1);
      });
    });

    group('hasCanvasItems', () {
      test('should return true when items exist', () async {
        when(() => mockDb.getCanvasItemCount(10)).thenAnswer((_) async => 3);

        final bool result = await repository.hasCanvasItems(10);

        expect(result, true);
      });

      test('should return false when no items', () async {
        when(() => mockDb.getCanvasItemCount(10)).thenAnswer((_) async => 0);

        final bool result = await repository.hasCanvasItems(10);

        expect(result, false);
      });
    });

    group('getViewport', () {
      test('should return viewport from database', () async {
        final Map<String, dynamic> row = <String, dynamic>{
          'collection_id': 10,
          'scale': 1.5,
          'offset_x': -100.0,
          'offset_y': -200.0,
        };

        when(() => mockDb.getCanvasViewport(10)).thenAnswer((_) async => row);

        final CanvasViewport? result = await repository.getViewport(10);

        expect(result, isNotNull);
        expect(result!.collectionId, 10);
        expect(result.scale, 1.5);
        expect(result.offsetX, -100.0);
        expect(result.offsetY, -200.0);
      });

      test('should return null when viewport not found', () async {
        when(() => mockDb.getCanvasViewport(10)).thenAnswer((_) async => null);

        final CanvasViewport? result = await repository.getViewport(10);

        expect(result, isNull);
      });
    });

    group('saveViewport', () {
      test('should upsert viewport to database', () async {
        const CanvasViewport viewport = CanvasViewport(
          collectionId: 10,
          scale: 2.0,
          offsetX: -50.0,
          offsetY: -75.0,
        );

        when(() => mockDb.upsertCanvasViewport(
              collectionId: 10,
              scale: 2.0,
              offsetX: -50.0,
              offsetY: -75.0,
            )).thenAnswer((_) async {});

        await repository.saveViewport(viewport);

        verify(() => mockDb.upsertCanvasViewport(
              collectionId: 10,
              scale: 2.0,
              offsetX: -50.0,
              offsetY: -75.0,
            )).called(1);
      });
    });

    group('initializeCanvas', () {
      test('should create canvas items in grid layout', () async {
        final List<CollectionGame> games = <CollectionGame>[
          CollectionGame(
            id: 1,
            collectionId: 10,
            igdbId: 100,
            platformId: 18,
            status: GameStatus.notStarted,
            addedAt: testDate,
          ),
          CollectionGame(
            id: 2,
            collectionId: 10,
            igdbId: 200,
            platformId: 18,
            status: GameStatus.notStarted,
            addedAt: testDate,
          ),
        ];

        int insertCallCount = 0;
        when(() => mockDb.insertCanvasItem(any())).thenAnswer((_) async {
          insertCallCount++;
          return insertCallCount;
        });
        when(() => mockDb.upsertCanvasViewport(
              collectionId: any(named: 'collectionId'),
              scale: any(named: 'scale'),
              offsetX: any(named: 'offsetX'),
              offsetY: any(named: 'offsetY'),
            )).thenAnswer((_) async {});

        final List<CanvasItem> result =
            await repository.initializeCanvas(10, games);

        expect(result.length, 2);
        expect(result[0].id, 1);
        expect(result[0].itemRefId, 100);
        // 2 games → cols=2, gridWidth=344, startX=2500-172=2328
        // gridHeight=220, startY=2500-110=2390
        expect(result[0].x, 2328.0);
        expect(result[0].y, 2390.0);
        expect(result[1].id, 2);
        expect(result[1].itemRefId, 200);
        expect(result[1].x, 2512.0); // 2328 + 1 * (160 + 24)
        expect(result[1].y, 2390.0);
        verify(() => mockDb.insertCanvasItem(any())).called(2);
        verify(() => mockDb.upsertCanvasViewport(
              collectionId: 10,
              scale: 1.0,
              offsetX: 0.0,
              offsetY: 0.0,
            )).called(1);
      });

      test('should wrap to next row after gridColumns', () async {
        // Create 6 games (should wrap at column 5)
        final List<CollectionGame> games = List<CollectionGame>.generate(
          6,
          (int i) => CollectionGame(
            id: i + 1,
            collectionId: 10,
            igdbId: (i + 1) * 100,
            platformId: 18,
            status: GameStatus.notStarted,
            addedAt: testDate,
          ),
        );

        int insertCallCount = 0;
        when(() => mockDb.insertCanvasItem(any())).thenAnswer((_) async {
          insertCallCount++;
          return insertCallCount;
        });
        when(() => mockDb.upsertCanvasViewport(
              collectionId: any(named: 'collectionId'),
              scale: any(named: 'scale'),
              offsetX: any(named: 'offsetX'),
              offsetY: any(named: 'offsetY'),
            )).thenAnswer((_) async {});

        final List<CanvasItem> result =
            await repository.initializeCanvas(10, games);

        expect(result.length, 6);
        // 6 games → cols=5, gridWidth=896, startX=2500-448=2052
        // gridHeight=464, startY=2500-232=2268
        // Item at index 5: col = 5 % 5 = 0, row = 5 ~/ 5 = 1
        expect(result[5].x, 2052.0); // startX + 0 * 184
        expect(result[5].y, 2512.0); // 2268 + 1 * (220 + 24)
      });

      test('should handle empty games list', () async {
        when(() => mockDb.upsertCanvasViewport(
              collectionId: any(named: 'collectionId'),
              scale: any(named: 'scale'),
              offsetX: any(named: 'offsetX'),
              offsetY: any(named: 'offsetY'),
            )).thenAnswer((_) async {});

        final List<CanvasItem> result =
            await repository.initializeCanvas(10, <CollectionGame>[]);

        expect(result, isEmpty);
        verifyNever(() => mockDb.insertCanvasItem(any()));
        // Should still create default viewport
        verify(() => mockDb.upsertCanvasViewport(
              collectionId: 10,
              scale: 1.0,
              offsetX: 0.0,
              offsetY: 0.0,
            )).called(1);
      });
    });
  });
}
