// Виджет-обёртка для прослушивания событий геймпада.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/gamepad_service.dart';
import '../gamepad_action.dart';
import '../gamepad_provider.dart';

/// Виджет-обёртка, прослушивающая события геймпада и вызывающая callbacks.
///
/// Оборачивает дочерний виджет и подписывается на [gamepadServiceProvider].
/// При получении события определяет тип и вызывает соответствующий callback.
///
/// При фокусе на TextField навигационные действия (D-pad) пропускаются,
/// чтобы не конфликтовать с вводом текста.
class GamepadListener extends ConsumerStatefulWidget {
  /// Создаёт [GamepadListener].
  const GamepadListener({
    required this.child,
    this.onConfirm,
    this.onBack,
    this.onNavigate,
    this.onTabSwitch,
    this.onSubTabSwitch,
    this.onScroll,
    this.onPan,
    this.onZoom,
    this.onMenu,
    super.key,
  });

  /// Дочерний виджет.
  final Widget child;

  /// A кнопка — подтвердить.
  final VoidCallback? onConfirm;

  /// B кнопка — назад.
  final VoidCallback? onBack;

  /// D-pad навигация (up/down/left/right).
  final void Function(GamepadAction action)? onNavigate;

  /// LB/RB — переключение основных табов.
  final void Function(GamepadAction action)? onTabSwitch;

  /// LT/RT — переключение суб-табов/фильтров.
  final void Function(GamepadAction action)? onSubTabSwitch;

  /// Left Stick — скролл.
  final void Function(GamepadAction action)? onScroll;

  /// Right Stick — панорама.
  final void Function(GamepadAction action)? onPan;

  /// Triggers analog — зум.
  final void Function(GamepadAction action)? onZoom;

  /// Start — контекстное меню.
  final VoidCallback? onMenu;

  @override
  ConsumerState<GamepadListener> createState() => _GamepadListenerState();
}

class _GamepadListenerState extends ConsumerState<GamepadListener> {
  StreamSubscription<GamepadServiceEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    final GamepadService service = ref.read(gamepadServiceProvider);
    _subscription = service.events.listen(_handleEvent);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _handleEvent(GamepadServiceEvent event) {
    // Переключаем на gamepad-режим
    ref.read(inputModeProvider.notifier).setGamepadMode();

    final GamepadAction? action = _mapServiceEvent(event);
    if (action == null) return;

    // Проверяем конфликт с TextField
    if (_isTextFieldFocused() && _isNavigationAction(action)) {
      if (action == GamepadAction.back) {
        // B на TextField → снять фокус
        FocusManager.instance.primaryFocus?.unfocus();
      }
      return;
    }

    _dispatchAction(action);
  }

  GamepadAction? _mapServiceEvent(GamepadServiceEvent event) {
    final String key = event.key;
    final double value = event.value;

    switch (event.type) {
      case GamepadServiceEventType.button:
        return _mapButton(key);
      case GamepadServiceEventType.analog:
        return _mapAnalog(key, value);
      case GamepadServiceEventType.trigger:
        return _mapTrigger(key, value);
    }
  }

  /// Маппинг цифровых кнопок.
  ///
  /// Key-значения могут отличаться между платформами.
  /// Поддерживаем несколько вариантов для кроссплатформенности.
  GamepadAction? _mapButton(String key) {
    // A button (Xbox) / Cross (PS)
    if (key == '0' || key == 'a' || key == 'button-a') {
      return GamepadAction.confirm;
    }
    // B button (Xbox) / Circle (PS)
    if (key == '1' || key == 'b' || key == 'button-b') {
      return GamepadAction.back;
    }
    // Left Bumper (LB / L1)
    if (key == '6' ||
        key == '4' ||
        key == 'leftBumper' ||
        key == 'left-bumper') {
      return GamepadAction.previousTab;
    }
    // Right Bumper (RB / R1)
    if (key == '7' ||
        key == '5' ||
        key == 'rightBumper' ||
        key == 'right-bumper') {
      return GamepadAction.nextTab;
    }
    // D-pad
    if (key == 'dpadUp' || key == 'dpup' || key == 'dpad-up') {
      return GamepadAction.navigateUp;
    }
    if (key == 'dpadDown' || key == 'dpdown' || key == 'dpad-down') {
      return GamepadAction.navigateDown;
    }
    if (key == 'dpadLeft' || key == 'dpleft' || key == 'dpad-left') {
      return GamepadAction.navigateLeft;
    }
    if (key == 'dpadRight' || key == 'dpright' || key == 'dpad-right') {
      return GamepadAction.navigateRight;
    }
    // Start / Menu
    if (key == '11' ||
        key == '9' ||
        key == '7' ||
        key == 'start' ||
        key == 'menu') {
      return GamepadAction.openMenu;
    }
    return null;
  }

