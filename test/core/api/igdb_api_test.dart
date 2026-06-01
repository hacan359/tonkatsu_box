import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/igdb_api.dart';
import 'package:tonkatsu_box/shared/models/game.dart';
import 'package:tonkatsu_box/shared/models/platform.dart';

import '../../helpers/test_helpers.dart';

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
    test('should create из JSON', () {
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
    test('should create с сообщением', () {
      const IgdbApiException exception = IgdbApiException('Test error');

      expect(exception.message, equals('Test error'));
      expect(exception.statusCode, isNull);
    });

    test('should create с сообщением и кодом', () {
      const IgdbApiException exception = IgdbApiException(
        'Test error',
        statusCode: 401,
      );

      expect(exception.message, equals('Test error'));
      expect(exception.statusCode, equals(401));
    });

    test('toString should return строковое представление', () {
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
      test('should set credentials', () {
        sut.setCredentials(
          clientId: testClientId,
          accessToken: testAccessToken,
        );
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
      test('should return токен при успешном ответе', () async {
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

      test('должен выбросить исключение on error соединения', () async {
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
      test('should return true при валидных credentials', () async {
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

      test('should return false при невалидных credentials', () async {
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

      test('should return список платформ', () async {
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

      test('should handle пустой ответ', () async {
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
      test('should return пустой список для пустых ids', () async {
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

      test('should return платформы по ID', () async {
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

      test('должен выбросить исключение on error сервера', () async {
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

    group('getTopGamesByPlatform', () {
      test('должен выбросить исключение без credentials', () {
        expect(
          () => sut.getTopGamesByPlatform(platformId: 19),
          throwsA(isA<IgdbApiException>().having(
            (IgdbApiException e) => e.message,
            'message',
            'API credentials not set',
          )),
        );
      });

      test('should return список топ игр по платформе', () async {
        sut.setCredentials(
          clientId: testClientId,
          accessToken: testAccessToken,
        );

        final List<Map<String, dynamic>> responseData = <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'name': 'Super Mario World',
            'rating': 95.0,
            'rating_count': 500,
          },
          <String, dynamic>{
            'id': 2,
            'name': 'Chrono Trigger',
            'rating': 93.0,
            'rating_count': 400,
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

        final List<Game> result = await sut.getTopGamesByPlatform(
          platformId: 19,
          limit: 50,
        );

        expect(result, hasLength(2));
        expect(result[0].id, equals(1));
        expect(result[0].name, equals('Super Mario World'));
        expect(result[1].id, equals(2));
      });

      test('должен отправить правильный body запроса', () async {
        sut.setCredentials(
          clientId: testClientId,
          accessToken: testAccessToken,
        );

        String? capturedBody;

        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenAnswer((Invocation invocation) async {
          capturedBody = invocation.namedArguments[#data] as String?;
          return Response<dynamic>(
            data: <Map<String, dynamic>>[],
            statusCode: 200,
            requestOptions: RequestOptions(),
          );
        });

        await sut.getTopGamesByPlatform(
          platformId: 19,
          minRatingCount: 30,
          limit: 25,
        );

        expect(capturedBody, contains('platforms = (19)'));
        expect(capturedBody, contains('rating_count >= 30'));
        expect(capturedBody, contains('rating != null'));
        expect(capturedBody, contains('sort rating desc'));
        expect(capturedBody, contains('limit 25'));
      });

      test('should handle пустой ответ', () async {
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

        final List<Game> result = await sut.getTopGamesByPlatform(
          platformId: 19,
        );

        expect(result, isEmpty);
      });

      test('должен выбросить исключение on error API', () async {
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
          () => sut.getTopGamesByPlatform(platformId: 19),
          throwsA(isA<IgdbApiException>()),
        );
      });

      test('should handle DioException 401', () async {
        sut.setCredentials(
          clientId: testClientId,
          accessToken: testAccessToken,
        );

        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            statusCode: 401,
            requestOptions: RequestOptions(),
          ),
          requestOptions: RequestOptions(),
        ));

        expect(
          () => sut.getTopGamesByPlatform(platformId: 19),
          throwsA(isA<IgdbApiException>().having(
            (IgdbApiException e) => e.message,
            'message',
            'Invalid or expired access token',
          )),
        );
      });

      test('should handle DioException 429', () async {
        sut.setCredentials(
          clientId: testClientId,
          accessToken: testAccessToken,
        );

        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            statusCode: 429,
            requestOptions: RequestOptions(),
          ),
          requestOptions: RequestOptions(),
        ));

        expect(
          () => sut.getTopGamesByPlatform(platformId: 19),
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

    group('_igdbPost auto-refresh', () {
      void setupWithSecret() {
        sut.setCredentials(
          clientId: testClientId,
          accessToken: testAccessToken,
          clientSecret: testClientSecret,
        );
      }

      test('should retry request after 401 when token refresh succeeds',
          () async {
        setupWithSecret();

        int igdbCallCount = 0;

        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenAnswer((_) async {
          igdbCallCount++;
          if (igdbCallCount == 1) {
            throw DioException(
              response: Response<dynamic>(
                statusCode: 401,
                requestOptions: RequestOptions(),
              ),
              requestOptions: RequestOptions(),
            );
          }
          return Response<dynamic>(
            data: <Map<String, dynamic>>[],
            statusCode: 200,
            requestOptions: RequestOptions(),
          );
        });

        when(() => mockDio.post<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'access_token': 'new_token',
                'expires_in': 5000000,
                'token_type': 'bearer',
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<Game> result =
            await sut.searchGames(query: 'test');

        expect(result, isEmpty);
        // 2 IGDB calls: initial 401 + retry; 1 Twitch refresh call.
        expect(igdbCallCount, equals(2));
        verify(() => mockDio.post<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).called(1);
      });

      test('should rethrow 401 when no clientSecret for refresh', () async {
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
          () => sut.searchGames(query: 'test'),
          throwsA(isA<IgdbApiException>()),
        );
      });

      test('should rethrow 401 when token refresh fails', () async {
        setupWithSecret();

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
          () => sut.searchGames(query: 'test'),
          throwsA(isA<IgdbApiException>()),
        );
      });

      test('should call onTokenRefreshed callback after refresh', () async {
        setupWithSecret();

        String? refreshedToken;
        int? refreshedExpiresAt;
        sut.onTokenRefreshed = (String token, int expiresAt) {
          refreshedToken = token;
          refreshedExpiresAt = expiresAt;
        };

        int callCount = 0;

        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenAnswer((Invocation invocation) async {
          callCount++;
          if (callCount == 1) {
            throw DioException(
              response: Response<dynamic>(
                statusCode: 401,
                requestOptions: RequestOptions(),
              ),
              requestOptions: RequestOptions(),
            );
          }
          return Response<dynamic>(
            data: <Map<String, dynamic>>[],
            statusCode: 200,
            requestOptions: RequestOptions(),
          );
        });

        when(() => mockDio.post<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'access_token': 'refreshed_token',
                'expires_in': 5000000,
                'token_type': 'bearer',
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        await sut.searchGames(query: 'test');

        expect(refreshedToken, equals('refreshed_token'));
        expect(refreshedExpiresAt, isNotNull);
      });

      test('should not retry on non-401 errors', () async {
        setupWithSecret();

        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          response: Response<dynamic>(
            statusCode: 500,
            requestOptions: RequestOptions(),
          ),
          requestOptions: RequestOptions(),
        ));

        expect(
          () => sut.searchGames(query: 'test'),
          throwsA(isA<IgdbApiException>()),
        );

        verify(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).called(1);
      });
    });
  });
}
