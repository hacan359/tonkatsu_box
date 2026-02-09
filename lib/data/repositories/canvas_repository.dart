import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_service.dart';
import '../../shared/models/canvas_connection.dart';
import '../../shared/models/canvas_item.dart';
import '../../shared/models/canvas_viewport.dart';
import '../../shared/models/collection_item.dart';
import '../../shared/models/game.dart';
import '../../shared/models/movie.dart';
import '../../shared/models/tv_show.dart';

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

  /// Возвращает элементы канваса с подгруженными данными медиа.
  Future<List<CanvasItem>> getItemsWithData(int collectionId) async {
    final List<CanvasItem> items = await getItems(collectionId);
    return _enrichItemsWithMediaData(items);
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
    await _db.deleteCanvasItemByRef(collectionId, 'game', igdbId);
  }

  /// Удаляет элемент канваса по типу и ID связанного объекта.
  Future<void> deleteMediaItem(
    int collectionId,
    CanvasItemType itemType,
    int refId,
  ) async {
    await _db.deleteCanvasItemByRef(collectionId, itemType.value, refId);
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

  /// Загружает медиа-данные (game/movie/tvShow) для canvas items.
  Future<List<CanvasItem>> _enrichItemsWithMediaData(
    List<CanvasItem> items,
  ) async {
    if (items.isEmpty) return items;

    // Собираем ID по типам медиа
    final List<int> gameIds = items
        .where((CanvasItem item) =>
            item.itemType == CanvasItemType.game && item.itemRefId != null)
        .map((CanvasItem item) => item.itemRefId!)
        .toList();

    final List<int> movieTmdbIds = items
        .where((CanvasItem item) =>
            item.itemType == CanvasItemType.movie && item.itemRefId != null)
        .map((CanvasItem item) => item.itemRefId!)
        .toList();

    final List<int> tvShowTmdbIds = items
        .where((CanvasItem item) =>
            item.itemType == CanvasItemType.tvShow && item.itemRefId != null)
        .map((CanvasItem item) => item.itemRefId!)
        .toList();

    // Если нет медиа-элементов, возвращаем как есть
    if (gameIds.isEmpty && movieTmdbIds.isEmpty && tvShowTmdbIds.isEmpty) {
      return items;
    }

    // Загружаем данные параллельно
    final List<Object> results = await Future.wait(<Future<Object>>[
      gameIds.isNotEmpty
          ? _db.getGamesByIds(gameIds)
          : Future<List<Game>>.value(<Game>[]),
      movieTmdbIds.isNotEmpty
          ? _db.getMoviesByTmdbIds(movieTmdbIds)
          : Future<List<Movie>>.value(<Movie>[]),
      tvShowTmdbIds.isNotEmpty
          ? _db.getTvShowsByTmdbIds(tvShowTmdbIds)
          : Future<List<TvShow>>.value(<TvShow>[]),
    ]);

    final Map<int, Game> gamesMap = <int, Game>{
      for (final Game g in results[0] as List<Game>) g.id: g,
    };
    final Map<int, Movie> moviesMap = <int, Movie>{
      for (final Movie m in results[1] as List<Movie>) m.tmdbId: m,
    };
    final Map<int, TvShow> tvShowsMap = <int, TvShow>{
      for (final TvShow t in results[2] as List<TvShow>) t.tmdbId: t,
    };

    return items.map((CanvasItem item) {
      if (item.itemRefId == null) return item;
      switch (item.itemType) {
        case CanvasItemType.game:
          return item.copyWith(game: gamesMap[item.itemRefId]);
        case CanvasItemType.movie:
          return item.copyWith(movie: moviesMap[item.itemRefId]);
        case CanvasItemType.tvShow:
          return item.copyWith(tvShow: tvShowsMap[item.itemRefId]);
        case CanvasItemType.text:
        case CanvasItemType.image:
        case CanvasItemType.link:
          return item;
      }
    }).toList();
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

  // ==================== Game Canvas ====================

  /// Возвращает элементы game canvas для элемента коллекции.
  Future<List<CanvasItem>> getGameCanvasItems(int collectionItemId) async {
    final List<Map<String, dynamic>> rows =
        await _db.getGameCanvasItems(collectionItemId);
    return rows.map(CanvasItem.fromDb).toList();
  }

  /// Возвращает элементы game canvas с подгруженными данными медиа.
  Future<List<CanvasItem>> getGameCanvasItemsWithData(
    int collectionItemId,
  ) async {
    final List<CanvasItem> items =
        await getGameCanvasItems(collectionItemId);
    return _enrichItemsWithMediaData(items);
  }

  /// Проверяет, есть ли элементы game canvas.
  Future<bool> hasGameCanvasItems(int collectionItemId) async {
    final int count = await _db.getGameCanvasItemCount(collectionItemId);
    return count > 0;
  }

  /// Возвращает viewport game canvas.
  ///
  /// Возвращает [CanvasViewport] с `collectionId` равным `collectionItemId`
  /// для совместимости с [CanvasState].
  Future<CanvasViewport?> getGameCanvasViewport(
    int collectionItemId,
  ) async {
    final Map<String, dynamic>? row =
        await _db.getGameCanvasViewport(collectionItemId);
    if (row == null) return null;
    return CanvasViewport(
      collectionId: collectionItemId,
      scale: (row['scale'] as num?)?.toDouble() ?? 1.0,
      offsetX: (row['offset_x'] as num?)?.toDouble() ?? 0.0,
      offsetY: (row['offset_y'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Сохраняет viewport game canvas.
  Future<void> saveGameCanvasViewport(
    int collectionItemId,
    CanvasViewport viewport,
  ) async {
    await _db.upsertGameCanvasViewport(
      collectionItemId: collectionItemId,
      scale: viewport.scale,
      offsetX: viewport.offsetX,
      offsetY: viewport.offsetY,
    );
  }

  /// Возвращает связи game canvas.
  Future<List<CanvasConnection>> getGameCanvasConnections(
    int collectionItemId,
  ) async {
    final List<Map<String, dynamic>> rows =
        await _db.getGameCanvasConnections(collectionItemId);
    return rows.map(CanvasConnection.fromDb).toList();
  }

  // ==================== Initialization ====================

  /// Инициализирует канвас для коллекции, размещая элементы сеткой по центру.
  ///
  /// Вызывается при первом открытии Canvas View.
  /// Сетка центрируется вокруг [initialCenterX], [initialCenterY].
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

      final CanvasItemType canvasType =
          CanvasItemType.fromMediaType(items[i].mediaType);

      final CanvasItem item = CanvasItem(
        id: 0,
        collectionId: collectionId,
        itemType: canvasType,
        itemRefId: items[i].externalId,
        x: x,
        y: y,
        width: defaultCardWidth,
        height: defaultCardHeight,
        zIndex: i,
        createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
      );

      final CanvasItem created = await createItem(item);
      createdItems.add(created.copyWith(
        game: items[i].game,
        movie: items[i].movie,
        tvShow: items[i].tvShow,
      ));
    }

    // Создаём viewport по умолчанию
    await saveViewport(CanvasViewport(collectionId: collectionId));

    return createdItems;
  }
}
