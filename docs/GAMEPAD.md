# Управление геймпадом (Xbox Controller, Windows)

## Обзор

Приложение поддерживает полное управление Xbox-контроллером на Windows.
Пакет: `gamepads` ^0.1.9 (Flame Engine) — event-driven stream API.

Два режима ввода переключаются автоматически:
- **Mouse** (по умолчанию) — стандартное поведение, focus-рамки скрыты
- **Gamepad** — любое событие геймпада переключает режим; движение мыши возвращает обратно

## Маппинг кнопок

```
Кнопка              Raw key        Действие
─────────────────────────────────────────────────────
D-pad Up/Down/L/R   pov            Навигация фокуса (DirectionalFocusIntent)
A                   button-0       Подтвердить / Открыть (ActivateIntent)
B                   button-1       Назад / Закрыть (Navigator.pop)
LB (Left Bumper)    button-4       Предыдущий таб (Home←Search←Settings)
RB (Right Bumper)   button-5       Следующий таб (Home→Search→Settings)
LT (Left Trigger)   dwZpos (<0)    Предыдущий суб-таб / фильтр
RT (Right Trigger)   dwZpos (>0)    Следующий суб-таб / фильтр
Left Stick X/Y      dwXpos/dwYpos  Скролл списков/сеток
Right Stick X/Y     dwRpos/dwUpos  Панорама Canvas
Start               button-7       Контекстное меню
```

Кнопки X (`button-2`), Y (`button-3`), Back/Select (`button-6`) — не назначены.

## Архитектура

```
lib/core/services/gamepad_service.dart          ← Сервис: raw events → GamepadServiceEvent
lib/shared/gamepad/
├── gamepad_action.dart                         ← Enum GamepadAction (21 значение) + InputMode
├── gamepad_provider.dart                       ← Riverpod: gamepadServiceProvider, inputModeProvider
└── widgets/
    ├── gamepad_listener.dart                   ← Виджет-обёртка: events → callbacks по типу
    └── gamepad_focus_indicator.dart             ← Рамка фокуса (2px gameAccent) в gamepad-режиме
```

### Поток данных

```
Gamepads.events (raw)
    │
    ▼
GamepadService                    Нормализация осей (0–65535 → -1.0..1.0)
  - Stick deadzone (|v| < 0.3)   POV hat → dpad-up/down/left/right
  - Button debounce (150ms)       Trigger edge detection (LT/RT)
    │
    ▼
GamepadServiceEvent { key, value, type, rawEvent }
    │
    ▼
GamepadListener (виджет)          Маппинг key → GamepadAction
  - _mapButton()                  button-0..7, dpad-*
  - _mapAnalog()                  dwXpos/dwYpos → scroll, dwRpos/dwUpos → pan
  - _mapTrigger()                 dwZpos → sub-tab switch
    │
    ▼
Callbacks: onNavigate, onConfirm, onBack, onTabSwitch, onSubTabSwitch,
           onScroll, onPan, onZoom, onMenu
```

### Глобальная интеграция

**`app.dart`** — `Listener(onPointerHover)` на верхнем уровне переключает `InputMode` на mouse при движении мыши.

**`navigation_shell.dart`** — `GamepadListener` оборачивает Scaffold:
- `onTabSwitch` — LB/RB переключают табы (Home/Search/Settings)
- `onNavigate` — D-pad перемещает фокус через `DirectionalFocusIntent`
- `onConfirm` — A активирует виджет через `ActivateIntent`
- `onBack` — B вызывает `Navigator.pop()`

## Windows JOYINFOEX

Raw значения от пакета `gamepads_windows`:

| Ключ | Тип | Диапазон | Описание |
|------|-----|----------|----------|
| `dwXpos` | analog | 0–65535 | Left Stick X (32767 = центр) |
| `dwYpos` | analog | 0–65535 | Left Stick Y |
| `dwRpos` | analog | 0–65535 | Right Stick X |
| `dwUpos` | analog | 0–65535 | Right Stick Y |
| `dwZpos` | analog | 0–65535 | Общая ось LT/RT (ниже центра = LT, выше = RT) |
| `pov` | analog | degrees×100 | D-pad: 0=Up, 9000=Right, 18000=Down, 27000=Left, 65535=Released |
| `button-0`..`button-7` | digital | 0.0/1.0 | A, B, X, Y, LB, RB, Back, Start |

Нормализация осей: `((value - 32767.5) / 32767.5).clamp(-1.0, 1.0)`

## GamepadService — детали обработки

### Stick deadzone
Нормализованное значение `|v| < 0.3` отфильтровывается — нет события.

### POV hat (D-pad)
- Генерирует синтетические ключи: `dpad-up`, `dpad-down`, `dpad-left`, `dpad-right`
- Direction tracking: повторное событие с тем же направлением игнорируется (POV шлёт непрерывно при удержании)
- Debounce: 150ms между событиями одного направления
- Диагонали (4500, 13500, 22500, 31500) игнорируются

