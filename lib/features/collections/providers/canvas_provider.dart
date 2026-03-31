import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../data/repositories/canvas_repository.dart';
import '../../../data/repositories/collection_repository.dart';
import '../../../shared/models/canvas_connection.dart';
import '../../../shared/models/canvas_item.dart';
import '../../../shared/models/canvas_viewport.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/media_type.dart';
import 'canvas_operations_mixin.dart';
import 'canvas_state.dart';
import 'canvas_timer_mixin.dart';
import 'collections_provider.dart';

export 'canvas_operations_mixin.dart';
export 'canvas_state.dart';
export 'canvas_timer_mixin.dart';
export 'game_canvas_provider.dart';

/// Провайдер для управления канвасом конкретной коллекции.
final NotifierProviderFamily<CanvasNotifier, CanvasState, int?>
    canvasNotifierProvider =
    NotifierProvider.family<CanvasNotifier, CanvasState, int?>(
  CanvasNotifier.new,
);

/// Notifier для управления состоянием канваса коллекции.
///
/// Реактивно синхронизируется с элементами коллекции:
/// при добавлении/удалении элементов автоматически создаёт/удаляет
/// соответствующие элементы на канвасе.
class CanvasNotifier extends FamilyNotifier<CanvasState, int?>
    with CanvasTimerMixin, CanvasOperationsMixin
    implements BaseCanvasController {
  static final Logger _log = Logger('CanvasNotifier');

  late CanvasRepository _repository;
  late int? _collectionId;
  bool _isSyncing = false;

  // CanvasTimerMixin
  @override
  CanvasRepository get timerRepository => _repository;

  @override
  int get viewportId => _collectionId!;

  @override
  void persistViewport(CanvasViewport viewport) {
    _repository.saveViewport(viewport);
  }

  // CanvasOperationsMixin
  @override
  CanvasRepository get operationsRepository => _repository;

  @override
  int get collectionId => _collectionId!;

  @override
  int? get itemCollectionItemId => null;

  @override
  CanvasState build(int? arg) {
    _collectionId = arg;
    _repository = ref.watch(canvasRepositoryProvider);

    // Canvas не поддерживается для uncategorized элементов
    if (_collectionId == null) {
      return const CanvasState(isLoading: false, isInitialized: true);
    }

    ref.onDispose(cancelTimers);

    // Реактивная синхронизация: при изменении элементов коллекции
    // автоматически добавляем/удаляем элементы канваса
    ref.listen<AsyncValue<List<CollectionItem>>>(
      collectionItemsNotifierProvider(_collectionId),
      (AsyncValue<List<CollectionItem>>? previous,
          AsyncValue<List<CollectionItem>> next) {
        if (state.isInitialized && !state.isLoading && next.hasValue) {
          _syncAndReload();
        }
      },
    );

    // Запускаем загрузку после инициализации state
    Future<void>.microtask(_loadCanvas);

    return const CanvasState();
  }

  Future<void> _loadCanvas() async {
    if (_collectionId == null) return;
    final int cId = _collectionId!;
    try {
      final bool hasItems = await _repository.hasCanvasItems(cId);

      if (!hasItems) {
        // Первый запуск — инициализируем канвас из элементов коллекции
        await _initializeFromItems();
      } else {
        // Синхронизация: удаляем сиротские элементы канваса
        await _syncCanvasWithItems();

        // Загружаем элементы, viewport и связи параллельно
        final (
          List<CanvasItem> items,
          CanvasViewport? viewport,
          List<CanvasConnection> connections,
        ) = await (
          _repository.getItemsWithData(cId),
          _repository.getViewport(cId),
          _repository.getConnections(cId),
        ).wait;

        state = state.copyWith(
          items: items,
          connections: connections,
          viewport: viewport ?? CanvasViewport(collectionId: cId),
          isLoading: false,
          isInitialized: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _initializeFromItems() async {
    if (_collectionId == null) return;
    final int cId = _collectionId!;
    try {
      // Пробуем получить из провайдера, иначе загружаем из БД напрямую
      final AsyncValue<List<CollectionItem>> itemsAsync =
          ref.read(collectionItemsNotifierProvider(cId));
      final List<CollectionItem> allItems = itemsAsync.valueOrNull ??
          await ref.read(collectionRepositoryProvider).getItemsWithData(cId);

      final List<CanvasItem> items =
          await _repository.initializeCanvas(cId, allItems);

      state = state.copyWith(
        items: items,
        viewport: CanvasViewport(collectionId: cId),
        isLoading: false,
        isInitialized: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Синхронизирует канвас с элементами коллекции и перезагружает.
  ///
  /// Вызывается реактивно при изменении элементов коллекции.
  /// Защита от конкурентных вызовов через [_isSyncing].
  Future<void> _syncAndReload() async {
    if (_collectionId == null || _isSyncing) return;
    _isSyncing = true;
    final int cId = _collectionId!;
    try {
      await _syncCanvasWithItems();
    } catch (e) {
      _log.warning('Canvas sync failed, proceeding to reload', e);
    }
    try {
      // Перезагружаем элементы канваса даже если sync упал
      final List<CanvasItem> items =
          await _repository.getItemsWithData(cId);
      state = state.copyWith(items: items);
    } catch (e) {
      _log.warning('Canvas reload failed, keeping current state', e);
    } finally {
      _isSyncing = false;
    }
  }

  /// Синхронизирует элементы канваса с текущими элементами коллекции.
  ///
  /// Двусторонняя синхронизация:
  /// - Удаляет элементы канваса для удалённых из коллекции
  /// - Создаёт элементы канваса для новых элементов в коллекции
  ///
  /// Матчинг выполняется по паре (itemType, itemRefId), т.к. элементы
  /// канваса коллекции имеют `collection_item_id = NULL` (в отличие от
  /// game canvas, где `collection_item_id` указывает на конкретный элемент).
  Future<void> _syncCanvasWithItems() async {
    if (_collectionId == null) return;
    final int cId = _collectionId!;
    // Получаем элементы из провайдера или напрямую из БД
    final AsyncValue<List<CollectionItem>> itemsAsync =
        ref.read(collectionItemsNotifierProvider(cId));
    final List<CollectionItem> allItems = itemsAsync.valueOrNull ??
        await ref.read(collectionRepositoryProvider).getItemsWithData(cId);

    final List<CanvasItem> canvasItems =
        await _repository.getItems(cId);

    // Считаем сколько копий каждого (type, refId) в коллекции и на canvas.
    // Если на canvas больше копий чем в коллекции — лишние удаляем.
    final Map<(String, int), int> collMediaCounts =
        <(String, int), int>{};
    for (final CollectionItem ci in allItems) {
      final (String, int) key =
          (CanvasItemType.fromMediaType(ci.mediaType).value, ci.externalId);
      collMediaCounts[key] = (collMediaCounts[key] ?? 0) + 1;
    }

    // Для каждого ключа оставляем не больше элементов чем в коллекции.
    final Map<(String, int), int> seenCounts = <(String, int), int>{};
    final List<int> orphanIds = <int>[];
    for (final CanvasItem item in canvasItems) {
      if (item.itemType.isMediaItem && item.itemRefId != null) {
        final (String, int) key = (item.itemType.value, item.itemRefId!);
        final int allowed = collMediaCounts[key] ?? 0;
        final int seen = seenCounts[key] ?? 0;
        if (seen >= allowed) {
          orphanIds.add(item.id);
        } else {
          seenCounts[key] = seen + 1;
        }
      }
    }
    if (orphanIds.isNotEmpty) {
      await _repository.deleteItemsBatch(orphanIds);
    }

    // seenCounts содержит количество canvas-элементов, оставшихся после
    // удаления orphans. Находим элементы коллекции, для которых на canvas
    // меньше копий чем нужно.
    final List<CollectionItem> missingItems = <CollectionItem>[];
    final Map<(String, int), int> addedCounts = <(String, int), int>{};
    for (final CollectionItem i in allItems) {
      final String typeValue =
          CanvasItemType.fromMediaType(i.mediaType).value;
      final (String, int) key = (typeValue, i.externalId);
      final int onCanvas = seenCounts[key] ?? 0;
      final int alreadyAdded = addedCounts[key] ?? 0;
      if (onCanvas + alreadyAdded < collMediaCounts[key]!) {
        missingItems.add(i);
        addedCounts[key] = alreadyAdded + 1;
      }
    }

    if (missingItems.isEmpty) return;

    // Позиция для новых элементов: ниже существующих
    double maxY = CanvasRepository.initialCenterY;
    for (final CanvasItem item in canvasItems) {
      final double bottom =
          item.y + (item.height ?? CanvasRepository.defaultCardHeight);
      if (bottom > maxY) maxY = bottom;
    }

    final double startY = canvasItems.isEmpty
        ? CanvasRepository.initialCenterY -
            CanvasRepository.defaultCardHeight / 2
        : maxY + CanvasRepository.gridGap;

    final int cols = missingItems.length < CanvasRepository.gridColumns
        ? missingItems.length
        : CanvasRepository.gridColumns;
    final double gridWidth =
        cols * (CanvasRepository.defaultCardWidth + CanvasRepository.gridGap) -
            CanvasRepository.gridGap;
    final double startX = CanvasRepository.initialCenterX - gridWidth / 2;

    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final int baseZIndex = canvasItems.isEmpty
        ? 0
        : canvasItems
                .map((CanvasItem item) => item.zIndex)
                .reduce((int a, int b) => a > b ? a : b) +
            1;

    // НЕ устанавливаем collectionItemId — элементы канваса коллекции
    // хранятся с collection_item_id = NULL (getCanvasItems фильтрует по этому)
    final List<CanvasItem> newItems = <CanvasItem>[
      for (int i = 0; i < missingItems.length; i++)
        CanvasItem(
          id: 0,
          collectionId: cId,
          itemType: CanvasItemType.fromMediaType(missingItems[i].mediaType),
          itemRefId: missingItems[i].externalId,
          x: startX +
              (i % cols) *
                  (CanvasRepository.defaultCardWidth +
                      CanvasRepository.gridGap),
          y: startY +
              (i ~/ cols) *
                  (CanvasRepository.defaultCardHeight +
                      CanvasRepository.gridGap),
          width: CanvasRepository.defaultCardWidth,
          height: CanvasRepository.defaultCardHeight,
          zIndex: baseZIndex + i,
          createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
        ),
    ];
    await _repository.createItemsBatch(newItems);
  }

  /// Удаляет медиа-элемент с канваса по ID элемента коллекции.
  ///
  /// Обновляет state мгновенно и удаляет из БД.
  void removeByCollectionItemId(int collectionItemId) {
    if (_collectionId == null) return;
    final int cId = _collectionId!;
    state = state.copyWith(
      items: state.items
          .where((CanvasItem item) =>
              item.collectionItemId != collectionItemId)
          .toList(),
    );
    _repository.deleteByCollectionItemId(cId, collectionItemId);
  }

  /// Удаляет медиа-элемент с канваса по типу и ID.
  ///
  /// Обновляет state мгновенно и удаляет из БД.
  void removeMediaItem(MediaType mediaType, int externalId) {
    if (_collectionId == null) return;
    final int cId = _collectionId!;
    final CanvasItemType canvasType =
        CanvasItemType.fromMediaType(mediaType);
    state = state.copyWith(
      items: state.items
          .where((CanvasItem item) =>
              !(item.itemType == canvasType &&
                  item.itemRefId == externalId))
          .toList(),
    );
    _repository.deleteMediaItem(cId, canvasType, externalId);
  }

  /// Удаляет элемент игры с канваса по igdbId.
  ///
  /// Обновляет state мгновенно и удаляет из БД.
  void removeGameItem(int igdbId) {
    removeMediaItem(MediaType.game, igdbId);
  }

  /// Обновляет канвас (перезагрузка из БД).
  @override
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    await _loadCanvas();
  }
}
