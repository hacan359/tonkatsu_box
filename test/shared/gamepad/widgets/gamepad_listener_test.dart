import 'package:xerabora/l10n/app_localizations.dart';
// Тесты для GamepadListener — маппинг событий и поведение с TextField.
//
// Платформенная проверка: GamepadListener подписывается на events
// только на десктопе (kIsMobile == false). В тестовой среде kIsMobile == false,
// поэтому подписка создаётся и тесты работают как прежде.
// На Android/iOS подписка пропускается — геймпад не используется.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';

import 'package:xerabora/core/services/gamepad_service.dart';
import 'package:xerabora/shared/gamepad/gamepad_action.dart';
import 'package:xerabora/shared/gamepad/gamepad_provider.dart';
import 'package:xerabora/shared/gamepad/widgets/gamepad_listener.dart';

/// Мок-источник событий.
class MockGamepadEventSource implements GamepadEventSource {
  final StreamController<GamepadEvent> controller =
      StreamController<GamepadEvent>.broadcast();

  @override
  Stream<GamepadEvent> get events => controller.stream;

  void emit(GamepadEvent event) => controller.add(event);

  void dispose() => controller.close();
}

GamepadEvent _event({
  required String key,
  required double value,
  KeyType type = KeyType.analog,
}) {
  return GamepadEvent(
    gamepadId: '0',
    timestamp: 0,
    type: type,
    key: key,
    value: value,
  );
}

