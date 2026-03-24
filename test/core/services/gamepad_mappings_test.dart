// Тесты для GamepadMapping — платформенные маппинги осей и кнопок.

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/core/services/gamepad_mappings.dart';

void main() {
  group('WindowsGamepadMapping', () {
    const WindowsGamepadMapping mapping = WindowsGamepadMapping();

    group('normalizeAxis', () {
      test('should return ~1.0 for max value (65535)', () {
        expect(mapping.normalizeAxis(65535), closeTo(1.0, 0.01));
      });

      test('should return ~-1.0 for min value (0)', () {
        expect(mapping.normalizeAxis(0), closeTo(-1.0, 0.01));
      });

      test('should return ~0.0 for center value (32767)', () {
        expect(mapping.normalizeAxis(32767), closeTo(0.0, 0.01));
      });
    });

    group('mapDpad', () {
      test('should return up for POV 0', () {
        expect(mapping.mapDpad('pov', 0), 'up');
      });

      test('should return right for POV 9000', () {
        expect(mapping.mapDpad('pov', 9000), 'right');
      });

      test('should return down for POV 18000', () {
        expect(mapping.mapDpad('pov', 18000), 'down');
      });

      test('should return left for POV 27000', () {
        expect(mapping.mapDpad('pov', 27000), 'left');
      });

      test('should return null for POV 65535 (released)', () {
        expect(mapping.mapDpad('pov', 65535), isNull);
      });

      test('should return null for diagonals', () {
        expect(mapping.mapDpad('pov', 4500), isNull);
        expect(mapping.mapDpad('pov', 13500), isNull);
      });

      test('should return null for non-pov key', () {
        expect(mapping.mapDpad('dwXpos', 0), isNull);
      });
    });

    group('isStickAxis', () {
      test('should recognize all 4 stick axes', () {
        expect(mapping.isStickAxis('dwXpos'), isTrue);
        expect(mapping.isStickAxis('dwYpos'), isTrue);
        expect(mapping.isStickAxis('dwRpos'), isTrue);
        expect(mapping.isStickAxis('dwUpos'), isTrue);
      });

      test('should reject non-stick keys', () {
        expect(mapping.isStickAxis('pov'), isFalse);
        expect(mapping.isStickAxis('dwZpos'), isFalse);
        expect(mapping.isStickAxis('button-0'), isFalse);
      });
    });

    group('isTriggerAxis', () {
      test('should recognize shared trigger axis', () {
        expect(mapping.isTriggerAxis('dwZpos'), isTrue);
      });

      test('should reject non-trigger keys', () {
        expect(mapping.isTriggerAxis('dwXpos'), isFalse);
      });
    });

    group('normalizeAxisKey', () {
      test('should normalize Windows axis names', () {
        expect(mapping.normalizeAxisKey('dwXpos'), 'stick-left-x');
        expect(mapping.normalizeAxisKey('dwYpos'), 'stick-left-y');
        expect(mapping.normalizeAxisKey('dwRpos'), 'stick-right-x');
        expect(mapping.normalizeAxisKey('dwUpos'), 'stick-right-y');
      });

      test('should pass through unknown keys', () {
        expect(mapping.normalizeAxisKey('unknown'), 'unknown');
      });
    });

    test('triggersSharedAxis should be true', () {
      expect(mapping.triggersSharedAxis, isTrue);
    });

    test('povAxis should be pov', () {
      expect(mapping.povAxis, 'pov');
    });
  });

  group('LinuxGamepadMapping', () {
    const LinuxGamepadMapping mapping = LinuxGamepadMapping();

    group('normalizeAxis', () {
      test('should return ~1.0 for max value (32767)', () {
        expect(mapping.normalizeAxis(32767), closeTo(1.0, 0.01));
      });

      test('should return ~-1.0 for min value (-32767)', () {
        expect(mapping.normalizeAxis(-32767), closeTo(-1.0, 0.01));
      });

      test('should return 0.0 for center (0)', () {
        expect(mapping.normalizeAxis(0), 0.0);
      });
    });

    group('mapDpad', () {
      test('should return right for positive abs-hat0x', () {
        expect(mapping.mapDpad('abs-hat0x', 1), 'right');
      });

      test('should return left for negative abs-hat0x', () {
        expect(mapping.mapDpad('abs-hat0x', -1), 'left');
      });

      test('should return null for zero abs-hat0x', () {
        expect(mapping.mapDpad('abs-hat0x', 0), isNull);
      });

      test('should return up for negative abs-hat0y', () {
        expect(mapping.mapDpad('abs-hat0y', -1), 'up');
      });

      test('should return down for positive abs-hat0y', () {
        expect(mapping.mapDpad('abs-hat0y', 1), 'down');
      });

      test('should return null for non-dpad key', () {
        expect(mapping.mapDpad('abs-x', 1), isNull);
      });
    });

    group('isStickAxis', () {
      test('should recognize stick axes', () {
        expect(mapping.isStickAxis('abs-x'), isTrue);
        expect(mapping.isStickAxis('abs-y'), isTrue);
        expect(mapping.isStickAxis('abs-rx'), isTrue);
        expect(mapping.isStickAxis('abs-ry'), isTrue);
      });

      test('should reject D-pad hat axes', () {
        expect(mapping.isStickAxis('abs-hat0x'), isFalse);
        expect(mapping.isStickAxis('abs-hat0y'), isFalse);
      });
    });

    group('isTriggerAxis', () {
      test('should recognize separate trigger axes', () {
        expect(mapping.isTriggerAxis('abs-z'), isTrue);
        expect(mapping.isTriggerAxis('abs-rz'), isTrue);
      });
    });

    group('normalizeAxisKey', () {
      test('should normalize Linux axis names', () {
        expect(mapping.normalizeAxisKey('abs-x'), 'stick-left-x');
        expect(mapping.normalizeAxisKey('abs-y'), 'stick-left-y');
        expect(mapping.normalizeAxisKey('abs-rx'), 'stick-right-x');
        expect(mapping.normalizeAxisKey('abs-ry'), 'stick-right-y');
      });
    });

    test('triggersSharedAxis should be false', () {
      expect(mapping.triggersSharedAxis, isFalse);
    });

    test('povAxis should be null', () {
      expect(mapping.povAxis, isNull);
    });
  });

  group('AndroidGamepadMapping', () {
    test('should extend LinuxGamepadMapping', () {
      const AndroidGamepadMapping mapping = AndroidGamepadMapping();
      expect(mapping, isA<LinuxGamepadMapping>());
    });

    test('should have same axis names as Linux', () {
      const AndroidGamepadMapping mapping = AndroidGamepadMapping();
      expect(mapping.leftStickX, 'abs-x');
      expect(mapping.leftTrigger, 'abs-z');
    });
  });
}
