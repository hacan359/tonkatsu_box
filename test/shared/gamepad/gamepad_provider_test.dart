// Тесты для Riverpod провайдеров геймпада.
//
// Платформенная проверка: gamepadServiceProvider вызывает start() только
// на десктопе (kIsMobile == false). В тестовой среде Platform — Linux/macOS/Windows,
// поэтому kIsMobile == false и сервис стартует. На Android/iOS start() пропускается,
// что снижает нагрузку при запуске приложения.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/gamepad/gamepad_action.dart';
import 'package:xerabora/shared/gamepad/gamepad_provider.dart';

void main() {
  group('InputModeNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('начальное состояние — InputMode.mouse', () {
      final InputMode mode = container.read(inputModeProvider);
      expect(mode, equals(InputMode.mouse));
    });

    test('setGamepadMode переключает на gamepad', () {
      container.read(inputModeProvider.notifier).setGamepadMode();
      final InputMode mode = container.read(inputModeProvider);
      expect(mode, equals(InputMode.gamepad));
    });

    test('setMouseMode переключает на mouse', () {
      // Сначала переключаем на gamepad
      container.read(inputModeProvider.notifier).setGamepadMode();
      expect(container.read(inputModeProvider), equals(InputMode.gamepad));

      // Затем обратно на mouse
      container.read(inputModeProvider.notifier).setMouseMode();
      expect(container.read(inputModeProvider), equals(InputMode.mouse));
    });

    test('setGamepadMode не уведомляет при повторном вызове', () {
      int notifyCount = 0;
      container.listen(
        inputModeProvider,
        (InputMode? previous, InputMode next) => notifyCount++,
      );

      container.read(inputModeProvider.notifier).setGamepadMode();
      container.read(inputModeProvider.notifier).setGamepadMode();
      container.read(inputModeProvider.notifier).setGamepadMode();

      // Только одно уведомление (mouse → gamepad)
      expect(notifyCount, equals(1));
    });

    test('setMouseMode не уведомляет при повторном вызове', () {
      int notifyCount = 0;
      container.listen(
        inputModeProvider,
        (InputMode? previous, InputMode next) => notifyCount++,
      );

      // mouse → mouse — нет уведомления
      container.read(inputModeProvider.notifier).setMouseMode();

      expect(notifyCount, equals(0));
    });

    test('переключение mouse → gamepad → mouse генерирует 2 уведомления',
        () {
      int notifyCount = 0;
      container.listen(
        inputModeProvider,
        (InputMode? previous, InputMode next) => notifyCount++,
      );

      container.read(inputModeProvider.notifier).setGamepadMode();
      container.read(inputModeProvider.notifier).setMouseMode();

      expect(notifyCount, equals(2));
    });
  });

  group('GamepadAction enum', () {
    test('содержит все необходимые значения навигации', () {
      expect(GamepadAction.values, contains(GamepadAction.navigateUp));
      expect(GamepadAction.values, contains(GamepadAction.navigateDown));
      expect(GamepadAction.values, contains(GamepadAction.navigateLeft));
      expect(GamepadAction.values, contains(GamepadAction.navigateRight));
    });

    test('содержит действия подтверждения и отмены', () {
      expect(GamepadAction.values, contains(GamepadAction.confirm));
      expect(GamepadAction.values, contains(GamepadAction.back));
    });

    test('содержит действия табов и суб-табов', () {
      expect(GamepadAction.values, contains(GamepadAction.previousTab));
      expect(GamepadAction.values, contains(GamepadAction.nextTab));
      expect(GamepadAction.values, contains(GamepadAction.previousSubTab));
      expect(GamepadAction.values, contains(GamepadAction.nextSubTab));
    });

    test('содержит действия скролла и панорамы', () {
      expect(GamepadAction.values, contains(GamepadAction.scrollUp));
      expect(GamepadAction.values, contains(GamepadAction.scrollDown));
      expect(GamepadAction.values, contains(GamepadAction.scrollLeft));
      expect(GamepadAction.values, contains(GamepadAction.scrollRight));
      expect(GamepadAction.values, contains(GamepadAction.panUp));
      expect(GamepadAction.values, contains(GamepadAction.panDown));
      expect(GamepadAction.values, contains(GamepadAction.panLeft));
      expect(GamepadAction.values, contains(GamepadAction.panRight));
    });

    test('содержит действия зума и меню', () {
      expect(GamepadAction.values, contains(GamepadAction.zoomIn));
      expect(GamepadAction.values, contains(GamepadAction.zoomOut));
      expect(GamepadAction.values, contains(GamepadAction.openMenu));
    });

    test('содержит 21 значение', () {
      expect(GamepadAction.values, hasLength(21));
    });
  });

  group('InputMode enum', () {
    test('содержит mouse и gamepad', () {
      expect(InputMode.values, hasLength(2));
      expect(InputMode.values, contains(InputMode.mouse));
      expect(InputMode.values, contains(InputMode.gamepad));
    });
  });
}
