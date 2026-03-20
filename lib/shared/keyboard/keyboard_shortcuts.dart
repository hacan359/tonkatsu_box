// Определения глобальных клавиатурных сочетаний.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/platform_features.dart';

/// Описание одного хоткея для легенды (F1 диалог).
class ShortcutEntry {
  /// Создаёт [ShortcutEntry].
  const ShortcutEntry({required this.keys, required this.description});

  /// Человекочитаемое описание клавиш, например 'Ctrl+N'.
  final String keys;

  /// Описание действия, например 'Создать коллекцию'.
  final String description;
}

/// Группа хоткеев (секция в диалоге F1).
class ShortcutGroup {
  /// Создаёт [ShortcutGroup].
  const ShortcutGroup({required this.title, required this.entries});

  /// Название группы, например 'Навигация'.
  final String title;

  /// Список хоткеев в группе.
  final List<ShortcutEntry> entries;
}

/// Глобальные клавиатурные сочетания (NavigationShell).
///
/// Возвращает маппинг [ShortcutActivator] → callback для использования
/// в [CallbackShortcuts]. Только для десктопа.
Map<ShortcutActivator, VoidCallback> buildGlobalShortcuts({
  required void Function(int tabIndex) onSwitchTab,
  required VoidCallback onNextTab,
  required VoidCallback onPreviousTab,
  required VoidCallback onBack,
  required VoidCallback onSearch,
  required VoidCallback onRefresh,
  required VoidCallback onShowHelp,
}) {
  if (kIsMobile) return <ShortcutActivator, VoidCallback>{};

  return <ShortcutActivator, VoidCallback>{
    // Ctrl+1..6 — переключение табов
    const SingleActivator(LogicalKeyboardKey.digit1, control: true):
        () => onSwitchTab(0),
    const SingleActivator(LogicalKeyboardKey.digit2, control: true):
        () => onSwitchTab(1),
    const SingleActivator(LogicalKeyboardKey.digit3, control: true):
        () => onSwitchTab(2),
    const SingleActivator(LogicalKeyboardKey.digit4, control: true):
        () => onSwitchTab(3),
    const SingleActivator(LogicalKeyboardKey.digit5, control: true):
        () => onSwitchTab(4),
    const SingleActivator(LogicalKeyboardKey.digit6, control: true):
        () => onSwitchTab(5),

    // Ctrl+Tab / Ctrl+Shift+Tab — циклическое переключение
    const SingleActivator(LogicalKeyboardKey.tab, control: true): onNextTab,
    const SingleActivator(LogicalKeyboardKey.tab, control: true, shift: true):
        onPreviousTab,

    // Escape — назад
    const SingleActivator(LogicalKeyboardKey.escape): onBack,

    // Alt+Left — назад (браузерный стиль)
    const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): onBack,

    // Ctrl+F — фокус на поиск
    const SingleActivator(LogicalKeyboardKey.keyF, control: true): onSearch,

    // F5 — обновить
    const SingleActivator(LogicalKeyboardKey.f5): onRefresh,

    // F1 — показать легенду хоткеев
    const SingleActivator(LogicalKeyboardKey.f1): onShowHelp,
  };
}

/// Проверяет, находится ли фокус в текстовом поле.
///
/// Используется для подавления однобуквенных хоткеев (V, B, L и т.д.)
/// когда пользователь набирает текст.
bool isTextFieldFocused() {
  final FocusNode? focus = FocusManager.instance.primaryFocus;
  if (focus == null) return false;

  final BuildContext? ctx = focus.context;
  if (ctx == null) return false;

  // Проверяем наличие EditableText в предках сфокусированного виджета
  bool found = false;
  ctx.visitAncestorElements((Element element) {
    if (element.widget is EditableText) {
      found = true;
      return false; // прекратить обход
    }
    return true; // продолжить
  });
  return found;
}

/// Глобальная группа хоткеев «Навигация» для легенды F1.
const ShortcutGroup globalShortcutGroup = ShortcutGroup(
  title: 'Навигация',
  entries: <ShortcutEntry>[
    ShortcutEntry(keys: 'Ctrl+1..6', description: 'Переключить таб'),
    ShortcutEntry(keys: 'Ctrl+Tab', description: 'Следующий таб'),
    ShortcutEntry(keys: 'Ctrl+Shift+Tab', description: 'Предыдущий таб'),
    ShortcutEntry(keys: 'Escape', description: 'Назад'),
    ShortcutEntry(keys: 'Alt+←', description: 'Назад'),
    ShortcutEntry(keys: 'Ctrl+F', description: 'Поиск'),
    ShortcutEntry(keys: 'F5', description: 'Обновить'),
    ShortcutEntry(keys: 'F1', description: 'Эта справка'),
  ],
);