/// Эмит события и ожидание прохождения через цепочку стримов.
///
/// Стримы GamepadService используют async broadcast controllers,
/// поэтому в тестах нужен runAsync для обработки microtasks.
Future<void> emitAndProcess(
  WidgetTester tester,
  MockGamepadEventSource source,
  GamepadEvent event,
) async {
  await tester.runAsync(() async {
    source.emit(event);
    // Две async hop: source → service → listener
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pump();
}

void main() {
  late MockGamepadEventSource mockSource;
  late GamepadService service;

  setUp(() {
    mockSource = MockGamepadEventSource();
    service = GamepadService(source: mockSource);
    service.start();
  });

  tearDown(() {
    service.dispose();
    mockSource.dispose();
  });

  Widget buildTestWidget({
    required Widget child,
    required GamepadService gamepadService,
    VoidCallback? onConfirm,
    VoidCallback? onBack,
    void Function(GamepadAction)? onNavigate,
    void Function(GamepadAction)? onTabSwitch,
    void Function(GamepadAction)? onScroll,
    VoidCallback? onMenu,
  }) {
    return ProviderScope(
      overrides: <Override>[
        gamepadServiceProvider.overrideWithValue(gamepadService),
      ],
      child: MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
        home: GamepadListener(
          onConfirm: onConfirm,
          onBack: onBack,
          onNavigate: onNavigate,
          onTabSwitch: onTabSwitch,
          onScroll: onScroll,
          onMenu: onMenu,
          child: child,
        ),
      ),
    );
  }

  group('GamepadListener маппинг кнопок', () {
    testWidgets('button-0 (A) → onConfirm', (WidgetTester tester) async {
      bool confirmed = false;

      await tester.pumpWidget(buildTestWidget(
        gamepadService: service,
        onConfirm: () => confirmed = true,
        child: const Text('test'),
      ));

      await emitAndProcess(
        tester,
        mockSource,
        _event(key: 'button-0', value: 1.0, type: KeyType.button),
      );

      expect(confirmed, isTrue);
    });

    testWidgets('button-1 (B) → onBack', (WidgetTester tester) async {
      bool backed = false;

      await tester.pumpWidget(buildTestWidget(
        gamepadService: service,
        onBack: () => backed = true,
        child: const Text('test'),
      ));

      await emitAndProcess(
        tester,
        mockSource,
        _event(key: 'button-1', value: 1.0, type: KeyType.button),
      );

      expect(backed, isTrue);
    });

    testWidgets('button-4 (LB) → onTabSwitch previousTab',
        (WidgetTester tester) async {
      GamepadAction? receivedAction;

      await tester.pumpWidget(buildTestWidget(
        gamepadService: service,
        onTabSwitch: (GamepadAction action) => receivedAction = action,
        child: const Text('test'),
      ));

      await emitAndProcess(
        tester,
        mockSource,
        _event(key: 'button-4', value: 1.0, type: KeyType.button),
      );

      expect(receivedAction, GamepadAction.previousTab);
    });

    testWidgets('button-5 (RB) → onTabSwitch nextTab',
        (WidgetTester tester) async {
      GamepadAction? receivedAction;

      await tester.pumpWidget(buildTestWidget(
        gamepadService: service,
        onTabSwitch: (GamepadAction action) => receivedAction = action,
        child: const Text('test'),
      ));

      await emitAndProcess(
        tester,
        mockSource,
        _event(key: 'button-5', value: 1.0, type: KeyType.button),
      );

      expect(receivedAction, GamepadAction.nextTab);
    });

    testWidgets('button-7 (Start) → onMenu', (WidgetTester tester) async {
      bool menuOpened = false;

      await tester.pumpWidget(buildTestWidget(
        gamepadService: service,
        onMenu: () => menuOpened = true,
        child: const Text('test'),
      ));

      await emitAndProcess(
        tester,
        mockSource,
        _event(key: 'button-7', value: 1.0, type: KeyType.button),
      );

      expect(menuOpened, isTrue);
    });

    testWidgets('dpad-up → onNavigate navigateUp',
        (WidgetTester tester) async {
      GamepadAction? receivedAction;

      await tester.pumpWidget(buildTestWidget(
        gamepadService: service,
        onNavigate: (GamepadAction action) => receivedAction = action,
        child: const Text('test'),
      ));

      // POV up = 0
      await emitAndProcess(
        tester,
        mockSource,
        _event(key: 'pov', value: 0),
      );

      expect(receivedAction, GamepadAction.navigateUp);
    });

    testWidgets('dpad-down → onNavigate navigateDown',
        (WidgetTester tester) async {
      GamepadAction? receivedAction;

      await tester.pumpWidget(buildTestWidget(
        gamepadService: service,
        onNavigate: (GamepadAction action) => receivedAction = action,
        child: const Text('test'),
      ));

      // POV down = 18000
      await emitAndProcess(
        tester,
        mockSource,
        _event(key: 'pov', value: 18000),
      );

      expect(receivedAction, GamepadAction.navigateDown);
    });
  });

  group('GamepadListener аналоговые стики', () {
    testWidgets('dwYpos > deadzone → onScroll scrollDown',
        (WidgetTester tester) async {
      GamepadAction? receivedAction;

      await tester.pumpWidget(buildTestWidget(
        gamepadService: service,
        onScroll: (GamepadAction action) => receivedAction = action,
        child: const Text('test'),
      ));

      // Left Stick Y full down = 65535
      await emitAndProcess(
        tester,
        mockSource,
        _event(key: 'dwYpos', value: 65535),
      );

      expect(receivedAction, GamepadAction.scrollDown);
    });

    testWidgets('dwYpos в центре (deadzone) → нет события',
        (WidgetTester tester) async {
      GamepadAction? receivedAction;

      await tester.pumpWidget(buildTestWidget(
        gamepadService: service,
        onScroll: (GamepadAction action) => receivedAction = action,
        child: const Text('test'),
      ));

      // Left Stick Y in center = 32767
      await emitAndProcess(
        tester,
        mockSource,
        _event(key: 'dwYpos', value: 32767),
      );

      expect(receivedAction, isNull);
    });
  });

  group('GamepadListener TextField поведение', () {
    testWidgets('B на TextField → снимает фокус',
        (WidgetTester tester) async {
      final FocusNode textFieldFocus = FocusNode();

      await tester.pumpWidget(ProviderScope(
        overrides: <Override>[
          gamepadServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
          home: GamepadListener(
            child: Scaffold(
              body: TextField(focusNode: textFieldFocus),
            ),
          ),
        ),
      ));

      // Фокусируемся на TextField
      textFieldFocus.requestFocus();
      await tester.pump();
      expect(textFieldFocus.hasFocus, isTrue);

      // Нажимаем B
      await emitAndProcess(
        tester,
        mockSource,
        _event(key: 'button-1', value: 1.0, type: KeyType.button),
      );

      // Фокус должен быть снят
      expect(textFieldFocus.hasFocus, isFalse);

      textFieldFocus.dispose();
    });

    testWidgets('A на TextField → заблокирован (не вызывает onConfirm)',
        (WidgetTester tester) async {
      bool confirmed = false;
      final FocusNode textFieldFocus = FocusNode();

      await tester.pumpWidget(ProviderScope(
        overrides: <Override>[
          gamepadServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
          home: GamepadListener(
            onConfirm: () => confirmed = true,
            child: Scaffold(
              body: TextField(focusNode: textFieldFocus),
            ),
          ),
        ),
      ));

      textFieldFocus.requestFocus();
      await tester.pump();

      await emitAndProcess(
        tester,
        mockSource,
        _event(key: 'button-0', value: 1.0, type: KeyType.button),
      );

      expect(confirmed, isFalse);

      textFieldFocus.dispose();
    });

    testWidgets('D-pad Left на TextField → заблокирован',
        (WidgetTester tester) async {
      GamepadAction? receivedAction;
      final FocusNode textFieldFocus = FocusNode();

      await tester.pumpWidget(ProviderScope(
        overrides: <Override>[
          gamepadServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
          home: GamepadListener(
            onNavigate: (GamepadAction action) => receivedAction = action,
            child: Scaffold(
              body: TextField(focusNode: textFieldFocus),
            ),
          ),
        ),
      ));

      textFieldFocus.requestFocus();
      await tester.pump();

      // POV left = 27000
      await emitAndProcess(
        tester,
        mockSource,
        _event(key: 'pov', value: 27000),
      );

      expect(receivedAction, isNull);

      textFieldFocus.dispose();
    });

    testWidgets(
        'D-pad Down на TextField → снимает фокус с TextField',
        (WidgetTester tester) async {
      final FocusNode textField1Focus = FocusNode(debugLabel: 'field1');
      final FocusNode textField2Focus = FocusNode(debugLabel: 'field2');

      await tester.pumpWidget(ProviderScope(
        overrides: <Override>[
          gamepadServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
          home: GamepadListener(
            child: Scaffold(
              body: Column(
                children: <Widget>[
                  TextField(focusNode: textField1Focus),
                  const SizedBox(height: 20),
                  TextField(focusNode: textField2Focus),
                ],
              ),
            ),
          ),
        ),
      ));

      // Фокусируемся на первом TextField
      textField1Focus.requestFocus();
      await tester.pump();
      expect(textField1Focus.hasFocus, isTrue);

      // D-pad Down = POV 18000
      await emitAndProcess(
        tester,
        mockSource,
        _event(key: 'pov', value: 18000),
      );
      await tester.pumpAndSettle();

      // Первый TextField должен потерять фокус
      expect(textField1Focus.hasFocus, isFalse);

      textField1Focus.dispose();
      textField2Focus.dispose();
    });

    testWidgets('LB/RB на TextField → не заблокирован (tab switch)',
        (WidgetTester tester) async {
      GamepadAction? receivedAction;
      final FocusNode textFieldFocus = FocusNode();

      await tester.pumpWidget(ProviderScope(
        overrides: <Override>[
          gamepadServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
          home: GamepadListener(
            onTabSwitch: (GamepadAction action) => receivedAction = action,
            child: Scaffold(
              body: TextField(focusNode: textFieldFocus),
            ),
          ),
        ),
      ));

      textFieldFocus.requestFocus();
      await tester.pump();

      // LB не является navigation action → не блокируется
      await emitAndProcess(
        tester,
        mockSource,
        _event(key: 'button-4', value: 1.0, type: KeyType.button),
      );

      expect(receivedAction, GamepadAction.previousTab);

      textFieldFocus.dispose();
    });
  });

  group('GamepadListener без callbacks', () {
    testWidgets('не бросает ошибку если callback не задан',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(
        gamepadService: service,
        child: const Text('test'),
      ));

      // Все типы событий без callbacks
      await emitAndProcess(
        tester,
        mockSource,
        _event(key: 'button-0', value: 1.0, type: KeyType.button),
      );
      await emitAndProcess(
        tester,
        mockSource,
        _event(key: 'button-7', value: 1.0, type: KeyType.button),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('GamepadListener InputMode', () {
    testWidgets('gamepad событие переключает InputMode на gamepad',
        (WidgetTester tester) async {
      late WidgetRef capturedRef;

      await tester.pumpWidget(ProviderScope(
        overrides: <Override>[
          gamepadServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
          home: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) {
              capturedRef = ref;
              return const GamepadListener(
                child: Text('test'),
              );
            },
          ),
        ),
      ));

      // До события — mouse
      expect(capturedRef.read(inputModeProvider), InputMode.mouse);

      // Отправляем gamepad-событие
      await emitAndProcess(
        tester,
        mockSource,
        _event(key: 'button-0', value: 1.0, type: KeyType.button),
      );

      // После — gamepad
      expect(capturedRef.read(inputModeProvider), InputMode.gamepad);
    });
  });
}
