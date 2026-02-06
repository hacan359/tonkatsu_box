import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/canvas_repository.dart';
import '../../../shared/models/canvas_item.dart';
import '../../../shared/models/canvas_viewport.dart';
import '../../../shared/models/collection_game.dart';
import 'collections_provider.dart';

/// Состояние канваса для коллекции.
class CanvasState {
  /// Создаёт экземпляр [CanvasState].
  const CanvasState({
    this.items = const <CanvasItem>[],
    this.viewport = CanvasViewport.defaultValue,
    this.isLoading = true,
    this.isInitialized = false,
    this.error,
  });

  /// Элементы на канвасе.
  final List<CanvasItem> items;

  /// Состояние viewport (зум, позиция камеры).
  final CanvasViewport viewport;

  /// Загружается ли канвас.
  final bool isLoading;

  /// Инициализирован ли канвас (данные загружены).
  final bool isInitialized;

  /// Ошибка при загрузке.
  final String? error;

  /// Создаёт копию с изменёнными полями.
  CanvasState copyWith({
    List<CanvasItem>? items,
    CanvasViewport? viewport,
    bool? isLoading,
    bool? isInitialized,
    String? error,
  }) {
    return CanvasState(
      items: items ?? this.items,
      viewport: viewport ?? this.viewport,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error,
    );
  }
}

/// Провайдер для управления канвасом конкретной коллекции.
final NotifierProviderFamily<CanvasNotifier, CanvasState, int>
    canvasNotifierProvider =
    NotifierProvider.family<CanvasNotifier, CanvasState, int>(
  CanvasNotifier.new,
);

/// Notifier для управления состоянием канваса.
class CanvasNotifier extends FamilyNotifier<CanvasState, int> {
  late CanvasRepository _repository;
  late int _collectionId;
  Timer? _viewportSaveTimer;
  Timer? _positionSaveTimer;

