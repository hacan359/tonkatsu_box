// Утилиты для клавиатурных сочетаний.

import 'package:flutter/material.dart';

import '../constants/platform_features.dart';

/// Оборачивает [child] в [CallbackShortcuts] + [Focus] для экранных хоткеев.
///
/// На мобильных платформах возвращает [child] без обёрток.
/// [autofocus] управляет автоматическим фокусом (по умолчанию true).
Widget wrapWithScreenShortcuts({
  required Map<ShortcutActivator, VoidCallback> bindings,
  required Widget child,
  bool autofocus = true,
}) {
  if (kIsMobile) return child;

  return CallbackShortcuts(
    bindings: bindings,
    child: Focus(
      autofocus: autofocus,
      child: child,
    ),
  );
}

/// Форматирует хоткей для tooltip: 'Текст (Ctrl+N)'.
String tooltipWithShortcut(String label, String shortcut) {
  if (kIsMobile) return label;
  return '$label ($shortcut)';
}
