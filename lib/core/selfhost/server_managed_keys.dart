import 'package:core/api/credential_names.dart';
import 'package:core/api/proxy_targets.dart';
import 'package:dio/dio.dart';

import 'server_origin.dart';

/// Stands in for a secret the browser may not hold: the API clients gate on
/// "is a key configured", and the proxy swaps this for the real one.
const String kServerManagedKey = 'server-managed';

/// Presence only, never a value. An unreachable server yields an empty map, so
/// the app boots with search disabled rather than not at all.
Future<Map<String, bool>> fetchServerCredentialAvailability({Dio? dio}) async {
  final Dio client = dio ??
      Dio(BaseOptions(
        baseUrl: serverBaseUrl(),
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

  try {
    final Response<Object?> response =
        await client.get<Object?>('$kProxyPathPrefix/keys');
    final Object? data = response.data;
    if (data is! Map<String, Object?>) return const <String, bool>{};

    return <String, bool>{
      for (final String name in CredentialNames.all)
        if (data[name] == true) name: true,
    };
  } on Object {
    return const <String, bool>{};
  }
}
