import 'dart:io';

/// The `gamepads` package returns different axis/button key names per OS:
/// Windows JOYINFOEX (`dwXpos`, `pov`, 0–65535); Linux and Android use
/// `/dev/input/js*` style keys (`abs-x`, `abs-hat0x`, -32767–32767).
abstract class GamepadMapping {
  const GamepadMapping();

  String get leftStickX;
  String get leftStickY;
  String get rightStickX;
  String get rightStickY;

  String get leftTrigger;
  String get rightTrigger;

  /// Windows uses a single shared dwZpos axis for both triggers.
  bool get triggersSharedAxis;

  /// D-pad axis name (POV hat), or null for axis-based D-pads.
  String? get povAxis;

  /// Normalizes a raw axis value to -1.0..1.0.
  double normalizeAxis(double rawValue);

  /// Maps a raw D-pad key+value to `'up'`, `'down'`, `'left'`, `'right'`,
  /// or null.
  String? mapDpad(String rawKey, double value);

  bool isStickAxis(String key) {
    return key == leftStickX ||
        key == leftStickY ||
        key == rightStickX ||
        key == rightStickY;
  }

  bool isTriggerAxis(String key) {
    if (triggersSharedAxis) {
      return key == leftTrigger; // single shared axis
    }
    return key == leftTrigger || key == rightTrigger;
  }

  String normalizeAxisKey(String key) {
    if (key == leftStickX) return 'stick-left-x';
    if (key == leftStickY) return 'stick-left-y';
    if (key == rightStickX) return 'stick-right-x';
    if (key == rightStickY) return 'stick-right-y';
    return key;
  }

  static GamepadMapping forCurrentPlatform() {
    if (Platform.isWindows) return const WindowsGamepadMapping();
    if (Platform.isLinux) return const LinuxGamepadMapping();
    if (Platform.isAndroid) return const AndroidGamepadMapping();
    return const WindowsGamepadMapping(); // fallback
  }
}

/// Windows JOYINFOEX mapping: axes 0–65535 (center ~32767), D-pad as a POV
/// hat in degrees×100 (0/9000/18000/27000/65535), triggers share dwZpos.
class WindowsGamepadMapping extends GamepadMapping {
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
      _ => null, // released (65535) or diagonals
    };
  }
}

/// Linux /dev/input/js* mapping: axes -32767–32767, D-pad via abs-hat0x and
/// abs-hat0y axes, separate trigger axes abs-z (LT) and abs-rz (RT).
class LinuxGamepadMapping extends GamepadMapping {
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

/// Same as Linux — the gamepads package uses the same keys there. May need
/// adjustment after testing on real devices.
class AndroidGamepadMapping extends LinuxGamepadMapping {
  const AndroidGamepadMapping();
}
