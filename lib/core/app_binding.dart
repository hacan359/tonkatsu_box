import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef CtrlWheelHandler = void Function(PointerScrollEvent event);

/// Takes Ctrl+wheel before hit-testing: the innermost scrollable wins the
/// pointer-signal resolver, and AlwaysScrollableScrollPhysics never declines.
class TonkatsuBinding extends WidgetsFlutterBinding {
  static TonkatsuBinding? _instance;

  /// Installed by the app root; while null every wheel goes through as usual.
  static CtrlWheelHandler? onCtrlWheel;

  static TonkatsuBinding ensureInitialized() => _instance ?? TonkatsuBinding();

  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
  }

  @override
  void dispatchEvent(PointerEvent event, HitTestResult? hitTestResult) {
    final CtrlWheelHandler? handler = onCtrlWheel;
    if (handler != null &&
        event is PointerScrollEvent &&
        HardwareKeyboard.instance.isControlPressed) {
      handler(event);
      return;
    }
    super.dispatchEvent(event, hitTestResult);
  }
}
