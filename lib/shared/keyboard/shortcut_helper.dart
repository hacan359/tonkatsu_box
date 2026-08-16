import 'package:flutter/material.dart';

import '../constants/platform_features.dart';

/// Returns [child] untouched on mobile, where there is no keyboard.
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

/// Appends the shortcut to a tooltip label; a no-op on mobile.
String tooltipWithShortcut(String label, String shortcut) {
  if (kIsMobile) return label;
  return '$label ($shortcut)';
}
