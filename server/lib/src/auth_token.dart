import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';

/// Lives next to the database so a restart keeps every browser signed in.
const String kAuthTokenFileName = 'auth_token';

/// The one secret a selfhost server holds: whoever carries it owns `/rpc`.
class AuthToken {
  const AuthToken(this.raw);

  /// [explicit] wins over the stored file, which wins over minting a new one —
  /// an operator-set value must never be silently replaced by a generated one.
  factory AuthToken.load({required String dataDir, String? explicit}) {
    final String? given = explicit?.trim();
    if (given != null && given.isNotEmpty) return AuthToken(given);

    final File file = File(p.join(dataDir, kAuthTokenFileName));
    if (file.existsSync()) {
      final String stored = file.readAsStringSync().trim();
      if (stored.isNotEmpty) return AuthToken(stored);
    }

    final AuthToken fresh = AuthToken.generate();
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('${fresh.raw}\n', flush: true);
    return fresh;
  }

  factory AuthToken.generate() {
    final Random random = Random.secure();
    final List<int> bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return AuthToken(base64UrlEncode(bytes).replaceAll('=', ''));
  }

  final String raw;

  /// Constant time: a wrong first byte must not answer faster than a wrong last.
  bool matches(String? candidate) {
    if (candidate == null || candidate.length != raw.length) return false;
    int diff = 0;
    for (int i = 0; i < raw.length; i++) {
      diff |= candidate.codeUnitAt(i) ^ raw.codeUnitAt(i);
    }
    return diff == 0;
  }

  /// The scheme is case-insensitive per RFC 7235; the token itself is not.
  static String? bearerOf(Request request) {
    final String? header = request.headers[HttpHeaders.authorizationHeader];
    if (header == null) return null;
    const String scheme = 'bearer ';
    if (header.length <= scheme.length ||
        header.substring(0, scheme.length).toLowerCase() != scheme) {
      return null;
    }
    final String value = header.substring(scheme.length).trim();
    return value.isEmpty ? null : value;
  }
}
