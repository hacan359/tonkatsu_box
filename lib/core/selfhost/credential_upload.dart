import 'dart:convert';

import 'package:core/api/credential_names.dart';
import 'package:core/api/proxy_targets.dart';
import 'package:dio/dio.dart';

import 'server_origin.dart';

/// The exported config spells its keys the way SharedPreferences does; the
/// proxy spells them its own way. This is the only place the two meet.
const Map<String, String> kConfigKeyToCredential = <String, String>{
  'tmdb_api_key': CredentialNames.tmdb,
  'tvdb_api_key': CredentialNames.tvdb,
  'steamgriddb_api_key': CredentialNames.steamGridDb,
  'igdb_client_id': CredentialNames.igdbClientId,
  'igdb_client_secret': CredentialNames.igdbClientSecret,
  'ra_username': CredentialNames.raUsername,
  'ra_api_key': CredentialNames.ra,
  'comicvine_api_key': CredentialNames.comicVine,
  'google_books_api_key': CredentialNames.googleBooks,
  'hardcover_api_key': CredentialNames.hardcover,
  'simkl_client_id': CredentialNames.simklClientId,
};

/// Pulls the credentials out of an exported config, ignoring everything else
/// in it — theme and language are the browser's business, not the server's.
Map<String, String> credentialsFromConfig(List<int> bytes) {
  final Object? decoded = jsonDecode(utf8.decode(bytes));
  if (decoded is! Map<String, Object?>) return const <String, String>{};

  return <String, String>{
    for (final MapEntry<String, String> pair in kConfigKeyToCredential.entries)
      if (decoded[pair.key] case final String value when value.isNotEmpty)
        pair.value: value,
  };
}

/// Hands them to the server and returns what it now holds. They pass through
/// the tab but are never stored there.
Future<Map<String, bool>> uploadCredentials(
  Map<String, String> credentials, {
  Dio? dio,
}) async {
  final Dio client = dio ??
      Dio(BaseOptions(
        baseUrl: serverBaseUrl(),
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));

  final Response<Object?> response = await client.post<Object?>(
    '$kProxyPathPrefix/keys',
    data: credentials,
  );
  final Object? data = response.data;
  if (data is! Map<String, Object?>) return const <String, bool>{};

  return <String, bool>{
    for (final String name in CredentialNames.all)
      if (data[name] == true) name: true,
  };
}
