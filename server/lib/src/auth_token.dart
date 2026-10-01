import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';

/// A server that listens beyond loopback is reachable by anyone on the LAN (or
/// the internet behind a NAT), and the `/rpc` and `/proxy/keys` endpoints would
/// hand them the whole database and every API key. When that happens the
/// server requires a bearer token that only the operator holds.
///
/// Loopback installs (the default) skip the token entirely: whoever can reach
/// a 127.0.0.1 socket already owns the machine the data lives on, and the
/// browser is loaded from the same server, so forcing a token there would just
/// lock the owner out of their own setup.
class AuthToken {
  AuthToken._(this.raw, {required this.dataDir});

  /// The token in plain text, for the operator to copy into the browser.
  final String raw;

  /// Where the token persists, so a restart does not invalidate every browser.
  final String? dataDir;

  /// Loads `<dataDir>/auth_token`, generating and persisting one when the
  /// file is absent but [generate] is requested. A missing [dataDir] yields
  /// an in-memory token that rotates on every boot — acceptable for tests.
  factory AuthToken.load({
    String? dataDir,
    bool generate = false,
  }) {
    if (dataDir != null) {
      final File file = File(p.join(dataDir, 'auth_token'));
      if (file.existsSync()) {
        final String raw = file.readAsStringSync().trim();
        if (raw.isNotEmpty) return AuthToken._(raw, dataDir: dataDir);
      }
    }
    if (!generate) {
      // Absent file and no instruction to mint one: behave as "no token". The
      // caller (loopback-only) then skips auth entirely.
      return AuthToken._('', dataDir: dataDir);
    }
    final String raw = _generate();
    if (dataDir != null) {
      final File file = File(p.join(dataDir, 'auth_token'));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('$raw\n', flush: true);
    }
    return AuthToken._(raw, dataDir: dataDir);
  }

  /// Constant-time re-check against a client-supplied value, so a timing side
  /// channel cannot tell a wrong token from a shorter one.
  bool matches(String? candidate) {
    if (candidate == null || candidate.isEmpty) return false;
    final String a = candidate;
    final String b = raw;
    if (a.length != b.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  /// Reads the bearer value out of a request, or null when absent.
  static String? bearerOf(Request request) {
    final String? header = request.headers[HttpHeaders.authorizationHeader];
    if (header == null) return null;
    const String prefix = 'Bearer ';
    if (!header.startsWith(prefix)) return null;
    final String value = header.substring(prefix.length).trim();
    return value.isEmpty ? null : value;
  }

  static final Random _random = Random.secure();

  static String _generate() {
    final List<int> bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}