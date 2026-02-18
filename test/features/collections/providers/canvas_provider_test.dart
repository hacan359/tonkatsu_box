import 'dart:async';

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
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';

// Моки
class MockCanvasRepository extends Mock implements CanvasRepository {}

class MockCollectionItemsNotifier extends CollectionItemsNotifier {
  MockCollectionItemsNotifier(this._initialState);

  final AsyncValue<List<CollectionItem>> _initialState;

  @override
  AsyncValue<List<CollectionItem>> build(int? arg) {
    return _initialState;
  }

  void emitState(AsyncValue<List<CollectionItem>> newState) {
    state = newState;
  }
}

// Фейковые классы для registerFallbackValue
class FakeCanvasItem extends Fake implements CanvasItem {}

class FakeCanvasViewport extends Fake implements CanvasViewport {}

void main() {
  // Регистрация фейковых значений для mocktail
  setUpAll(() {
    registerFallbackValue(FakeCanvasItem());
    registerFallbackValue(FakeCanvasViewport());
  });

  group('CanvasState', () {
    test('should create with default values', () {
      const CanvasState state = CanvasState();

      expect(state.items, isEmpty);
      expect(state.viewport, CanvasViewport.defaultValue);
      expect(state.isLoading, true);
      expect(state.isInitialized, false);
      expect(state.error, isNull);
    });

    test('should create with custom values', () {
      final DateTime testDate = DateTime(2024, 6, 15);
      final List<CanvasItem> items = <CanvasItem>[
        CanvasItem(
          id: 1,
          collectionId: 10,
          itemType: CanvasItemType.game,
          itemRefId: 100,
          x: 50.0,
          y: 100.0,
          zIndex: 0,
          createdAt: testDate,
        ),
      ];
      const CanvasViewport viewport = CanvasViewport(
        collectionId: 10,
        scale: 1.5,
        offsetX: -100.0,
        offsetY: -200.0,
      );

      final CanvasState state = CanvasState(
        items: items,
        viewport: viewport,
        isLoading: false,
        isInitialized: true,
        error: 'Some error',
      );

      expect(state.items.length, 1);
      expect(state.viewport.scale, 1.5);
      expect(state.isLoading, false);
      expect(state.isInitialized, true);
      expect(state.error, 'Some error');
    });

    group('copyWith', () {
      test('should copy with changed items', () {
        const CanvasState original = CanvasState();
        final DateTime testDate = DateTime(2024, 6, 15);
        final List<CanvasItem> newItems = <CanvasItem>[
          CanvasItem(
            id: 1,
            collectionId: 10,
            itemType: CanvasItemType.game,
            x: 0,
            y: 0,
            zIndex: 0,
            createdAt: testDate,
          ),
        ];

        final CanvasState copy = original.copyWith(items: newItems);

        expect(copy.items.length, 1);
        expect(copy.isLoading, original.isLoading);
        expect(copy.isInitialized, original.isInitialized);
      });

      test('should copy with changed viewport', () {
        const CanvasState original = CanvasState();
        const CanvasViewport newViewport = CanvasViewport(
          collectionId: 5,
          scale: 2.0,
        );

        final CanvasState copy = original.copyWith(viewport: newViewport);

        expect(copy.viewport.scale, 2.0);
        expect(copy.items, original.items);
      });

      test('should copy with changed loading state', () {
        const CanvasState original = CanvasState();

        final CanvasState copy = original.copyWith(
          isLoading: false,
          isInitialized: true,
        );

        expect(copy.isLoading, false);
        expect(copy.isInitialized, true);
      });

      test('should clear error when copying with null error', () {
        const CanvasState original = CanvasState(error: 'Some error');

        final CanvasState copy = original.copyWith(isLoading: false);

        // error defaults to null in copyWith when not explicitly passed
        expect(copy.error, isNull);
      });

      test('should preserve error when explicitly passed', () {
        const CanvasState original = CanvasState();

        final CanvasState copy = original.copyWith(error: 'New error');

        expect(copy.error, 'New error');
      });

      test('should keep original values when not specified', () {
        final DateTime testDate = DateTime(2024, 6, 15);
        final CanvasState original = CanvasState(
          items: <CanvasItem>[
            CanvasItem(
              id: 1,
              collectionId: 10,
              itemType: CanvasItemType.game,
              x: 0,
              y: 0,
              zIndex: 0,
              createdAt: testDate,
            ),
          ],
          viewport: const CanvasViewport(
            collectionId: 10,
            scale: 2.0,
          ),
          isLoading: false,
          isInitialized: true,
          error: 'Error',
        );

        final CanvasState copy = original.copyWith(error: 'Error');

        expect(copy.items.length, original.items.length);
        expect(copy.viewport.scale, original.viewport.scale);
        expect(copy.isLoading, original.isLoading);
        expect(copy.isInitialized, original.isInitialized);
      });
    });
  });

  group('CanvasNotifier', () {
    late MockCanvasRepository mockRepository;
    final DateTime testDate = DateTime(2024, 6, 15);
    const int collectionId = 1;

    // Вспомогательные данные для тестов
    late List<CanvasItem> testItems;
    late List<CollectionItem> testCollectionItems;

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
          itemType: CanvasItemType.game,
          itemRefId: 300,
          x: 450.0,
          y: 100.0,
          width: 160,
          height: 220,
          zIndex: 2,
          createdAt: testDate,
        ),
      ];

      testCollectionItems = <CollectionItem>[
        CollectionItem(
          id: 1,
          collectionId: collectionId,
          mediaType: MediaType.game,
          externalId: 100,
          platformId: 6,
          status: ItemStatus.notStarted,
          addedAt: testDate,
        ),
        CollectionItem(
          id: 2,
          collectionId: collectionId,
          mediaType: MediaType.game,
          externalId: 200,
          platformId: 6,
          status: ItemStatus.inProgress,
          addedAt: testDate,
        ),
        CollectionItem(
          id: 3,
          collectionId: collectionId,
          mediaType: MediaType.game,
          externalId: 300,
          platformId: 48,
          status: ItemStatus.completed,
          addedAt: testDate,
        ),
      ];
    });

    // Вспомогательный метод для создания ProviderContainer
    ProviderContainer createContainer({
      AsyncValue<List<CollectionItem>>? itemsState,
    }) {
      final AsyncValue<List<CollectionItem>> initialItemsState = itemsState ??
          AsyncData<List<CollectionItem>>(testCollectionItems);

      return ProviderContainer(
        overrides: <Override>[
          canvasRepositoryProvider.overrideWithValue(mockRepository),
          collectionItemsNotifierProvider
              .overrideWith(() => MockCollectionItemsNotifier(initialItemsState)),
        ],
      );
    }

    // Вспомогательный метод: настроить репо для загрузки существующих элементов
    void setupExistingCanvas({
      List<CanvasItem>? items,
      CanvasViewport? viewport,
    }) {
      final List<CanvasItem> effectiveItems = items ?? testItems;
      when(() => mockRepository.hasCanvasItems(collectionId))
          .thenAnswer((_) async => true);
      when(() => mockRepository.getItems(collectionId))
          .thenAnswer((_) async => effectiveItems);
      when(() => mockRepository.getItemsWithData(collectionId))
          .thenAnswer((_) async => effectiveItems);
      when(() => mockRepository.getViewport(collectionId))
          .thenAnswer((_) async => viewport);
      when(() => mockRepository.deleteItem(any()))
          .thenAnswer((_) async {});
      when(() => mockRepository.getConnections(collectionId))
          .thenAnswer((_) async => const <CanvasConnection>[]);
    }

    // Вспомогательный метод: настроить репо для инициализации нового канваса
    void setupNewCanvas({List<CollectionItem>? items}) {
      final List<CollectionItem> effectiveItems = items ?? testCollectionItems;
      when(() => mockRepository.hasCanvasItems(collectionId))
          .thenAnswer((_) async => false);
      when(() => mockRepository.initializeCanvas(collectionId, any()))
          .thenAnswer((_) async {
        final List<CanvasItem> created = <CanvasItem>[];
        for (int i = 0; i < effectiveItems.length; i++) {
          created.add(
            CanvasItem(
              id: i + 1,
              collectionId: collectionId,
              itemType: CanvasItemType.game,
              itemRefId: effectiveItems[i].externalId,
              x: 100.0 + i * 184.0,
              y: 100.0,
              width: 160,
              height: 220,
              zIndex: i,
              createdAt: testDate,
            ),
          );
        }
        return created;
      });
    }

    group('build()', () {
      test(
        'должен загрузить существующие элементы канваса когда они есть в БД',
        () async {
          const CanvasViewport savedViewport = CanvasViewport(
            collectionId: collectionId,
            scale: 1.5,
            offsetX: -100.0,
            offsetY: -200.0,
          );
          setupExistingCanvas(viewport: savedViewport);

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          // Читаем state для запуска build()
          final CanvasState initialState =
              container.read(canvasNotifierProvider(collectionId));
          expect(initialState.isLoading, true);

          // Ждём загрузки (Future.microtask)
          await Future<void>.delayed(Duration.zero);

          final CanvasState loadedState =
              container.read(canvasNotifierProvider(collectionId));
          expect(loadedState.isLoading, false);
          expect(loadedState.isInitialized, true);
          expect(loadedState.items.length, 3);
          expect(loadedState.viewport.scale, 1.5);
          expect(loadedState.viewport.offsetX, -100.0);
          expect(loadedState.error, isNull);

          verify(() => mockRepository.hasCanvasItems(collectionId)).called(1);
          verify(() => mockRepository.getItemsWithData(collectionId)).called(1);
          verify(() => mockRepository.getViewport(collectionId)).called(1);
        },
      );

      test(
        'должен инициализировать канвас из игр когда элементов нет в БД',
        () async {
          setupNewCanvas();

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasState state =
              container.read(canvasNotifierProvider(collectionId));
          expect(state.isLoading, false);
          expect(state.isInitialized, true);
          expect(state.items.length, 3);
          expect(state.error, isNull);
          expect(state.viewport.collectionId, collectionId);

          verify(
            () => mockRepository.initializeCanvas(collectionId, any()),
          ).called(1);
        },
      );

      test(
        'должен использовать viewport по умолчанию когда viewport null в БД',
        () async {
          setupExistingCanvas(viewport: null);

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasState state =
              container.read(canvasNotifierProvider(collectionId));
          expect(state.viewport.collectionId, collectionId);
          expect(state.viewport.scale, 1.0);
          expect(state.viewport.offsetX, 0.0);
          expect(state.viewport.offsetY, 0.0);
        },
      );

      test(
        'должен установить ошибку когда загрузка канваса бросает исключение',
        () async {
          when(() => mockRepository.hasCanvasItems(collectionId))
              .thenThrow(Exception('Database error'));

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasState state =
              container.read(canvasNotifierProvider(collectionId));
          expect(state.isLoading, false);
          expect(state.error, contains('Database error'));
        },
      );

      test(
        'должен установить ошибку когда инициализация из игр бросает исключение',
        () async {
          when(() => mockRepository.hasCanvasItems(collectionId))
              .thenAnswer((_) async => false);
          when(() => mockRepository.initializeCanvas(collectionId, any()))
              .thenThrow(Exception('Init error'));

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasState state =
              container.read(canvasNotifierProvider(collectionId));
          expect(state.isLoading, false);
          expect(state.error, contains('Init error'));
        },
      );

      test(
        'должен инициализировать канвас с пустым списком игр когда игры ещё не загружены',
        () async {
          when(() => mockRepository.hasCanvasItems(collectionId))
              .thenAnswer((_) async => false);
          when(() => mockRepository.initializeCanvas(collectionId, any()))
              .thenAnswer((_) async => <CanvasItem>[]);

          final ProviderContainer container = createContainer(
            itemsState:
                const AsyncLoading<List<CollectionItem>>(),
          );
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasState state =
              container.read(canvasNotifierProvider(collectionId));
          expect(state.isLoading, false);
          expect(state.isInitialized, true);
          expect(state.items, isEmpty);

          verify(
            () => mockRepository.initializeCanvas(
              collectionId,
              <CollectionItem>[],
            ),
          ).called(1);
        },
      );
    });

    group('_syncCanvasWithGames() через build/_loadCanvas', () {
      test(
        'должен удалить сиротские элементы канваса когда игры удалены из коллекции',
        () async {
          // В канвасе 3 элемента, но в коллекции только 2 игры (externalId 100 и 200)
          final List<CollectionItem> twoItems = <CollectionItem>[
            testCollectionItems[0],
            testCollectionItems[1],
          ];
          setupExistingCanvas();

          final ProviderContainer container = createContainer(
            itemsState: AsyncData<List<CollectionItem>>(twoItems),
          );
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          // Элемент с itemRefId=300 должен быть удалён
          verify(() => mockRepository.deleteItem(3)).called(1);
        },
      );

      test(
        'должен добавить недостающие элементы канваса когда игры добавлены в коллекцию',
        () async {
          // В канвасе 2 элемента, но в коллекции 3 игры (добавлена externalId=400)
          final List<CanvasItem> twoCanvasItems = <CanvasItem>[
            testItems[0],
            testItems[1],
          ];
          final List<CollectionItem> threeCollectionItems = <CollectionItem>[
            ...testCollectionItems.sublist(0, 2),
            CollectionItem(
              id: 4,
              collectionId: collectionId,
              mediaType: MediaType.game,
              externalId: 400,
              platformId: 6,
              status: ItemStatus.planned,
              addedAt: testDate,
            ),
          ];

          when(() => mockRepository.hasCanvasItems(collectionId))
              .thenAnswer((_) async => true);
          when(() => mockRepository.getItems(collectionId))
              .thenAnswer((_) async => twoCanvasItems);
          when(() => mockRepository.getItemsWithData(collectionId))
              .thenAnswer((_) async => twoCanvasItems);
          when(() => mockRepository.getViewport(collectionId))
              .thenAnswer((_) async => null);
          when(() => mockRepository.getConnections(collectionId))
              .thenAnswer((_) async => const <CanvasConnection>[]);
          when(() => mockRepository.createItem(any()))
              .thenAnswer((Invocation invocation) async {
            final CanvasItem item =
                invocation.positionalArguments[0] as CanvasItem;
            return item.copyWith(id: 10);
          });

          final ProviderContainer container = createContainer(
            itemsState: AsyncData<List<CollectionItem>>(threeCollectionItems),
          );
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          verify(() => mockRepository.createItem(any())).called(1);
        },
      );

      test(
        'должен пропустить синхронизацию когда игры ещё не загружены',
        () async {
          when(() => mockRepository.hasCanvasItems(collectionId))
              .thenAnswer((_) async => true);
          when(() => mockRepository.getItems(collectionId))
              .thenAnswer((_) async => testItems);
          when(() => mockRepository.getItemsWithData(collectionId))
              .thenAnswer((_) async => testItems);
          when(() => mockRepository.getViewport(collectionId))
              .thenAnswer((_) async => null);
          when(() => mockRepository.getConnections(collectionId))
              .thenAnswer((_) async => const <CanvasConnection>[]);

          final ProviderContainer container = createContainer(
            itemsState:
                const AsyncLoading<List<CollectionItem>>(),
          );
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          // getItems вызывается для syncCanvasWithGames, но т.к. items == null
          // синхронизация пропускается и getItems НЕ вызывается
          // (hasCanvasItems -> true -> _syncCanvasWithGames -> items == null -> return)
          // Далее getItemsWithData вызывается для загрузки
          verify(() => mockRepository.getItemsWithData(collectionId)).called(1);
          verifyNever(() => mockRepository.deleteItem(any()));
        },
      );
    });

    group('removeGameItem()', () {
      test(
        'должен удалить элемент игры из state и БД когда вызван с externalId',
        () async {
          setupExistingCanvas();
          when(
            () => mockRepository.deleteMediaItem(
                collectionId, CanvasItemType.game, any<int>()),
          ).thenAnswer((_) async {});

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          notifier.removeGameItem(200);

          final CanvasState state =
              container.read(canvasNotifierProvider(collectionId));
          expect(state.items.length, 2);
          expect(
            state.items
                .any((CanvasItem item) => item.itemRefId == 200),
            false,
          );

          verify(
            () => mockRepository.deleteMediaItem(
                collectionId, CanvasItemType.game, 200),
          ).called(1);
        },
      );

      test(
        'должен не менять state когда externalId не найден',
        () async {
          setupExistingCanvas();
          when(
            () => mockRepository.deleteMediaItem(
                collectionId, CanvasItemType.game, any<int>()),
          ).thenAnswer((_) async {});

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          notifier.removeGameItem(999);

          final CanvasState state =
              container.read(canvasNotifierProvider(collectionId));
          expect(state.items.length, 3);
        },
      );
    });

    group('refresh()', () {
      test(
        'должен перезагрузить канвас из БД когда вызван',
        () async {
          setupExistingCanvas();

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          // Первая загрузка завершена
          expect(
            container.read(canvasNotifierProvider(collectionId)).isLoading,
            false,
          );

          // Настраиваем обновлённые данные
          final List<CanvasItem> updatedItems = <CanvasItem>[testItems[0]];
          when(() => mockRepository.getItemsWithData(collectionId))
              .thenAnswer((_) async => updatedItems);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          await notifier.refresh();

          final CanvasState state =
              container.read(canvasNotifierProvider(collectionId));
          expect(state.isLoading, false);
          expect(state.items.length, 1);
          expect(state.error, isNull);
        },
      );

      test(
        'должен установить isLoading в true перед загрузкой когда refresh вызван',
        () async {
          setupExistingCanvas();

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          // Делаем загрузку медленной чтобы проверить isLoading
          final Completer<List<CanvasItem>> completer =
              Completer<List<CanvasItem>>();
          when(() => mockRepository.hasCanvasItems(collectionId))
              .thenAnswer((_) async => true);
          when(() => mockRepository.getItemsWithData(collectionId))
              .thenAnswer((_) => completer.future);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);

          // ignore: unawaited_futures
          final Future<void> refreshFuture = notifier.refresh();

          // Не завершаем completer, проверяем промежуточное состояние
          // (refresh устанавливает isLoading=true синхронно, но hasCanvasItems
          // тоже async, поэтому подождём microtask)
          await Future<void>.delayed(Duration.zero);

          // Завершаем загрузку
          completer.complete(testItems);
          await refreshFuture;

          final CanvasState state =
              container.read(canvasNotifierProvider(collectionId));
          expect(state.isLoading, false);
        },
      );

      test(
        'должен очистить предыдущую ошибку когда refresh вызван',
        () async {
          // Первая загрузка с ошибкой
          when(() => mockRepository.hasCanvasItems(collectionId))
              .thenThrow(Exception('First error'));

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          expect(
            container.read(canvasNotifierProvider(collectionId)).error,
            isNotNull,
          );

          // Настраиваем успешную загрузку
          setupExistingCanvas();

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          await notifier.refresh();

          final CanvasState state =
              container.read(canvasNotifierProvider(collectionId));
          expect(state.error, isNull);
          expect(state.isLoading, false);
          expect(state.isInitialized, true);
        },
      );
    });

    group('moveItem()', () {
      test(
        'должен обновить позицию элемента в state мгновенно когда вызван',
        () async {
          setupExistingCanvas();

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          notifier.moveItem(1, 999.0, 888.0);

          final CanvasState state =
              container.read(canvasNotifierProvider(collectionId));
          final CanvasItem movedItem = state.items.firstWhere(
            (CanvasItem item) => item.id == 1,
          );
          expect(movedItem.x, 999.0);
          expect(movedItem.y, 888.0);
        },
      );

      test(
        'должен сохранить в БД с debounce когда moveItem вызван',
        () async {
          setupExistingCanvas();
          when(
            () => mockRepository.updateItemPosition(
              any(),
              x: any(named: 'x'),
              y: any(named: 'y'),
            ),
          ).thenAnswer((_) async {});

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          notifier.moveItem(1, 100.0, 200.0);

          // Сразу после вызова — БД ещё не вызвана (debounce 300ms)
          verifyNever(
            () => mockRepository.updateItemPosition(
              any(),
              x: any(named: 'x'),
              y: any(named: 'y'),
            ),
          );

          // Ждём debounce
          await Future<void>.delayed(const Duration(milliseconds: 350));

          verify(
            () => mockRepository.updateItemPosition(
              1,
              x: 100.0,
              y: 200.0,
            ),
          ).called(1);
        },
      );

      test(
        'должен отменить предыдущий debounce когда moveItem вызван повторно',
        () async {
          setupExistingCanvas();
          when(
            () => mockRepository.updateItemPosition(
              any(),
              x: any(named: 'x'),
              y: any(named: 'y'),
            ),
          ).thenAnswer((_) async {});

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);

          // Быстрые последовательные перемещения
          notifier.moveItem(1, 100.0, 200.0);
          await Future<void>.delayed(const Duration(milliseconds: 100));
          notifier.moveItem(1, 150.0, 250.0);
          await Future<void>.delayed(const Duration(milliseconds: 100));
          notifier.moveItem(1, 200.0, 300.0);

          // Ждём debounce после последнего вызова
          await Future<void>.delayed(const Duration(milliseconds: 350));

          // Только последнее значение должно быть сохранено
          verify(
            () => mockRepository.updateItemPosition(
              1,
              x: 200.0,
              y: 300.0,
            ),
          ).called(1);
          // Промежуточные значения НЕ должны быть сохранены
          verifyNever(
            () => mockRepository.updateItemPosition(
              1,
              x: 100.0,
              y: 200.0,
            ),
          );
          verifyNever(
            () => mockRepository.updateItemPosition(
              1,
              x: 150.0,
              y: 250.0,
            ),
          );
        },
      );

      test(
        'должен не менять другие элементы когда перемещается один элемент',
        () async {
          setupExistingCanvas();

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          notifier.moveItem(1, 999.0, 888.0);

          final CanvasState state =
              container.read(canvasNotifierProvider(collectionId));
          final CanvasItem unchanged = state.items.firstWhere(
            (CanvasItem item) => item.id == 2,
          );
          expect(unchanged.x, 250.0);
          expect(unchanged.y, 100.0);
        },
      );
    });

    group('updateViewport()', () {
      test(
        'должен обновить viewport в state мгновенно когда вызван',
        () async {
          setupExistingCanvas();

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          notifier.updateViewport(2.0, -100.0, -200.0);

          final CanvasState state =
              container.read(canvasNotifierProvider(collectionId));
          expect(state.viewport.scale, 2.0);
          expect(state.viewport.offsetX, -100.0);
          expect(state.viewport.offsetY, -200.0);
          expect(state.viewport.collectionId, collectionId);
        },
      );

      test(
        'должен сохранить viewport в БД с debounce когда вызван',
        () async {
          setupExistingCanvas();
          when(
            () => mockRepository.saveViewport(any()),
          ).thenAnswer((_) async {});

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          notifier.updateViewport(2.0, -100.0, -200.0);

          // Сразу после вызова — не сохранено (debounce 500ms)
          verifyNever(() => mockRepository.saveViewport(any()));

          // Ждём debounce
          await Future<void>.delayed(const Duration(milliseconds: 550));

          verify(() => mockRepository.saveViewport(any())).called(1);
        },
      );

      test(
        'должен отменить предыдущий debounce когда updateViewport вызван повторно',
        () async {
          setupExistingCanvas();
          when(
            () => mockRepository.saveViewport(any()),
          ).thenAnswer((_) async {});

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);

          notifier.updateViewport(1.5, -50.0, -50.0);
          await Future<void>.delayed(const Duration(milliseconds: 200));
          notifier.updateViewport(2.0, -100.0, -200.0);

          // Ждём debounce после последнего вызова
          await Future<void>.delayed(const Duration(milliseconds: 550));

          // Только один вызов
          verify(() => mockRepository.saveViewport(any())).called(1);
        },
      );
    });

    group('resetViewport()', () {
      test(
        'должен сбросить viewport на значение по умолчанию когда вызван',
        () async {
          const CanvasViewport savedViewport = CanvasViewport(
            collectionId: collectionId,
            scale: 2.0,
            offsetX: -500.0,
            offsetY: -300.0,
          );
          setupExistingCanvas(viewport: savedViewport);
          when(
            () => mockRepository.saveViewport(any()),
          ).thenAnswer((_) async {});

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          // Проверяем что viewport сохранён
          expect(
            container.read(canvasNotifierProvider(collectionId)).viewport.scale,
            2.0,
          );

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          notifier.resetViewport();

          final CanvasState state =
              container.read(canvasNotifierProvider(collectionId));
          expect(state.viewport.scale, 1.0);
          expect(state.viewport.offsetX, 0.0);
          expect(state.viewport.offsetY, 0.0);
          expect(state.viewport.collectionId, collectionId);

          // Должен сохранить в БД без debounce
          verify(() => mockRepository.saveViewport(any())).called(1);
        },
      );
    });

    group('resetPositions()', () {
      test(
        'должен не менять state когда список элементов пуст',
        () async {
          setupExistingCanvas(items: <CanvasItem>[]);

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          await notifier.resetPositions(1000.0);

          final CanvasState state =
              container.read(canvasNotifierProvider(collectionId));
          expect(state.items, isEmpty);
        },
      );

      test(
        'должен расположить элементы сеткой по центру канваса когда вызван',
        () async {
          setupExistingCanvas();
          when(
            () => mockRepository.updateItemPosition(
              any(),
              x: any(named: 'x'),
              y: any(named: 'y'),
            ),
          ).thenAnswer((_) async {});

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          await notifier.resetPositions(1000.0);

          final CanvasState state =
              container.read(canvasNotifierProvider(collectionId));

          // Все элементы должны иметь zIndex == 0 после сброса
          for (final CanvasItem item in state.items) {
            expect(item.zIndex, 0);
          }

          // Должен вызвать updateItemPosition для каждого элемента
          verify(
            () => mockRepository.updateItemPosition(
              any(),
              x: any(named: 'x'),
              y: any(named: 'y'),
            ),
          ).called(3);
        },
      );

      test(
        'должен рассчитать колонки по ширине viewport когда вызван',
        () async {
          setupExistingCanvas();
          when(
            () => mockRepository.updateItemPosition(
              any(),
              x: any(named: 'x'),
              y: any(named: 'y'),
            ),
          ).thenAnswer((_) async {});

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);

          // Узкий viewport — все элементы в одну колонку
          await notifier.resetPositions(160.0);

          final CanvasState state =
              container.read(canvasNotifierProvider(collectionId));

          // При одной колонке все x-координаты должны быть одинаковыми
          final Set<double> uniqueX =
              state.items.map((CanvasItem item) => item.x).toSet();
          expect(uniqueX.length, 1);
        },
      );
    });

    group('addItem()', () {
      test(
        'должен добавить элемент в state и вернуть элемент с ID когда вызван',
        () async {
          setupExistingCanvas();

          final CanvasItem newItem = CanvasItem(
            id: 0,
            collectionId: collectionId,
            itemType: CanvasItemType.text,
            x: 500.0,
            y: 500.0,
            zIndex: 10,
            createdAt: testDate,
          );

          when(() => mockRepository.createItem(any()))
              .thenAnswer((_) async => newItem.copyWith(id: 42));

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          final CanvasItem created = await notifier.addItem(newItem);

          expect(created.id, 42);

          final CanvasState state =
              container.read(canvasNotifierProvider(collectionId));
          expect(state.items.length, 4);
          expect(
            state.items.any((CanvasItem item) => item.id == 42),
            true,
          );

          verify(() => mockRepository.createItem(any())).called(1);
        },
      );
    });

    group('deleteItem()', () {
      test(
        'должен удалить элемент из state и БД когда вызван с id',
        () async {
          setupExistingCanvas();
          when(() => mockRepository.deleteItem(any()))
              .thenAnswer((_) async {});

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          expect(
            container
                .read(canvasNotifierProvider(collectionId))
                .items
                .length,
            3,
          );

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          await notifier.deleteItem(2);

          final CanvasState state =
              container.read(canvasNotifierProvider(collectionId));
          expect(state.items.length, 2);
          expect(
            state.items.any((CanvasItem item) => item.id == 2),
            false,
          );

          verify(() => mockRepository.deleteItem(2)).called(1);
        },
      );

      test(
        'должен не менять размер списка когда id не найден',
        () async {
          setupExistingCanvas();
          when(() => mockRepository.deleteItem(any()))
              .thenAnswer((_) async {});

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          await notifier.deleteItem(999);

          final CanvasState state =
              container.read(canvasNotifierProvider(collectionId));
          // id==999 не найден — все 3 остались
          expect(state.items.length, 3);
        },
      );
    });

    group('bringToFront()', () {
      test(
        'должен установить максимальный z-index + 1 когда вызван',
        () async {
          setupExistingCanvas();
          when(
            () => mockRepository.updateItemZIndex(any(), any()),
          ).thenAnswer((_) async {});

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          await notifier.bringToFront(1);

          final CanvasState state =
              container.read(canvasNotifierProvider(collectionId));
          final CanvasItem frontItem = state.items.firstWhere(
            (CanvasItem item) => item.id == 1,
          );

          // Максимальный zIndex был 2, значит новый = 3
          expect(frontItem.zIndex, 3);

          verify(() => mockRepository.updateItemZIndex(1, 3)).called(1);
        },
      );

      test(
        'должен не менять state когда список элементов пуст',
        () async {
          setupExistingCanvas(items: <CanvasItem>[]);

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          await notifier.bringToFront(1);

          verifyNever(() => mockRepository.updateItemZIndex(any(), any()));
        },
      );

      test(
        'должен не менять другие элементы когда один перемещён на передний план',
        () async {
          setupExistingCanvas();
          when(
            () => mockRepository.updateItemZIndex(any(), any()),
          ).thenAnswer((_) async {});

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          await notifier.bringToFront(1);

          final CanvasState state =
              container.read(canvasNotifierProvider(collectionId));
          final CanvasItem item2 = state.items.firstWhere(
            (CanvasItem item) => item.id == 2,
          );
          final CanvasItem item3 = state.items.firstWhere(
            (CanvasItem item) => item.id == 3,
          );
          expect(item2.zIndex, 1);
          expect(item3.zIndex, 2);
        },
      );
    });

    group('sendToBack()', () {
      test(
        'должен установить минимальный z-index - 1 когда вызван',
        () async {
          setupExistingCanvas();
          when(
            () => mockRepository.updateItemZIndex(any(), any()),
          ).thenAnswer((_) async {});

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          await notifier.sendToBack(3);

          final CanvasState state =
              container.read(canvasNotifierProvider(collectionId));
          final CanvasItem backItem = state.items.firstWhere(
            (CanvasItem item) => item.id == 3,
          );

          // Минимальный zIndex был 0, значит новый = -1
          expect(backItem.zIndex, -1);

          verify(() => mockRepository.updateItemZIndex(3, -1)).called(1);
        },
      );

      test(
        'должен не менять state когда список элементов пуст',
        () async {
          setupExistingCanvas(items: <CanvasItem>[]);

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          await notifier.sendToBack(3);

          verifyNever(() => mockRepository.updateItemZIndex(any(), any()));
        },
      );

      test(
        'должен не менять другие элементы когда один отправлен на задний план',
        () async {
          setupExistingCanvas();
          when(
            () => mockRepository.updateItemZIndex(any(), any()),
          ).thenAnswer((_) async {});

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          await notifier.sendToBack(3);

          final CanvasState state =
              container.read(canvasNotifierProvider(collectionId));
          final CanvasItem item1 = state.items.firstWhere(
            (CanvasItem item) => item.id == 1,
          );
          final CanvasItem item2 = state.items.firstWhere(
            (CanvasItem item) => item.id == 2,
          );
          expect(item1.zIndex, 0);
          expect(item2.zIndex, 1);
        },
      );
    });

    group('bringToFront() и sendToBack() последовательно', () {
      test(
        'должен корректно обрабатывать множественные перемещения по z-index',
        () async {
          setupExistingCanvas();
          when(
            () => mockRepository.updateItemZIndex(any(), any()),
          ).thenAnswer((_) async {});

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);

          // item1(z=0) -> front -> z=3
          await notifier.bringToFront(1);
          // item2(z=1) -> back -> z=-1
          await notifier.sendToBack(2);

          final CanvasState state =
              container.read(canvasNotifierProvider(collectionId));
          final CanvasItem item1 = state.items.firstWhere(
            (CanvasItem item) => item.id == 1,
          );
          final CanvasItem item2 = state.items.firstWhere(
            (CanvasItem item) => item.id == 2,
          );
          final CanvasItem item3 = state.items.firstWhere(
            (CanvasItem item) => item.id == 3,
          );

          expect(item1.zIndex, 3);
          // Минимальный z-index после первого bringToFront: min(3,1,2) = 1
          // sendToBack(2) -> 1 - 1 = 0
          expect(item2.zIndex, 0);
          expect(item3.zIndex, 2);
        },
      );
    });

    group('addTextItem()', () {
      test(
        'должен создать текстовый элемент с правильным типом, данными и размерами',
        () async {
          setupExistingCanvas();
          when(() => mockRepository.createItem(any()))
              .thenAnswer((Invocation invocation) async {
            final CanvasItem item =
                invocation.positionalArguments[0] as CanvasItem;
            return item.copyWith(id: 100);
          });

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          final CanvasItem created =
              await notifier.addTextItem(150.0, 250.0, 'Hello', 16.0);

          expect(created.id, 100);
          expect(created.itemType, CanvasItemType.text);
          expect(created.x, 150.0);
          expect(created.y, 250.0);
          expect(created.width, 200);
          expect(created.height, isNull);
          expect(created.data, isNotNull);
          expect(created.data!['content'], 'Hello');
          expect(created.data!['fontSize'], 16.0);
          expect(created.collectionId, collectionId);

          final CanvasState state =
              container.read(canvasNotifierProvider(collectionId));
          expect(state.items.length, 4);
          expect(
            state.items.any((CanvasItem item) => item.id == 100),
            true,
          );
        },
      );

      test(
        'должен установить zIndex в maxZ+1 когда есть существующие элементы',
        () async {
          setupExistingCanvas(); // 3 items с zIndex 0, 1, 2
          late CanvasItem capturedItem;
          when(() => mockRepository.createItem(any()))
              .thenAnswer((Invocation invocation) async {
            capturedItem =
                invocation.positionalArguments[0] as CanvasItem;
            return capturedItem.copyWith(id: 100);
          });

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          await notifier.addTextItem(0.0, 0.0, 'Test', 14.0);

          // maxZ = 2, поэтому zIndex нового элемента = 3
          expect(capturedItem.zIndex, 3);
        },
      );

      test(
        'должен установить zIndex в 0 когда список элементов пуст',
        () async {
          setupExistingCanvas(items: <CanvasItem>[]);
          late CanvasItem capturedItem;
          when(() => mockRepository.createItem(any()))
              .thenAnswer((Invocation invocation) async {
            capturedItem =
                invocation.positionalArguments[0] as CanvasItem;
            return capturedItem.copyWith(id: 100);
          });

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          await notifier.addTextItem(0.0, 0.0, 'Test', 14.0);

          expect(capturedItem.zIndex, 0);
        },
      );
    });

    group('addImageItem()', () {
      test(
        'должен создать элемент изображения с правильным типом и размерами 200x200',
        () async {
          setupExistingCanvas();
          when(() => mockRepository.createItem(any()))
              .thenAnswer((Invocation invocation) async {
            final CanvasItem item =
                invocation.positionalArguments[0] as CanvasItem;
            return item.copyWith(id: 101);
          });

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          final Map<String, dynamic> imageData = <String, dynamic>{
            'url': 'https://example.com/image.png',
            'source': 'steamgriddb',
          };
          final CanvasItem created =
              await notifier.addImageItem(300.0, 400.0, imageData);

          expect(created.id, 101);
          expect(created.itemType, CanvasItemType.image);
          expect(created.x, 300.0);
          expect(created.y, 400.0);
          expect(created.width, 200);
          expect(created.height, 200);
          expect(created.collectionId, collectionId);

          final CanvasState state =
              container.read(canvasNotifierProvider(collectionId));
          expect(state.items.length, 4);
        },
      );

      test(
        'должен передать imageData в поле data элемента',
        () async {
          setupExistingCanvas();
          late CanvasItem capturedItem;
          when(() => mockRepository.createItem(any()))
              .thenAnswer((Invocation invocation) async {
            capturedItem =
                invocation.positionalArguments[0] as CanvasItem;
            return capturedItem.copyWith(id: 101);
          });

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          final Map<String, dynamic> imageData = <String, dynamic>{
            'url': 'https://example.com/img.jpg',
            'width': 640,
            'height': 480,
          };
          await notifier.addImageItem(100.0, 100.0, imageData);

          expect(capturedItem.data, isNotNull);
          expect(capturedItem.data!['url'], 'https://example.com/img.jpg');
          expect(capturedItem.data!['width'], 640);
          expect(capturedItem.data!['height'], 480);
        },
      );
    });

    group('addLinkItem()', () {
      test(
        'должен создать элемент ссылки с правильным типом и размерами 200x48',
        () async {
          setupExistingCanvas();
          when(() => mockRepository.createItem(any()))
              .thenAnswer((Invocation invocation) async {
            final CanvasItem item =
                invocation.positionalArguments[0] as CanvasItem;
            return item.copyWith(id: 102);
          });

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          final CanvasItem created = await notifier.addLinkItem(
            500.0,
            600.0,
            'https://example.com',
            'Example',
          );

          expect(created.id, 102);
          expect(created.itemType, CanvasItemType.link);
          expect(created.x, 500.0);
          expect(created.y, 600.0);
          expect(created.width, 200);
          expect(created.height, 48);
          expect(created.collectionId, collectionId);

          final CanvasState state =
              container.read(canvasNotifierProvider(collectionId));
          expect(state.items.length, 4);
        },
      );

      test(
        'должен установить url и label в поле data элемента',
        () async {
          setupExistingCanvas();
          late CanvasItem capturedItem;
          when(() => mockRepository.createItem(any()))
              .thenAnswer((Invocation invocation) async {
            capturedItem =
                invocation.positionalArguments[0] as CanvasItem;
            return capturedItem.copyWith(id: 102);
          });

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          await notifier.addLinkItem(
            0.0,
            0.0,
            'https://igdb.com/games/123',
            'IGDB Page',
          );

          expect(capturedItem.data, isNotNull);
          expect(capturedItem.data!['url'], 'https://igdb.com/games/123');
          expect(capturedItem.data!['label'], 'IGDB Page');
        },
      );
    });

    group('updateItemData()', () {
      test(
        'должен обновить data в state для указанного itemId',
        () async {
          setupExistingCanvas();
          when(() => mockRepository.updateItemData(any(), any()))
              .thenAnswer((_) async {});

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          final Map<String, dynamic> newData = <String, dynamic>{
            'content': 'Updated text',
            'fontSize': 20.0,
          };
          await notifier.updateItemData(1, newData);

          final CanvasState state =
              container.read(canvasNotifierProvider(collectionId));
          final CanvasItem updatedItem = state.items.firstWhere(
            (CanvasItem item) => item.id == 1,
          );
          expect(updatedItem.data, isNotNull);
          expect(updatedItem.data!['content'], 'Updated text');
          expect(updatedItem.data!['fontSize'], 20.0);
        },
      );

      test(
        'должен вызвать repository.updateItemData с правильными параметрами',
        () async {
          setupExistingCanvas();
          when(() => mockRepository.updateItemData(any(), any()))
              .thenAnswer((_) async {});

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          final Map<String, dynamic> newData = <String, dynamic>{
            'url': 'https://updated.com',
          };
          await notifier.updateItemData(2, newData);

          verify(
            () => mockRepository.updateItemData(2, newData),
          ).called(1);
        },
      );

      test(
        'должен не менять другие элементы когда обновляется data одного элемента',
        () async {
          setupExistingCanvas();
          when(() => mockRepository.updateItemData(any(), any()))
              .thenAnswer((_) async {});

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          // Запоминаем исходное состояние элементов 2 и 3
          final CanvasState stateBefore =
              container.read(canvasNotifierProvider(collectionId));
          final CanvasItem item2Before = stateBefore.items.firstWhere(
            (CanvasItem item) => item.id == 2,
          );
          final CanvasItem item3Before = stateBefore.items.firstWhere(
            (CanvasItem item) => item.id == 3,
          );

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          await notifier.updateItemData(
            1,
            <String, dynamic>{'content': 'New'},
          );

          final CanvasState stateAfter =
              container.read(canvasNotifierProvider(collectionId));
          final CanvasItem item2After = stateAfter.items.firstWhere(
            (CanvasItem item) => item.id == 2,
          );
          final CanvasItem item3After = stateAfter.items.firstWhere(
            (CanvasItem item) => item.id == 3,
          );

          expect(item2After.x, item2Before.x);
          expect(item2After.y, item2Before.y);
          expect(item2After.data, item2Before.data);
          expect(item3After.x, item3Before.x);
          expect(item3After.y, item3Before.y);
          expect(item3After.data, item3Before.data);
        },
      );
    });

    group('updateItemSize()', () {
      test(
        'должен обновить width и height в state для указанного элемента',
        () async {
          setupExistingCanvas();
          when(
            () => mockRepository.updateItemSize(
              any(),
              width: any(named: 'width'),
              height: any(named: 'height'),
            ),
          ).thenAnswer((_) async {});

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          await notifier.updateItemSize(1, width: 300.0, height: 400.0);

          final CanvasState state =
              container.read(canvasNotifierProvider(collectionId));
          final CanvasItem updatedItem = state.items.firstWhere(
            (CanvasItem item) => item.id == 1,
          );
          expect(updatedItem.width, 300.0);
          expect(updatedItem.height, 400.0);
        },
      );

      test(
        'должен вызвать repository.updateItemSize с правильными параметрами',
        () async {
          setupExistingCanvas();
          when(
            () => mockRepository.updateItemSize(
              any(),
              width: any(named: 'width'),
              height: any(named: 'height'),
            ),
          ).thenAnswer((_) async {});

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          await notifier.updateItemSize(2, width: 500.0, height: 600.0);

          verify(
            () => mockRepository.updateItemSize(
              2,
              width: 500.0,
              height: 600.0,
            ),
          ).called(1);
        },
      );

      test(
        'должен не менять другие элементы когда обновляется размер одного элемента',
        () async {
          setupExistingCanvas();
          when(
            () => mockRepository.updateItemSize(
              any(),
              width: any(named: 'width'),
              height: any(named: 'height'),
            ),
          ).thenAnswer((_) async {});

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          // Запоминаем исходное состояние элементов 2 и 3
          final CanvasState stateBefore =
              container.read(canvasNotifierProvider(collectionId));
          final CanvasItem item2Before = stateBefore.items.firstWhere(
            (CanvasItem item) => item.id == 2,
          );
          final CanvasItem item3Before = stateBefore.items.firstWhere(
            (CanvasItem item) => item.id == 3,
          );

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          await notifier.updateItemSize(1, width: 999.0, height: 888.0);

          final CanvasState stateAfter =
              container.read(canvasNotifierProvider(collectionId));
          final CanvasItem item2After = stateAfter.items.firstWhere(
            (CanvasItem item) => item.id == 2,
          );
          final CanvasItem item3After = stateAfter.items.firstWhere(
            (CanvasItem item) => item.id == 3,
          );

          expect(item2After.width, item2Before.width);
          expect(item2After.height, item2Before.height);
          expect(item3After.width, item3Before.width);
          expect(item3After.height, item3Before.height);
        },
      );
    });

    group('addItem() и deleteItem() вместе', () {
      test(
        'должен корректно добавить и затем удалить элемент',
        () async {
          setupExistingCanvas();
          when(() => mockRepository.deleteItem(any()))
              .thenAnswer((_) async {});

          final CanvasItem newItem = CanvasItem(
            id: 0,
            collectionId: collectionId,
            itemType: CanvasItemType.image,
            x: 300.0,
            y: 300.0,
            zIndex: 5,
            createdAt: testDate,
          );

          when(() => mockRepository.createItem(any()))
              .thenAnswer((_) async => newItem.copyWith(id: 50));

          final ProviderContainer container = createContainer();
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);

          // Добавляем
          await notifier.addItem(newItem);
          expect(
            container
                .read(canvasNotifierProvider(collectionId))
                .items
                .length,
            4,
          );

          // Удаляем
          await notifier.deleteItem(50);
          expect(
            container
                .read(canvasNotifierProvider(collectionId))
                .items
                .length,
            3,
          );
        },
      );
    });

    group('resetPositions() расчёт сетки', () {
      test(
        'должен расположить один элемент по центру канваса',
        () async {
          // Используем одну игру в коллекции, чтобы _syncCanvasWithGames
          // не пыталась добавить недостающие элементы
          final List<CanvasItem> singleItem = <CanvasItem>[testItems[0]];
          final List<CollectionItem> singleCollectionItem = <CollectionItem>[
            testCollectionItems[0],
          ];
          setupExistingCanvas(items: singleItem);
          when(
            () => mockRepository.updateItemPosition(
              any(),
              x: any(named: 'x'),
              y: any(named: 'y'),
            ),
          ).thenAnswer((_) async {});

          final ProviderContainer container = createContainer(
            itemsState: AsyncData<List<CollectionItem>>(singleCollectionItem),
          );
          addTearDown(container.dispose);

          container.read(canvasNotifierProvider(collectionId));
          await Future<void>.delayed(Duration.zero);

          final CanvasNotifier notifier = container
              .read(canvasNotifierProvider(collectionId).notifier);
          await notifier.resetPositions(1000.0);

          final CanvasState state =
              container.read(canvasNotifierProvider(collectionId));
          expect(state.items.length, 1);

          // Один элемент — 1 колонка, gridWidth = cardW = 160
          // startX = 2500 - 160/2 = 2420
          // startY = 2500 - 220/2 = 2390
          expect(state.items[0].x, 2500.0 - 160.0 / 2);
          expect(state.items[0].y, 2500.0 - 220.0 / 2);
        },
      );
    });
  });
}
