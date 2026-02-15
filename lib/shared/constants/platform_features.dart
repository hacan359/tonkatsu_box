// Флаги доступности функций на текущей платформе.
import 'dart:io' show Platform;

/// Доступен ли Board (визуальная доска) на текущей платформе.
///
/// Board доступен на всех платформах.
bool get kCanvasEnabled => true;

/// Доступен ли VGMaps Browser (webview_windows).
bool get kVgMapsEnabled => Platform.isWindows;

/// Доступен ли Screenshot Capture.
bool get kScreenshotEnabled => Platform.isWindows;
