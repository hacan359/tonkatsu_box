import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/gamepad_service.dart';
import '../constants/platform_features.dart';
import 'gamepad_action.dart';

/// On iOS and Windows the service is created but never started — Windows
/// polling crashes the native plugin.
final Provider<GamepadService> gamepadServiceProvider =
    Provider<GamepadService>((Ref ref) {
  final GamepadService service = GamepadService();
  if (kGamepadSupported) {
    service.start();
  }
  ref.onDispose(service.dispose);
  return service;
});

/// Input mode provider (mouse / gamepad).
final NotifierProvider<InputModeNotifier, InputMode> inputModeProvider =
    NotifierProvider<InputModeNotifier, InputMode>(InputModeNotifier.new);

/// Input mode notifier.
class InputModeNotifier extends Notifier<InputMode> {
  @override
  InputMode build() => InputMode.mouse;

  /// Switch to gamepad mode.
  void setGamepadMode() {
    if (state != InputMode.gamepad) {
      state = InputMode.gamepad;
    }
  }

  /// Switch to mouse mode.
  void setMouseMode() {
    if (state != InputMode.mouse) {
      state = InputMode.mouse;
    }
  }
}

/// Stream provider of processed gamepad events.
final StreamProvider<GamepadServiceEvent> gamepadEventProvider =
    StreamProvider<GamepadServiceEvent>((Ref ref) {
  final GamepadService service = ref.watch(gamepadServiceProvider);
  return service.events;
});
