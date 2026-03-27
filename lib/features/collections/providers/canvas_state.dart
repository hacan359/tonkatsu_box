import '../../../shared/models/canvas_connection.dart';
import '../../../shared/models/canvas_item.dart';
import '../../../shared/models/canvas_viewport.dart';

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
