// Riverpod провайдеры для геймпада.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/gamepad_service.dart';
import '../constants/platform_features.dart';
import 'gamepad_action.dart';

/// Провайдер сервиса геймпада (singleton).
///
/// На мобильных платформах (Android/iOS) сервис создаётся, но не запускается —
/// подписка на Gamepads.events не нужна и создаёт лишнюю нагрузку при старте.
final Provider<GamepadService> gamepadServiceProvider =
    Provider<GamepadService>((Ref ref) {
  final GamepadService service = GamepadService();
  if (!kIsMobile) {
    service.start();
  }
  ref.onDispose(service.dispose);
  return service;
});

/// Провайдер режима ввода (mouse / gamepad).
final NotifierProvider<InputModeNotifier, InputMode> inputModeProvider =
    NotifierProvider<InputModeNotifier, InputMode>(InputModeNotifier.new);

/// Нотифаер режима ввода.
class InputModeNotifier extends Notifier<InputMode> {
  @override
  InputMode build() => InputMode.mouse;

  /// Переключить на gamepad-режим.
  void setGamepadMode() {
    if (state != InputMode.gamepad) {
      state = InputMode.gamepad;
    }
  }

  /// Переключить на mouse-режим.
  void setMouseMode() {
    if (state != InputMode.mouse) {
      state = InputMode.mouse;
    }
  }
}

/// Провайдер стрима обработанных событий геймпада.
final StreamProvider<GamepadServiceEvent> gamepadEventProvider =
    StreamProvider<GamepadServiceEvent>((Ref ref) {
  final GamepadService service = ref.watch(gamepadServiceProvider);
  return service.events;
});
