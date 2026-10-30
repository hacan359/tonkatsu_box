import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'browser_url_io.dart'
    if (dart.library.js_interop) 'browser_url_web.dart';
import 'server_origin.dart';

/// The query parameter of the sign-in link the server prints on start.
const String kServerTokenQueryParam = 'token';

/// The selfhost server's bearer token, kept in this browser's storage. One
/// global value, not per profile: the web build talks to exactly one server.
class ServerAuthToken {
  ServerAuthToken._();

  static const String _prefKey = 'server_auth_token';

  static SharedPreferences? _prefs;
  static String? _current;

  static Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    _current = _nonEmpty(prefs.getString(_prefKey));
  }

  /// Null until a token was saved; requests then go out without a header.
  static String? get current => _current;

  static Future<void> write(String token) async {
    final SharedPreferences prefs = _prefs ??=
        await SharedPreferences.getInstance();
    final String? value = _nonEmpty(token);
    _current = value;
    if (value == null) {
      await prefs.remove(_prefKey);
    } else {
      await prefs.setString(_prefKey, value);
    }
  }

  /// Stores the token a sign-in link carries and rewrites the address bar
  /// without it, so history and bookmarks do not keep the secret.
  static Future<bool> consumeFromUrl(Uri location) async {
    final String? token = _nonEmpty(
      location.queryParameters[kServerTokenQueryParam],
    );
    if (token == null) return false;
    await write(token);
    final Map<String, String> rest = Map<String, String>.of(
      location.queryParameters,
    )..remove(kServerTokenQueryParam);
    replaceBrowserUrl(
      Uri(
        path: location.path.isEmpty ? '/' : location.path,
        queryParameters: rest.isEmpty ? null : rest,
      ).toString(),
    );
    return true;
  }

  static String? _nonEmpty(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();
}

/// Reads the token per request, so one saved in Settings or on the token
/// screen applies at once instead of after every Dio in the app is rebuilt.
class ServerAuthInterceptor extends Interceptor {
  ServerAuthInterceptor({String? serverOrigin}) : _origin = serverOrigin;

  final String? _origin;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final String? token = ServerAuthToken.current;
    // Only our own server gets the secret; the proxy rewrite ran first, so
    // an upstream call already points at it and a stray host never will.
    if (token != null && options.uri.origin == (_origin ?? serverBaseUrl())) {
      // A literal rather than HttpHeaders: dart:io must stay out of web code.
      options.headers['authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
