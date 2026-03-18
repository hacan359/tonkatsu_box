// Тесты для RaApi.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/api/ra_api.dart';
import 'package:xerabora/shared/models/ra_game_progress.dart';
import 'package:xerabora/shared/models/ra_user_profile.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(registerAllFallbacks);

  late RaApi sut;
  late MockDio mockDio;

  const String testUsername = 'TestUser';
  const String testApiKey = 'test_api_key_123';

  setUp(() {
    mockDio = MockDio();
    sut = RaApi(dio: mockDio);
  });

  group('RaApiException', () {
    test('should create with message only', () {
      const RaApiException exception = RaApiException('Test error');

      expect(exception.message, equals('Test error'));
      expect(exception.statusCode, isNull);
    });

    test('should create with message and statusCode', () {
      const RaApiException exception = RaApiException(
        'Unauthorized',
        statusCode: 401,
      );

      expect(exception.message, equals('Unauthorized'));
      expect(exception.statusCode, equals(401));
    });

    test('toString should include statusCode and message', () {
      const RaApiException exception = RaApiException(
        'Not found',
        statusCode: 404,
      );

      expect(
        exception.toString(),
        equals('RaApiException(404): Not found'),
      );
    });

    test('toString should handle null statusCode', () {
      const RaApiException exception = RaApiException('Unknown error');

      expect(
        exception.toString(),
        equals('RaApiException(null): Unknown error'),
      );
    });
  });

  group('RaApi', () {
    group('setCredentials', () {
      test('should set credentials', () {
        sut.setCredentials(username: testUsername, apiKey: testApiKey);

        expect(sut.hasCredentials, isTrue);
      });
    });

    group('hasCredentials', () {
      test('should return false when no credentials set', () {
        expect(sut.hasCredentials, isFalse);
      });

      test('should return true when credentials set', () {
        sut.setCredentials(username: testUsername, apiKey: testApiKey);

        expect(sut.hasCredentials, isTrue);
      });

      test('should return false when username is empty', () {
        sut.setCredentials(username: '', apiKey: testApiKey);

        expect(sut.hasCredentials, isFalse);
      });

      test('should return false when apiKey is empty', () {
        sut.setCredentials(username: testUsername, apiKey: '');

        expect(sut.hasCredentials, isFalse);
      });
    });

    group('validateCredentials', () {
      test('should return true when profile has User field', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'User': 'TestUser',
                'TotalPoints': 100,
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final bool result = await sut.validateCredentials(
          testUsername,
          testApiKey,
        );

        expect(result, isTrue);
      });

      test('should return false when response data is null', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: null,
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final bool result = await sut.validateCredentials(
          testUsername,
          testApiKey,
        );

        expect(result, isFalse);
      });

      test('should return false when User field is null', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'User': null,
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final bool result = await sut.validateCredentials(
          testUsername,
          testApiKey,
        );

        expect(result, isFalse);
      });

      test('should return false when User key is missing', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'TotalPoints': 100,
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final bool result = await sut.validateCredentials(
          testUsername,
          testApiKey,
        );

        expect(result, isFalse);
      });

      test('should return false on DioException', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(),
          response: Response<dynamic>(
            statusCode: 401,
            requestOptions: RequestOptions(),
          ),
        ));

        final bool result = await sut.validateCredentials(
          testUsername,
          testApiKey,
        );

        expect(result, isFalse);
      });
    });

    group('getUserProfile', () {
      test('should throw RaApiException when no credentials', () {
        expect(
          () => sut.getUserProfile('TestUser'),
          throwsA(isA<RaApiException>().having(
            (RaApiException e) => e.message,
            'message',
            'RA credentials not set',
          )),
        );
      });

      test('should return profile on success', () async {
        sut.setCredentials(username: testUsername, apiKey: testApiKey);

        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'User': 'TestUser',
                'TotalPoints': 5000,
                'MemberSince': '2024-03-15',
                'UserPic': '/UserPic/TestUser.png',
                'TotalTruePoints': 8000,
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final RaUserProfile profile = await sut.getUserProfile('TestUser');

        expect(profile.user, equals('TestUser'));
        expect(profile.totalPoints, equals(5000));
      });

      test('should throw RaApiException on DioException', () async {
        sut.setCredentials(username: testUsername, apiKey: testApiKey);

        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(),
          message: 'Connection refused',
          response: Response<dynamic>(
            statusCode: 500,
            requestOptions: RequestOptions(),
          ),
        ));

        expect(
          () => sut.getUserProfile('TestUser'),
          throwsA(isA<RaApiException>().having(
            (RaApiException e) => e.statusCode,
            'statusCode',
            500,
          )),
        );
      });
    });

    group('getCompletedGames', () {
      test('should throw RaApiException when no credentials', () {
        expect(
          () => sut.getCompletedGames('TestUser'),
          throwsA(isA<RaApiException>().having(
            (RaApiException e) => e.message,
            'message',
            'RA credentials not set',
          )),
        );
      });

      test('should return games from single page', () async {
        sut.setCredentials(username: testUsername, apiKey: testApiKey);

        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'Results': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'GameID': 1,
                    'Title': 'Super Mario World',
                    'ConsoleName': 'SNES',
                    'ConsoleID': 3,
                    'NumAwardedHardcore': 50,
                    'MaxPossible': 96,
                  },
                  <String, dynamic>{
                    'GameID': 2,
                    'Title': 'Chrono Trigger',
                    'ConsoleName': 'SNES',
                    'ConsoleID': 3,
                    'NumAwardedHardcore': 30,
                    'MaxPossible': 45,
                  },
                ],
                'Total': 2,
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<RaGameProgress> games =
            await sut.getCompletedGames('TestUser');

        expect(games, hasLength(2));
        expect(games[0].gameId, equals(1));
        expect(games[0].title, equals('Super Mario World'));
        expect(games[1].gameId, equals(2));
      });

      test('should handle empty results', () async {
        sut.setCredentials(username: testUsername, apiKey: testApiKey);

        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'Results': <dynamic>[],
                'Total': 0,
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<RaGameProgress> games =
            await sut.getCompletedGames('TestUser');

        expect(games, isEmpty);
      });

      test('should throw RaApiException on DioException', () async {
        sut.setCredentials(username: testUsername, apiKey: testApiKey);

        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(),
          message: 'Timeout',
          response: Response<dynamic>(
            statusCode: 504,
            requestOptions: RequestOptions(),
          ),
        ));

        expect(
          () => sut.getCompletedGames('TestUser'),
          throwsA(isA<RaApiException>()),
        );
      });

      test('should handle null Total gracefully', () async {
        sut.setCredentials(username: testUsername, apiKey: testApiKey);

        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'Results': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'GameID': 1,
                    'Title': 'Test',
                    'ConsoleName': 'NES',
                    'ConsoleID': 7,
                    'MaxPossible': 5,
                  },
                ],
                'Total': null,
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<RaGameProgress> games =
            await sut.getCompletedGames('TestUser');

        // Total is 0, offset (1) >= 0 => break after first page.
        expect(games, hasLength(1));
      });
    });

    group('getUserAwardDates', () {
      test('should throw RaApiException when no credentials', () {
        expect(
          () => sut.getUserAwardDates('TestUser'),
          throwsA(isA<RaApiException>().having(
            (RaApiException e) => e.message,
            'message',
            'RA credentials not set',
          )),
        );
      });

      test('should return award dates for game awards', () async {
        sut.setCredentials(username: testUsername, apiKey: testApiKey);

        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'VisibleUserAwards': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'AwardType': 'Game Beaten',
                    'AwardData': 1234,
                    'AwardedAt': '2024-06-15T12:00:00Z',
                  },
                  <String, dynamic>{
                    'AwardType': 'Mastery/Completion',
                    'AwardData': 5678,
                    'AwardedAt': '2024-07-01T10:00:00Z',
                  },
                ],
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final Map<int, DateTime> result =
            await sut.getUserAwardDates('TestUser');

        expect(result, hasLength(2));
        expect(result[1234], isNotNull);
        expect(result[5678], isNotNull);
      });

      test('should skip non-game awards', () async {
        sut.setCredentials(username: testUsername, apiKey: testApiKey);

        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'VisibleUserAwards': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'AwardType': 'Site Award',
                    'AwardData': 100,
                    'AwardedAt': '2024-06-15T12:00:00Z',
                  },
                  <String, dynamic>{
                    'AwardType': 'Game Beaten',
                    'AwardData': 200,
                    'AwardedAt': '2024-06-20T12:00:00Z',
                  },
                ],
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final Map<int, DateTime> result =
            await sut.getUserAwardDates('TestUser');

        expect(result, hasLength(1));
        expect(result.containsKey(100), isFalse);
        expect(result.containsKey(200), isTrue);
      });

      test('should keep latest date for same game', () async {
        sut.setCredentials(username: testUsername, apiKey: testApiKey);

        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'VisibleUserAwards': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'AwardType': 'Game Beaten',
                    'AwardData': 1234,
                    'AwardedAt': '2024-06-15T12:00:00Z',
                  },
                  <String, dynamic>{
                    'AwardType': 'Mastery/Completion',
                    'AwardData': 1234,
                    'AwardedAt': '2024-07-01T12:00:00Z',
                  },
                ],
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final Map<int, DateTime> result =
            await sut.getUserAwardDates('TestUser');

        expect(result, hasLength(1));
        expect(result[1234]!.month, equals(7));
      });

      test('should keep earlier date when later comes first', () async {
        sut.setCredentials(username: testUsername, apiKey: testApiKey);

        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'VisibleUserAwards': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'AwardType': 'Mastery/Completion',
                    'AwardData': 1234,
                    'AwardedAt': '2024-07-01T12:00:00Z',
                  },
                  <String, dynamic>{
                    'AwardType': 'Game Beaten',
                    'AwardData': 1234,
                    'AwardedAt': '2024-06-15T12:00:00Z',
                  },
                ],
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final Map<int, DateTime> result =
            await sut.getUserAwardDates('TestUser');

        // Keeps the later date (July).
        expect(result[1234]!.month, equals(7));
      });

      test('should return empty map on DioException', () async {
        sut.setCredentials(username: testUsername, apiKey: testApiKey);

        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(),
        ));

        final Map<int, DateTime> result =
            await sut.getUserAwardDates('TestUser');

        expect(result, isEmpty);
      });

      test('should handle null VisibleUserAwards', () async {
        sut.setCredentials(username: testUsername, apiKey: testApiKey);

        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'VisibleUserAwards': null,
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final Map<int, DateTime> result =
            await sut.getUserAwardDates('TestUser');

        expect(result, isEmpty);
      });

      test('should skip awards with null AwardType', () async {
        sut.setCredentials(username: testUsername, apiKey: testApiKey);

        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'VisibleUserAwards': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'AwardType': null,
                    'AwardData': 100,
                    'AwardedAt': '2024-06-15T12:00:00Z',
                  },
                ],
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final Map<int, DateTime> result =
            await sut.getUserAwardDates('TestUser');

        expect(result, isEmpty);
      });

      test('should skip awards with null gameId', () async {
        sut.setCredentials(username: testUsername, apiKey: testApiKey);

        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'VisibleUserAwards': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'AwardType': 'Game Beaten',
                    'AwardData': null,
                    'AwardedAt': '2024-06-15T12:00:00Z',
                  },
                ],
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final Map<int, DateTime> result =
            await sut.getUserAwardDates('TestUser');

        expect(result, isEmpty);
      });

      test('should skip awards with null AwardedAt', () async {
        sut.setCredentials(username: testUsername, apiKey: testApiKey);

        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'VisibleUserAwards': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'AwardType': 'Game Beaten',
                    'AwardData': 100,
                    'AwardedAt': null,
                  },
                ],
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final Map<int, DateTime> result =
            await sut.getUserAwardDates('TestUser');

        expect(result, isEmpty);
      });

      test('should skip awards with invalid date string', () async {
        sut.setCredentials(username: testUsername, apiKey: testApiKey);

        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'VisibleUserAwards': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'AwardType': 'Game Beaten',
                    'AwardData': 100,
                    'AwardedAt': 'invalid-date',
                  },
                ],
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final Map<int, DateTime> result =
            await sut.getUserAwardDates('TestUser');

        expect(result, isEmpty);
      });
    });
  });
}
