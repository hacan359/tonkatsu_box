import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/screenscraper_api.dart';

import '../../helpers/test_helpers.dart';

Response<Map<String, dynamic>> _resp(Map<String, dynamic> data) =>
    Response<Map<String, dynamic>>(
      data: data,
      statusCode: 200,
      requestOptions: RequestOptions(),
    );

Map<String, dynamic> _searchBody() => <String, dynamic>{
      'response': <String, dynamic>{
        'jeux': <dynamic>[
          <String, dynamic>{
            'id': '2143',
            'noms': <dynamic>[
              <String, dynamic>{'region': 'wor', 'text': 'Chrono Trigger'},
            ],
            'medias': <dynamic>[
              <String, dynamic>{
                'type': 'ss',
                'url': 'https://neoclone.screenscraper.fr/api2/mediaJeu.php',
                'format': 'png',
                'region': 'wor',
              },
            ],
          },
        ],
      },
    };

void main() {
  late ScreenScraperApi sut;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    sut = ScreenScraperApi(dio: mockDio);
  });

  Map<String, dynamic> capturedQuery() {
    return verify(() => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: captureAny(named: 'queryParameters'),
        )).captured.single as Map<String, dynamic>;
  }

  void stubSearch() {
    when(() => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => _resp(_searchBody()));
  }

  group('ScreenScraperApi', () {
    group('hasDevCredentials', () {
      test('should be false without a build-time or a runtime pair', () {
        expect(sut.hasDevCredentials, isFalse);
      });

      test('should be false when only half the runtime pair is given', () {
        sut.setDevCredentials(devId: 'dev', devPassword: '');

        expect(sut.hasDevCredentials, isFalse);
      });

      test('should be true once the runtime pair is set', () {
        sut.setDevCredentials(devId: 'dev', devPassword: 'secret');

        expect(sut.hasDevCredentials, isTrue);
      });
    });

    group('searchGame', () {
      test('should refuse without dev credentials', () {
        sut.setUserCredentials(ssid: 'user', sspassword: 'pass');

        expect(
          () => sut.searchGame(name: 'Chrono Trigger', systemeId: 4),
          throwsA(isA<ScreenScraperApiException>()),
        );
      });

      test('should refuse with dev credentials but no user pair', () {
        sut.setDevCredentials(devId: 'dev', devPassword: 'secret');

        expect(
          () => sut.searchGame(name: 'Chrono Trigger', systemeId: 4),
          throwsA(isA<ScreenScraperApiException>()),
        );
      });

      test('should send the runtime dev pair alongside the user pair',
          () async {
        stubSearch();
        sut
          ..setDevCredentials(devId: 'dev', devPassword: 'secret')
          ..setUserCredentials(ssid: 'user', sspassword: 'pass');

        await sut.searchGame(name: 'Chrono Trigger', systemeId: 4);

        final Map<String, dynamic> query = capturedQuery();
        expect(query['devid'], 'dev');
        expect(query['devpassword'], 'secret');
        expect(query['ssid'], 'user');
        expect(query['sspassword'], 'pass');
        expect(query['recherche'], 'Chrono Trigger');
        expect(query['systemeid'], '4');
      });

      test('should return the first match with its medias', () async {
        stubSearch();
        sut
          ..setDevCredentials(devId: 'dev', devPassword: 'secret')
          ..setUserCredentials(ssid: 'user', sspassword: 'pass');

        final SsGame? game =
            await sut.searchGame(name: 'Chrono Trigger', systemeId: 4);

        expect(game?.id, 2143);
        expect(game?.name, 'Chrono Trigger');
        expect(game?.medias.single.type, 'ss');
      });

      test('should wrap a transport failure in a ScreenScraperApiException',
          () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(),
          response: Response<dynamic>(
            statusCode: 503,
            requestOptions: RequestOptions(),
          ),
          type: DioExceptionType.badResponse,
        ));
        sut
          ..setDevCredentials(devId: 'dev', devPassword: 'secret')
          ..setUserCredentials(ssid: 'user', sspassword: 'pass');

        await expectLater(
          sut.searchGame(name: 'Chrono Trigger', systemeId: 4),
          throwsA(isA<ScreenScraperApiException>()
              .having((ScreenScraperApiException e) => e.statusCode,
                  'statusCode', 503)),
        );
      });
    });

    group('getUserInfo', () {
      test('should refuse without dev credentials', () {
        sut.setUserCredentials(ssid: 'user', sspassword: 'pass');

        expect(
          sut.getUserInfo,
          throwsA(isA<ScreenScraperApiException>()),
        );
      });

      test('should parse the quota out of the ssuser block', () async {
        when(() => mockDio.get<Map<String, dynamic>>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => _resp(<String, dynamic>{
              'response': <String, dynamic>{
                'ssuser': <String, dynamic>{
                  'requeststoday': '12',
                  'maxrequestsperday': '20000',
                  'maxrequestspermin': '400',
                  'maxthreads': '5',
                  'niveau': '3',
                },
              },
            }));
        sut
          ..setDevCredentials(devId: 'dev', devPassword: 'secret')
          ..setUserCredentials(ssid: 'user', sspassword: 'pass');

        final SsUserQuota quota = await sut.getUserInfo();

        expect(quota.requestsToday, 12);
        expect(quota.maxPerDay, 20000);
        expect(quota.maxPerMinute, 400);
        expect(quota.maxThreads, 5);
        expect(quota.level, 3);
      });
    });
  });
}
