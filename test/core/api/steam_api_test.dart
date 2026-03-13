// Тесты для Steam API клиента.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/api/steam_api.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late SteamApi sut;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    sut = SteamApi(dio: mockDio);
  });

  group('SteamApiException', () {
    test('contains message and statusCode', () {
      const SteamApiException exception = SteamApiException(
        'Test error',
        statusCode: 401,
      );

      expect(exception.message, 'Test error');
      expect(exception.statusCode, 401);
    });

    test('toString returns readable representation', () {
      const SteamApiException exception = SteamApiException(
        'Invalid API key',
        statusCode: 403,
      );

      expect(
        exception.toString(),
        'SteamApiException(403): Invalid API key',
      );
    });

    test('statusCode can be null', () {
      const SteamApiException exception = SteamApiException('Network error');
      expect(exception.statusCode, isNull);
    });
  });

  group('SteamOwnedGame', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final SteamOwnedGame game = SteamOwnedGame.fromJson(
          const <String, dynamic>{
            'appid': 440,
            'name': 'Team Fortress 2',
            'playtime_forever': 1250,
            'rtime_last_played': 1706400000,
          },
        );

        expect(game.appId, 440);
        expect(game.name, 'Team Fortress 2');
        expect(game.playtimeMinutes, 1250);
        expect(game.lastPlayed, isNotNull);
        expect(
          game.lastPlayed!.millisecondsSinceEpoch,
          1706400000 * 1000,
        );
      });

      test('handles missing playtime_forever', () {
        final SteamOwnedGame game = SteamOwnedGame.fromJson(
          const <String, dynamic>{
            'appid': 100,
            'name': 'Test Game',
          },
        );

        expect(game.playtimeMinutes, 0);
      });

      test('handles zero rtime_last_played', () {
        final SteamOwnedGame game = SteamOwnedGame.fromJson(
          const <String, dynamic>{
            'appid': 100,
            'name': 'Test Game',
            'rtime_last_played': 0,
          },
        );

        expect(game.lastPlayed, isNull);
      });

      test('handles null rtime_last_played', () {
        final SteamOwnedGame game = SteamOwnedGame.fromJson(
          const <String, dynamic>{
            'appid': 100,
            'name': 'Test Game',
            'rtime_last_played': null,
          },
        );

        expect(game.lastPlayed, isNull);
      });
    });

    group('playtimeHours', () {
      test('converts minutes to hours', () {
        final SteamOwnedGame game = createTestSteamOwnedGame(
          playtimeMinutes: 120,
        );

        expect(game.playtimeHours, 2.0);
      });

      test('handles fractional hours', () {
        final SteamOwnedGame game = createTestSteamOwnedGame(
          playtimeMinutes: 90,
        );

        expect(game.playtimeHours, 1.5);
      });

      test('returns zero for zero playtime', () {
        final SteamOwnedGame game = createTestSteamOwnedGame(
          playtimeMinutes: 0,
        );

        expect(game.playtimeHours, 0.0);
      });
    });

    group('shouldSkip', () {
      test('skips soundtracks', () {
        final SteamOwnedGame game = createTestSteamOwnedGame(
          name: 'Hollow Knight Soundtrack',
        );

        expect(game.shouldSkip, isTrue);
      });

      test('skips OST', () {
        final SteamOwnedGame game = createTestSteamOwnedGame(
          name: 'Celeste OST',
        );

        expect(game.shouldSkip, isTrue);
      });

      test('skips demos', () {
        final SteamOwnedGame game = createTestSteamOwnedGame(
          name: 'RE4 Demo',
        );

        expect(game.shouldSkip, isTrue);
      });

      test('skips betas', () {
        final SteamOwnedGame game = createTestSteamOwnedGame(
          name: 'Game Beta',
        );

        expect(game.shouldSkip, isTrue);
      });

      test('skips test servers', () {
        final SteamOwnedGame game = createTestSteamOwnedGame(
          name: 'Rust Test Server',
        );

        expect(game.shouldSkip, isTrue);
      });

      test('skips dedicated servers', () {
        final SteamOwnedGame game = createTestSteamOwnedGame(
          name: 'CS:GO Dedicated Server',
        );

        expect(game.shouldSkip, isTrue);
      });

      test('skips playtests', () {
        final SteamOwnedGame game = createTestSteamOwnedGame(
          name: 'Deadlock Playtest',
        );

        expect(game.shouldSkip, isTrue);
      });

      test('does not skip regular games', () {
        final SteamOwnedGame game = createTestSteamOwnedGame(
          name: 'The Witcher 3: Wild Hunt',
        );

        expect(game.shouldSkip, isFalse);
      });

      test('is case-insensitive', () {
        final SteamOwnedGame game = createTestSteamOwnedGame(
          name: 'game SOUNDTRACK edition',
        );

        expect(game.shouldSkip, isTrue);
      });
    });
  });

  group('SteamApi', () {
    group('getOwnedGames', () {
      test('parses response correctly', () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<Map<String, dynamic>>(
              data: <String, dynamic>{
                'response': <String, dynamic>{
                  'game_count': 2,
                  'games': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'appid': 440,
                      'name': 'Team Fortress 2',
                      'playtime_forever': 1250,
                      'rtime_last_played': 1706400000,
                    },
                    <String, dynamic>{
                      'appid': 570,
                      'name': 'Dota 2',
                      'playtime_forever': 0,
                    },
                  ],
                },
              },
              statusCode: 200,
              requestOptions: RequestOptions(path: ''),
            ));

        final List<SteamOwnedGame> games = await sut.getOwnedGames(
          apiKey: 'test_key',
          steamId: '76561198012345678',
        );

        expect(games, hasLength(2));
        expect(games[0].name, 'Team Fortress 2');
        expect(games[0].playtimeMinutes, 1250);
        expect(games[1].name, 'Dota 2');
        expect(games[1].playtimeMinutes, 0);
      });

      test('returns empty list for empty response', () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<Map<String, dynamic>>(
              data: <String, dynamic>{
                'response': <String, dynamic>{},
              },
              statusCode: 200,
              requestOptions: RequestOptions(path: ''),
            ));

        final List<SteamOwnedGame> games = await sut.getOwnedGames(
          apiKey: 'test_key',
          steamId: '76561198012345678',
        );

        expect(games, isEmpty);
      });

      test('returns empty list for null data', () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<Map<String, dynamic>>(
              data: null,
              statusCode: 200,
              requestOptions: RequestOptions(path: ''),
            ));

        final List<SteamOwnedGame> games = await sut.getOwnedGames(
          apiKey: 'test_key',
          steamId: '76561198012345678',
        );

        expect(games, isEmpty);
      });

      test('throws SteamApiException for 401', () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            statusCode: 401,
            requestOptions: RequestOptions(path: ''),
          ),
          requestOptions: RequestOptions(path: ''),
        ));

        expect(
          () => sut.getOwnedGames(
            apiKey: 'bad_key',
            steamId: '76561198012345678',
          ),
          throwsA(isA<SteamApiException>().having(
            (SteamApiException e) => e.message,
            'message',
            'Invalid API key',
          )),
        );
      });

      test('throws SteamApiException for 500', () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            statusCode: 500,
            requestOptions: RequestOptions(path: ''),
          ),
          requestOptions: RequestOptions(path: ''),
        ));

        expect(
          () => sut.getOwnedGames(
            apiKey: 'test_key',
            steamId: 'invalid_id',
          ),
          throwsA(isA<SteamApiException>().having(
            (SteamApiException e) => e.message,
            'message',
            'Steam ID not found or profile is private',
          )),
        );
      });

      test('throws SteamApiException for network error', () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          type: DioExceptionType.connectionTimeout,
          message: 'Connection timeout',
          requestOptions: RequestOptions(path: ''),
        ));

        expect(
          () => sut.getOwnedGames(
            apiKey: 'test_key',
            steamId: '76561198012345678',
          ),
          throwsA(isA<SteamApiException>()),
        );
      });
    });
  });
}
