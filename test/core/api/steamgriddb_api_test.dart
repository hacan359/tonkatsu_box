import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/api/steamgriddb_api.dart';
import 'package:xerabora/shared/models/steamgriddb_game.dart';
import 'package:xerabora/shared/models/steamgriddb_image.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late SteamGridDbApi sut;
  late MockDio mockDio;

  const String testApiKey = 'test_api_key_123';

  setUp(() {
    mockDio = MockDio();
    sut = SteamGridDbApi(dio: mockDio);
  });

  tearDown(() {
    sut.dispose();
  });

  group('SteamGridDbApiException', () {
    test('содержит message и statusCode', () {
      const SteamGridDbApiException exception = SteamGridDbApiException(
        'Test error',
        statusCode: 401,
      );

      expect(exception.message, 'Test error');
      expect(exception.statusCode, 401);
    });

    test('toString возвращает читаемое представление', () {
      const SteamGridDbApiException exception = SteamGridDbApiException(
        'Not found',
        statusCode: 404,
      );

      expect(
        exception.toString(),
        'SteamGridDbApiException: Not found (status: 404)',
      );
    });

    test('statusCode может быть null', () {
      const SteamGridDbApiException exception = SteamGridDbApiException(
        'Network error',
      );

      expect(exception.statusCode, isNull);
    });
  });

  group('SteamGridDbApi', () {
    group('setApiKey / clearApiKey', () {
      test('выбрасывает исключение без API ключа', () {
        expect(
          () => sut.searchGames('test'),
          throwsA(isA<SteamGridDbApiException>().having(
            (SteamGridDbApiException e) => e.message,
            'message',
            'API key not set',
          )),
        );
      });

      test('работает после установки API ключа', () async {
        sut.setApiKey(testApiKey);

        when(() => mockDio.get<dynamic>(
              any(),
              options: any(named: 'options'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'data': <Map<String, dynamic>>[],
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<SteamGridDbGame> result = await sut.searchGames('test');
        expect(result, isEmpty);
      });

      test('выбрасывает после очистки API ключа', () {
        sut.setApiKey(testApiKey);
        sut.clearApiKey();

        expect(
          () => sut.searchGames('test'),
          throwsA(isA<SteamGridDbApiException>()),
        );
      });
    });

    group('searchGames', () {
      setUp(() {
        sut.setApiKey(testApiKey);
      });

      test('возвращает список игр при успешном ответе', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              options: any(named: 'options'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'data': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'id': 2590,
                    'name': 'The Witcher 3',
                    'types': <String>['steam'],
                    'verified': true,
                  },
                  <String, dynamic>{
                    'id': 100,
                    'name': 'The Witcher 2',
                    'types': <String>['gog'],
                    'verified': false,
                  },
                ],
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<SteamGridDbGame> result = await sut.searchGames('witcher');

        expect(result, hasLength(2));
        expect(result[0].id, 2590);
        expect(result[0].name, 'The Witcher 3');
        expect(result[1].id, 100);
      });

      test('возвращает пустой список для пустого запроса', () async {
        final List<SteamGridDbGame> result = await sut.searchGames('');

        expect(result, isEmpty);
        verifyNever(() => mockDio.get<dynamic>(
              any(),
              options: any(named: 'options'),
            ));
      });

      test('возвращает пустой список для запроса из пробелов', () async {
        final List<SteamGridDbGame> result = await sut.searchGames('   ');

        expect(result, isEmpty);
        verifyNever(() => mockDio.get<dynamic>(
              any(),
              options: any(named: 'options'),
            ));
      });

      test('кодирует спецсимволы в запросе', () async {
        String? capturedUrl;

        when(() => mockDio.get<dynamic>(
              any(),
              options: any(named: 'options'),
            )).thenAnswer((Invocation invocation) async {
          capturedUrl = invocation.positionalArguments[0] as String;
          return Response<dynamic>(
            data: <String, dynamic>{
              'data': <Map<String, dynamic>>[],
            },
            statusCode: 200,
            requestOptions: RequestOptions(),
          );
        });

        await sut.searchGames('game & test');

        expect(capturedUrl, contains('game%20%26%20test'));
      });

      test('выбрасывает исключение при 401', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              options: any(named: 'options'),
            )).thenThrow(DioException(
          response: Response<dynamic>(
            statusCode: 401,
            requestOptions: RequestOptions(),
          ),
          requestOptions: RequestOptions(),
        ));

        expect(
          () => sut.searchGames('test'),
          throwsA(isA<SteamGridDbApiException>().having(
            (SteamGridDbApiException e) => e.message,
            'message',
            'Invalid or expired API key',
          )),
        );
      });

      test('выбрасывает исключение при 429', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              options: any(named: 'options'),
            )).thenThrow(DioException(
          response: Response<dynamic>(
            statusCode: 429,
            requestOptions: RequestOptions(),
          ),
          requestOptions: RequestOptions(),
        ));

        expect(
          () => sut.searchGames('test'),
          throwsA(isA<SteamGridDbApiException>().having(
            (SteamGridDbApiException e) => e.message,
            'message',
            'Rate limit exceeded. Please try again later',
          )),
        );
      });

      test('выбрасывает исключение при таймауте', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              options: any(named: 'options'),
            )).thenThrow(DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(),
        ));

        expect(
          () => sut.searchGames('test'),
          throwsA(isA<SteamGridDbApiException>().having(
            (SteamGridDbApiException e) => e.message,
            'message',
            'Connection timeout',
          )),
        );
      });

      test('выбрасывает исключение при ошибке соединения', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              options: any(named: 'options'),
            )).thenThrow(DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(),
        ));

        expect(
          () => sut.searchGames('test'),
          throwsA(isA<SteamGridDbApiException>().having(
            (SteamGridDbApiException e) => e.message,
            'message',
            'No internet connection',
          )),
        );
      });

      test('выбрасывает исключение при non-200 статусе', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              options: any(named: 'options'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: null,
              statusCode: 500,
              requestOptions: RequestOptions(),
            ));

        expect(
          () => sut.searchGames('test'),
          throwsA(isA<SteamGridDbApiException>()),
        );
      });
    });

    group('getGrids', () {
      setUp(() {
        sut.setApiKey(testApiKey);
      });

      test('возвращает изображения при успешном ответе', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              options: any(named: 'options'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'data': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'id': 1001,
                    'score': 5,
                    'style': 'alternate',
                    'url': 'https://cdn.steamgriddb.com/grid/full.png',
                    'thumb': 'https://cdn.steamgriddb.com/grid/thumb.png',
                    'width': 600,
                    'height': 900,
                    'mime': 'image/png',
                    'author': <String, dynamic>{'name': 'Artist'},
                  },
                ],
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<SteamGridDbImage> result = await sut.getGrids(2590);

        expect(result, hasLength(1));
        expect(result[0].id, 1001);
        expect(result[0].style, 'alternate');
        expect(result[0].author, 'Artist');
      });

      test('возвращает пустой список при пустом data', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              options: any(named: 'options'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'data': <Map<String, dynamic>>[],
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<SteamGridDbImage> result = await sut.getGrids(999);

        expect(result, isEmpty);
      });

      test('выбрасывает исключение без API ключа', () {
        final SteamGridDbApi noKeyApi = SteamGridDbApi(dio: mockDio);

        expect(
          () => noKeyApi.getGrids(1),
          throwsA(isA<SteamGridDbApiException>()),
        );

        noKeyApi.dispose();
      });

      test('выбрасывает исключение при 404', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              options: any(named: 'options'),
            )).thenThrow(DioException(
          response: Response<dynamic>(
            statusCode: 404,
            requestOptions: RequestOptions(),
          ),
          requestOptions: RequestOptions(),
        ));

        expect(
          () => sut.getGrids(999999),
          throwsA(isA<SteamGridDbApiException>().having(
            (SteamGridDbApiException e) => e.message,
            'message',
            'Game not found',
          )),
        );
      });

      test('вызывает правильный URL', () async {
        String? capturedUrl;

        when(() => mockDio.get<dynamic>(
              any(),
              options: any(named: 'options'),
            )).thenAnswer((Invocation invocation) async {
          capturedUrl = invocation.positionalArguments[0] as String;
          return Response<dynamic>(
            data: <String, dynamic>{
              'data': <Map<String, dynamic>>[],
            },
            statusCode: 200,
            requestOptions: RequestOptions(),
          );
        });

        await sut.getGrids(2590);

        expect(capturedUrl, contains('/grids/game/2590'));
      });
    });

    group('getHeroes', () {
      setUp(() {
        sut.setApiKey(testApiKey);
      });

      test('возвращает изображения при успешном ответе', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              options: any(named: 'options'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'data': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'id': 2001,
                    'score': 3,
                    'style': 'blurred',
                    'url': 'https://cdn.steamgriddb.com/hero/full.jpg',
                    'thumb': 'https://cdn.steamgriddb.com/hero/thumb.jpg',
                    'width': 1920,
                    'height': 620,
                  },
                ],
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<SteamGridDbImage> result = await sut.getHeroes(2590);

        expect(result, hasLength(1));
        expect(result[0].id, 2001);
        expect(result[0].style, 'blurred');
      });

      test('вызывает правильный URL', () async {
        String? capturedUrl;

        when(() => mockDio.get<dynamic>(
              any(),
              options: any(named: 'options'),
            )).thenAnswer((Invocation invocation) async {
          capturedUrl = invocation.positionalArguments[0] as String;
          return Response<dynamic>(
            data: <String, dynamic>{
              'data': <Map<String, dynamic>>[],
            },
            statusCode: 200,
            requestOptions: RequestOptions(),
          );
        });

        await sut.getHeroes(100);

        expect(capturedUrl, contains('/heroes/game/100'));
      });
    });

    group('getLogos', () {
      setUp(() {
        sut.setApiKey(testApiKey);
      });

      test('возвращает изображения при успешном ответе', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              options: any(named: 'options'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'data': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'id': 3001,
                    'score': 7,
                    'style': 'white',
                    'url': 'https://cdn.steamgriddb.com/logo/full.png',
                    'thumb': 'https://cdn.steamgriddb.com/logo/thumb.png',
                    'width': 512,
                    'height': 256,
                    'mime': 'image/png',
                  },
                ],
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<SteamGridDbImage> result = await sut.getLogos(2590);

        expect(result, hasLength(1));
        expect(result[0].id, 3001);
      });

      test('вызывает правильный URL', () async {
        String? capturedUrl;

        when(() => mockDio.get<dynamic>(
              any(),
              options: any(named: 'options'),
            )).thenAnswer((Invocation invocation) async {
          capturedUrl = invocation.positionalArguments[0] as String;
          return Response<dynamic>(
            data: <String, dynamic>{
              'data': <Map<String, dynamic>>[],
            },
            statusCode: 200,
            requestOptions: RequestOptions(),
          );
        });

        await sut.getLogos(50);

        expect(capturedUrl, contains('/logos/game/50'));
      });
    });

    group('getIcons', () {
      setUp(() {
        sut.setApiKey(testApiKey);
      });

      test('возвращает изображения при успешном ответе', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              options: any(named: 'options'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'data': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'id': 4001,
                    'score': 2,
                    'style': 'official',
                    'url': 'https://cdn.steamgriddb.com/icon/full.ico',
                    'thumb': 'https://cdn.steamgriddb.com/icon/thumb.png',
                    'width': 256,
                    'height': 256,
                  },
                ],
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<SteamGridDbImage> result = await sut.getIcons(2590);

        expect(result, hasLength(1));
        expect(result[0].id, 4001);
      });

      test('вызывает правильный URL', () async {
        String? capturedUrl;

        when(() => mockDio.get<dynamic>(
              any(),
              options: any(named: 'options'),
            )).thenAnswer((Invocation invocation) async {
          capturedUrl = invocation.positionalArguments[0] as String;
          return Response<dynamic>(
            data: <String, dynamic>{
              'data': <Map<String, dynamic>>[],
            },
            statusCode: 200,
            requestOptions: RequestOptions(),
          );
        });

        await sut.getIcons(75);

        expect(capturedUrl, contains('/icons/game/75'));
      });
    });

    group('dispose', () {
      test('закрывает Dio клиент', () {
        when(() => mockDio.close()).thenAnswer((_) async {});

        sut.dispose();

        verify(() => mockDio.close()).called(1);
      });
    });
  });
}
