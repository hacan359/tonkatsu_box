import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_service.dart';
import '../../shared/models/canvas_connection.dart';
import '../../shared/models/canvas_item.dart';
import '../../shared/models/canvas_viewport.dart';
import '../../shared/models/collection_item.dart';
import '../../shared/models/game.dart';

/// Провайдер для репозитория канваса.
final Provider<CanvasRepository> canvasRepositoryProvider =
    Provider<CanvasRepository>((Ref ref) {
  return CanvasRepository(
    db: ref.watch(databaseServiceProvider),
  );
});

/// Репозиторий для работы с элементами канваса.
///
/// Управляет CRUD операциями для canvas_items и canvas_viewport.
class CanvasRepository {
  /// Создаёт экземпляр [CanvasRepository].
  CanvasRepository({required DatabaseService db}) : _db = db;

  final DatabaseService _db;

  /// Ширина карточки по умолчанию.
  static const double defaultCardWidth = 160;

  /// Высота карточки по умолчанию.
  static const double defaultCardHeight = 220;

  /// Отступ между карточками в сетке.
  static const double gridGap = 24;

  /// Количество колонок при авторазмещении.
  static const int gridColumns = 5;

  /// X координата центра канваса для размещения элементов.
  static const double initialCenterX = 2500.0;

  /// Y координата центра канваса для размещения элементов.
  static const double initialCenterY = 2500.0;

  // ==================== Canvas Items ====================

  /// Возвращает все элементы канваса для коллекции.
  Future<List<CanvasItem>> getItems(int collectionId) async {
    final List<Map<String, dynamic>> rows =
        await _db.getCanvasItems(collectionId);
    return rows.map(CanvasItem.fromDb).toList();
  }

  /// Возвращает элементы канваса с подгруженными данными игр.
  Future<List<CanvasItem>> getItemsWithData(int collectionId) async {
    final List<CanvasItem> items = await getItems(collectionId);
    if (items.isEmpty) return items;

    // Собираем ID игр для подгрузки
    final List<int> gameIds = items
        .where((CanvasItem item) =>
            item.itemType == CanvasItemType.game && item.itemRefId != null)
        .map((CanvasItem item) => item.itemRefId!)
        .toList();

    if (gameIds.isEmpty) return items;

    final List<Game> games = await _db.getGamesByIds(gameIds);
    final Map<int, Game> gamesMap = <int, Game>{
      for (final Game g in games) g.id: g,
    };

    return items.map((CanvasItem item) {
      if (item.itemType == CanvasItemType.game && item.itemRefId != null) {
        return item.copyWith(game: gamesMap[item.itemRefId]);
      }
      return item;
    }).toList();
  }

  /// Создаёт элемент канваса и возвращает его с присвоенным ID.
  Future<CanvasItem> createItem(CanvasItem item) async {
    final int id = await _db.insertCanvasItem(item.toDb());
    return item.copyWith(id: id);
  }

  /// Обновляет элемент канваса.
  Future<void> updateItem(CanvasItem item) async {
    final Map<String, dynamic> dbData = item.toDb();
    dbData.remove('id');
    await _db.updateCanvasItem(item.id, dbData);
  }

  /// Обновляет позицию элемента на канвасе.
  Future<void> updateItemPosition(
    int id, {
    required double x,
    required double y,
  }) async {
    await _db.updateCanvasItem(id, <String, dynamic>{'x': x, 'y': y});
  }

  /// Обновляет размеры элемента.
  Future<void> updateItemSize(
    int id, {
    double? width,
    double? height,
  }) async {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (width != null) data['width'] = width;
    if (height != null) data['height'] = height;
    if (data.isNotEmpty) {
      await _db.updateCanvasItem(id, data);
    }
  }

  /// Обновляет дополнительные данные элемента (JSON).
  Future<void> updateItemData(int id, Map<String, dynamic>? data) async {
    await _db.updateCanvasItem(id, <String, dynamic>{
      'data': data != null ? json.encode(data) : null,
    });
  }

  /// Обновляет z-index элемента.
  Future<void> updateItemZIndex(int id, int zIndex) async {
    await _db.updateCanvasItem(id, <String, dynamic>{'z_index': zIndex});
  }

  /// Удаляет элемент канваса.
  Future<void> deleteItem(int id) async {
    await _db.deleteCanvasItem(id);
  }

