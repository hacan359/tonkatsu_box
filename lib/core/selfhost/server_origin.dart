/// Points a `flutter run -d chrome` session at a server on another port; empty
/// in the selfhost deployment, where the page comes from that same server.
const String kServerBaseUrl = String.fromEnvironment('SERVER_BASE_URL');

/// Only meaningful in a browser — `Uri.base` is the current document there and
/// a `file:` directory everywhere else.
String serverBaseUrl() =>
    kServerBaseUrl.isEmpty ? Uri.base.origin : kServerBaseUrl;
