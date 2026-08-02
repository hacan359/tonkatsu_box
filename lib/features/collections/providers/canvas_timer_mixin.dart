import 'dart:async';

import 'package:core/models/canvas_item.dart';
import 'package:core/models/canvas_viewport.dart';

import '../../../data/repositories/canvas_repository.dart';
import 'canvas_state.dart';

/// Mixin с debounce-логикой для сохранения позиций и viewport канваса.
///
/// Используется в [CanvasNotifier] и [GameCanvasNotifier] для устранения
/// дублирования кода. Классы-потребители обязаны реализовать [persistViewport]
/// и [viewportId].
mixin CanvasTimerMixin {
  Timer? _viewportSaveTimer;
  Timer? _positionSaveTimer;

  CanvasRepository get timerRepository;

  CanvasState get state;

  set state(CanvasState value);

  /// ID для создания [CanvasViewport] (collectionId или collectionItemId).
  int get viewportId;

  void persistViewport(CanvasViewport viewport);

  void cancelTimers() {
    _viewportSaveTimer?.cancel();
    _positionSaveTimer?.cancel();
  }

  /// Перемещает элемент на канвасе.
  ///
  /// Обновляет state мгновенно, сохраняет в БД с debounce 300ms.
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
      timerRepository.updateItemPosition(itemId, x: x, y: y);
    });
  }

  /// Обновляет viewport (зум и позицию камеры).
  ///
  /// Сохраняет в БД с debounce 500ms.
  void updateViewport(double scale, double offsetX, double offsetY) {
    final CanvasViewport newViewport = CanvasViewport(
      collectionId: viewportId,
      scale: scale,
      offsetX: offsetX,
      offsetY: offsetY,
    );

    state = state.copyWith(viewport: newViewport);

    _viewportSaveTimer?.cancel();
    _viewportSaveTimer = Timer(const Duration(milliseconds: 500), () {
      persistViewport(newViewport);
    });
  }

  /// Сбрасывает viewport в значение по умолчанию (scale=1, offset=0,0).
  void resetViewport() {
    final CanvasViewport defaultViewport = CanvasViewport(
      collectionId: viewportId,
    );

    state = state.copyWith(viewport: defaultViewport);

    _viewportSaveTimer?.cancel();
    persistViewport(defaultViewport);
  }
}
