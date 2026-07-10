// Intentionally empty. This package exists only so that the pub resolver
// picks it instead of the real gamepads_windows, whose native device
// listener crashes on USB connect/disconnect. Nothing imports this library:
// the real package is native-only and the app's Dart side never subscribes
// to gamepad events on Windows.
