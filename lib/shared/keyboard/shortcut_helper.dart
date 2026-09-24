import 'package:flutter/material.dart';

import '../constants/platform_features.dart';

/// Returns [child] untouched on mobile, where there is no keyboard. The
/// Focus exists so a freshly pushed route has focus under its own shortcuts.
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
      // A whole-screen node is invisible; Tab and D-pad must skip it.
      skipTraversal: true,
      child: child,
    ),
  );
}

/// Appends the shortcut to a tooltip label; a no-op on mobile.
String tooltipWithShortcut(String label, String shortcut) {
  if (kIsMobile) return label;
  return '$label ($shortcut)';
}
