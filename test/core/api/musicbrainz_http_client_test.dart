import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/musicbrainz/musicbrainz_http_client.dart';
import 'package:tonkatsu_box/core/api/musicbrainz/musicbrainz_types.dart';

import '../../helpers/test_helpers.dart';

DioException _statusError(int status, {Map<String, List<String>>? headers}) {
  final RequestOptions options = RequestOptions(path: 'release-group');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: status,
      headers: Headers.fromMap(headers ?? <String, List<String>>{}),
    ),
  );
}

Response<dynamic> _okResponse() => Response<dynamic>(
      requestOptions: RequestOptions(path: 'release-group'),
      statusCode: 200,
      data: <String, dynamic>{},
    );

void main() {
  group('MusicBrainzHttpClient', () {
    late MockDio dio;
    late MusicBrainzHttpClient client;

    setUp(() {
      dio = MockDio();
      client = MusicBrainzHttpClient(dio: dio);
    });

    group('get', () {
      test('should retry and succeed when 503 clears', () async {
        int calls = 0;
        when(() => dio.get<dynamic>(any(),
            queryParameters: any(named: 'queryParameters'))).thenAnswer((_) {
          calls++;
          if (calls == 1) {
            throw _statusError(503, headers: <String, List<String>>{
              'retry-after': <String>['1'],
            });
          }
          return Future<Response<dynamic>>.value(_okResponse());
        });

        final Response<dynamic> response = await client.get('release-group');

        expect(response.statusCode, 200);
        expect(calls, 2);
      });

      test('should rethrow when 503 persists through every attempt', () async {
        when(() => dio.get<dynamic>(any(),
                queryParameters: any(named: 'queryParameters')))
            .thenThrow(_statusError(503, headers: <String, List<String>>{
          'retry-after': <String>['1'],
        }));

        await expectLater(
          client.get('release-group'),
          throwsA(isA<DioException>()),
        );
        verify(() => dio.get<dynamic>(any(),
            queryParameters: any(named: 'queryParameters'))).called(3);
      }, timeout: const Timeout(Duration(seconds: 20)));

      test('should not retry when the error is not 503', () async {
        when(() => dio.get<dynamic>(any(),
                queryParameters: any(named: 'queryParameters')))
            .thenThrow(_statusError(404));

        await expectLater(
          client.get('release-group/x'),
          throwsA(isA<DioException>()),
        );
        verify(() => dio.get<dynamic>(any(),
            queryParameters: any(named: 'queryParameters'))).called(1);
      });

      test('should always append fmt=json to the query', () async {
        when(() => dio.get<dynamic>(any(),
                queryParameters: any(named: 'queryParameters')))
            .thenAnswer((_) async => _okResponse());

        await client.get('release-group',
            queryParameters: <String, dynamic>{'query': 'x'});

        final Map<String, dynamic> params = verify(() => dio.get<dynamic>(
                any(),
                queryParameters: captureAny(named: 'queryParameters')))
            .captured
            .single as Map<String, dynamic>;
        expect(params['fmt'], 'json');
        expect(params['query'], 'x');
      });
    });

    group('handleDioException', () {
      test('should label a 503 as the rate limit', () {
        final MusicBrainzApiException e =
            client.handleDioException(_statusError(503), 'fallback');

        expect(e.statusCode, 503);
        expect(e.message, contains('rate limit'));
      });

      test('should keep the default message for other statuses', () {
        final MusicBrainzApiException e =
            client.handleDioException(_statusError(500), 'fallback');

        expect(e.message, 'fallback');
      });
    });
  });
}