  /// Маппинг аналоговых стиков.
  GamepadAction? _mapAnalog(String key, double value) {
    final bool isLeft = key.contains('left') || key.contains('Left');
    final bool isX = key.contains('x') || key.contains('X');

    if (isLeft) {
      // Left Stick → скролл
      if (isX) {
        return value > 0 ? GamepadAction.scrollRight : GamepadAction.scrollLeft;
      }
      return value > 0 ? GamepadAction.scrollDown : GamepadAction.scrollUp;
    } else {
      // Right Stick → панорама
      if (isX) {
        return value > 0 ? GamepadAction.panRight : GamepadAction.panLeft;
      }
      return value > 0 ? GamepadAction.panDown : GamepadAction.panUp;
    }
  }

  /// Маппинг триггеров (аналоговые).
  GamepadAction? _mapTrigger(String key, double value) {
    if (value < 0.5) return null; // Порог для digital-интерпретации

    final bool isLeft = key.contains('left') ||
        key.contains('Left') ||
        key == '4' ||
        key == '2';

    if (isLeft) {
      return GamepadAction.previousSubTab;
    }
    return GamepadAction.nextSubTab;
  }

  void _dispatchAction(GamepadAction action) {
    switch (action) {
      case GamepadAction.confirm:
        widget.onConfirm?.call();
      case GamepadAction.back:
        widget.onBack?.call();
      case GamepadAction.navigateUp:
      case GamepadAction.navigateDown:
      case GamepadAction.navigateLeft:
      case GamepadAction.navigateRight:
        widget.onNavigate?.call(action);
      case GamepadAction.previousTab:
      case GamepadAction.nextTab:
        widget.onTabSwitch?.call(action);
      case GamepadAction.previousSubTab:
      case GamepadAction.nextSubTab:
        widget.onSubTabSwitch?.call(action);
      case GamepadAction.scrollUp:
      case GamepadAction.scrollDown:
      case GamepadAction.scrollLeft:
      case GamepadAction.scrollRight:
        widget.onScroll?.call(action);
      case GamepadAction.panUp:
      case GamepadAction.panDown:
      case GamepadAction.panLeft:
      case GamepadAction.panRight:
        widget.onPan?.call(action);
      case GamepadAction.zoomIn:
      case GamepadAction.zoomOut:
        widget.onZoom?.call(action);
      case GamepadAction.openMenu:
        widget.onMenu?.call();
    }
  }

  bool _isTextFieldFocused() {
    final FocusNode? focus = FocusManager.instance.primaryFocus;
    if (focus == null) return false;
    // EditableText является родителем для TextField/TextFormField
    final BuildContext? context = focus.context;
    if (context == null) return false;
    bool isEditable = false;
    context.visitAncestorElements((Element element) {
      if (element.widget is EditableText) {
        isEditable = true;
        return false;
      }
      return true;
    });
    return isEditable;
  }

  bool _isNavigationAction(GamepadAction action) {
    return action == GamepadAction.navigateUp ||
        action == GamepadAction.navigateDown ||
        action == GamepadAction.navigateLeft ||
        action == GamepadAction.navigateRight ||
        action == GamepadAction.confirm ||
        action == GamepadAction.back;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
