import 'dart:convert';

import 'package:core/api/credential_names.dart';
import 'package:core/api/proxy_targets.dart';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/constants/platform_features.dart';
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
  'podcastindex_api_key': CredentialNames.podcastIndexKey,
  'podcastindex_api_secret': CredentialNames.podcastIndexSecret,
  'screenscraper_ssid': CredentialNames.ssSsid,
  'screenscraper_sspassword': CredentialNames.ssSspassword,
};

final Map<String, String> kCredentialToConfigKey = <String, String>{
  for (final MapEntry<String, String> e in kConfigKeyToCredential.entries)
    e.value: e.key,
};

Dio _client(Dio? override) =>
    override ??
    Dio(BaseOptions(
      baseUrl: serverBaseUrl(),
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

/// The keys the server holds. An unreachable server yields an empty map, so the
/// app boots with search disabled rather than not at all.
Future<Map<String, String>> fetchServerCredentials({Dio? dio}) async {
  try {
    final Response<Object?> response =
        await _client(dio).get<Object?>('$kProxyPathPrefix/keys');
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

/// Pushes everything the prefs hold, for the screens that write a credential
/// straight to SharedPreferences instead of going through SettingsNotifier.
Future<void> syncCredentialsToServer(SharedPreferences prefs) async {
  if (!kIsWebBuild) return;
  final Map<String, String> credentials = <String, String>{
    for (final MapEntry<String, String> e in kConfigKeyToCredential.entries)
      if (prefs.getString(e.key) case final String value when value.isNotEmpty)
        e.value: value,
  };
  if (credentials.isEmpty) return;
  try {
    await uploadCredentials(credentials);
  } on Object catch (e) {
    // Best effort: the import/restore that triggered the sync has already
    // committed, so a failed upload must not abort its success path.
    Logger('ServerCredentials').warning('Failed to sync credentials', e);
  }
}

/// Hands them to the server, which is where the proxy reads them from, and
/// returns what it now holds. An empty value clears one.
Future<Map<String, String>> uploadCredentials(
  Map<String, String> credentials, {
  Dio? dio,
}) async {
  final Response<Object?> response = await _client(dio).post<Object?>(
    '$kProxyPathPrefix/keys',
    data: credentials,
  );
  final Object? data = response.data;
  if (data is! Map<String, Object?>) return const <String, String>{};

  return <String, String>{
    for (final String name in CredentialNames.all)
      if (data[name] case final String value) name: value,
  };
}
