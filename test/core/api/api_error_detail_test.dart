import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/core/api/api_error_detail.dart';

DioException _exception({
  required Uri uri,
  String method = 'GET',
  int? statusCode,
  Object? responseData,
  String? message,
  Object? error,
  DioExceptionType type = DioExceptionType.badResponse,
}) {
  final RequestOptions options = RequestOptions(
    path: uri.path,
    method: method,
    baseUrl: '${uri.scheme}://${uri.authority}',
    queryParameters: uri.queryParameters,
  );
  return DioException(
    requestOptions: options,
    response: statusCode == null && responseData == null
        ? null
        : Response<Object?>(
            requestOptions: options,
            statusCode: statusCode,
            data: responseData,
          ),
    type: type,
    message: message,
    error: error,
  );
}

void main() {
  group('buildApiErrorDetail', () {
    test('redacts RetroAchievements y= api key from URL', () {
      final String detail = buildApiErrorDetail(
        apiName: 'RA',
        exception: _exception(
          uri: Uri.parse(
            'https://retroachievements.org/API/API_GetUserProfile.php'
            '?u=TestUser&y=SECRET_KEY_12345',
          ),
          statusCode: 401,
        ),
        userMessage: 'Unauthorized',
      );

      expect(detail, contains('y=***'));
      expect(detail, isNot(contains('SECRET_KEY_12345')));
      expect(detail, contains('u=TestUser'));
      expect(detail, contains('Status: 401'));
    });

    test('redacts api_key query parameter', () {
      final String detail = buildApiErrorDetail(
        apiName: 'TMDB',
        exception: _exception(
          uri: Uri.parse(
            'https://api.themoviedb.org/3/find/123?api_key=TOPSECRET&language=en',
          ),
        ),
        userMessage: 'Network error',
      );

      expect(detail, contains('api_key=***'));
      expect(detail, isNot(contains('TOPSECRET')));
      expect(detail, contains('language=en'));
    });

    test('redacts case-insensitive query param names', () {
      final String detail = buildApiErrorDetail(
        apiName: 'X',
        exception: _exception(
          uri: Uri.parse('https://example.com/x?API_KEY=AAA&Token=BBB'),
        ),
        userMessage: 'err',
      );

      expect(detail, isNot(contains('AAA')));
      expect(detail, isNot(contains('BBB')));
      expect(detail, contains('API_KEY=***'));
      expect(detail, contains('Token=***'));
    });

    test('redacts keys inside Dio message string', () {
      final String detail = buildApiErrorDetail(
        apiName: 'RA',
        exception: _exception(
          uri: Uri.parse('https://retroachievements.org/API/x.php'),
          message:
              'DioException: failed to fetch https://example.com/x?y=LEAKED_KEY',
        ),
        userMessage: 'fail',
      );

      expect(detail, contains('Dio:'));
      expect(detail, isNot(contains('LEAKED_KEY')));
      expect(detail, contains('y=***'));
    });

    test('redacts keys inside Cause string', () {
      final String detail = buildApiErrorDetail(
        apiName: 'TMDB',
        exception: _exception(
          uri: Uri.parse('https://api.themoviedb.org/3/find'),
          error: 'SocketException on api_key=SHOULD_BE_HIDDEN',
        ),
        userMessage: 'fail',
      );

      expect(detail, contains('Cause:'));
      expect(detail, isNot(contains('SHOULD_BE_HIDDEN')));
      expect(detail, contains('api_key=***'));
    });

    test('redacts keys inside response body', () {
      final String detail = buildApiErrorDetail(
        apiName: 'RA',
        exception: _exception(
          uri: Uri.parse('https://retroachievements.org/x.php'),
          statusCode: 500,
          responseData: '{"echo":"y=ECHOED_KEY","ok":false}',
        ),
        userMessage: 'server error',
      );

      expect(detail, contains('Response:'));
      expect(detail, isNot(contains('ECHOED_KEY')));
      expect(detail, contains('y=***'));
    });

    test('preserves non-sensitive params untouched', () {
      final String detail = buildApiErrorDetail(
        apiName: 'X',
        exception: _exception(
          uri: Uri.parse(
            'https://example.com/items?page=2&id=42&sort=name',
          ),
        ),
        userMessage: 'err',
      );

      expect(detail, contains('page=2'));
      expect(detail, contains('id=42'));
      expect(detail, contains('sort=name'));
    });

    test('handles URL without query parameters', () {
      final String detail = buildApiErrorDetail(
        apiName: 'X',
        exception: _exception(
          uri: Uri.parse('https://example.com/items'),
        ),
        userMessage: 'err',
      );

      expect(detail, contains('URL: GET https://example.com/items'));
    });

    test('truncates very long response bodies after redaction', () {
      final String longBody = 'y=LEAKED&data=${'A' * 600}';
      final String detail = buildApiErrorDetail(
        apiName: 'X',
        exception: _exception(
          uri: Uri.parse('https://example.com/x'),
          statusCode: 500,
          responseData: longBody,
        ),
        userMessage: 'err',
      );

      expect(detail, isNot(contains('LEAKED')));
      expect(detail, contains('...'));
    });

    test('includes apiName, userMessage, method and type', () {
      final String detail = buildApiErrorDetail(
        apiName: 'TMDB',
        exception: _exception(
          uri: Uri.parse('https://api.themoviedb.org/3/find'),
          method: 'POST',
          type: DioExceptionType.connectionTimeout,
        ),
        userMessage: 'Timed out',
      );

      expect(detail, contains('API: TMDB'));
      expect(detail, contains('Error: Timed out'));
      expect(detail, contains('URL: POST'));
      expect(detail, contains('Type: connectionTimeout'));
    });
  });
}
