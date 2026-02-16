// Сервис для обработки событий геймпада.

import 'dart:async';

import 'package:gamepads/gamepads.dart';

/// Абстракция источника событий геймпада (для тестов).
abstract class GamepadEventSource {
  /// Стрим сырых событий от геймпада.
  Stream<GamepadEvent> get events;
}

/// Реальный источник событий через пакет gamepads.
class RealGamepadEventSource implements GamepadEventSource {
  @override
  Stream<GamepadEvent> get events => Gamepads.events;
}

/// Сервис обработки событий геймпада.
///
/// Преобразует сырые [GamepadEvent] в семантические [GamepadServiceEvent]:
/// - Маппинг кнопок по ключам (platform-specific)
/// - Дедзона для аналоговых стиков (порог [stickDeadzone])
/// - Debounce для D-pad и кнопок ([buttonDebounceMs])
///
/// Для тестов можно передать кастомный [GamepadEventSource].
class GamepadService {
  /// Создаёт [GamepadService].
  ///
  /// [source] — источник событий (по умолчанию [RealGamepadEventSource]).
  GamepadService({GamepadEventSource? source})
      : _source = source ?? RealGamepadEventSource();

  final GamepadEventSource _source;
  StreamSubscription<GamepadEvent>? _subscription;
  final StreamController<GamepadServiceEvent> _controller =
      StreamController<GamepadServiceEvent>.broadcast();

  /// Дедзона для аналоговых стиков (0.0–1.0).
  static const double stickDeadzone = 0.3;

  /// Debounce для цифровых кнопок (мс).
  static const int buttonDebounceMs = 150;

  /// Последнее время нажатия каждой кнопки (для debounce).
  final Map<String, int> _lastButtonTime = <String, int>{};

  /// Стрим обработанных событий.
  Stream<GamepadServiceEvent> get events => _controller.stream;

  /// Стрим сырых событий (для debug-панели).
  Stream<GamepadEvent> get rawEvents => _source.events;

  /// Запускает прослушивание событий геймпада.
  void start() {
    _subscription?.cancel();
    _subscription = _source.events.listen(_handleRawEvent);
  }

  /// Останавливает прослушивание.
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

  /// Маппит сырое событие в сервисное.
  ///
  /// Возвращает null если событие отфильтровано (дедзона, debounce).
  GamepadServiceEvent? _mapEvent(GamepadEvent event) {
    final String key = event.key;
    final double value = event.value;

    // Аналоговые стики — фильтр по дедзоне
    if (_isStickAxis(key)) {
      if (value.abs() < stickDeadzone) return null;
      return GamepadServiceEvent(
        key: key,
        value: value,
        type: GamepadServiceEventType.analog,
        rawEvent: event,
      );
    }

    // Триггеры — аналоговые значения
    if (_isTrigger(key)) {
      return GamepadServiceEvent(
        key: key,
        value: value,
        type: GamepadServiceEventType.trigger,
        rawEvent: event,
      );
    }

    // Цифровые кнопки (D-pad, A/B/X/Y, бамперы, Start)
    if (value == 1.0) {
      // Нажатие — с debounce
      final int now = DateTime.now().millisecondsSinceEpoch;
      final int? lastTime = _lastButtonTime[key];
      if (lastTime != null && (now - lastTime) < buttonDebounceMs) {
        return null;
      }
      _lastButtonTime[key] = now;

      return GamepadServiceEvent(
        key: key,
        value: value,
        type: GamepadServiceEventType.button,
        rawEvent: event,
      );
    }

    // Отпускание кнопки (value == 0.0) — не генерируем событие
    return null;
  }

  bool _isStickAxis(String key) {
    return key.contains('leftStick') ||
        key.contains('rightStick') ||
        key.contains('left.x') ||
        key.contains('left.y') ||
        key.contains('right.x') ||
        key.contains('right.y');
  }

  bool _isTrigger(String key) {
    return key.contains('trigger') ||
        key.contains('Trigger') ||
        key == '4' ||
        key == '5';
  }
}

/// Тип обработанного события.
enum GamepadServiceEventType {
  /// Цифровая кнопка (A/B/D-pad/бамперы/Start).
  button,

  /// Аналоговый стик.
  analog,

  /// Триггер (аналоговый).
  trigger,
}

/// Обработанное событие геймпада.
class GamepadServiceEvent {
  /// Создаёт [GamepadServiceEvent].
  const GamepadServiceEvent({
    required this.key,
    required this.value,
    required this.type,
    required this.rawEvent,
  });

  /// Ключ кнопки/оси (platform-specific).
  final String key;

  /// Значение (0.0–1.0 для кнопок, -1.0–1.0 для стиков).
  final double value;

  /// Тип события.
  final GamepadServiceEventType type;

  /// Исходное сырое событие.
  final GamepadEvent rawEvent;

  @override
  String toString() => 'GamepadServiceEvent($key, $value, $type)';
}
