// Флаги доступности функций на текущей платформе.
import 'dart:io' show Platform;

/// Доступен ли Canvas (холст) на текущей платформе.
///
/// Canvas отключён на мобильных платформах (Android, iOS).
bool get kCanvasEnabled => !Platform.isAndroid && !Platform.isIOS;

/// Доступен ли VGMaps Browser (webview_windows).
bool get kVgMapsEnabled => Platform.isWindows;

/// Доступен ли Screenshot Capture.
bool get kScreenshotEnabled => Platform.isWindows;
