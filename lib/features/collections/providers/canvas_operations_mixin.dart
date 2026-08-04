import 'package:core/models/canvas_connection.dart';
import 'package:core/models/canvas_item.dart';

import '../../../data/repositories/canvas_repository.dart';
import 'canvas_state.dart';

/// Shared by [CanvasNotifier] and [GameCanvasNotifier]; the only difference is
/// [itemCollectionItemId] — null for a collection canvas, set for a per-item one.
mixin CanvasOperationsMixin {
  CanvasState get state;

  set state(CanvasState value);

  CanvasRepository get operationsRepository;

  int get collectionId;

  /// Null for a collection canvas, the item's id for a per-item one.
  int? get itemCollectionItemId;

  int _nextZIndex() {
    if (state.items.isEmpty) return 0;
    return state.items
            .map((CanvasItem item) => item.zIndex)
            .reduce((int a, int b) => a > b ? a : b) +
        1;
  }


  Future<CanvasItem> addItem(CanvasItem item) async {
    final CanvasItem created = await operationsRepository.createItem(item);
    state = state.copyWith(
      items: <CanvasItem>[...state.items, created],
    );
    return created;
  }

  /// Connections cascade in the DB (FK CASCADE); state filters them out here.
  Future<void> deleteItem(int itemId) async {
    await operationsRepository.deleteItem(itemId);
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

  Future<CanvasItem> addTextItem(
    double x,
    double y,
    String content,
    double fontSize,
  ) async {
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final CanvasItem item = CanvasItem(
      id: 0,
      collectionId: collectionId,
      collectionItemId: itemCollectionItemId,
      itemType: CanvasItemType.text,
      x: x,
      y: y,
      width: 200,
      height: null,
      zIndex: _nextZIndex(),
      data: <String, dynamic>{
        'content': content,
        'fontSize': fontSize,
      },
      createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
    );

    return addItem(item);
  }

  /// [width] / [height] default to 200x200 when omitted.
  Future<CanvasItem> addImageItem(
    double x,
    double y,
    Map<String, dynamic> imageData, {
    double width = 200,
    double height = 200,
  }) async {
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final CanvasItem item = CanvasItem(
      id: 0,
      collectionId: collectionId,
      collectionItemId: itemCollectionItemId,
      itemType: CanvasItemType.image,
      x: x,
      y: y,
      width: width,
      height: height,
      zIndex: _nextZIndex(),
      data: imageData,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
    );

    return addItem(item);
  }

  Future<CanvasItem> addLinkItem(
    double x,
    double y,
    String url,
    String label,
  ) async {
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final CanvasItem item = CanvasItem(
      id: 0,
      collectionId: collectionId,
      collectionItemId: itemCollectionItemId,
      itemType: CanvasItemType.link,
      x: x,
      y: y,
      width: 200,
      height: 48,
      zIndex: _nextZIndex(),
      data: <String, dynamic>{
        'url': url,
        'label': label,
      },
      createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
    );

    return addItem(item);
  }

  Future<void> updateItemData(
    int itemId,
    Map<String, dynamic> data,
  ) async {
    await operationsRepository.updateItemData(itemId, data);
    state = state.copyWith(
      items: state.items.map((CanvasItem item) {
        if (item.id == itemId) {
          return item.copyWith(data: data);
        }
        return item;
      }).toList(),
    );
  }

  /// Updates state immediately, then persists.
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
    await operationsRepository.updateItemSize(
      itemId,
      width: width,
      height: height,
    );
  }

  Future<void> bringToFront(int itemId) async {
    if (state.items.isEmpty) return;

    final int maxZ = state.items
        .map((CanvasItem item) => item.zIndex)
        .reduce((int a, int b) => a > b ? a : b);
    final int newZ = maxZ + 1;

    await operationsRepository.updateItemZIndex(itemId, newZ);
    state = state.copyWith(
      items: state.items.map((CanvasItem item) {
        if (item.id == itemId) {
          return item.copyWith(zIndex: newZ);
        }
        return item;
      }).toList(),
    );
  }

  Future<void> sendToBack(int itemId) async {
    if (state.items.isEmpty) return;

    final int minZ = state.items
        .map((CanvasItem item) => item.zIndex)
        .reduce((int a, int b) => a < b ? a : b);
    final int newZ = minZ - 1;

    await operationsRepository.updateItemZIndex(itemId, newZ);
    state = state.copyWith(
      items: state.items.map((CanvasItem item) {
        if (item.id == itemId) {
          return item.copyWith(zIndex: newZ);
        }
        return item;
      }).toList(),
    );
  }

  /// [viewportWidth] is the visible width, used to pick the column count.
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
      operationsRepository.updateItemPosition(item.id, x: x, y: y);
    }

    state = state.copyWith(items: updated);
  }


  void startConnection(int fromItemId) {
    state = state.copyWith(connectingFromId: fromItemId);
  }

  Future<void> completeConnection(int toItemId) async {
    final int? fromItemId = state.connectingFromId;
    if (fromItemId == null || fromItemId == toItemId) {
      cancelConnection();
      return;
    }

    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final CanvasConnection conn = CanvasConnection(
      id: 0,
      collectionId: collectionId,
      collectionItemId: itemCollectionItemId,
      fromItemId: fromItemId,
      toItemId: toItemId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now * 1000),
    );

    final CanvasConnection created =
        await operationsRepository.createConnection(conn);
    state = state.copyWith(
      connections: <CanvasConnection>[...state.connections, created],
      clearConnectingFromId: true,
    );
  }

  void cancelConnection() {
    state = state.copyWith(clearConnectingFromId: true);
  }

  Future<void> deleteConnection(int connectionId) async {
    await operationsRepository.deleteConnection(connectionId);
    state = state.copyWith(
      connections: state.connections
          .where((CanvasConnection conn) => conn.id != connectionId)
          .toList(),
    );
  }

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

    await operationsRepository.updateConnection(updated);

    final List<CanvasConnection> newConnections =
        List<CanvasConnection>.from(state.connections);
    newConnections[index] = updated;
    state = state.copyWith(connections: newConnections);
  }
}
