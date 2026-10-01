import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/constants/platform_features.dart';

/// Where the browser remembers the selfhost server's bearer token.
///
/// The server only demands a token when it listens beyond loopback; loopback
/// installs skip it entirely and this value simply stays empty. The token is
/// stored in [SharedPreferences] — the same store the rest of the web build
/// uses — and copied into [_cached] at boot so every request can read it
/// synchronously while building its headers.
class ServerAuthToken {
  ServerAuthToken._();

  static const String _prefKey = 'server_auth_token';

  /// In-memory copy for synchronous reads while constructing requests.
  static String? _cached;

  /// Loads the remembered token into [_cached]. Call once at boot, before any
  /// request goes out.
  static Future<void> init() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? value = prefs.getString(_prefKey);
    _cached = (value == null || value.isEmpty) ? null : value;
  }

  /// The token requests carry, or null when none is stored.
  static String? get current => _cached;

  /// Saves the token the operator pasted in. Empty clears it.
  static Future<void> write(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _cached = token.isEmpty ? null : token;
    if (token.isEmpty) {
      await prefs.remove(_prefKey);
    } else {
      await prefs.setString(_prefKey, token);
    }
  }

  /// Adds `Authorization: Bearer <token>` to [headers] when a token is held.
  /// The literal key (not `HttpHeaders.authorizationHeader`) keeps this file
  /// free of `dart:io`, which the web build must not import.
  static Map<String, String> withToken(
      Map<String, String> headers, String? token) {
    if (token == null || token.isEmpty) return headers;
    return <String, String>{
      ...headers,
      'authorization': 'Bearer $token',
    };
  }
}