  /// Удаляет элемент канваса, связанный с игрой (по igdbId).
  Future<void> deleteGameItem(int collectionId, int igdbId) async {
    await _db.deleteCanvasItemByRef(collectionId, igdbId);
  }

  /// Проверяет, есть ли элементы канваса для коллекции.
  Future<bool> hasCanvasItems(int collectionId) async {
    final int count = await _db.getCanvasItemCount(collectionId);
    return count > 0;
  }

  // ==================== Canvas Viewport ====================

  /// Возвращает состояние viewport для коллекции.
  Future<CanvasViewport?> getViewport(int collectionId) async {
    final Map<String, dynamic>? row =
        await _db.getCanvasViewport(collectionId);
    if (row == null) return null;
    return CanvasViewport.fromDb(row);
  }

  /// Сохраняет состояние viewport.
  Future<void> saveViewport(CanvasViewport viewport) async {
    await _db.upsertCanvasViewport(
      collectionId: viewport.collectionId,
      scale: viewport.scale,
      offsetX: viewport.offsetX,
      offsetY: viewport.offsetY,
    );
  }

  // ==================== Canvas Connections ====================

  /// Возвращает все связи канваса для коллекции.
  Future<List<CanvasConnection>> getConnections(int collectionId) async {
    final List<Map<String, dynamic>> rows =
        await _db.getCanvasConnections(collectionId);
    return rows.map(CanvasConnection.fromDb).toList();
  }

  /// Создаёт связь и возвращает её с присвоенным ID.
  Future<CanvasConnection> createConnection(CanvasConnection conn) async {
    final int id = await _db.insertCanvasConnection(conn.toDb());
    return conn.copyWith(id: id);
  }

  /// Обновляет свойства связи (label, color, style).
  Future<void> updateConnection(CanvasConnection conn) async {
    final Map<String, dynamic> data = <String, dynamic>{
      'label': conn.label,
      'color': conn.color,
      'style': conn.style.value,
    };
    await _db.updateCanvasConnection(conn.id, data);
  }

  /// Удаляет связь.
  Future<void> deleteConnection(int id) async {
    await _db.deleteCanvasConnection(id);
  }

  // ==================== Initialization ====================

  /// Инициализирует канвас для коллекции, размещая игры сеткой по центру.
  ///
  /// Вызывается при первом открытии Canvas View.
  /// Сетка центрируется вокруг [initialCenterX], [initialCenterY].
  /// Инициализирует канвас для коллекции, размещая элементы сеткой по центру.
  ///
  /// Принимает [List<CollectionItem>] — обычно отфильтрованные по mediaType=game.
  Future<List<CanvasItem>> initializeCanvas(
    int collectionId,
    List<CollectionItem> items,
  ) async {
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final List<CanvasItem> createdItems = <CanvasItem>[];

    if (items.isEmpty) {
      await saveViewport(CanvasViewport(collectionId: collectionId));
      return createdItems;
    }

    // Рассчитываем размеры сетки для центрирования
    final int cols =
        items.length < gridColumns ? items.length : gridColumns;
    final int rowCount = (items.length + cols - 1) ~/ cols;
    final double gridWidth = cols * (defaultCardWidth + gridGap) - gridGap;
    final double gridHeight =
        rowCount * (defaultCardHeight + gridGap) - gridGap;
    final double startX = initialCenterX - gridWidth / 2;
    final double startY = initialCenterY - gridHeight / 2;

    for (int i = 0; i < items.length; i++) {
      final int col = i % cols;
      final int row = i ~/ cols;
      final double x = startX + col * (defaultCardWidth + gridGap);
      final double y = startY + row * (defaultCardHeight + gridGap);

      final CanvasItem item = CanvasItem(
        id: 0,
        collectionId: collectionId,
        itemType: CanvasItemType.game,
        itemRefId: items[i].externalId,
        x: x,
        y: y,
        width: defaultCardWidth,
        height: defaultCardHeight,
        zIndex: i,
        createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
      );

      final CanvasItem created = await createItem(item);
      createdItems.add(created.copyWith(game: items[i].game));
    }

    // Создаём viewport по умолчанию
    await saveViewport(CanvasViewport(collectionId: collectionId));

    return createdItems;
  }
}
