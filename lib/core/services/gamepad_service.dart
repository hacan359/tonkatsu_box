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
/// - Нормализация аналоговых осей Windows JOYINFOEX (0–65535 → -1.0–1.0)
/// - Маппинг D-pad POV hat в дискретные button-события
/// - Дедзона для аналоговых стиков (порог [stickDeadzone])
/// - Edge detection для триггеров (один раз при пересечении порога)
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

  /// Дедзона для аналоговых стиков (нормализованное значение 0.0–1.0).
  static const double stickDeadzone = 0.3;

  /// Debounce для цифровых кнопок и D-pad (мс).
  static const int buttonDebounceMs = 150;

  /// Центр диапазона Windows JOYINFOEX (16-bit unsigned).
  static const double _axisCenter = 32767.5;

  /// Полуразмах диапазона для нормализации в -1.0..1.0.
  static const double _axisRange = 32767.5;

  /// Порог триггера для интерпретации как цифровое нажатие.
  static const double _triggerThreshold = 0.5;

  // POV hat значения (degrees × 100 в JOYINFOEX).
  static const int _povUp = 0;
  static const int _povRight = 9000;
  static const int _povDown = 18000;
  static const int _povLeft = 27000;
  static const int _povReleased = 65535;

  /// Последнее время нажатия каждой кнопки (для debounce).
  final Map<String, int> _lastButtonTime = <String, int>{};

  /// Последнее направление D-pad (для предотвращения повторных событий).
  String? _lastPovDirection;

  /// Состояние триггера: -1 = LT, 0 = центр, 1 = RT.
  int _triggerState = 0;

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
  /// повторное POV-направление, триггер в центральной зоне).
  GamepadServiceEvent? _mapEvent(GamepadEvent event) {
    final String key = event.key;
    final double value = event.value;

    // D-pad (POV hat switch)
    if (key == 'pov') {
      return _mapPov(value, event);
    }

    // Аналоговые стики: dwXpos, dwYpos (left), dwRpos, dwUpos (right)
    if (_isStickAxis(key)) {
      final double normalized =
          ((value - _axisCenter) / _axisRange).clamp(-1.0, 1.0);
      if (normalized.abs() < stickDeadzone) return null;
      return GamepadServiceEvent(
        key: key,
        value: normalized,
        type: GamepadServiceEventType.analog,
        rawEvent: event,
      );
    }

    // Триггеры: dwZpos (общая ось LT/RT)
    if (key == 'dwZpos') {
      return _mapTrigger(value, event);
    }

    // Цифровые кнопки (button-0 .. button-7)
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

  /// Маппинг POV hat в кнопочные события.
  ///
  /// POV отправляет значения в сотых долях градуса:
  /// 0=вверх, 9000=вправо, 18000=вниз, 27000=влево, 65535=отпущено.
  /// Диагонали (4500, 13500, 22500, 31500) игнорируются.
  ///
  /// Направление трекается: повторное событие с тем же направлением
  /// не генерируется (POV шлёт события непрерывно при удержании).
  GamepadServiceEvent? _mapPov(double value, GamepadEvent rawEvent) {
    final int pov = value.round();
    final String? direction = _povToDirection(pov);

    if (direction == null) {
      // Отпущено или неизвестное значение — сброс состояния
      _lastPovDirection = null;
      return null;
    }

    // Не повторяем то же направление (POV шлёт события непрерывно)
    if (direction == _lastPovDirection) return null;
    _lastPovDirection = direction;

    // Debounce
    final String syntheticKey = 'dpad-$direction';
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int? lastTime = _lastButtonTime[syntheticKey];
    if (lastTime != null && (now - lastTime) < buttonDebounceMs) {
      return null;
    }
    _lastButtonTime[syntheticKey] = now;

    return GamepadServiceEvent(
      key: syntheticKey,
      value: 1.0,
      type: GamepadServiceEventType.button,
      rawEvent: rawEvent,
    );
  }

  /// Edge detection для триггеров.
  ///
  /// Windows Xbox контроллер использует общую ось [dwZpos] для LT и RT:
  /// - Центр (~32767) = ни один триггер не нажат
  /// - Значения ниже = LT нажат (нормализованное < -[_triggerThreshold])
  /// - Значения выше = RT нажат (нормализованное > [_triggerThreshold])
  ///
  /// Событие генерируется только при пересечении порога (один раз за нажатие).
  GamepadServiceEvent? _mapTrigger(double value, GamepadEvent rawEvent) {
    final double normalized =
        ((value - _axisCenter) / _axisRange).clamp(-1.0, 1.0);

    final int newState;
    if (normalized < -_triggerThreshold) {
      newState = -1; // LT нажат
    } else if (normalized > _triggerThreshold) {
      newState = 1; // RT нажат
    } else {
      newState = 0; // Центр — ни один триггер
    }

    // Нет изменения состояния — не генерируем событие
    if (newState == _triggerState) return null;
    _triggerState = newState;

    // Возврат в центр — сброс без события
    if (newState == 0) return null;

    return GamepadServiceEvent(
      key: 'dwZpos',
      value: normalized,
      type: GamepadServiceEventType.trigger,
      rawEvent: rawEvent,
    );
  }

  String? _povToDirection(int pov) {
    switch (pov) {
      case _povUp:
        return 'up';
      case _povRight:
        return 'right';
      case _povDown:
        return 'down';
      case _povLeft:
        return 'left';
      case _povReleased:
        return null;
      default:
        return null; // Диагонали и прочее — игнорируем
    }
  }

  bool _isStickAxis(String key) {
    return key == 'dwXpos' ||
        key == 'dwYpos' ||
        key == 'dwRpos' ||
        key == 'dwUpos';
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

  /// Ключ кнопки/оси.
  ///
  /// Для кнопок: `button-0` .. `button-7`.
  /// Для D-pad: `dpad-up`, `dpad-down`, `dpad-left`, `dpad-right`.
  /// Для стиков: `dwXpos`, `dwYpos`, `dwRpos`, `dwUpos`.
  /// Для триггеров: `dwZpos`.
  final String key;

  /// Нормализованное значение.
  ///
  /// Кнопки/D-pad: 1.0 (нажато).
  /// Стики: -1.0 .. 1.0 (после дедзоны).
  /// Триггеры: -1.0 (LT) .. 1.0 (RT).
  final double value;

  /// Тип события.
  final GamepadServiceEventType type;

  /// Исходное сырое событие.
  final GamepadEvent rawEvent;

  @override
  String toString() => 'GamepadServiceEvent($key, $value, $type)';
}
