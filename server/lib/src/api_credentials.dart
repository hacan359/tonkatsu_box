import 'dart:convert';
import 'dart:io';

import 'package:core/api/credential_names.dart';
import 'package:path/path.dart' as p;

export 'package:core/api/credential_names.dart' show CredentialNames;

/// The keys file is unreadable or not an object — a misconfiguration worth
/// stopping for, since the alternative is 503s nobody can explain.
class ApiCredentialsException implements Exception {
  const ApiCredentialsException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Secrets the proxy injects into outgoing requests. They never travel to the
/// browser — a client only learns *which* of them are set.
class ApiCredentials {
  const ApiCredentials(this._values);

  /// `<data>/keys.json` first, then env (`TONKATSU_KEY_<NAME>`), so a container
  /// can override a mounted file without rewriting it.
  factory ApiCredentials.load({
    Map<String, String> env = const <String, String>{},
    String? dataDir,
  }) {
    final Map<String, String> values = <String, String>{};

    if (dataDir != null) {
      final File file = File(p.join(dataDir, 'keys.json'));
      if (file.existsSync()) {
        final Object? decoded;
        try {
          decoded = jsonDecode(file.readAsStringSync());
        } on FormatException catch (e) {
          throw ApiCredentialsException('${file.path} is not valid JSON: $e');
        }
        if (decoded is! Map<String, Object?>) {
          throw ApiCredentialsException('${file.path} must hold a JSON object');
        }
        decoded.forEach((String name, Object? value) {
          if (value is String && value.isNotEmpty) values[name] = value;
        });
      }
    }

    for (final String name in CredentialNames.all) {
      final String? fromEnv = env['TONKATSU_KEY_${name.toUpperCase()}'];
      if (fromEnv != null && fromEnv.isNotEmpty) values[name] = fromEnv;
    }

    return ApiCredentials(values);
  }

  final Map<String, String> _values;

  /// Empty reads as absent, so a blank env var cannot become an empty `Bearer`.
  String? operator [](String name) {
    final String? value = _values[name];
    return (value == null || value.isEmpty) ? null : value;
  }

  bool has(String name) => this[name] != null;

  /// What `/proxy/keys` answers: presence only, never a value.
  Map<String, bool> get availability => <String, bool>{
        for (final String name in CredentialNames.all) name: has(name),
      };
}
