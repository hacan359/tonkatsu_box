// Виджет для горизонтального скролла мышкой на десктопе.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Перехватывает вертикальный скролл мышью и перенаправляет
/// его в горизонтальный [ScrollController].
///
/// На мобильных устройствах свайп работает как обычно.
class HorizontalMouseScroll extends StatelessWidget {
  /// Создаёт [HorizontalMouseScroll].
  const HorizontalMouseScroll({
    required this.controller,
    required this.child,
    super.key,
  });

  /// Контроллер горизонтального списка.
  final ScrollController controller;

  /// Дочерний виджет (горизонтальный ListView).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (PointerSignalEvent event) {
        if (event is PointerScrollEvent && controller.hasClients) {
          final double offset = controller.offset + event.scrollDelta.dy;
          controller.jumpTo(
            offset.clamp(0.0, controller.position.maxScrollExtent),
          );
        }
      },
      child: child,
    );
  }
}
