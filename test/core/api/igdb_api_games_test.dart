import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/api/igdb_api.dart';
import 'package:xerabora/shared/models/game.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late IgdbApi api;

  setUp(() {
    mockDio = MockDio();
    api = IgdbApi(dio: mockDio);
    api.setCredentials(clientId: 'test_client', accessToken: 'test_token');
  });

  group('IgdbApi - Game methods', () {
    group('searchGames', () {
      test('returns list of games on successful search', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response<dynamic>(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
              data: <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 1942,
                  'name': 'The Witcher 3',
                  'summary': 'Great RPG',
                },
                <String, dynamic>{
                  'id': 1943,
                  'name': 'The Witcher 2',
                },
              ],
            ));

        final List<Game> result = await api.searchGames(query: 'witcher');

        expect(result, hasLength(2));
        expect(result[0].id, 1942);
        expect(result[0].name, 'The Witcher 3');
        expect(result[1].id, 1943);
      });

      test('returns empty list for empty query', () async {
        final List<Game> result = await api.searchGames(query: '');

        expect(result, isEmpty);
        verifyNever(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            ));
      });

      test('returns empty list for whitespace-only query', () async {
        final List<Game> result = await api.searchGames(query: '   ');

        expect(result, isEmpty);
      });

      test('includes platform filter when specified', () async {
        String? capturedData;

        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenAnswer((Invocation invocation) async {
          capturedData = invocation.namedArguments[const Symbol('data')] as String?;
          return Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: <Map<String, dynamic>>[],
          );
        });

        await api.searchGames(query: 'zelda', platformIds: <int>[130]);

        expect(capturedData, contains('where platforms = (130)'));
      });

      test('escapes quotes in query', () async {
        String? capturedData;

        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenAnswer((Invocation invocation) async {
          capturedData = invocation.namedArguments[const Symbol('data')] as String?;
          return Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: <Map<String, dynamic>>[],
          );
        });

        await api.searchGames(query: 'test "game"');

        expect(capturedData, contains(r'test \"game\"'));
      });

      test('respects limit parameter', () async {
        String? capturedData;

        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenAnswer((Invocation invocation) async {
          capturedData = invocation.namedArguments[const Symbol('data')] as String?;
          return Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: <Map<String, dynamic>>[],
          );
        });

        await api.searchGames(query: 'test', limit: 50);

        expect(capturedData, contains('limit 50'));
      });

      test('throws IgdbApiException on 401 error', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => api.searchGames(query: 'test'),
          throwsA(isA<IgdbApiException>()
              .having((IgdbApiException e) => e.message, 'message',
                  contains('token'))),
        );
      });

      test('throws IgdbApiException on 429 rate limit error', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 429,
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => api.searchGames(query: 'test'),
          throwsA(isA<IgdbApiException>()
              .having((IgdbApiException e) => e.message, 'message',
                  contains('Rate limit'))),
        );
      });

      test('throws IgdbApiException when credentials not set', () async {
        final IgdbApi apiWithoutCreds = IgdbApi(dio: mockDio);

        expect(
          () => apiWithoutCreds.searchGames(query: 'test'),
          throwsA(isA<IgdbApiException>()
              .having((IgdbApiException e) => e.message, 'message',
                  contains('credentials'))),
        );
      });
    });

    group('getGameById', () {
      test('returns game when found', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response<dynamic>(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
              data: <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 1942,
                  'name': 'The Witcher 3',
                },
              ],
            ));

        final Game? result = await api.getGameById(1942);

        expect(result, isNotNull);
        expect(result!.id, 1942);
        expect(result.name, 'The Witcher 3');
      });

      test('returns null when game not found', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response<dynamic>(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
              data: <Map<String, dynamic>>[],
            ));

        final Game? result = await api.getGameById(99999);

        expect(result, isNull);
      });

      test('sends correct query with game id', () async {
        String? capturedData;

        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenAnswer((Invocation invocation) async {
          capturedData = invocation.namedArguments[const Symbol('data')] as String?;
          return Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: <Map<String, dynamic>>[],
          );
        });

        await api.getGameById(1942);

        expect(capturedData, contains('where id = 1942'));
      });
    });

    group('getGamesByIds', () {
      test('returns list of games for given ids', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response<dynamic>(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
              data: <Map<String, dynamic>>[
                <String, dynamic>{'id': 1, 'name': 'Game 1'},
                <String, dynamic>{'id': 2, 'name': 'Game 2'},
                <String, dynamic>{'id': 3, 'name': 'Game 3'},
              ],
            ));

        final List<Game> result = await api.getGamesByIds(<int>[1, 2, 3]);

        expect(result, hasLength(3));
        expect(result.map((Game g) => g.id), containsAll(<int>[1, 2, 3]));
      });

      test('returns empty list for empty ids', () async {
        final List<Game> result = await api.getGamesByIds(<int>[]);

        expect(result, isEmpty);
        verifyNever(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            ));
      });

      test('sends ids in correct format', () async {
        String? capturedData;

        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenAnswer((Invocation invocation) async {
          capturedData = invocation.namedArguments[const Symbol('data')] as String?;
          return Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: <Map<String, dynamic>>[],
          );
        });

        await api.getGamesByIds(<int>[1, 2, 3]);

        expect(capturedData, contains('where id = (1,2,3)'));
      });

      test('batches requests for more than 500 ids', () async {
        int callCount = 0;

        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenAnswer((_) async {
          callCount++;
          return Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: <Map<String, dynamic>>[],
          );
        });

        // Create list of 600 ids
        final List<int> ids = List<int>.generate(600, (int i) => i + 1);

        await api.getGamesByIds(ids);

        // Should make 2 requests: first for 500, second for 100
        expect(callCount, 2);
      });
    });
  });
}
