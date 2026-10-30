import 'package:web/web.dart' as web;

/// `replaceState` rather than a Navigator route: the app has no Router, so
/// Flutter's own route reporting leaves the browser URL untouched.
void replaceBrowserUrl(String url) {
  web.window.history.replaceState(null, '', url);
}
