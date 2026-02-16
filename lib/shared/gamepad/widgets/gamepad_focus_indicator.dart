// Виджет рамки фокуса для gamepad-режима.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../gamepad_action.dart';
import '../gamepad_provider.dart';

/// Обёртка для focusable элементов с визуальной рамкой фокуса.
///
/// В [InputMode.gamepad] показывает рамку вокруг элемента при фокусе.
/// В [InputMode.mouse] рамка скрыта — стандартное поведение мыши.
class GamepadFocusIndicator extends ConsumerWidget {
  /// Создаёт [GamepadFocusIndicator].
  const GamepadFocusIndicator({
    required this.child,
    this.focusNode,
    this.borderRadius,
    this.focusColor,
    super.key,
  });

  /// Дочерний виджет.
  final Widget child;

  /// FocusNode для отслеживания фокуса.
  ///
  /// Если null, создаётся встроенный Focus виджет.
  final FocusNode? focusNode;

  /// Радиус скругления рамки.
  final double? borderRadius;

  /// Цвет рамки фокуса (по умолчанию [AppColors.gameAccent]).
  final Color? focusColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final InputMode inputMode = ref.watch(inputModeProvider);

    if (inputMode != InputMode.gamepad) {
      return child;
    }

    return Focus(
      focusNode: focusNode,
      child: Builder(
        builder: (BuildContext context) {
          final bool hasFocus = Focus.of(context).hasFocus;
          final double radius = borderRadius ?? AppSpacing.radiusSm;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: hasFocus
                  ? Border.all(
                      color: focusColor ?? AppColors.gameAccent,
                      width: 2,
                    )
                  : null,
            ),
            child: child,
          );
        },
      ),
    );
  }
}
