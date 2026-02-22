import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/canvas_repository.dart';
import '../../../data/repositories/collection_repository.dart';
import '../../../shared/models/canvas_connection.dart';
import '../../../shared/models/canvas_item.dart';
import '../../../shared/models/canvas_viewport.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/media_type.dart';
import 'collections_provider.dart';

/// Состояние канваса для коллекции.
class CanvasState {
  /// Создаёт экземпляр [CanvasState].
  const CanvasState({
    this.items = const <CanvasItem>[],
    this.connections = const <CanvasConnection>[],
    this.viewport = CanvasViewport.defaultValue,
    this.isLoading = true,
    this.isInitialized = false,
    this.connectingFromId,
    this.error,
  });

  /// Элементы на канвасе.
  final List<CanvasItem> items;

  /// Связи между элементами.
  final List<CanvasConnection> connections;

  /// Состояние viewport (зум, позиция камеры).
  final CanvasViewport viewport;

  /// Загружается ли канвас.
  final bool isLoading;

  /// Инициализирован ли канвас (данные загружены).
  final bool isInitialized;

  /// ID элемента, от которого создаётся связь (null = не в режиме создания).
  final int? connectingFromId;

  /// Ошибка при загрузке.
  final String? error;

  /// Создаёт копию с изменёнными полями.
  CanvasState copyWith({
    List<CanvasItem>? items,
    List<CanvasConnection>? connections,
    CanvasViewport? viewport,
    bool? isLoading,
    bool? isInitialized,
    int? connectingFromId,
    bool clearConnectingFromId = false,
    String? error,
  }) {
    return CanvasState(
      items: items ?? this.items,
      connections: connections ?? this.connections,
      viewport: viewport ?? this.viewport,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      connectingFromId: clearConnectingFromId
          ? null
          : (connectingFromId ?? this.connectingFromId),
      error: error,
    );
  }
}

/// Общий интерфейс для управления канвасом.
///
/// Реализуется [CanvasNotifier] (коллекционный canvas)
/// и [GameCanvasNotifier] (per-game canvas).
abstract class BaseCanvasController {
  /// Перемещает элемент.
  void moveItem(int itemId, double x, double y);

  /// Обновляет viewport.
  void updateViewport(double scale, double offsetX, double offsetY);

  /// Сбрасывает viewport.
  void resetViewport();

  /// Сбрасывает позиции в сетку.
  Future<void> resetPositions(double viewportWidth);

  /// Добавляет элемент.
  Future<CanvasItem> addItem(CanvasItem item);

  /// Удаляет элемент.
  Future<void> deleteItem(int itemId);

  /// Добавляет текстовый блок.
  Future<CanvasItem> addTextItem(
    double x,
    double y,
    String content,
    double fontSize,
  );

  /// Добавляет изображение.
  Future<CanvasItem> addImageItem(
    double x,
    double y,
    Map<String, dynamic> imageData, {
    double width,
    double height,
  });

  /// Добавляет ссылку.
  Future<CanvasItem> addLinkItem(
    double x,
    double y,
    String url,
    String label,
  );

  /// Обновляет данные элемента.
  Future<void> updateItemData(int itemId, Map<String, dynamic> data);

  /// Обновляет размеры элемента.
  Future<void> updateItemSize(
    int itemId, {
    required double width,
    required double height,
  });

  /// Перемещает на передний план.
  Future<void> bringToFront(int itemId);

  /// Перемещает на задний план.
  Future<void> sendToBack(int itemId);

  /// Начинает создание связи.
  void startConnection(int fromItemId);

  /// Завершает создание связи.
  Future<void> completeConnection(int toItemId);

  /// Отменяет режим создания связи.
  void cancelConnection();

  /// Удаляет связь.
  Future<void> deleteConnection(int connectionId);

  /// Обновляет связь.
  Future<void> updateConnection(
    int connectionId, {
    String? label,
    String? color,
    ConnectionStyle? style,
  });

  /// Перезагрузка canvas.
  Future<void> refresh();
}

/// Провайдер для управления канвасом конкретной коллекции.
final NotifierProviderFamily<CanvasNotifier, CanvasState, int?>
    canvasNotifierProvider =
    NotifierProvider.family<CanvasNotifier, CanvasState, int?>(
  CanvasNotifier.new,
);

