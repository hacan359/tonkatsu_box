// Helper for building detailed API error info from DioException.

import 'package:dio/dio.dart';

/// Query-parameter names that must be redacted from error details.
///
/// Covers credentials used across all API clients (RA, TMDB, SteamGridDB,
/// IGDB, AniList). Comparison is case-insensitive.
const Set<String> _redactKeys = <String>{
  'y', // RetroAchievements
  'api_key',
  'apikey',
  'key',
  'token',
  'access_token',
  'client_secret',
  'authorization',
};

String _redactUri(Uri uri) {
  if (uri.queryParameters.isEmpty) return uri.toString();
  final StringBuffer query = StringBuffer();
  bool first = true;
  for (final MapEntry<String, String> e in uri.queryParameters.entries) {
    if (!first) query.write('&');
    first = false;
    final String value = _redactKeys.contains(e.key.toLowerCase())
        ? '***'
        : Uri.encodeQueryComponent(e.value);
    query.write('${Uri.encodeQueryComponent(e.key)}=$value');
  }
  final String base = uri.replace(query: '').toString();
  final String stripped =
      base.endsWith('?') ? base.substring(0, base.length - 1) : base;
  return '$stripped?$query';
}

final RegExp _redactRegExp = RegExp(
  r'(\b(?:' + _redactKeys.join('|') + r')=)[^&\s"]+',
  caseSensitive: false,
);

String _redactString(String input) {
  return input.replaceAllMapped(
    _redactRegExp,
    (Match m) => '${m.group(1)}***',
  );
}

/// Builds a detailed debug string from a [DioException].
///
/// Includes the API name, request URL and method, status code,
/// DioException type, and underlying error if present. Sensitive query
/// parameters (api keys, tokens) are redacted so the result is safe to
/// copy to the clipboard.
String buildApiErrorDetail({
  required String apiName,
  required DioException exception,
  required String userMessage,
}) {
  final StringBuffer buf = StringBuffer()
    ..writeln('API: $apiName')
    ..writeln('Error: $userMessage')
    ..writeln(
        'URL: ${exception.requestOptions.method} ${_redactUri(exception.requestOptions.uri)}');

  final int? statusCode = exception.response?.statusCode;
  if (statusCode != null) {
    buf.writeln('Status: $statusCode');
  }

  buf.writeln('Type: ${exception.type.name}');

  if (exception.message != null) {
    buf.writeln('Dio: ${_redactString(exception.message!)}');
  }

  if (exception.error != null) {
    buf.writeln('Cause: ${_redactString(exception.error.toString())}');
  }

  final Object? responseData = exception.response?.data;
  if (responseData != null) {
    final String body = _redactString(responseData.toString());
    final String truncated =
        body.length > 500 ? '${body.substring(0, 500)}...' : body;
    buf.writeln('Response: $truncated');
  }

  return buf.toString().trimRight();
}
