import 'package:flutter/widgets.dart' show BuildContext, MediaQuery, Orientation;

// A conditional import, not `kIsWeb`: only this keeps dart:io out of the web
// compile. defaultTargetPlatform would also report android in Windows tests.
import 'platform_features_io.dart'
    if (dart.library.js_interop) 'platform_features_web.dart'
    as platform;

/// Whether this is the selfhost web build (served from the container).
/// Const so dart2js tree-shakes desktop-only screens behind `!kIsWebBuild`.
const bool kIsWebBuild = platform.isWeb;

/// Whether the Board (visual canvas) is available. Available on all platforms.
bool get kCanvasEnabled => true;

/// Whether the VGMaps browser (webview_windows) is available.
bool get kVgMapsEnabled => platform.isWindows;

/// Whether screenshot capture is available.
bool get kScreenshotEnabled => platform.isWindows;

/// Discord Rich Presence is available on desktop.
bool get kDiscordRpcAvailable =>
    platform.isWindows || platform.isLinux || platform.isMacOS;

/// Mobile platform (Android / iOS).
bool get kIsMobile => platform.isAndroid || platform.isIOS;

/// Off on Windows — gamepads_windows crashes with 0xc0000005 in its polling
/// thread for some users. Off on iOS and web: no plugin.
bool get kGamepadSupported =>
    !platform.isIOS && !platform.isWindows && !platform.isWeb;

/// Landscape orientation on a mobile device.
bool isLandscapeMobile(BuildContext context) {
  return kIsMobile &&
      MediaQuery.orientationOf(context) == Orientation.landscape;
}

/// Compact screen (<600px) — mobile or a narrow desktop window.
bool isCompactScreen(BuildContext context) {
  return MediaQuery.sizeOf(context).width < 600;
}

/// Switches the content layout to its desktop form. Unrelated to the side
/// menu, which is unified across all widths.
const double kDesktopContentBreakpoint = 800;