### Trigger edge detection (LT/RT)
- Общая ось `dwZpos` для обоих триггеров
- State tracking: -1 (LT нажат), 0 (центр), 1 (RT нажат)
- Событие генерируется только при пересечении порога (`|normalized| > 0.5`)
- Возврат в центр — сброс состояния без события
- Результат: одно событие за нажатие, а не поток значений

### Button debounce
Все цифровые кнопки (`button-0`..`button-7`) имеют debounce 150ms.
Событие отпускания (`value == 0.0`) не генерирует событие.

## Как работает D-pad навигация

D-pad использует встроенную систему фокуса Flutter:

1. `GamepadListener.onNavigate` в `NavigationShell` вызывает `_onGamepadNavigate`
2. Если ничего не сфокусировано — `FocusScope.of(context).nextFocus()` фокусирует первый виджет
3. Если виджет в фокусе — `Actions.maybeInvoke(ctx, DirectionalFocusIntent(direction))` перемещает фокус пространственно (ближайший виджет в указанном направлении)

Кнопка A использует `Actions.maybeInvoke(ctx, ActivateIntent())` — это вызывает `onTap` у InkWell или зарегистрированный `ActivateIntent` в `Actions`.

## Какие виджеты уже поддерживают геймпад

### Focusable из коробки (InkWell-based):
- `HeroCollectionCard` — Material > InkWell
- `CollectionTile` — Material > InkWell
- `MediaCard` — Material > InkWell
- `ListTile`, `SwitchListTile`, `ElevatedButton`, `IconButton` — стандартные Material виджеты
- `NavigationRail`, `BottomNavigationBar` — стандартные навигационные виджеты

### Доработанные:
- **`PosterCard`** — изначально использовал `GestureDetector` (не focusable). Добавлен `Focus` + `Actions(ActivateIntent → onTap)`. Фокус активирует hover-анимацию (масштабирование).

## Чеклист: поддержка геймпада в новых виджетах

### Виджет с InkWell/Material кнопкой

Ничего делать не нужно. `InkWell` автоматически:
- Focusable (участвует в `DirectionalFocusIntent` навигации)
- Обрабатывает `ActivateIntent` → вызывает `onTap`

### Виджет с GestureDetector

`GestureDetector` **не focusable**. Нужно обернуть:

```dart
return Actions(
  actions: <Type, Action<Intent>>{
    ActivateIntent: CallbackAction<ActivateIntent>(
      onInvoke: (ActivateIntent intent) {
        onTap?.call();
        return null;
      },
    ),
  },
  child: Focus(
    focusNode: _focusNode,  // создать в initState, dispose в dispose
    onFocusChange: (bool hasFocus) {
      // Опционально: визуальная обратная связь при фокусе
    },
    child: GestureDetector(
      onTap: onTap,
      child: ...,
    ),
  ),
);
```

**Важно:** `Actions` должен быть ВЫШЕ `Focus` в дереве, иначе `Actions.invoke` из контекста FocusNode не найдёт обработчик (ищет вверх по дереву).

### Новый экран с GamepadListener

Если экрану нужны специфические gamepad-действия (скролл стиками, суб-табы триггерами):

```dart
GamepadListener(
  onScroll: (GamepadAction action) {
    // Left Stick → скролл ScrollController
  },
  onSubTabSwitch: (GamepadAction action) {
    // LT/RT → переключение TabController
  },
  child: ...,
)
```

D-pad навигация и кнопка A обрабатываются глобально в `NavigationShell` — отдельно подключать не нужно.

### GamepadFocusIndicator (рамка фокуса)

Для визуальной рамки вокруг focusable элемента в gamepad-режиме:

```dart
GamepadFocusIndicator(
  borderRadius: AppSpacing.radiusMd,
  child: MyWidget(...),
)
```

Показывает рамку 2px `AppColors.gameAccent` только в `InputMode.gamepad` при фокусе.

## Debug-панель

Settings > Developer Tools > Gamepad Debug — показывает raw и обработанные события в реальном времени. Полезно для проверки маппинга кнопок.

## Тесты

```
test/core/services/gamepad_service_test.dart               — 45 тестов (нормализация, POV, триггеры, debounce)
test/shared/gamepad/gamepad_provider_test.dart              — 12 тестов (InputMode, enum values)
test/shared/gamepad/widgets/gamepad_listener_test.dart      — 16 тестов (маппинг кнопок, стики, TextField, InputMode)
test/shared/widgets/poster_card_test.dart                   — 6 тестов фокуса (Focus, Actions, ActivateIntent, анимация)
```

Стратегия моков: `MockGamepadEventSource` с `StreamController<GamepadEvent>` для симуляции событий.

### Тестирование async стримов в widget tests

`GamepadService` использует async broadcast `StreamController`, поэтому в widget-тестах нужен `tester.runAsync` для обработки microtasks. Хелпер `emitAndProcess`:

```dart
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
```
