// Платформенные маппинги осей и кнопок геймпада.

import 'dart:io';

/// Конфигурация осей и кнопок для конкретной платформы.
///
/// Пакет `gamepads` возвращает разные key names в зависимости от ОС:
/// - Windows: JOYINFOEX (`dwXpos`, `pov`, 0–65535)
/// - Linux: `/dev/input/js*` (`abs-x`, `abs-hat0x`, -32767–32767)
/// - Android: аналогично Linux
abstract class GamepadMapping {
  /// Создаёт [GamepadMapping].
  const GamepadMapping();

  /// Имена осей стиков.
  String get leftStickX;
  String get leftStickY;
  String get rightStickX;
  String get rightStickY;

  /// Имена осей триггеров.
  String get leftTrigger;
  String get rightTrigger;

  /// Windows использует общую ось dwZpos для обоих триггеров.
  bool get triggersSharedAxis;

  /// Имя оси D-pad (POV hat или null для axis-based D-pad).
  String? get povAxis;

  /// Нормализация значения оси в -1.0..1.0.
  double normalizeAxis(double rawValue);

  /// Маппинг D-pad raw key+value → синтетическое направление.
  ///
  /// Возвращает `'up'`, `'down'`, `'left'`, `'right'` или null.
  String? mapDpad(String rawKey, double value);

  /// Проверяет является ли ключ осью стика.
  bool isStickAxis(String key) {
    return key == leftStickX ||
        key == leftStickY ||
        key == rightStickX ||
        key == rightStickY;
  }

  /// Проверяет является ли ключ осью триггера.
  bool isTriggerAxis(String key) {
    if (triggersSharedAxis) {
      return key == leftTrigger; // одна общая ось
    }
    return key == leftTrigger || key == rightTrigger;
  }

  /// Нормализует платформенный axis key в единый формат.
  String normalizeAxisKey(String key) {
    if (key == leftStickX) return 'stick-left-x';
    if (key == leftStickY) return 'stick-left-y';
    if (key == rightStickX) return 'stick-right-x';
    if (key == rightStickY) return 'stick-right-y';
    return key;
  }

  /// Возвращает маппинг для текущей платформы.
  static GamepadMapping forCurrentPlatform() {
    if (Platform.isWindows) return const WindowsGamepadMapping();
    if (Platform.isLinux) return const LinuxGamepadMapping();
    if (Platform.isAndroid) return const AndroidGamepadMapping();
    return const WindowsGamepadMapping(); // fallback
  }
}

/// Windows маппинг (JOYINFOEX).
///
/// Оси: 0–65535, центр ~32767.
/// D-pad: POV hat в градусах×100 (0/9000/18000/27000/65535).
/// Триггеры: общая ось dwZpos.
class WindowsGamepadMapping extends GamepadMapping {
  /// Создаёт [WindowsGamepadMapping].
  const WindowsGamepadMapping();

  @override
  String get leftStickX => 'dwXpos';
  @override
  String get leftStickY => 'dwYpos';
  @override
  String get rightStickX => 'dwRpos';
  @override
  String get rightStickY => 'dwUpos';
  @override
  String get leftTrigger => 'dwZpos';
  @override
  String get rightTrigger => 'dwZpos';
  @override
  bool get triggersSharedAxis => true;
  @override
  String? get povAxis => 'pov';

  static const double _axisCenter = 32767.5;
  static const double _axisRange = 32767.5;

  @override
  double normalizeAxis(double rawValue) {
    return ((rawValue - _axisCenter) / _axisRange).clamp(-1.0, 1.0);
  }

  @override
  String? mapDpad(String rawKey, double value) {
    if (rawKey != 'pov') return null;
    final int pov = value.round();
    return switch (pov) {
      0 => 'up',
      9000 => 'right',
      18000 => 'down',
      27000 => 'left',
      _ => null, // released (65535) или диагонали
    };
  }
}

/// Linux маппинг (/dev/input/js*).
///
/// Оси: -32767–32767.
/// D-pad: abs-hat0x (left/right), abs-hat0y (up/down).
/// Триггеры: отдельные оси abs-z (LT), abs-rz (RT).
class LinuxGamepadMapping extends GamepadMapping {
  /// Создаёт [LinuxGamepadMapping].
  const LinuxGamepadMapping();

  @override
  String get leftStickX => 'abs-x';
  @override
  String get leftStickY => 'abs-y';
  @override
  String get rightStickX => 'abs-rx';
  @override
  String get rightStickY => 'abs-ry';
  @override
  String get leftTrigger => 'abs-z';
  @override
  String get rightTrigger => 'abs-rz';
  @override
  bool get triggersSharedAxis => false;
  @override
  String? get povAxis => null; // axis-based D-pad

  @override
  double normalizeAxis(double rawValue) {
    return (rawValue / 32767.0).clamp(-1.0, 1.0);
  }

  @override
  String? mapDpad(String rawKey, double value) {
    if (rawKey == 'abs-hat0x') {
      if (value > 0) return 'right';
      if (value < 0) return 'left';
      return null;
    }
    if (rawKey == 'abs-hat0y') {
      if (value < 0) return 'up';
      if (value > 0) return 'down';
      return null;
    }
    return null;
  }

  @override
  bool isStickAxis(String key) {
    return super.isStickAxis(key) &&
        key != 'abs-hat0x' &&
        key != 'abs-hat0y';
  }
}

/// Android маппинг.
///
/// Аналогичен Linux — пакет gamepads использует те же ключи.
/// Может потребовать корректировки после тестирования на реальных устройствах.
class AndroidGamepadMapping extends LinuxGamepadMapping {
  /// Создаёт [AndroidGamepadMapping].
  const AndroidGamepadMapping();
}
