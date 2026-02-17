// Виджет-обёртка для прослушивания событий геймпада.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/gamepad_service.dart';
import '../../../shared/constants/platform_features.dart';
import '../gamepad_action.dart';
import '../gamepad_provider.dart';

/// Виджет-обёртка, прослушивающая события геймпада и вызывающая callbacks.
///
/// Оборачивает дочерний виджет и подписывается на [gamepadServiceProvider].
/// При получении события определяет тип и вызывает соответствующий callback.
///
/// При фокусе на TextField:
/// - D-pad Up/Down — выход из TextField и навигация к соседнему виджету
/// - D-pad Left/Right — заблокированы (курсор в тексте)
/// - A — заблокирован (ввод текста)
/// - B — снятие фокуса с TextField
///
/// Маппинг кнопок Xbox контроллера (Windows JOYINFOEX):
/// - `button-0` (A) → confirm
/// - `button-1` (B) → back
/// - `button-4` (LB) → previousTab
/// - `button-5` (RB) → nextTab
/// - `button-7` (Start) → openMenu
/// - `dpad-*` (POV hat) → navigate
/// - `dwXpos`/`dwYpos` (Left Stick) → scroll
/// - `dwRpos`/`dwUpos` (Right Stick) → pan
/// - `dwZpos` (Triggers) → sub-tab switch
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
    // На мобильных платформах геймпад не используется — пропускаем подписку.
    if (!kIsMobile) {
      final GamepadService service = ref.read(gamepadServiceProvider);
      _subscription = service.events.listen(_handleEvent);
    }
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
        return;
      }
      if (action == GamepadAction.navigateUp ||
          action == GamepadAction.navigateDown) {
        // D-pad Up/Down → выйти из TextField и перейти к соседнему виджету
        final FocusNode? focus = FocusManager.instance.primaryFocus;
        final BuildContext? focusContext = focus?.context;
        if (focusContext != null) {
          focus!.unfocus();
          // Перемещаем фокус в направлении D-pad
          final TraversalDirection direction =
              action == GamepadAction.navigateUp
                  ? TraversalDirection.up
                  : TraversalDirection.down;
          Actions.maybeInvoke(
            focusContext,
            DirectionalFocusIntent(direction),
          );
        }
        return;
      }
      // D-pad Left/Right, A — заблокированы в TextField (курсор / ввод)
      return;
    }

    _dispatchAction(action);
  }

  GamepadAction? _mapServiceEvent(GamepadServiceEvent event) {
    switch (event.type) {
      case GamepadServiceEventType.button:
        return _mapButton(event.key);
      case GamepadServiceEventType.analog:
        return _mapAnalog(event.key, event.value);
      case GamepadServiceEventType.trigger:
        return _mapTrigger(event.value);
    }
  }

  /// Маппинг цифровых кнопок и D-pad.
  ///
  /// Ключи соответствуют Windows JOYINFOEX / gamepads_windows:
  /// - `button-0` .. `button-7` — кнопки контроллера
  /// - `dpad-*` — синтетические ключи от [GamepadService] для POV hat
  GamepadAction? _mapButton(String key) {
    switch (key) {
      // Xbox кнопки
      case 'button-0': // A
        return GamepadAction.confirm;
      case 'button-1': // B
        return GamepadAction.back;
      // button-2 = X, button-3 = Y — не назначены
      case 'button-4': // LB (Left Bumper)
        return GamepadAction.previousTab;
      case 'button-5': // RB (Right Bumper)
        return GamepadAction.nextTab;
      // button-6 = Back/Select — не назначена
      case 'button-7': // Start/Menu
        return GamepadAction.openMenu;
      // D-pad (синтетические ключи от GamepadService)
      case 'dpad-up':
        return GamepadAction.navigateUp;
      case 'dpad-down':
        return GamepadAction.navigateDown;
      case 'dpad-left':
        return GamepadAction.navigateLeft;
      case 'dpad-right':
        return GamepadAction.navigateRight;
      default:
        return null;
    }
  }

  /// Маппинг аналоговых стиков.
  ///
  /// Значения нормализованы [GamepadService]: -1.0 (лево/верх) .. 1.0 (право/низ).
  /// - `dwXpos`/`dwYpos` — Left Stick → скролл
  /// - `dwRpos`/`dwUpos` — Right Stick → панорама
  GamepadAction? _mapAnalog(String key, double value) {
    switch (key) {
      case 'dwXpos': // Left Stick X → горизонтальный скролл
        return value > 0
            ? GamepadAction.scrollRight
            : GamepadAction.scrollLeft;
      case 'dwYpos': // Left Stick Y → вертикальный скролл
        return value > 0 ? GamepadAction.scrollDown : GamepadAction.scrollUp;
      case 'dwRpos': // Right Stick X → горизонтальная панорама
        return value > 0 ? GamepadAction.panRight : GamepadAction.panLeft;
      case 'dwUpos': // Right Stick Y → вертикальная панорама
        return value > 0 ? GamepadAction.panDown : GamepadAction.panUp;
      default:
        return null;
    }
  }

  /// Маппинг триггеров в переключение суб-табов.
  ///
  /// Значение нормализовано [GamepadService]: отрицательное = LT, положительное = RT.
  /// Edge detection уже применён в сервисе — приходит одно событие за нажатие.
  GamepadAction? _mapTrigger(double value) {
    if (value < 0) {
      return GamepadAction.previousSubTab; // LT
    }
    return GamepadAction.nextSubTab; // RT
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
