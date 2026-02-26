import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/api/igdb_api.dart';
import 'package:xerabora/shared/models/platform.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late IgdbApi sut;
  late MockDio mockDio;

  const String testClientId = 'test_client_id';
  const String testClientSecret = 'test_client_secret';
  const String testAccessToken = 'test_access_token';

  setUp(() {
    mockDio = MockDio();
    sut = IgdbApi(dio: mockDio);
  });

  tearDown(() {
    sut.dispose();
  });

  group('TwitchAuthResult', () {
    test('должен создать из JSON', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'access_token': testAccessToken,
        'expires_in': 5000000,
        'token_type': 'bearer',
      };

      final TwitchAuthResult result = TwitchAuthResult.fromJson(json);

      expect(result.accessToken, equals(testAccessToken));
      expect(result.expiresIn, equals(5000000));
      expect(result.tokenType, equals('bearer'));
    });

    test('expiresAt должен рассчитывать время истечения', () {
      const TwitchAuthResult result = TwitchAuthResult(
        accessToken: testAccessToken,
        expiresIn: 3600,
        tokenType: 'bearer',
      );

      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final int expectedExpiry = now + 3600;

      expect(result.expiresAt, closeTo(expectedExpiry, 2));
    });
  });

  group('IgdbApiException', () {
    test('должен создать с сообщением', () {
      const IgdbApiException exception = IgdbApiException('Test error');

      expect(exception.message, equals('Test error'));
      expect(exception.statusCode, isNull);
    });

    test('должен создать с сообщением и кодом', () {
      const IgdbApiException exception = IgdbApiException(
        'Test error',
        statusCode: 401,
      );

      expect(exception.message, equals('Test error'));
      expect(exception.statusCode, equals(401));
    });

    test('toString должен вернуть строковое представление', () {
      const IgdbApiException exception = IgdbApiException(
        'Test error',
        statusCode: 401,
      );

      expect(
        exception.toString(),
        equals('IgdbApiException: Test error (status: 401)'),
      );
    });
  });

  group('IgdbApi', () {
    group('setCredentials', () {
      test('должен установить credentials', () {
        sut.setCredentials(
          clientId: testClientId,
          accessToken: testAccessToken,
        );

        // Проверяем что после установки credentials можно вызвать fetchPlatforms
        // без исключения о недостающих credentials
        // (тест на исключение ниже)
      });
    });

    group('clearCredentials', () {
      test('должен очистить credentials', () {
        sut.setCredentials(
          clientId: testClientId,
          accessToken: testAccessToken,
        );
        sut.clearCredentials();

        expect(
          () => sut.fetchPlatforms(),
          throwsA(isA<IgdbApiException>().having(
            (IgdbApiException e) => e.message,
            'message',
            'API credentials not set',
          )),
        );
      });
    });

    group('getAccessToken', () {
      test('должен вернуть токен при успешном ответе', () async {
        final Map<String, dynamic> responseData = <String, dynamic>{
          'access_token': testAccessToken,
          'expires_in': 5000000,
          'token_type': 'bearer',
        };

        when(() => mockDio.post<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: responseData,
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final TwitchAuthResult result = await sut.getAccessToken(
          clientId: testClientId,
          clientSecret: testClientSecret,
        );

        expect(result.accessToken, equals(testAccessToken));
      });

      test('должен выбросить исключение при невалидных credentials', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          response: Response<dynamic>(
            statusCode: 401,
            requestOptions: RequestOptions(),
          ),
          requestOptions: RequestOptions(),
        ));

        expect(
          () => sut.getAccessToken(
            clientId: testClientId,
            clientSecret: testClientSecret,
          ),
          throwsA(isA<IgdbApiException>().having(
            (IgdbApiException e) => e.message,
            'message',
            'Invalid client ID or client secret',
          )),
        );
      });

      test('должен выбросить исключение при таймауте', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(),
        ));

        expect(
          () => sut.getAccessToken(
            clientId: testClientId,
            clientSecret: testClientSecret,
          ),
          throwsA(isA<IgdbApiException>().having(
            (IgdbApiException e) => e.message,
            'message',
            'Connection timeout',
          )),
        );
      });

      test('должен выбросить исключение при ошибке соединения', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(),
        ));

        expect(
          () => sut.getAccessToken(
            clientId: testClientId,
            clientSecret: testClientSecret,
          ),
          throwsA(isA<IgdbApiException>().having(
            (IgdbApiException e) => e.message,
            'message',
            'No internet connection',
          )),
        );
      });

      test('должен выбросить исключение при неуспешном статусе', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: null,
              statusCode: 500,
              requestOptions: RequestOptions(),
            ));

        expect(
          () => sut.getAccessToken(
            clientId: testClientId,
            clientSecret: testClientSecret,
          ),
          throwsA(isA<IgdbApiException>()),
        );
      });
    });

    group('validateCredentials', () {
      test('должен вернуть true при валидных credentials', () async {
        final Map<String, dynamic> responseData = <String, dynamic>{
          'access_token': testAccessToken,
          'expires_in': 5000000,
          'token_type': 'bearer',
        };

        when(() => mockDio.post<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: responseData,
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final bool result = await sut.validateCredentials(
          clientId: testClientId,
          clientSecret: testClientSecret,
        );

        expect(result, isTrue);
      });

      test('должен вернуть false при невалидных credentials', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          response: Response<dynamic>(
            statusCode: 401,
            requestOptions: RequestOptions(),
          ),
          requestOptions: RequestOptions(),
        ));

        final bool result = await sut.validateCredentials(
          clientId: testClientId,
          clientSecret: testClientSecret,
        );

        expect(result, isFalse);
      });
    });

    group('fetchPlatforms', () {
      test('должен выбросить исключение без credentials', () {
        expect(
          () => sut.fetchPlatforms(),
          throwsA(isA<IgdbApiException>().having(
            (IgdbApiException e) => e.message,
            'message',
            'API credentials not set',
          )),
        );
      });

      test('должен вернуть список платформ', () async {
        sut.setCredentials(
          clientId: testClientId,
          accessToken: testAccessToken,
        );

        final List<Map<String, dynamic>> responseData = <Map<String, dynamic>>[
          <String, dynamic>{'id': 1, 'name': 'SNES', 'abbreviation': 'SNES'},
          <String, dynamic>{'id': 2, 'name': 'PlayStation', 'abbreviation': 'PS1'},
        ];

        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: responseData,
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<Platform> result = await sut.fetchPlatforms();

        expect(result, hasLength(2));
        expect(result[0].id, equals(1));
        expect(result[0].name, equals('SNES'));
        expect(result[1].id, equals(2));
      });

      test('должен обработать пустой ответ', () async {
        sut.setCredentials(
          clientId: testClientId,
          accessToken: testAccessToken,
        );

        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <Map<String, dynamic>>[],
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<Platform> result = await sut.fetchPlatforms();

        expect(result, isEmpty);
      });

      test('должен выбросить исключение при 401', () async {
        sut.setCredentials(
          clientId: testClientId,
          accessToken: testAccessToken,
        );

        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          response: Response<dynamic>(
            statusCode: 401,
            requestOptions: RequestOptions(),
          ),
          requestOptions: RequestOptions(),
        ));

        expect(
          () => sut.fetchPlatforms(),
          throwsA(isA<IgdbApiException>().having(
            (IgdbApiException e) => e.message,
            'message',
            'Invalid or expired access token',
          )),
        );
      });

      test('должен выбросить исключение при 429 (rate limit)', () async {
        sut.setCredentials(
          clientId: testClientId,
          accessToken: testAccessToken,
        );

        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          response: Response<dynamic>(
            statusCode: 429,
            requestOptions: RequestOptions(),
          ),
          requestOptions: RequestOptions(),
        ));

        expect(
          () => sut.fetchPlatforms(),
          throwsA(isA<IgdbApiException>().having(
            (IgdbApiException e) => e.message,
            'message',
            'Rate limit exceeded. Please try again later',
          )),
        );
      });

      test('должен выбросить исключение при неуспешном статусе', () async {
        sut.setCredentials(
          clientId: testClientId,
          accessToken: testAccessToken,
        );

        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: null,
              statusCode: 500,
              requestOptions: RequestOptions(),
            ));

        expect(
          () => sut.fetchPlatforms(),
          throwsA(isA<IgdbApiException>()),
        );
      });
    });

    group('fetchPlatformsByIds', () {
      test('должен вернуть пустой список для пустых ids', () async {
        final List<Platform> result = await sut.fetchPlatformsByIds(<int>[]);

        expect(result, isEmpty);
        verifyNever(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            ));
      });

      test('должен выбросить исключение без credentials', () {
        expect(
          () => sut.fetchPlatformsByIds(<int>[6, 48]),
          throwsA(isA<IgdbApiException>().having(
            (IgdbApiException e) => e.message,
            'message',
            'API credentials not set',
          )),
        );
      });

      test('должен вернуть платформы по ID', () async {
        sut.setCredentials(
          clientId: testClientId,
          accessToken: testAccessToken,
        );

        final List<Map<String, dynamic>> responseData =
            <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 6,
            'name': 'PC (Microsoft Windows)',
            'abbreviation': 'PC',
          },
          <String, dynamic>{
            'id': 48,
            'name': 'PlayStation 4',
            'abbreviation': 'PS4',
          },
        ];

        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: responseData,
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<Platform> result =
            await sut.fetchPlatformsByIds(<int>[6, 48]);

        expect(result, hasLength(2));
        expect(result[0].id, equals(6));
        expect(result[0].abbreviation, equals('PC'));
        expect(result[1].id, equals(48));
        expect(result[1].abbreviation, equals('PS4'));
      });

      test('должен выбросить исключение при ошибке сервера', () async {
        sut.setCredentials(
          clientId: testClientId,
          accessToken: testAccessToken,
        );

        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: null,
              statusCode: 500,
              requestOptions: RequestOptions(),
            ));

        expect(
          () => sut.fetchPlatformsByIds(<int>[6]),
          throwsA(isA<IgdbApiException>()),
        );
      });

      test('должен выбросить исключение при 401', () async {
        sut.setCredentials(
          clientId: testClientId,
          accessToken: testAccessToken,
        );

        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          response: Response<dynamic>(
            statusCode: 401,
            requestOptions: RequestOptions(),
          ),
          requestOptions: RequestOptions(),
        ));

        expect(
          () => sut.fetchPlatformsByIds(<int>[6]),
          throwsA(isA<IgdbApiException>().having(
            (IgdbApiException e) => e.message,
            'message',
            'Invalid or expired access token',
          )),
        );
      });

      test('должен выбросить исключение при 429', () async {
        sut.setCredentials(
          clientId: testClientId,
          accessToken: testAccessToken,
        );

        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          response: Response<dynamic>(
            statusCode: 429,
            requestOptions: RequestOptions(),
          ),
          requestOptions: RequestOptions(),
        ));

        expect(
          () => sut.fetchPlatformsByIds(<int>[6]),
          throwsA(isA<IgdbApiException>().having(
            (IgdbApiException e) => e.message,
            'message',
            'Rate limit exceeded. Please try again later',
          )),
        );
      });
    });

    group('dispose', () {
      test('должен закрыть Dio клиент', () {
        when(() => mockDio.close()).thenReturn(null);

        sut.dispose();

        verify(() => mockDio.close()).called(1);
      });
    });
  });
}
