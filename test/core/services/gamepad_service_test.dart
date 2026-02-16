// Тесты для GamepadService — маппинг, нормализация, дедзона, debounce.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:xerabora/core/services/gamepad_service.dart';

/// Мок-источник событий для тестов.
class MockGamepadEventSource implements GamepadEventSource {
  final StreamController<GamepadEvent> controller =
      StreamController<GamepadEvent>.broadcast();

  @override
  Stream<GamepadEvent> get events => controller.stream;

  void emit(GamepadEvent event) => controller.add(event);

  void dispose() => controller.close();
}

/// Хелпер для создания GamepadEvent.
GamepadEvent _event({
  required String key,
  required double value,
  KeyType type = KeyType.analog,
  String gamepadId = '0',
}) {
  return GamepadEvent(
    gamepadId: gamepadId,
    timestamp: DateTime.now().millisecondsSinceEpoch,
    type: type,
    key: key,
    value: value,
  );
}

void main() {
  late MockGamepadEventSource source;
  late GamepadService service;

  setUp(() {
    source = MockGamepadEventSource();
    service = GamepadService(source: source);
    service.start();
  });

  tearDown(() {
    service.dispose();
    source.dispose();
  });

  group('GamepadService — Аналоговые стики', () {
    test('нормализует dwXpos из 0-65535 в -1.0..1.0', () async {
      final List<GamepadServiceEvent> events = <GamepadServiceEvent>[];
      service.events.listen(events.add);

      // Полное отклонение вправо: 65535 → ~1.0
      source.emit(_event(key: 'dwXpos', value: 65535));
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.first.key, equals('dwXpos'));
      expect(events.first.value, closeTo(1.0, 0.01));
      expect(events.first.type, equals(GamepadServiceEventType.analog));
    });

    test('нормализует dwYpos — полное отклонение вверх (0 → -1.0)', () async {
      final List<GamepadServiceEvent> events = <GamepadServiceEvent>[];
      service.events.listen(events.add);

      source.emit(_event(key: 'dwYpos', value: 0));
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.first.value, closeTo(-1.0, 0.01));
    });

    test('нормализует dwRpos и dwUpos (Right Stick)', () async {
      final List<GamepadServiceEvent> events = <GamepadServiceEvent>[];
      service.events.listen(events.add);

      source.emit(_event(key: 'dwRpos', value: 0));
      await Future<void>.delayed(Duration.zero);
      source.emit(_event(key: 'dwUpos', value: 65535));
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(2));
      expect(events[0].key, equals('dwRpos'));
      expect(events[0].value, closeTo(-1.0, 0.01));
      expect(events[1].key, equals('dwUpos'));
      expect(events[1].value, closeTo(1.0, 0.01));
    });

    test('фильтрует значения в дедзоне (центр ~32767)', () async {
      final List<GamepadServiceEvent> events = <GamepadServiceEvent>[];
      service.events.listen(events.add);

      // Центр — нормализованное ~0.0, абс < 0.3 → фильтруется
      source.emit(_event(key: 'dwXpos', value: 32767));
      source.emit(_event(key: 'dwYpos', value: 32768));
      source.emit(_event(key: 'dwRpos', value: 32500));
      source.emit(_event(key: 'dwUpos', value: 33000));
      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty);
    });

    test('пропускает значения за пределами дедзоны', () async {
      final List<GamepadServiceEvent> events = <GamepadServiceEvent>[];
      service.events.listen(events.add);

      // Deadzone порог: 0.3 * 32767.5 ≈ 9830 от центра
      // Значение 22000 → нормализованное: (22000-32767.5)/32767.5 ≈ -0.33 → проходит
      source.emit(_event(key: 'dwXpos', value: 22000));
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.first.value, lessThan(-0.3));
    });

    test('игнорирует неизвестные ключи осей', () async {
      final List<GamepadServiceEvent> events = <GamepadServiceEvent>[];
      service.events.listen(events.add);

      source.emit(_event(key: 'unknownAxis', value: 50000));
      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty);
    });
  });

  group('GamepadService — D-pad (POV hat)', () {
    test('маппит POV 0 → dpad-up', () async {
      final List<GamepadServiceEvent> events = <GamepadServiceEvent>[];
      service.events.listen(events.add);

      source.emit(_event(key: 'pov', value: 0));
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.first.key, equals('dpad-up'));
      expect(events.first.value, equals(1.0));
      expect(events.first.type, equals(GamepadServiceEventType.button));
    });

    test('маппит POV 9000 → dpad-right', () async {
      final List<GamepadServiceEvent> events = <GamepadServiceEvent>[];
      service.events.listen(events.add);

      source.emit(_event(key: 'pov', value: 9000));
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.first.key, equals('dpad-right'));
    });

    test('маппит POV 18000 → dpad-down', () async {
      final List<GamepadServiceEvent> events = <GamepadServiceEvent>[];
      service.events.listen(events.add);

      source.emit(_event(key: 'pov', value: 18000));
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.first.key, equals('dpad-down'));
    });

    test('маппит POV 27000 → dpad-left', () async {
      final List<GamepadServiceEvent> events = <GamepadServiceEvent>[];
      service.events.listen(events.add);

      source.emit(_event(key: 'pov', value: 27000));
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.first.key, equals('dpad-left'));
    });

    test('игнорирует POV 65535 (отпущено)', () async {
      final List<GamepadServiceEvent> events = <GamepadServiceEvent>[];
      service.events.listen(events.add);

      source.emit(_event(key: 'pov', value: 65535));
      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty);
    });

    test('игнорирует диагонали POV', () async {
      final List<GamepadServiceEvent> events = <GamepadServiceEvent>[];
      service.events.listen(events.add);

      source.emit(_event(key: 'pov', value: 4500)); // up-right
      source.emit(_event(key: 'pov', value: 13500)); // down-right
      source.emit(_event(key: 'pov', value: 22500)); // down-left
      source.emit(_event(key: 'pov', value: 31500)); // up-left
      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty);
    });

    test('не повторяет одно направление при удержании', () async {
      final List<GamepadServiceEvent> events = <GamepadServiceEvent>[];
      service.events.listen(events.add);

      source.emit(_event(key: 'pov', value: 0)); // up
      await Future<void>.delayed(Duration.zero);
      source.emit(_event(key: 'pov', value: 0)); // up (повтор)
      await Future<void>.delayed(Duration.zero);
      source.emit(_event(key: 'pov', value: 0)); // up (повтор)
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1)); // Только первое
    });

    test('генерирует новое событие при смене направления', () async {
      final List<GamepadServiceEvent> events = <GamepadServiceEvent>[];
      service.events.listen(events.add);

      source.emit(_event(key: 'pov', value: 0)); // up
      await Future<void>.delayed(
          const Duration(milliseconds: 200)); // > debounce

      source.emit(_event(key: 'pov', value: 65535)); // released
      await Future<void>.delayed(Duration.zero);

      source.emit(_event(key: 'pov', value: 9000)); // right
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(2));
      expect(events[0].key, equals('dpad-up'));
      expect(events[1].key, equals('dpad-right'));
    });

    test('сбрасывает состояние при отпускании и позволяет повторное нажатие',
        () async {
      final List<GamepadServiceEvent> events = <GamepadServiceEvent>[];
      service.events.listen(events.add);

      source.emit(_event(key: 'pov', value: 0)); // up
      await Future<void>.delayed(
          const Duration(milliseconds: 200)); // > debounce

      source.emit(_event(key: 'pov', value: 65535)); // released
      await Future<void>.delayed(Duration.zero);

      source.emit(_event(key: 'pov', value: 0)); // up снова
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(2));
      expect(events[0].key, equals('dpad-up'));
      expect(events[1].key, equals('dpad-up'));
    });
  });

  group('GamepadService — Триггеры (dwZpos)', () {
    test('генерирует событие при нажатии LT (значение ниже центра)', () async {
      final List<GamepadServiceEvent> events = <GamepadServiceEvent>[];
      service.events.listen(events.add);

      // LT: значение ~0 → нормализованное ≈ -1.0
      source.emit(_event(key: 'dwZpos', value: 0));
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.first.key, equals('dwZpos'));
      expect(events.first.value, closeTo(-1.0, 0.01));
      expect(events.first.type, equals(GamepadServiceEventType.trigger));
    });

    test('генерирует событие при нажатии RT (значение выше центра)', () async {
      final List<GamepadServiceEvent> events = <GamepadServiceEvent>[];
      service.events.listen(events.add);

      // RT: значение ~65535 → нормализованное ≈ 1.0
      source.emit(_event(key: 'dwZpos', value: 65535));
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.first.value, closeTo(1.0, 0.01));
    });

    test('фильтрует центральную зону (ни один триггер не нажат)', () async {
      final List<GamepadServiceEvent> events = <GamepadServiceEvent>[];
      service.events.listen(events.add);

      // Центр: нормализованное ~0, абс < 0.5 → фильтруется
      source.emit(_event(key: 'dwZpos', value: 32767));
      source.emit(_event(key: 'dwZpos', value: 32768));
      source.emit(_event(key: 'dwZpos', value: 30000)); // ~-0.08
      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty);
    });

    test('edge detection — не повторяет при удержании', () async {
      final List<GamepadServiceEvent> events = <GamepadServiceEvent>[];
      service.events.listen(events.add);

      source.emit(_event(key: 'dwZpos', value: 0)); // LT
      await Future<void>.delayed(Duration.zero);
      source.emit(_event(key: 'dwZpos', value: 100)); // LT (удержание)
      await Future<void>.delayed(Duration.zero);
      source.emit(_event(key: 'dwZpos', value: 500)); // LT (удержание)
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1)); // Только первое
    });

    test('edge detection — сброс через центр позволяет повторное нажатие',
        () async {
      final List<GamepadServiceEvent> events = <GamepadServiceEvent>[];
      service.events.listen(events.add);

      source.emit(_event(key: 'dwZpos', value: 0)); // LT
      await Future<void>.delayed(Duration.zero);

      source.emit(_event(key: 'dwZpos', value: 32767)); // Центр
      await Future<void>.delayed(Duration.zero);

      source.emit(_event(key: 'dwZpos', value: 0)); // LT снова
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(2));
      expect(events[0].value, closeTo(-1.0, 0.01));
      expect(events[1].value, closeTo(-1.0, 0.01));
    });

    test('edge detection — переход LT → RT генерирует оба события', () async {
      final List<GamepadServiceEvent> events = <GamepadServiceEvent>[];
      service.events.listen(events.add);

      source.emit(_event(key: 'dwZpos', value: 0)); // LT
      await Future<void>.delayed(Duration.zero);

      source.emit(_event(key: 'dwZpos', value: 65535)); // RT
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(2));
      expect(events[0].value, lessThan(0)); // LT
      expect(events[1].value, greaterThan(0)); // RT
    });
  });

  group('GamepadService — Цифровые кнопки', () {
    test('генерирует событие при нажатии кнопки (value == 1.0)', () async {
      final List<GamepadServiceEvent> events = <GamepadServiceEvent>[];
      service.events.listen(events.add);

      source.emit(
          _event(key: 'button-0', value: 1.0, type: KeyType.button));
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.first.key, equals('button-0'));
      expect(events.first.value, equals(1.0));
      expect(events.first.type, equals(GamepadServiceEventType.button));
    });

    test('игнорирует отпускание кнопки (value == 0.0)', () async {
      final List<GamepadServiceEvent> events = <GamepadServiceEvent>[];
      service.events.listen(events.add);

      source.emit(
          _event(key: 'button-0', value: 0.0, type: KeyType.button));
      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty);
    });

    test('debounce — отклоняет быстрые повторные нажатия', () async {
      final List<GamepadServiceEvent> events = <GamepadServiceEvent>[];
      service.events.listen(events.add);

      source.emit(
          _event(key: 'button-0', value: 1.0, type: KeyType.button));
      await Future<void>.delayed(Duration.zero);

      // Быстрый повтор (< 150ms)
      source.emit(
          _event(key: 'button-0', value: 1.0, type: KeyType.button));
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
    });

    test('debounce — пропускает после паузы', () async {
      final List<GamepadServiceEvent> events = <GamepadServiceEvent>[];
      service.events.listen(events.add);

      source.emit(
          _event(key: 'button-0', value: 1.0, type: KeyType.button));
      await Future<void>.delayed(Duration.zero);

      // Ждём больше debounce (150ms)
      await Future<void>.delayed(const Duration(milliseconds: 200));

      source.emit(
          _event(key: 'button-0', value: 1.0, type: KeyType.button));
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(2));
    });

    test('debounce — разные кнопки не блокируют друг друга', () async {
      final List<GamepadServiceEvent> events = <GamepadServiceEvent>[];
      service.events.listen(events.add);

      source.emit(
          _event(key: 'button-0', value: 1.0, type: KeyType.button));
      await Future<void>.delayed(Duration.zero);
      source.emit(
          _event(key: 'button-1', value: 1.0, type: KeyType.button));
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(2));
      expect(events[0].key, equals('button-0'));
      expect(events[1].key, equals('button-1'));
    });

    test('маппит все кнопки button-0..button-7', () async {
      final List<GamepadServiceEvent> events = <GamepadServiceEvent>[];
      service.events.listen(events.add);

      for (int i = 0; i <= 7; i++) {
        source.emit(
            _event(key: 'button-$i', value: 1.0, type: KeyType.button));
        await Future<void>.delayed(Duration.zero);
      }

      expect(events, hasLength(8));
      for (int i = 0; i <= 7; i++) {
        expect(events[i].key, equals('button-$i'));
      }
    });
  });

  group('GamepadService — rawEvents', () {
    test('rawEvents пробрасывает сырые события без фильтрации', () async {
      final List<GamepadEvent> rawEvents = <GamepadEvent>[];
      service.rawEvents.listen(rawEvents.add);

      source.emit(_event(key: 'dwXpos', value: 32767)); // В дедзоне
      source.emit(_event(key: 'pov', value: 65535)); // Released
      source.emit(
          _event(key: 'button-0', value: 0.0, type: KeyType.button)); // Release
      await Future<void>.delayed(Duration.zero);

      // Все 3 сырых события должны пройти
      expect(rawEvents, hasLength(3));
    });
  });

  group('GamepadService — start/dispose', () {
    test('dispose закрывает стрим', () async {
      service.dispose();

      // Стрим должен быть закрыт — новые события не приходят
      bool isDone = false;
      service.events.listen(
        (_) {},
        onDone: () => isDone = true,
      );
      await Future<void>.delayed(Duration.zero);

      expect(isDone, isTrue);
    });

    test('start перезапускает подписку', () async {
      final List<GamepadServiceEvent> events = <GamepadServiceEvent>[];
      final GamepadService freshService = GamepadService(source: source);

      // Без start — события не приходят
      freshService.events.listen(events.add);
      source.emit(
          _event(key: 'button-0', value: 1.0, type: KeyType.button));
      await Future<void>.delayed(Duration.zero);

      // start() активирует маппинг
      freshService.start();
      source.emit(
          _event(key: 'button-1', value: 1.0, type: KeyType.button));
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.first.key, equals('button-1'));

      freshService.dispose();
    });
  });

  group('GamepadService — _isStickAxis', () {
    test('распознаёт все 4 оси стиков', () async {
      final List<GamepadServiceEvent> events = <GamepadServiceEvent>[];
      service.events.listen(events.add);

      final List<String> stickAxes = <String>[
        'dwXpos',
        'dwYpos',
        'dwRpos',
        'dwUpos',
      ];

      for (final String axis in stickAxes) {
        // Значение за пределами дедзоны
        source.emit(_event(key: axis, value: 60000));
        await Future<void>.delayed(Duration.zero);
      }

      expect(events, hasLength(4));
      for (int i = 0; i < stickAxes.length; i++) {
        expect(events[i].key, equals(stickAxes[i]));
        expect(events[i].type, equals(GamepadServiceEventType.analog));
      }
    });
  });

  group('GamepadServiceEvent', () {
    test('toString возвращает читаемое представление', () {
      final GamepadServiceEvent event = GamepadServiceEvent(
        key: 'button-0',
        value: 1.0,
        type: GamepadServiceEventType.button,
        rawEvent: _event(
            key: 'button-0', value: 1.0, type: KeyType.button),
      );

      expect(
        event.toString(),
        equals(
            'GamepadServiceEvent(button-0, 1.0, GamepadServiceEventType.button)'),
      );
    });
  });
}