/// Notifier для управления состоянием канваса.
class CanvasNotifier extends FamilyNotifier<CanvasState, int?>
    implements BaseCanvasController {
  late CanvasRepository _repository;
  late int? _collectionId;
  Timer? _viewportSaveTimer;
  Timer? _positionSaveTimer;
  bool _isSyncing = false;

  @override
  CanvasState build(int? arg) {
    _collectionId = arg;
    _repository = ref.watch(canvasRepositoryProvider);

    // Canvas не поддерживается для uncategorized элементов
    if (_collectionId == null) {
      return const CanvasState(isLoading: false, isInitialized: true);
    }

    ref.onDispose(() {
      _viewportSaveTimer?.cancel();
      _positionSaveTimer?.cancel();
    });

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
    final int collectionId = _collectionId!;
    try {
      final bool hasItems = await _repository.hasCanvasItems(collectionId);

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
          _repository.getItemsWithData(collectionId),
          _repository.getViewport(collectionId),
          _repository.getConnections(collectionId),
        ).wait;

        state = state.copyWith(
          items: items,
          connections: connections,
          viewport: viewport ??
              CanvasViewport(collectionId: collectionId),
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
    final int collectionId = _collectionId!;
    try {
      // Пробуем получить из провайдера, иначе загружаем из БД напрямую
      final AsyncValue<List<CollectionItem>> itemsAsync =
          ref.read(collectionItemsNotifierProvider(collectionId));
      final List<CollectionItem> allItems = itemsAsync.valueOrNull ??
          await ref.read(collectionRepositoryProvider).getItemsWithData(
                collectionId,
              );

      final List<CanvasItem> items =
          await _repository.initializeCanvas(collectionId, allItems);

      state = state.copyWith(
        items: items,
        viewport: CanvasViewport(collectionId: collectionId),
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
    final int collectionId = _collectionId!;
    try {
      await _syncCanvasWithItems();
    } catch (_) {
      // Sync может упасть, но reload всё равно нужен
    }
    try {
      // Перезагружаем элементы канваса даже если sync упал
      final List<CanvasItem> items =
          await _repository.getItemsWithData(collectionId);
      state = state.copyWith(items: items);
    } catch (_) {
      // Ошибка перезагрузки — оставляем текущий state
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
    final int collectionId = _collectionId!;
    // Получаем элементы из провайдера или напрямую из БД
    final AsyncValue<List<CollectionItem>> itemsAsync =
        ref.read(collectionItemsNotifierProvider(collectionId));
    final List<CollectionItem> allItems = itemsAsync.valueOrNull ??
        await ref.read(collectionRepositoryProvider).getItemsWithData(
              collectionId,
            );

    final List<CanvasItem> canvasItems =
        await _repository.getItems(collectionId);

    // Строим множество ключей (type, refId) для элементов коллекции
    final Set<(String, int)> collectionMediaKeys = <(String, int)>{
      for (final CollectionItem ci in allItems)
        (CanvasItemType.fromMediaType(ci.mediaType).value, ci.externalId),
    };

    // Удаляем сиротские медиа-элементы (удалены из коллекции)
    for (final CanvasItem item in canvasItems) {
      if (item.itemType.isMediaItem && item.itemRefId != null) {
        final (String, int) key = (item.itemType.value, item.itemRefId!);
        if (!collectionMediaKeys.contains(key)) {
          await _repository.deleteItem(item.id);
        }
      }
    }

    // Строим множество ключей (type, refId) для существующих canvas-элементов
    final Set<(String, int)> canvasMediaKeys = <(String, int)>{
      for (final CanvasItem item in canvasItems)
        if (item.itemType.isMediaItem && item.itemRefId != null)
          (item.itemType.value, item.itemRefId!),
    };

    // Находим недостающие элементы
    final List<CollectionItem> missingItems = allItems
        .where((CollectionItem i) {
      final String typeValue =
          CanvasItemType.fromMediaType(i.mediaType).value;
      return !canvasMediaKeys.contains((typeValue, i.externalId));
    }).toList();

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

    for (int i = 0; i < missingItems.length; i++) {
      final int col = i % cols;
      final int row = i ~/ cols;
      final double x = startX +
          col * (CanvasRepository.defaultCardWidth + CanvasRepository.gridGap);
      final double y = startY +
          row *
              (CanvasRepository.defaultCardHeight + CanvasRepository.gridGap);

      final CanvasItemType canvasType =
          CanvasItemType.fromMediaType(missingItems[i].mediaType);

      // НЕ устанавливаем collectionItemId — элементы канваса коллекции
      // хранятся с collection_item_id = NULL (getCanvasItems фильтрует по этому)
      final CanvasItem item = CanvasItem(
        id: 0,
        collectionId: collectionId,
        itemType: canvasType,
        itemRefId: missingItems[i].externalId,
        x: x,
        y: y,
        width: CanvasRepository.defaultCardWidth,
        height: CanvasRepository.defaultCardHeight,
        zIndex: baseZIndex + i,
        createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
      );

      await _repository.createItem(item);
    }
  }

  /// Удаляет медиа-элемент с канваса по ID элемента коллекции.
  ///
  /// Обновляет state мгновенно и удаляет из БД.
  void removeByCollectionItemId(int collectionItemId) {
    if (_collectionId == null) return;
    final int collectionId = _collectionId!;
    state = state.copyWith(
      items: state.items
          .where((CanvasItem item) =>
              item.collectionItemId != collectionItemId)
          .toList(),
    );
    _repository.deleteByCollectionItemId(collectionId, collectionItemId);
  }

  /// Удаляет медиа-элемент с канваса по типу и ID.
  ///
  /// Обновляет state мгновенно и удаляет из БД.
  void removeMediaItem(MediaType mediaType, int externalId) {
    if (_collectionId == null) return;
    final int collectionId = _collectionId!;
    final CanvasItemType canvasType =
        CanvasItemType.fromMediaType(mediaType);
    state = state.copyWith(
      items: state.items
          .where((CanvasItem item) =>
              !(item.itemType == canvasType &&
                  item.itemRefId == externalId))
          .toList(),
    );
    _repository.deleteMediaItem(collectionId, canvasType, externalId);
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

  /// Перемещает элемент на канвасе.
  ///
  /// Обновляет state мгновенно, сохраняет в БД с debounce.
  @override
  void moveItem(int itemId, double x, double y) {
    // Локальное обновление
    state = state.copyWith(
      items: state.items.map((CanvasItem item) {
        if (item.id == itemId) {
          return item.copyWith(x: x, y: y);
        }
        return item;
      }).toList(),
    );

    // Debounced сохранение в БД
    _positionSaveTimer?.cancel();
    _positionSaveTimer = Timer(const Duration(milliseconds: 300), () {
      _repository.updateItemPosition(itemId, x: x, y: y);
    });
  }

  /// Обновляет viewport (зум и позицию камеры).
  ///
  /// Сохраняет в БД с debounce.
  @override
  void updateViewport(double scale, double offsetX, double offsetY) {
    final CanvasViewport newViewport = CanvasViewport(
      collectionId: _collectionId!,
      scale: scale,
      offsetX: offsetX,
      offsetY: offsetY,
    );

    state = state.copyWith(viewport: newViewport);

    // Debounced сохранение
    _viewportSaveTimer?.cancel();
    _viewportSaveTimer = Timer(const Duration(milliseconds: 500), () {
      _repository.saveViewport(newViewport);
    });
  }

  /// Сбрасывает viewport в значение по умолчанию (scale=1, offset=0,0).
  @override
  void resetViewport() {
    final CanvasViewport defaultViewport = CanvasViewport(
      collectionId: _collectionId!,
    );

    state = state.copyWith(viewport: defaultViewport);

    _viewportSaveTimer?.cancel();
    _repository.saveViewport(defaultViewport);
  }

  /// Сбрасывает позиции всех элементов в сетку по центру канваса.
  ///
  /// [viewportWidth] — ширина видимой области для расчёта колонок.
  /// Элементы центрируются вокруг [CanvasRepository.initialCenterX],
  /// [CanvasRepository.initialCenterY].
  @override
  Future<void> resetPositions(double viewportWidth) async {
    final List<CanvasItem> items = state.items;
    if (items.isEmpty) return;

    const double cardW = CanvasRepository.defaultCardWidth;
    const double cardH = CanvasRepository.defaultCardHeight;
    const double gap = CanvasRepository.gridGap;

    // Рассчитываем количество колонок по ширине видимой области
    final int columns =
        ((viewportWidth + gap) / (cardW + gap)).floor().clamp(1, items.length);
    final int rowCount = (items.length + columns - 1) ~/ columns;

    // Центрируем сетку вокруг центра канваса
    final double gridWidth = columns * (cardW + gap) - gap;
    final double gridHeight = rowCount * (cardH + gap) - gap;
    final double startX =
        CanvasRepository.initialCenterX - gridWidth / 2;
    final double startY =
        CanvasRepository.initialCenterY - gridHeight / 2;

    final List<CanvasItem> updated = <CanvasItem>[];
    for (int i = 0; i < items.length; i++) {
      final int col = i % columns;
      final int row = i ~/ columns;
      final double x = startX + col * (cardW + gap);
      final double y = startY + row * (cardH + gap);

      final CanvasItem item = items[i].copyWith(x: x, y: y, zIndex: 0);
      updated.add(item);
      _repository.updateItemPosition(item.id, x: x, y: y);
    }

    state = state.copyWith(items: updated);
  }

  /// Добавляет элемент на канвас.
  @override
  Future<CanvasItem> addItem(CanvasItem item) async {
    final CanvasItem created = await _repository.createItem(item);
    state = state.copyWith(
      items: <CanvasItem>[...state.items, created],
    );
    return created;
  }

  /// Удаляет элемент с канваса.
  ///
  /// Связи удаляются каскадно в БД (FK CASCADE).
  /// В state фильтруем connections с участием удалённого элемента.
  @override
  Future<void> deleteItem(int itemId) async {
    await _repository.deleteItem(itemId);
    state = state.copyWith(
      items: state.items
          .where((CanvasItem item) => item.id != itemId)
          .toList(),
      connections: state.connections
          .where((CanvasConnection conn) =>
              conn.fromItemId != itemId && conn.toItemId != itemId)
          .toList(),
    );
  }

  /// Добавляет текстовый блок на канвас.
  @override
  Future<CanvasItem> addTextItem(
    double x,
    double y,
    String content,
    double fontSize,
  ) async {
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final int maxZ = state.items.isEmpty
        ? 0
        : state.items
              .map((CanvasItem item) => item.zIndex)
              .reduce((int a, int b) => a > b ? a : b) +
          1;

    final CanvasItem item = CanvasItem(
      id: 0,
      collectionId: _collectionId!,
      itemType: CanvasItemType.text,
      x: x,
      y: y,
      width: 200,
      height: null,
      zIndex: maxZ,
      data: <String, dynamic>{
        'content': content,
        'fontSize': fontSize,
      },
      createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
    );

    return addItem(item);
  }

  /// Добавляет изображение на канвас.
  ///
  /// [width] и [height] задают размер элемента на канвасе.
  /// Если не указаны, используется 200x200.
  @override
  Future<CanvasItem> addImageItem(
    double x,
    double y,
    Map<String, dynamic> imageData, {
    double width = 200,
    double height = 200,
  }) async {
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final int maxZ = state.items.isEmpty
        ? 0
        : state.items
              .map((CanvasItem item) => item.zIndex)
              .reduce((int a, int b) => a > b ? a : b) +
          1;

    final CanvasItem item = CanvasItem(
      id: 0,
      collectionId: _collectionId!,
      itemType: CanvasItemType.image,
      x: x,
      y: y,
      width: width,
      height: height,
      zIndex: maxZ,
      data: imageData,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
    );

    return addItem(item);
  }

  /// Добавляет ссылку на канвас.
  @override
  Future<CanvasItem> addLinkItem(
    double x,
    double y,
    String url,
    String label,
  ) async {
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final int maxZ = state.items.isEmpty
        ? 0
        : state.items
              .map((CanvasItem item) => item.zIndex)
              .reduce((int a, int b) => a > b ? a : b) +
          1;

    final CanvasItem item = CanvasItem(
      id: 0,
      collectionId: _collectionId!,
      itemType: CanvasItemType.link,
      x: x,
      y: y,
      width: 200,
      height: 48,
      zIndex: maxZ,
      data: <String, dynamic>{
        'url': url,
        'label': label,
      },
      createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
    );

    return addItem(item);
  }

  /// Обновляет дополнительные данные элемента.
  @override
  Future<void> updateItemData(
    int itemId,
    Map<String, dynamic> data,
  ) async {
    await _repository.updateItemData(itemId, data);
    state = state.copyWith(
      items: state.items.map((CanvasItem item) {
        if (item.id == itemId) {
          return item.copyWith(data: data);
        }
        return item;
      }).toList(),
    );
  }

  /// Обновляет размеры элемента.
  ///
  /// Обновляет state мгновенно, сохраняет в БД.
  @override
  Future<void> updateItemSize(
    int itemId, {
    required double width,
    required double height,
  }) async {
    state = state.copyWith(
      items: state.items.map((CanvasItem item) {
        if (item.id == itemId) {
          return item.copyWith(width: width, height: height);
        }
        return item;
      }).toList(),
    );
    await _repository.updateItemSize(itemId, width: width, height: height);
  }

  /// Перемещает элемент на передний план (максимальный z-index).
  @override
  Future<void> bringToFront(int itemId) async {
    if (state.items.isEmpty) return;

    final int maxZ = state.items
        .map((CanvasItem item) => item.zIndex)
        .reduce((int a, int b) => a > b ? a : b);
    final int newZ = maxZ + 1;

    await _repository.updateItemZIndex(itemId, newZ);
    state = state.copyWith(
      items: state.items.map((CanvasItem item) {
        if (item.id == itemId) {
          return item.copyWith(zIndex: newZ);
        }
        return item;
      }).toList(),
    );
  }

  /// Перемещает элемент на задний план (минимальный z-index).
  @override
  Future<void> sendToBack(int itemId) async {
    if (state.items.isEmpty) return;

    final int minZ = state.items
        .map((CanvasItem item) => item.zIndex)
        .reduce((int a, int b) => a < b ? a : b);
    final int newZ = minZ - 1;

    await _repository.updateItemZIndex(itemId, newZ);
    state = state.copyWith(
      items: state.items.map((CanvasItem item) {
        if (item.id == itemId) {
          return item.copyWith(zIndex: newZ);
        }
        return item;
      }).toList(),
    );
  }

  // ==================== Connections ====================

  /// Начинает создание связи от указанного элемента.
  ///
  /// Устанавливает режим создания связи. При следующем клике
  /// на элемент вызывается [completeConnection].
  @override
  void startConnection(int fromItemId) {
    state = state.copyWith(connectingFromId: fromItemId);
  }

  /// Завершает создание связи к указанному элементу.
  ///
  /// Создаёт новую связь между [connectingFromId] и [toItemId],
  /// сохраняет в БД и обновляет state.
  @override
  Future<void> completeConnection(int toItemId) async {
    final int? fromItemId = state.connectingFromId;
    if (fromItemId == null || fromItemId == toItemId) {
      cancelConnection();
      return;
    }

    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final CanvasConnection conn = CanvasConnection(
      id: 0,
      collectionId: _collectionId!,
      fromItemId: fromItemId,
      toItemId: toItemId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
    );

    final CanvasConnection created = await _repository.createConnection(conn);
    state = state.copyWith(
      connections: <CanvasConnection>[...state.connections, created],
      clearConnectingFromId: true,
    );
  }

  /// Отменяет режим создания связи.
  @override
  void cancelConnection() {
    state = state.copyWith(clearConnectingFromId: true);
  }

  /// Удаляет связь.
  @override
  Future<void> deleteConnection(int connectionId) async {
    await _repository.deleteConnection(connectionId);
    state = state.copyWith(
      connections: state.connections
          .where((CanvasConnection conn) => conn.id != connectionId)
          .toList(),
    );
  }

  /// Обновляет свойства связи (label, color, style).
  @override
  Future<void> updateConnection(
    int connectionId, {
    String? label,
    String? color,
    ConnectionStyle? style,
  }) async {
    final int index = state.connections.indexWhere(
      (CanvasConnection conn) => conn.id == connectionId,
    );
    if (index == -1) return;

    final CanvasConnection updated = state.connections[index].copyWith(
      label: label,
      clearLabel: label == null,
      color: color,
      style: style,
    );

    await _repository.updateConnection(updated);

    final List<CanvasConnection> newConnections =
        List<CanvasConnection>.from(state.connections);
    newConnections[index] = updated;
    state = state.copyWith(connections: newConnections);
  }
}

// ==================== Game Canvas ====================

/// Провайдер для управления per-item canvas.
///
/// Ключ — `({collectionId, collectionItemId})`.
/// В отличие от [canvasNotifierProvider], per-item canvas:
/// - Не синхронизируется реактивно с элементами коллекции
/// - Автоинициализируется одним медиа-элементом (игра/фильм/сериал)
/// - Поддерживает game/movie/tvShow/text/image/link элементы
final NotifierProviderFamily<GameCanvasNotifier, CanvasState,
        ({int? collectionId, int collectionItemId})>
    gameCanvasNotifierProvider = NotifierProvider.family<GameCanvasNotifier,
        CanvasState, ({int? collectionId, int collectionItemId})>(
  GameCanvasNotifier.new,
);

/// Notifier для управления per-item canvas.
///
/// Упрощённая версия [CanvasNotifier] без реактивной синхронизации
/// с элементами коллекции. Каждый элемент коллекции имеет свой canvas.
class GameCanvasNotifier
    extends FamilyNotifier<CanvasState, ({int? collectionId, int collectionItemId})>
    implements BaseCanvasController {
  late CanvasRepository _repository;
  late int? _collectionId;
  late int _collectionItemId;
  Timer? _viewportSaveTimer;
  Timer? _positionSaveTimer;

  @override
  CanvasState build(({int? collectionId, int collectionItemId}) arg) {
    _collectionId = arg.collectionId;
    _collectionItemId = arg.collectionItemId;
    _repository = ref.watch(canvasRepositoryProvider);

    ref.onDispose(() {
      _viewportSaveTimer?.cancel();
      _positionSaveTimer?.cancel();
    });

    // Загружаем canvas после инициализации state
    Future<void>.microtask(_loadCanvas);

    return const CanvasState();
  }

  Future<void> _loadCanvas() async {
    try {
      final bool hasItems =
          await _repository.hasGameCanvasItems(_collectionItemId);

      if (!hasItems) {
        await _initializeWithCollectionItem();
        return;
      }

      final (
        List<CanvasItem> items,
        CanvasViewport? viewport,
        List<CanvasConnection> connections,
      ) = await (
        _repository.getGameCanvasItemsWithData(_collectionItemId),
        _repository.getGameCanvasViewport(_collectionItemId),
        _repository.getGameCanvasConnections(_collectionItemId),
      ).wait;

      state = state.copyWith(
        items: items,
        connections: connections,
        viewport: viewport ??
            CanvasViewport(collectionId: _collectionItemId),
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

  /// Инициализирует per-item canvas с одним медиа-элементом.
  Future<void> _initializeWithCollectionItem() async {
    final AsyncValue<List<CollectionItem>> itemsAsync =
        ref.read(collectionItemsNotifierProvider(_collectionId));
    final List<CollectionItem> allItems =
        itemsAsync.valueOrNull ?? <CollectionItem>[];

    CollectionItem? collectionItem;
    for (final CollectionItem item in allItems) {
      if (item.id == _collectionItemId) {
        collectionItem = item;
        break;
      }
    }

    if (collectionItem == null) {
      state = state.copyWith(
        viewport: CanvasViewport(collectionId: _collectionItemId),
        isLoading: false,
        isInitialized: true,
      );
      return;
    }

    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final CanvasItemType canvasType =
        CanvasItemType.fromMediaType(collectionItem.mediaType);

    // Размещаем единственный элемент по центру canvas
    const double x = CanvasRepository.initialCenterX -
        CanvasRepository.defaultCardWidth / 2;
    const double y = CanvasRepository.initialCenterY -
        CanvasRepository.defaultCardHeight / 2;

    final CanvasItem item = CanvasItem(
      id: 0,
      collectionId: _collectionId!,
      collectionItemId: _collectionItemId,
      itemType: canvasType,
      itemRefId: collectionItem.externalId,
      x: x,
      y: y,
      width: CanvasRepository.defaultCardWidth,
      height: CanvasRepository.defaultCardHeight,
      zIndex: 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
    );

    final CanvasItem created = await _repository.createItem(item);
    final CanvasItem enriched = created.copyWith(
      game: collectionItem.game,
      movie: collectionItem.movie,
      tvShow: collectionItem.tvShow,
    );

    await _repository.saveGameCanvasViewport(
      _collectionItemId,
      CanvasViewport(collectionId: _collectionItemId),
    );

    state = state.copyWith(
      items: <CanvasItem>[enriched],
      viewport: CanvasViewport(collectionId: _collectionItemId),
      isLoading: false,
      isInitialized: true,
    );
  }

  /// Перезагрузка canvas из БД.
  @override
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    await _loadCanvas();
  }

  /// Перемещает элемент на канвасе.
  @override
  void moveItem(int itemId, double x, double y) {
    state = state.copyWith(
      items: state.items.map((CanvasItem item) {
        if (item.id == itemId) {
          return item.copyWith(x: x, y: y);
        }
        return item;
      }).toList(),
    );

    _positionSaveTimer?.cancel();
    _positionSaveTimer = Timer(const Duration(milliseconds: 300), () {
      _repository.updateItemPosition(itemId, x: x, y: y);
    });
  }

  /// Обновляет viewport (зум и позицию камеры).
  @override
  void updateViewport(double scale, double offsetX, double offsetY) {
    final CanvasViewport newViewport = CanvasViewport(
      collectionId: _collectionItemId,
      scale: scale,
      offsetX: offsetX,
      offsetY: offsetY,
    );

    state = state.copyWith(viewport: newViewport);

    _viewportSaveTimer?.cancel();
    _viewportSaveTimer = Timer(const Duration(milliseconds: 500), () {
      _repository.saveGameCanvasViewport(_collectionItemId, newViewport);
    });
  }

  /// Сбрасывает viewport в значение по умолчанию.
  @override
  void resetViewport() {
    final CanvasViewport defaultViewport = CanvasViewport(
      collectionId: _collectionItemId,
    );

    state = state.copyWith(viewport: defaultViewport);

    _viewportSaveTimer?.cancel();
    _repository.saveGameCanvasViewport(_collectionItemId, defaultViewport);
  }

  /// Сбрасывает позиции элементов в сетку.
  @override
  Future<void> resetPositions(double viewportWidth) async {
    final List<CanvasItem> items = state.items;
    if (items.isEmpty) return;

    const double cardW = CanvasRepository.defaultCardWidth;
    const double cardH = CanvasRepository.defaultCardHeight;
    const double gap = CanvasRepository.gridGap;

    final int columns =
        ((viewportWidth + gap) / (cardW + gap)).floor().clamp(1, items.length);
    final int rowCount = (items.length + columns - 1) ~/ columns;

    final double gridWidth = columns * (cardW + gap) - gap;
    final double gridHeight = rowCount * (cardH + gap) - gap;
    final double startX =
        CanvasRepository.initialCenterX - gridWidth / 2;
    final double startY =
        CanvasRepository.initialCenterY - gridHeight / 2;

    final List<CanvasItem> updated = <CanvasItem>[];
    for (int i = 0; i < items.length; i++) {
      final int col = i % columns;
      final int row = i ~/ columns;
      final double x = startX + col * (cardW + gap);
      final double y = startY + row * (cardH + gap);

      final CanvasItem item = items[i].copyWith(x: x, y: y, zIndex: 0);
      updated.add(item);
      _repository.updateItemPosition(item.id, x: x, y: y);
    }

    state = state.copyWith(items: updated);
  }

  /// Добавляет элемент на game canvas.
  @override
  Future<CanvasItem> addItem(CanvasItem item) async {
    final CanvasItem created = await _repository.createItem(item);
    state = state.copyWith(
      items: <CanvasItem>[...state.items, created],
    );
    return created;
  }

  /// Удаляет элемент с game canvas.
  @override
  Future<void> deleteItem(int itemId) async {
    await _repository.deleteItem(itemId);
    state = state.copyWith(
      items: state.items
          .where((CanvasItem item) => item.id != itemId)
          .toList(),
      connections: state.connections
          .where((CanvasConnection conn) =>
              conn.fromItemId != itemId && conn.toItemId != itemId)
          .toList(),
    );
  }

  /// Добавляет текстовый блок.
  @override
  Future<CanvasItem> addTextItem(
    double x,
    double y,
    String content,
    double fontSize,
  ) async {
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final int maxZ = state.items.isEmpty
        ? 0
        : state.items
              .map((CanvasItem item) => item.zIndex)
              .reduce((int a, int b) => a > b ? a : b) +
          1;

    final CanvasItem item = CanvasItem(
      id: 0,
      collectionId: _collectionId!,
      collectionItemId: _collectionItemId,
      itemType: CanvasItemType.text,
      x: x,
      y: y,
      width: 200,
      height: null,
      zIndex: maxZ,
      data: <String, dynamic>{
        'content': content,
        'fontSize': fontSize,
      },
      createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
    );

    return addItem(item);
  }

  /// Добавляет изображение.
  @override
  Future<CanvasItem> addImageItem(
    double x,
    double y,
    Map<String, dynamic> imageData, {
    double width = 200,
    double height = 200,
  }) async {
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final int maxZ = state.items.isEmpty
        ? 0
        : state.items
              .map((CanvasItem item) => item.zIndex)
              .reduce((int a, int b) => a > b ? a : b) +
          1;

    final CanvasItem item = CanvasItem(
      id: 0,
      collectionId: _collectionId!,
      collectionItemId: _collectionItemId,
      itemType: CanvasItemType.image,
      x: x,
      y: y,
      width: width,
      height: height,
      zIndex: maxZ,
      data: imageData,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
    );

    return addItem(item);
  }

  /// Добавляет ссылку.
  @override
  Future<CanvasItem> addLinkItem(
    double x,
    double y,
    String url,
    String label,
  ) async {
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final int maxZ = state.items.isEmpty
        ? 0
        : state.items
              .map((CanvasItem item) => item.zIndex)
              .reduce((int a, int b) => a > b ? a : b) +
          1;

    final CanvasItem item = CanvasItem(
      id: 0,
      collectionId: _collectionId!,
      collectionItemId: _collectionItemId,
      itemType: CanvasItemType.link,
      x: x,
      y: y,
      width: 200,
      height: 48,
      zIndex: maxZ,
      data: <String, dynamic>{
        'url': url,
        'label': label,
      },
      createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
    );

    return addItem(item);
  }

  /// Обновляет данные элемента.
  @override
  Future<void> updateItemData(
    int itemId,
    Map<String, dynamic> data,
  ) async {
    await _repository.updateItemData(itemId, data);
    state = state.copyWith(
      items: state.items.map((CanvasItem item) {
        if (item.id == itemId) {
          return item.copyWith(data: data);
        }
        return item;
      }).toList(),
    );
  }

  /// Обновляет размеры элемента.
  @override
  Future<void> updateItemSize(
    int itemId, {
    required double width,
    required double height,
  }) async {
    state = state.copyWith(
      items: state.items.map((CanvasItem item) {
        if (item.id == itemId) {
          return item.copyWith(width: width, height: height);
        }
        return item;
      }).toList(),
    );
    await _repository.updateItemSize(itemId, width: width, height: height);
  }

  /// Перемещает элемент на передний план.
  @override
  Future<void> bringToFront(int itemId) async {
    if (state.items.isEmpty) return;

    final int maxZ = state.items
        .map((CanvasItem item) => item.zIndex)
        .reduce((int a, int b) => a > b ? a : b);
    final int newZ = maxZ + 1;

    await _repository.updateItemZIndex(itemId, newZ);
    state = state.copyWith(
      items: state.items.map((CanvasItem item) {
        if (item.id == itemId) {
          return item.copyWith(zIndex: newZ);
        }
        return item;
      }).toList(),
    );
  }

  /// Перемещает элемент на задний план.
  @override
  Future<void> sendToBack(int itemId) async {
    if (state.items.isEmpty) return;

    final int minZ = state.items
        .map((CanvasItem item) => item.zIndex)
        .reduce((int a, int b) => a < b ? a : b);
    final int newZ = minZ - 1;

    await _repository.updateItemZIndex(itemId, newZ);
    state = state.copyWith(
      items: state.items.map((CanvasItem item) {
        if (item.id == itemId) {
          return item.copyWith(zIndex: newZ);
        }
        return item;
      }).toList(),
    );
  }

  // ==================== Connections ====================

  /// Начинает создание связи.
  @override
  void startConnection(int fromItemId) {
    state = state.copyWith(connectingFromId: fromItemId);
  }

  /// Завершает создание связи.
  @override
  Future<void> completeConnection(int toItemId) async {
    final int? fromItemId = state.connectingFromId;
    if (fromItemId == null || fromItemId == toItemId) {
      cancelConnection();
      return;
    }

    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final CanvasConnection conn = CanvasConnection(
      id: 0,
      collectionId: _collectionId!,
      collectionItemId: _collectionItemId,
      fromItemId: fromItemId,
      toItemId: toItemId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
    );

    final CanvasConnection created = await _repository.createConnection(conn);
    state = state.copyWith(
      connections: <CanvasConnection>[...state.connections, created],
      clearConnectingFromId: true,
    );
  }

  /// Отменяет режим создания связи.
  @override
  void cancelConnection() {
    state = state.copyWith(clearConnectingFromId: true);
  }

  /// Удаляет связь.
  @override
  Future<void> deleteConnection(int connectionId) async {
    await _repository.deleteConnection(connectionId);
    state = state.copyWith(
      connections: state.connections
          .where((CanvasConnection conn) => conn.id != connectionId)
          .toList(),
    );
  }

  /// Обновляет свойства связи.
  @override
  Future<void> updateConnection(
    int connectionId, {
    String? label,
    String? color,
    ConnectionStyle? style,
  }) async {
    final int index = state.connections.indexWhere(
      (CanvasConnection conn) => conn.id == connectionId,
    );
    if (index == -1) return;

    final CanvasConnection updated = state.connections[index].copyWith(
      label: label,
      clearLabel: label == null,
      color: color,
      style: style,
    );

    await _repository.updateConnection(updated);

    final List<CanvasConnection> newConnections =
        List<CanvasConnection>.from(state.connections);
    newConnections[index] = updated;
    state = state.copyWith(connections: newConnections);
  }
}
