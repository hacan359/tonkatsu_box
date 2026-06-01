// Feature-availability flags for the current platform.
import 'dart:io' show Platform;

import 'package:flutter/widgets.dart' show BuildContext, MediaQuery, Orientation;

/// Whether the Board (visual canvas) is available. Available on all platforms.
bool get kCanvasEnabled => true;

/// Whether the VGMaps browser (webview_windows) is available.
bool get kVgMapsEnabled => Platform.isWindows;

/// Whether screenshot capture is available.
bool get kScreenshotEnabled => Platform.isWindows;

/// Discord Rich Presence is available on desktop.
bool get kDiscordRpcAvailable =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;

/// Mobile platform (Android / iOS).
bool get kIsMobile => Platform.isAndroid || Platform.isIOS;

/// Disabled on Windows: the native gamepads_windows plugin crashes with an
/// access violation (0xc0000005) in its device-polling thread for some users.
/// Disabled on iOS: no gamepads package.
bool get kGamepadSupported => !Platform.isIOS && !Platform.isWindows;

/// Landscape orientation on a mobile device.
bool isLandscapeMobile(BuildContext context) {
  return kIsMobile &&
      MediaQuery.orientationOf(context) == Orientation.landscape;
}

/// Compact screen (<600px) — mobile or a narrow desktop window.
bool isCompactScreen(BuildContext context) {
  return MediaQuery.sizeOf(context).width < 600;
}

/// Width threshold where the "desktop" content layout kicks in (wider grid
/// columns, denser tables). Unrelated to the side menu, which is now unified
/// across all widths.
const double kDesktopContentBreakpoint = 800;
