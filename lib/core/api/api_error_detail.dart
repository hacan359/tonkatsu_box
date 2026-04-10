// Helper for building detailed API error info from DioException.

import 'package:dio/dio.dart';

/// Builds a detailed debug string from a [DioException].
///
/// Includes the API name, request URL and method, status code,
/// DioException type, and underlying error if present.
String buildApiErrorDetail({
  required String apiName,
  required DioException exception,
  required String userMessage,
}) {
  final StringBuffer buf = StringBuffer()
    ..writeln('API: $apiName')
    ..writeln('Error: $userMessage')
    ..writeln(
        'URL: ${exception.requestOptions.method} ${exception.requestOptions.uri}');

  final int? statusCode = exception.response?.statusCode;
  if (statusCode != null) {
    buf.writeln('Status: $statusCode');
  }

  buf.writeln('Type: ${exception.type.name}');

  if (exception.message != null) {
    buf.writeln('Dio: ${exception.message}');
  }

  if (exception.error != null) {
    buf.writeln('Cause: ${exception.error}');
  }

  final Object? responseData = exception.response?.data;
  if (responseData != null) {
    final String body = responseData.toString();
    final String truncated =
        body.length > 500 ? '${body.substring(0, 500)}...' : body;
    buf.writeln('Response: $truncated');
  }

  return buf.toString().trimRight();
}
