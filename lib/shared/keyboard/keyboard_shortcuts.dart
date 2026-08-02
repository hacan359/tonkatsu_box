
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../constants/platform_features.dart';

/// One row of the F1 shortcut legend.
class ShortcutEntry {
  const ShortcutEntry({required this.keys, required this.description});

  /// Human-readable combo, e.g. `Ctrl+N`.
  final String keys;

  /// What the combo does.
  final String description;
}

/// One section of the F1 legend.
class ShortcutGroup {
  const ShortcutGroup({required this.title, required this.entries});

  /// Section heading.
  final String title;

  final List<ShortcutEntry> entries;
}

/// Desktop only. Returns the [ShortcutActivator] → callback map for
/// [CallbackShortcuts].
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
    // Ctrl+1..6 switch tabs.
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

    const SingleActivator(LogicalKeyboardKey.tab, control: true):
        onNextTab,
    const SingleActivator(LogicalKeyboardKey.tab, control: true, shift: true):
        onPreviousTab,

    const SingleActivator(LogicalKeyboardKey.escape):
        onBack,

    // Alt+Left goes back, browser-style.
    const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true):
        onBack,

    const SingleActivator(LogicalKeyboardKey.keyF, control: true):
        onSearch,

    const SingleActivator(LogicalKeyboardKey.f5):
        onRefresh,

    const SingleActivator(LogicalKeyboardKey.f1):
        onShowHelp,
  };
}

/// Suppresses single-letter hotkeys (V, B, L…) while the user is typing.
bool isTextFieldFocused() {
  final FocusNode? focus = FocusManager.instance.primaryFocus;
  if (focus == null) return false;

  final BuildContext? ctx = focus.context;
  if (ctx == null) return false;

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

/// Global navigation shortcuts group for the F1 legend.
ShortcutGroup globalShortcutGroup(S l) => ShortcutGroup(
      title: l.shortcutsGroupNavigation,
      entries: <ShortcutEntry>[
        ShortcutEntry(keys: 'Ctrl+1..6', description: l.shortcutSwitchTab),
        ShortcutEntry(keys: 'Ctrl+Tab', description: l.shortcutNextTab),
        ShortcutEntry(keys: 'Ctrl+Shift+Tab', description: l.shortcutPreviousTab),
        ShortcutEntry(keys: 'Escape', description: l.back),
        ShortcutEntry(keys: 'Alt+←', description: l.back),
        ShortcutEntry(keys: 'Ctrl+F', description: l.search),
        ShortcutEntry(keys: 'F5', description: l.refresh),
        ShortcutEntry(keys: 'F1', description: l.shortcutThisHelp),
      ],
    );
