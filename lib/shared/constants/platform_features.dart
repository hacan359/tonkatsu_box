// Флаги доступности функций на текущей платформе.
import 'dart:io' show Platform;

import 'package:flutter/widgets.dart' show BuildContext, MediaQuery, Orientation;

/// Доступен ли Board (визуальная доска) на текущей платформе.
///
/// Board доступен на всех платформах.
bool get kCanvasEnabled => true;

/// Доступен ли VGMaps Browser (webview_windows).
bool get kVgMapsEnabled => Platform.isWindows;

/// Доступен ли Screenshot Capture.
bool get kScreenshotEnabled => Platform.isWindows;

/// Мобильная платформа (Android / iOS).
bool get kIsMobile => Platform.isAndroid || Platform.isIOS;

/// Геймпад поддерживается на десктопах и Android (handhelds).
/// Не поддерживается только на iOS (нет пакета gamepads).
bool get kGamepadSupported => !Platform.isIOS;

/// Ландшафтный режим на мобильном устройстве.
bool isLandscapeMobile(BuildContext context) {
  return kIsMobile &&
      MediaQuery.orientationOf(context) == Orientation.landscape;
}
