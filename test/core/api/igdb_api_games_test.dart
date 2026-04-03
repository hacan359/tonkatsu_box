import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/api/igdb_api.dart';
import 'package:xerabora/shared/models/game.dart';

import '../../helpers/test_helpers.dart';

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

    group('multiSearchGamesByName', () {
      test('returns parsed games mapped by index', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenAnswer((_) async => Response<dynamic>(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
              data: <Map<String, dynamic>>[
                <String, dynamic>{
                  'name': 'q_0',
                  'result': <Map<String, dynamic>>[
                    <String, dynamic>{'id': 100, 'name': 'Hollow Knight'},
                  ],
                },
                <String, dynamic>{
                  'name': 'q_1',
                  'result': <Map<String, dynamic>>[
                    <String, dynamic>{'id': 200, 'name': 'Celeste'},
                  ],
                },
              ],
            ));

        final Map<int, List<Game>> result =
            await api.multiSearchGamesByName(<({String name, int? platformId})>[
          (name: 'Hollow Knight', platformId: 19),
          (name: 'Celeste', platformId: null),
        ]);

        expect(result, hasLength(2));
        expect(result[0]!.first.name, 'Hollow Knight');
        expect(result[1]!.first.name, 'Celeste');
      });

      test('returns empty map for empty queries', () async {
        final Map<int, List<Game>> result =
            await api.multiSearchGamesByName(
                <({String name, int? platformId})>[]);

        expect(result, isEmpty);
        verifyNever(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            ));
      });

      test('includes platform filter in query body', () async {
        String? capturedData;

        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenAnswer((Invocation inv) async {
          capturedData =
              inv.namedArguments[const Symbol('data')] as String?;
          return Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: <Map<String, dynamic>>[
              <String, dynamic>{
                'name': 'q_0',
                'result': <Map<String, dynamic>>[],
              },
            ],
          );
        });

        await api.multiSearchGamesByName(
            <({String name, int? platformId})>[
          (name: 'Mario', platformId: 19),
        ]);

        expect(capturedData, contains('platforms = (19)'));
        expect(capturedData, contains('name ~ *"Mario"*'));
      });

      test('omits platform filter when platformId is null', () async {
        String? capturedData;

        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenAnswer((Invocation inv) async {
          capturedData =
              inv.namedArguments[const Symbol('data')] as String?;
          return Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: <Map<String, dynamic>>[
              <String, dynamic>{
                'name': 'q_0',
                'result': <Map<String, dynamic>>[],
              },
            ],
          );
        });

        await api.multiSearchGamesByName(
            <({String name, int? platformId})>[
          (name: 'Mario', platformId: null),
        ]);

        expect(capturedData, isNot(contains('platforms = (')));
        expect(capturedData, contains('name ~ *"Mario"*'));
      });

      test('posts to /multiquery endpoint', () async {
        String? capturedUrl;

        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenAnswer((Invocation inv) async {
          capturedUrl = inv.positionalArguments[0] as String;
          return Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: <Map<String, dynamic>>[
              <String, dynamic>{
                'name': 'q_0',
                'result': <Map<String, dynamic>>[],
              },
            ],
          );
        });

        await api.multiSearchGamesByName(
            <({String name, int? platformId})>[
          (name: 'test', platformId: null),
        ]);

        expect(capturedUrl, endsWith('/multiquery'));
      });

      test('throws IgdbApiException on HTTP error', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 500,
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => api.multiSearchGamesByName(
              <({String name, int? platformId})>[
            (name: 'test', platformId: null),
          ]),
          throwsA(isA<IgdbApiException>()),
        );
      });
    });

    group('lookupSteamGames', () {
      test('returns games mapped by Steam appId', () async {
        int callCount = 0;
        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenAnswer((Invocation inv) async {
          callCount++;
          final String url = inv.positionalArguments[0] as String;
          if (url.contains('/external_games')) {
            return Response<dynamic>(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
              data: <Map<String, dynamic>>[
                <String, dynamic>{'game': 2963, 'uid': '570'},
                <String, dynamic>{'game': 231, 'uid': '70'},
              ],
            );
          }
          // /games endpoint
          return Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: <Map<String, dynamic>>[
              <String, dynamic>{'id': 2963, 'name': 'Dota 2'},
              <String, dynamic>{'id': 231, 'name': 'Half-Life'},
            ],
          );
        });

        final Map<String, Game> result =
            await api.lookupSteamGames(<String>['570', '70']);

        expect(result, hasLength(2));
        expect(result['570']!.name, 'Dota 2');
        expect(result['70']!.name, 'Half-Life');
        // 2 calls: external_games + games
        expect(callCount, 2);
      });

      test('returns empty map for empty input', () async {
        final Map<String, Game> result =
            await api.lookupSteamGames(<String>[]);

        expect(result, isEmpty);
        verifyNever(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            ));
      });

      test('posts to /external_games endpoint', () async {
        String? capturedUrl;
        String? capturedData;

        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenAnswer((Invocation inv) async {
          final String url = inv.positionalArguments[0] as String;
          if (url.contains('/external_games')) {
            capturedUrl = url;
            capturedData =
                inv.namedArguments[const Symbol('data')] as String?;
            return Response<dynamic>(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
              data: <Map<String, dynamic>>[],
            );
          }
          return Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: <Map<String, dynamic>>[],
          );
        });

        await api.lookupSteamGames(<String>['570']);

        expect(capturedUrl, endsWith('/external_games'));
        expect(capturedData, contains('external_game_source'));
        expect(capturedData, contains('"570"'));
      });

      test('handles unmatched appIds gracefully', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenAnswer((Invocation inv) async {
          final String url = inv.positionalArguments[0] as String;
          if (url.contains('/external_games')) {
            // Only one of two appIds matched.
            return Response<dynamic>(
              requestOptions: RequestOptions(path: ''),
              statusCode: 200,
              data: <Map<String, dynamic>>[
                <String, dynamic>{'game': 100, 'uid': '570'},
              ],
            );
          }
          return Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: <Map<String, dynamic>>[
              <String, dynamic>{'id': 100, 'name': 'Dota 2'},
            ],
          );
        });

        final Map<String, Game> result =
            await api.lookupSteamGames(<String>['570', '99999']);

        expect(result, hasLength(1));
        expect(result['570']!.name, 'Dota 2');
        expect(result.containsKey('99999'), isFalse);
      });

      test('throws IgdbApiException on HTTP error', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              options: any(named: 'options'),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 500,
          ),
          type: DioExceptionType.badResponse,
        ));

        expect(
          () => api.lookupSteamGames(<String>['570']),
          throwsA(isA<IgdbApiException>()),
        );
      });

      test('throws IgdbApiException when credentials not set', () async {
        final IgdbApi apiWithoutCreds = IgdbApi(dio: mockDio);

        expect(
          () => apiWithoutCreds.lookupSteamGames(<String>['570']),
          throwsA(isA<IgdbApiException>()
              .having((IgdbApiException e) => e.message, 'message',
                  contains('credentials'))),
        );
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
