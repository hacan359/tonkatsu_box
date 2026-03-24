// Сервис для обработки событий геймпада.

import 'dart:async';

import 'package:gamepads/gamepads.dart';

import 'gamepad_mappings.dart';

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
/// - Нормализация аналоговых осей через [GamepadMapping] (кроссплатформенно)
/// - Маппинг D-pad в дискретные button-события
/// - Дедзона для аналоговых стиков (порог [stickDeadzone])
/// - Edge detection для триггеров (один раз при пересечении порога)
/// - Debounce для D-pad и кнопок ([buttonDebounceMs])
///
/// Для тестов можно передать кастомный [GamepadEventSource] и [GamepadMapping].
class GamepadService {
  /// Создаёт [GamepadService].
  ///
  /// [source] — источник событий (по умолчанию [RealGamepadEventSource]).
  /// [mapping] — платформенный маппинг (по умолчанию определяется автоматически).
  GamepadService({GamepadEventSource? source, GamepadMapping? mapping})
      : _source = source ?? RealGamepadEventSource(),
        _mapping = mapping ?? GamepadMapping.forCurrentPlatform();

  final GamepadEventSource _source;
  final GamepadMapping _mapping;
  StreamSubscription<GamepadEvent>? _subscription;
  final StreamController<GamepadServiceEvent> _controller =
      StreamController<GamepadServiceEvent>.broadcast();

  /// Дедзона для аналоговых стиков (нормализованное значение 0.0–1.0).
  static const double stickDeadzone = 0.3;

  /// Debounce для цифровых кнопок и D-pad (мс).
  static const int buttonDebounceMs = 150;

  /// Порог триггера для интерпретации как цифровое нажатие.
  static const double _triggerThreshold = 0.5;

  /// Последнее время нажатия каждой кнопки (для debounce).
  final Map<String, int> _lastButtonTime = <String, int>{};

  /// Последнее направление D-pad (для предотвращения повторных событий).
  String? _lastDpadDirection;

  /// Состояние триггера: -1 = LT, 0 = центр, 1 = RT.
  int _triggerState = 0;

  /// Текущий маппинг платформы (для debug screen).
  GamepadMapping get mapping => _mapping;

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
  /// Возвращает null если событие отфильтровано (дедзона, debounce,
  /// повторное D-pad направление, триггер в центральной зоне).
  GamepadServiceEvent? _mapEvent(GamepadEvent event) {
    final String key = event.key;
    final double value = event.value;

    // D-pad
    final String? dpadDirection = _mapping.mapDpad(key, value);
    if (dpadDirection != null) {
      return _mapDpad(dpadDirection, event);
    }
    // D-pad released (POV hat) — сброс состояния
    if (key == _mapping.povAxis && dpadDirection == null) {
      _lastDpadDirection = null;
      return null;
    }

    // Аналоговые стики
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

    // Триггеры
    if (_mapping.isTriggerAxis(key)) {
      return _mapTrigger(key, value, event);
    }

    // Цифровые кнопки (button-0 .. button-N)
    if (value == 1.0) {
      return _mapButton(key, event);
    }

    // Отпускание кнопки (value == 0.0) — не генерируем событие
    return null;
  }

  /// Маппинг D-pad направления с debounce и deduplicate.
  GamepadServiceEvent? _mapDpad(String direction, GamepadEvent rawEvent) {
    // Не повторяем то же направление (POV шлёт события непрерывно)
    if (direction == _lastDpadDirection) return null;
    _lastDpadDirection = direction;

    // Debounce
    final String syntheticKey = 'dpad-$direction';
    if (!_debounce(syntheticKey)) return null;

    return GamepadServiceEvent(
      key: syntheticKey,
      value: 1.0,
      type: GamepadServiceEventType.button,
      rawEvent: rawEvent,
    );
  }

  /// Маппинг кнопки с debounce.
  GamepadServiceEvent? _mapButton(String key, GamepadEvent rawEvent) {
    if (!_debounce(key)) return null;

    return GamepadServiceEvent(
      key: key,
      value: 1.0,
      type: GamepadServiceEventType.button,
      rawEvent: rawEvent,
    );
  }

  /// Edge detection для триггеров.
  ///
  /// Для shared axis (Windows dwZpos): нормализованное значение,
  /// отрицательное = LT, положительное = RT.
  /// Для separate axes (Linux/Android): каждый триггер отдельно.
  GamepadServiceEvent? _mapTrigger(
    String key,
    double value,
    GamepadEvent rawEvent,
  ) {
    final double normalized = _mapping.normalizeAxis(value);

    if (_mapping.triggersSharedAxis) {
      // Windows: общая ось — LT отрицательный, RT положительный
      final int newState;
      if (normalized < -_triggerThreshold) {
        newState = -1; // LT
      } else if (normalized > _triggerThreshold) {
        newState = 1; // RT
      } else {
        newState = 0; // Центр
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
      // Linux/Android: раздельные оси
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

  /// Debounce проверка. Возвращает true если событие прошло.
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

/// Тип обработанного события.
enum GamepadServiceEventType {
  /// Цифровая кнопка (A/B/D-pad/бамперы/Start).
  button,

  /// Аналоговый стик.
  analog,

  /// Триггер (аналоговый, edge detection).
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

  /// Ключ кнопки/оси (нормализованный).
  ///
  /// Кнопки: `button-0` .. `button-N`.
  /// D-pad: `dpad-up`, `dpad-down`, `dpad-left`, `dpad-right`.
  /// Стики: `stick-left-x`, `stick-left-y`, `stick-right-x`, `stick-right-y`.
  /// Триггеры: `trigger`.
  final String key;

  /// Нормализованное значение.
  ///
  /// Кнопки/D-pad: 1.0 (нажато).
  /// Стики: -1.0 .. 1.0 (после дедзоны).
  /// Триггеры: -1.0 (LT) / 1.0 (RT).
  final double value;

  /// Тип события.
  final GamepadServiceEventType type;

  /// Исходное сырое событие.
  final GamepadEvent rawEvent;

  @override
  String toString() => 'GamepadServiceEvent($key, $value, $type)';
}