  @override
  CanvasState build(int arg) {
    _collectionId = arg;
    _repository = ref.watch(canvasRepositoryProvider);

    ref.onDispose(() {
      _viewportSaveTimer?.cancel();
      _positionSaveTimer?.cancel();
    });

    // Реактивная синхронизация: при изменении списка игр коллекции
    // автоматически добавляем/удаляем элементы канваса
    ref.listen<AsyncValue<List<CollectionGame>>>(
      collectionGamesNotifierProvider(_collectionId),
      (AsyncValue<List<CollectionGame>>? previous,
          AsyncValue<List<CollectionGame>> next) {
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
    try {
      final bool hasItems = await _repository.hasCanvasItems(_collectionId);

      if (!hasItems) {
        // Первый запуск — инициализируем канвас из игр коллекции
        await _initializeFromGames();
      } else {
        // Синхронизация: удаляем сиротские элементы канваса
        await _syncCanvasWithGames();

        // Загружаем элементы и viewport параллельно
        final (List<CanvasItem> items, CanvasViewport? viewport) =
            await (_repository.getItemsWithData(_collectionId),
                _repository.getViewport(_collectionId)).wait;

        state = state.copyWith(
          items: items,
          viewport: viewport ??
              CanvasViewport(collectionId: _collectionId),
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

  Future<void> _initializeFromGames() async {
    try {
      final AsyncValue<List<CollectionGame>> gamesAsync =
          ref.read(collectionGamesNotifierProvider(_collectionId));
      final List<CollectionGame> games =
          gamesAsync.valueOrNull ?? <CollectionGame>[];

      final List<CanvasItem> items =
          await _repository.initializeCanvas(_collectionId, games);

      state = state.copyWith(
        items: items,
        viewport: CanvasViewport(collectionId: _collectionId),
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

  /// Синхронизирует канвас с играми и перезагружает элементы.
  ///
  /// Вызывается реактивно при изменении списка игр коллекции.
  Future<void> _syncAndReload() async {
    try {
      await _syncCanvasWithGames();
      final List<CanvasItem> items =
          await _repository.getItemsWithData(_collectionId);
      state = state.copyWith(items: items);
    } catch (_) {
      // Ошибки синхронизации не критичны — при следующем открытии
      // канваса данные будут синхронизированы в _loadCanvas
    }
  }

  /// Синхронизирует элементы канваса с текущими играми коллекции.
  ///
  /// Двусторонняя синхронизация:
  /// - Удаляет элементы канваса для игр, удалённых из коллекции
  /// - Создаёт элементы канваса для новых игр в коллекции
  Future<void> _syncCanvasWithGames() async {
    final AsyncValue<List<CollectionGame>> gamesAsync =
        ref.read(collectionGamesNotifierProvider(_collectionId));
    final List<CollectionGame>? games = gamesAsync.valueOrNull;

    // Если игры ещё не загружены — пропускаем синхронизацию
    if (games == null) return;

    final Set<int> currentIgdbIds =
        games.map((CollectionGame g) => g.igdbId).toSet();

    final List<CanvasItem> canvasItems =
        await _repository.getItems(_collectionId);

    // Удаляем сиротские элементы (игра удалена из коллекции)
    for (final CanvasItem item in canvasItems) {
      if (item.itemType == CanvasItemType.game &&
          item.itemRefId != null &&
          !currentIgdbIds.contains(item.itemRefId)) {
        await _repository.deleteItem(item.id);
      }
    }

    // Добавляем недостающие элементы (игра добавлена в коллекцию)
    final Set<int> canvasIgdbIds = canvasItems
        .where((CanvasItem item) =>
            item.itemType == CanvasItemType.game && item.itemRefId != null)
        .map((CanvasItem item) => item.itemRefId!)
        .toSet();

    final List<CollectionGame> missingGames = games
        .where((CollectionGame g) => !canvasIgdbIds.contains(g.igdbId))
        .toList();

    if (missingGames.isEmpty) return;

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

    final int cols = missingGames.length < CanvasRepository.gridColumns
        ? missingGames.length
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

    for (int i = 0; i < missingGames.length; i++) {
      final int col = i % cols;
      final int row = i ~/ cols;
      final double x = startX +
          col * (CanvasRepository.defaultCardWidth + CanvasRepository.gridGap);
      final double y = startY +
          row *
              (CanvasRepository.defaultCardHeight + CanvasRepository.gridGap);

      final CanvasItem item = CanvasItem(
        id: 0,
        collectionId: _collectionId,
        itemType: CanvasItemType.game,
        itemRefId: missingGames[i].igdbId,
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

  /// Удаляет элемент игры с канваса по igdbId.
  ///
  /// Обновляет state мгновенно и удаляет из БД.
  void removeGameItem(int igdbId) {
    state = state.copyWith(
      items: state.items
          .where((CanvasItem item) =>
              !(item.itemType == CanvasItemType.game &&
                  item.itemRefId == igdbId))
          .toList(),
    );
    _repository.deleteGameItem(_collectionId, igdbId);
  }

  /// Обновляет канвас (перезагрузка из БД).
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    await _loadCanvas();
  }

  /// Перемещает элемент на канвасе.
  ///
  /// Обновляет state мгновенно, сохраняет в БД с debounce.
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
  void updateViewport(double scale, double offsetX, double offsetY) {
    final CanvasViewport newViewport = CanvasViewport(
      collectionId: _collectionId,
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
  void resetViewport() {
    final CanvasViewport defaultViewport = CanvasViewport(
      collectionId: _collectionId,
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
  Future<CanvasItem> addItem(CanvasItem item) async {
    final CanvasItem created = await _repository.createItem(item);
    state = state.copyWith(
      items: <CanvasItem>[...state.items, created],
    );
    return created;
  }

  /// Удаляет элемент с канваса.
  Future<void> deleteItem(int itemId) async {
    await _repository.deleteItem(itemId);
    state = state.copyWith(
      items: state.items
          .where((CanvasItem item) => item.id != itemId)
          .toList(),
    );
  }

  /// Перемещает элемент на передний план (максимальный z-index).
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
}
