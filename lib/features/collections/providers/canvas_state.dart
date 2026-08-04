import 'package:core/models/canvas_connection.dart';
import 'package:core/models/canvas_item.dart';
import 'package:core/models/canvas_viewport.dart';

class CanvasState {
  const CanvasState({
    this.items = const <CanvasItem>[],
    this.connections = const <CanvasConnection>[],
    this.viewport = CanvasViewport.defaultValue,
    this.isLoading = true,
    this.isInitialized = false,
    this.connectingFromId,
    this.error,
  });

  final List<CanvasItem> items;

  final List<CanvasConnection> connections;

  /// Состояние viewport (зум, позиция камеры).
  final CanvasViewport viewport;

  final bool isLoading;

  /// Инициализирован ли канвас (данные загружены).
  final bool isInitialized;

  /// ID элемента, от которого создаётся связь (null = не в режиме создания).
  final int? connectingFromId;

  final String? error;

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
  void moveItem(int itemId, double x, double y);

  void updateViewport(double scale, double offsetX, double offsetY);

  void resetViewport();

  Future<void> resetPositions(double viewportWidth);

  Future<CanvasItem> addItem(CanvasItem item);

  Future<void> deleteItem(int itemId);

  Future<CanvasItem> addTextItem(
    double x,
    double y,
    String content,
    double fontSize,
  );

  Future<CanvasItem> addImageItem(
    double x,
    double y,
    Map<String, dynamic> imageData, {
    double width,
    double height,
  });

  Future<CanvasItem> addLinkItem(
    double x,
    double y,
    String url,
    String label,
  );

  Future<void> updateItemData(int itemId, Map<String, dynamic> data);

  Future<void> updateItemSize(
    int itemId, {
    required double width,
    required double height,
  });

  Future<void> bringToFront(int itemId);

  Future<void> sendToBack(int itemId);

  void startConnection(int fromItemId);

  Future<void> completeConnection(int toItemId);

  void cancelConnection();

  Future<void> deleteConnection(int connectionId);

  Future<void> updateConnection(
    int connectionId, {
    String? label,
    String? color,
    ConnectionStyle? style,
  });

  Future<void> refresh();
}
