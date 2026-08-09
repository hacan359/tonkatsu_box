import 'package:core/api/credential_names.dart';
import 'package:core/api/proxy_targets.dart';
import 'package:dio/dio.dart';

import 'server_origin.dart';

/// The keys the server holds. An unreachable server yields an empty map, so the
/// app boots with search disabled rather than not at all.
Future<Map<String, String>> fetchServerCredentials({Dio? dio}) async {
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
    if (data is! Map<String, Object?>) return const <String, String>{};

    return <String, String>{
      for (final String name in CredentialNames.all)
        if (data[name] case final String value when value.isNotEmpty)
          name: value,
    };
  } on Object {
    return const <String, String>{};
  }
}
