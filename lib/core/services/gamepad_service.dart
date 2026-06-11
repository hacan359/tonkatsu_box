import 'dart:async';

import 'package:gamepads/gamepads.dart';

import 'gamepad_mappings.dart';

/// Gamepad event source abstraction (swappable in tests).
abstract class GamepadEventSource {
  Stream<GamepadEvent> get events;
}

class RealGamepadEventSource implements GamepadEventSource {
  @override
  Stream<GamepadEvent> get events => Gamepads.events;
}

/// Maps raw [GamepadEvent]s to semantic [GamepadServiceEvent]s: applies the
/// stick deadzone, trigger edge detection, and button/D-pad debounce.
class GamepadService {
  GamepadService({GamepadEventSource? source, GamepadMapping? mapping})
      : _source = source ?? RealGamepadEventSource(),
        _mapping = mapping ?? GamepadMapping.forCurrentPlatform();

  final GamepadEventSource _source;
  final GamepadMapping _mapping;
  StreamSubscription<GamepadEvent>? _subscription;
  final StreamController<GamepadServiceEvent> _controller =
      StreamController<GamepadServiceEvent>.broadcast();

  /// Stick deadzone, in normalized units (0.0–1.0).
  static const double stickDeadzone = 0.3;

  /// Debounce for digital buttons and the D-pad, in milliseconds.
  static const int buttonDebounceMs = 150;

  /// Threshold above which a trigger counts as a digital press.
  static const double _triggerThreshold = 0.5;

  final Map<String, int> _lastButtonTime = <String, int>{};

  /// Last D-pad direction, used to drop repeated events.
  String? _lastDpadDirection;

  /// Trigger state: -1 = LT, 0 = center, 1 = RT.
  int _triggerState = 0;

  /// Exposed for the debug screen.
  GamepadMapping get mapping => _mapping;

  Stream<GamepadServiceEvent> get events => _controller.stream;

  /// Raw event stream for the debug panel.
  Stream<GamepadEvent> get rawEvents => _source.events;

  void start() {
    _subscription?.cancel();
    _subscription = _source.events.listen(_handleRawEvent);
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _controller.close();
  }

  void _handleRawEvent(GamepadEvent event) {
    final GamepadServiceEvent? mapped = _mapEvent(event);
    if (mapped != null) {
      _controller.add(mapped);
    }
  }

  /// Returns null when the event is filtered out (deadzone, debounce,
  /// repeated D-pad direction, trigger in the center zone).
  GamepadServiceEvent? _mapEvent(GamepadEvent event) {
    final String key = event.key;
    final double value = event.value;

    final String? dpadDirection = _mapping.mapDpad(key, value);
    if (dpadDirection != null) {
      return _mapDpad(dpadDirection, event);
    }
    // D-pad released (POV hat): reset state
    if (key == _mapping.povAxis && dpadDirection == null) {
      _lastDpadDirection = null;
      return null;
    }

    if (_mapping.isStickAxis(key)) {
      final double normalized = _mapping.normalizeAxis(value);
      if (normalized.abs() < stickDeadzone) return null;
      return GamepadServiceEvent(
        key: _mapping.normalizeAxisKey(key),
        value: normalized,
        type: GamepadServiceEventType.analog,
        rawEvent: event,
      );
    }

    if (_mapping.isTriggerAxis(key)) {
      return _mapTrigger(key, value, event);
    }

    // Digital buttons (button-0 .. button-N)
    if (value == 1.0) {
      return _mapButton(key, event);
    }

    // Button release (value == 0.0): no event
    return null;
  }

  GamepadServiceEvent? _mapDpad(String direction, GamepadEvent rawEvent) {
    // POV hats emit events continuously; drop repeats of the same direction
    if (direction == _lastDpadDirection) return null;
    _lastDpadDirection = direction;

    final String syntheticKey = 'dpad-$direction';
    if (!_debounce(syntheticKey)) return null;

    return GamepadServiceEvent(
      key: syntheticKey,
      value: 1.0,
      type: GamepadServiceEventType.button,
      rawEvent: rawEvent,
    );
  }

  GamepadServiceEvent? _mapButton(String key, GamepadEvent rawEvent) {
    if (!_debounce(key)) return null;

    return GamepadServiceEvent(
      key: key,
      value: 1.0,
      type: GamepadServiceEventType.button,
      rawEvent: rawEvent,
    );
  }

  /// On a shared axis (Windows dwZpos) the normalized value is negative for
  /// LT and positive for RT; separate axes (Linux/Android) map individually.
  GamepadServiceEvent? _mapTrigger(
    String key,
    double value,
    GamepadEvent rawEvent,
  ) {
    final double normalized = _mapping.normalizeAxis(value);

    if (_mapping.triggersSharedAxis) {
      final int newState;
      if (normalized < -_triggerThreshold) {
        newState = -1; // LT
      } else if (normalized > _triggerThreshold) {
        newState = 1; // RT
      } else {
        newState = 0; // center
      }

      if (newState == _triggerState) return null;
      _triggerState = newState;
      if (newState == 0) return null;

      return GamepadServiceEvent(
        key: 'trigger',
        value: newState.toDouble(),
        type: GamepadServiceEventType.trigger,
        rawEvent: rawEvent,
      );
    } else {
      final bool isLeft = key == _mapping.leftTrigger;
      final bool pressed = normalized.abs() > _triggerThreshold;
      final int newState = pressed ? (isLeft ? -1 : 1) : 0;

      if (newState == _triggerState) return null;
      _triggerState = newState;
      if (newState == 0) return null;

      return GamepadServiceEvent(
        key: 'trigger',
        value: newState.toDouble(),
        type: GamepadServiceEventType.trigger,
        rawEvent: rawEvent,
      );
    }
  }

  /// Returns true if the event passes the debounce window.
  bool _debounce(String key) {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int? lastTime = _lastButtonTime[key];
    if (lastTime != null && (now - lastTime) < buttonDebounceMs) {
      return false;
    }
    _lastButtonTime[key] = now;
    return true;
  }
}

enum GamepadServiceEventType {
  /// Digital button (A/B/D-pad/bumpers/Start).
  button,

  /// Analog stick.
  analog,

  /// Trigger (analog, edge-detected).
  trigger,
}

class GamepadServiceEvent {
  const GamepadServiceEvent({
    required this.key,
    required this.value,
    required this.type,
    required this.rawEvent,
  });

  /// Normalized key: `button-0`..`button-N`, `dpad-{up,down,left,right}`,
  /// `stick-{left,right}-{x,y}`, or `trigger`.
  final String key;

  /// Buttons/D-pad: 1.0 (pressed). Sticks: -1.0..1.0 (post-deadzone).
  /// Triggers: -1.0 (LT) / 1.0 (RT).
  final double value;

  final GamepadServiceEventType type;

  final GamepadEvent rawEvent;

  @override
  String toString() => 'GamepadServiceEvent($key, $value, $type)';
}
