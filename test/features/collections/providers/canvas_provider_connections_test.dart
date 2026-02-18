import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/data/repositories/canvas_repository.dart';
import 'package:xerabora/features/collections/providers/canvas_provider.dart';
import 'package:xerabora/features/collections/providers/collections_provider.dart';
import 'package:xerabora/shared/models/canvas_connection.dart';
import 'package:xerabora/shared/models/canvas_item.dart';
import 'package:xerabora/shared/models/canvas_viewport.dart';
import 'package:xerabora/shared/models/collection_item.dart';

class MockCanvasRepository extends Mock implements CanvasRepository {}

class MockCollectionItemsNotifier extends CollectionItemsNotifier {
  @override
  AsyncValue<List<CollectionItem>> build(int? arg) {
    return const AsyncValue<List<CollectionItem>>.data(<CollectionItem>[]);
  }
}

class FakeCanvasItem extends Fake implements CanvasItem {}

class FakeCanvasViewport extends Fake implements CanvasViewport {}

class FakeCanvasConnection extends Fake implements CanvasConnection {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeCanvasItem());
    registerFallbackValue(FakeCanvasViewport());
    registerFallbackValue(FakeCanvasConnection());
  });

  group('CanvasState — connections', () {
    test('should create with empty connections by default', () {
      const CanvasState state = CanvasState();
      expect(state.connections, isEmpty);
      expect(state.connectingFromId, isNull);
    });

    test('should create with custom connections', () {
      final DateTime testDate = DateTime(2024, 6, 15);
      final List<CanvasConnection> connections = <CanvasConnection>[
        CanvasConnection(
          id: 1,
          collectionId: 10,
          fromItemId: 100,
          toItemId: 200,
          createdAt: testDate,
        ),
      ];

      final CanvasState state = CanvasState(
        connections: connections,
        connectingFromId: 5,
      );

      expect(state.connections.length, 1);
      expect(state.connectingFromId, 5);
    });

    group('copyWith — connections', () {
      test('should copy with changed connections', () {
        const CanvasState original = CanvasState();
        final DateTime testDate = DateTime(2024, 6, 15);
        final List<CanvasConnection> newConnections = <CanvasConnection>[
          CanvasConnection(
            id: 1,
            collectionId: 10,
            fromItemId: 100,
            toItemId: 200,
            createdAt: testDate,
          ),
        ];

        final CanvasState copy =
            original.copyWith(connections: newConnections);

        expect(copy.connections.length, 1);
        expect(copy.items, original.items);
      });

      test('should copy with connectingFromId', () {
        const CanvasState original = CanvasState();

        final CanvasState copy =
            original.copyWith(connectingFromId: 42);

        expect(copy.connectingFromId, 42);
      });

      test('should clear connectingFromId', () {
        const CanvasState original = CanvasState(connectingFromId: 42);

        final CanvasState copy =
            original.copyWith(clearConnectingFromId: true);

        expect(copy.connectingFromId, isNull);
      });

      test('should keep connectingFromId when not explicitly changed', () {
        const CanvasState original = CanvasState(connectingFromId: 42);

        final CanvasState copy = original.copyWith(isLoading: false);

        expect(copy.connectingFromId, 42);
      });

      test('clearConnectingFromId takes precedence over connectingFromId',
          () {
        const CanvasState original = CanvasState(connectingFromId: 42);

        final CanvasState copy = original.copyWith(
          connectingFromId: 99,
          clearConnectingFromId: true,
        );

        expect(copy.connectingFromId, isNull);
      });
    });
  });

  group('CanvasNotifier — connections', () {
    late MockCanvasRepository mockRepository;
    final DateTime testDate = DateTime(2024, 6, 15);
    const int collectionId = 1;

    late List<CanvasItem> testItems;
    late List<CanvasConnection> testConnections;

    setUp(() {
      mockRepository = MockCanvasRepository();

      testItems = <CanvasItem>[
        CanvasItem(
          id: 1,
          collectionId: collectionId,
          itemType: CanvasItemType.game,
          itemRefId: 100,
          x: 50.0,
          y: 100.0,
          width: 160,
          height: 220,
          zIndex: 0,
          createdAt: testDate,
        ),
        CanvasItem(
          id: 2,
          collectionId: collectionId,
          itemType: CanvasItemType.game,
          itemRefId: 200,
          x: 250.0,
          y: 100.0,
          width: 160,
          height: 220,
          zIndex: 1,
          createdAt: testDate,
        ),
        CanvasItem(
          id: 3,
          collectionId: collectionId,
          itemType: CanvasItemType.text,
          x: 450.0,
          y: 100.0,
          zIndex: 2,
          createdAt: testDate,
        ),
      ];

      testConnections = <CanvasConnection>[
        CanvasConnection(
          id: 10,
          collectionId: collectionId,
          fromItemId: 1,
          toItemId: 2,
          label: 'related',
          color: '#FF0000',
          style: ConnectionStyle.solid,
          createdAt: testDate,
        ),
      ];
    });

    /// Создаёт контейнер Riverpod для тестирования CanvasNotifier.
    ProviderContainer createContainer({
      bool hasCanvasItems = true,
      List<CanvasItem>? items,
      List<CanvasConnection>? connections,
    }) {
      when(() => mockRepository.hasCanvasItems(collectionId))
          .thenAnswer((_) async => hasCanvasItems);
      when(() => mockRepository.getItemsWithData(collectionId))
          .thenAnswer((_) async => items ?? testItems);
      when(() => mockRepository.getItems(collectionId))
          .thenAnswer((_) async => items ?? testItems);
      when(() => mockRepository.getViewport(collectionId))
          .thenAnswer(
              (_) async => const CanvasViewport(collectionId: collectionId));
      when(() => mockRepository.getConnections(collectionId))
          .thenAnswer((_) async => connections ?? testConnections);
      when(() => mockRepository.deleteItem(any()))
          .thenAnswer((_) async {});

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          canvasRepositoryProvider.overrideWithValue(mockRepository),
          collectionItemsNotifierProvider.overrideWith(
            MockCollectionItemsNotifier.new,
          ),
        ],
      );

      return container;
    }

    /// Ждёт загрузку канваса.
    Future<void> waitForLoad(
      ProviderContainer container, {
      Duration timeout = const Duration(seconds: 2),
    }) async {
      final Stopwatch sw = Stopwatch()..start();
      while (sw.elapsed < timeout) {
        final CanvasState state =
            container.read(canvasNotifierProvider(collectionId));
        if (state.isInitialized && !state.isLoading) break;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }

    test('should load connections during canvas load', () async {
      final ProviderContainer container = createContainer();

      // Тригерим загрузку
      container.read(canvasNotifierProvider(collectionId));
      await waitForLoad(container);

      final CanvasState state =
          container.read(canvasNotifierProvider(collectionId));
      expect(state.connections.length, 1);
      expect(state.connections.first.id, 10);
      expect(state.connections.first.fromItemId, 1);
      expect(state.connections.first.toItemId, 2);

      container.dispose();
    });

    test('startConnection should set connectingFromId', () async {
      final ProviderContainer container = createContainer();
      container.read(canvasNotifierProvider(collectionId));
      await waitForLoad(container);

      container
          .read(canvasNotifierProvider(collectionId).notifier)
          .startConnection(1);

      final CanvasState state =
          container.read(canvasNotifierProvider(collectionId));
      expect(state.connectingFromId, 1);

      container.dispose();
    });

    test('cancelConnection should clear connectingFromId', () async {
      final ProviderContainer container = createContainer();
      container.read(canvasNotifierProvider(collectionId));
      await waitForLoad(container);

      container
          .read(canvasNotifierProvider(collectionId).notifier)
          .startConnection(1);
      container
          .read(canvasNotifierProvider(collectionId).notifier)
          .cancelConnection();

      final CanvasState state =
          container.read(canvasNotifierProvider(collectionId));
      expect(state.connectingFromId, isNull);

      container.dispose();
    });

    test('completeConnection should create connection and reset mode',
        () async {
      final ProviderContainer container = createContainer();
      container.read(canvasNotifierProvider(collectionId));
      await waitForLoad(container);

      when(() => mockRepository.createConnection(any())).thenAnswer(
        (Invocation inv) async {
          final CanvasConnection conn =
              inv.positionalArguments[0] as CanvasConnection;
          return conn.copyWith(id: 99);
        },
      );

      container
          .read(canvasNotifierProvider(collectionId).notifier)
          .startConnection(1);
      await container
          .read(canvasNotifierProvider(collectionId).notifier)
          .completeConnection(2);

      final CanvasState state =
          container.read(canvasNotifierProvider(collectionId));
      expect(state.connectingFromId, isNull);
      expect(state.connections.length, 2);
      expect(state.connections.last.id, 99);
      expect(state.connections.last.fromItemId, 1);
      expect(state.connections.last.toItemId, 2);

      container.dispose();
    });

    test('completeConnection with same item should cancel', () async {
      final ProviderContainer container = createContainer();
      container.read(canvasNotifierProvider(collectionId));
      await waitForLoad(container);

      container
          .read(canvasNotifierProvider(collectionId).notifier)
          .startConnection(1);
      await container
          .read(canvasNotifierProvider(collectionId).notifier)
          .completeConnection(1);

      final CanvasState state =
          container.read(canvasNotifierProvider(collectionId));
      expect(state.connectingFromId, isNull);
      // No new connection created
      expect(state.connections.length, 1);

      container.dispose();
    });

    test('completeConnection without startConnection should cancel',
        () async {
      final ProviderContainer container = createContainer();
      container.read(canvasNotifierProvider(collectionId));
      await waitForLoad(container);

      await container
          .read(canvasNotifierProvider(collectionId).notifier)
          .completeConnection(2);

      final CanvasState state =
          container.read(canvasNotifierProvider(collectionId));
      expect(state.connectingFromId, isNull);
      expect(state.connections.length, 1);

      container.dispose();
    });

    test('deleteConnection should remove from state and db', () async {
      final ProviderContainer container = createContainer();
      container.read(canvasNotifierProvider(collectionId));
      await waitForLoad(container);

      when(() => mockRepository.deleteConnection(10))
          .thenAnswer((_) async {});

      await container
          .read(canvasNotifierProvider(collectionId).notifier)
          .deleteConnection(10);

      final CanvasState state =
          container.read(canvasNotifierProvider(collectionId));
      expect(state.connections, isEmpty);
      verify(() => mockRepository.deleteConnection(10)).called(1);

      container.dispose();
    });

    test('updateConnection should update in state and db', () async {
      final ProviderContainer container = createContainer();
      container.read(canvasNotifierProvider(collectionId));
      await waitForLoad(container);

      when(() => mockRepository.updateConnection(any()))
          .thenAnswer((_) async {});

      await container
          .read(canvasNotifierProvider(collectionId).notifier)
          .updateConnection(
            10,
            label: 'new label',
            color: '#00FF00',
            style: ConnectionStyle.dashed,
          );

      final CanvasState state =
          container.read(canvasNotifierProvider(collectionId));
      expect(state.connections.first.label, 'new label');
      expect(state.connections.first.color, '#00FF00');
      expect(state.connections.first.style, ConnectionStyle.dashed);
      verify(() => mockRepository.updateConnection(any())).called(1);

      container.dispose();
    });

    test('updateConnection with non-existent id should do nothing',
        () async {
      final ProviderContainer container = createContainer();
      container.read(canvasNotifierProvider(collectionId));
      await waitForLoad(container);

      await container
          .read(canvasNotifierProvider(collectionId).notifier)
          .updateConnection(
            999,
            label: 'should not apply',
          );

      final CanvasState state =
          container.read(canvasNotifierProvider(collectionId));
      expect(state.connections.first.label, 'related');
      verifyNever(() => mockRepository.updateConnection(any()));

      container.dispose();
    });

    test('deleteItem should also filter connections', () async {
      final ProviderContainer container = createContainer();
      container.read(canvasNotifierProvider(collectionId));
      await waitForLoad(container);

      when(() => mockRepository.deleteItem(1)).thenAnswer((_) async {});

      await container
          .read(canvasNotifierProvider(collectionId).notifier)
          .deleteItem(1);

      final CanvasState state =
          container.read(canvasNotifierProvider(collectionId));
      // Item 1 removed
      expect(state.items.any((CanvasItem i) => i.id == 1), isFalse);
      // Connection involving item 1 also removed
      expect(state.connections, isEmpty);

      container.dispose();
    });

    test('deleteItem should keep unrelated connections', () async {
      final CanvasConnection unrelated = CanvasConnection(
        id: 20,
        collectionId: collectionId,
        fromItemId: 2,
        toItemId: 3,
        createdAt: testDate,
      );

      final ProviderContainer container = createContainer(
        connections: <CanvasConnection>[...testConnections, unrelated],
      );
      container.read(canvasNotifierProvider(collectionId));
      await waitForLoad(container);

      when(() => mockRepository.deleteItem(1)).thenAnswer((_) async {});

      await container
          .read(canvasNotifierProvider(collectionId).notifier)
          .deleteItem(1);

      final CanvasState state =
          container.read(canvasNotifierProvider(collectionId));
      // Connection 10 (involving item 1) removed, connection 20 kept
      expect(state.connections.length, 1);
      expect(state.connections.first.id, 20);

      container.dispose();
    });
  });
}
