import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/simkl_api.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late MockDio mockDio;
  late SimklApi api;

  setUpAll(registerAllFallbacks);

  setUp(() {
    mockDio = MockDio();
    api = SimklApi(clientId: 'cid', dio: mockDio);
  });

  Response<dynamic> makeResponse(dynamic data, {int status = 200}) =>
      Response<dynamic>(
        data: data,
        statusCode: status,
        requestOptions: RequestOptions(path: ''),
      );

  void stubGet(Response<dynamic> response) {
    when(() => mockDio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => response);
  }

  void stubError(int? statusCode, {DioExceptionType? type}) {
    when(() => mockDio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        )).thenThrow(DioException(
      requestOptions: RequestOptions(path: ''),
      type: type ?? DioExceptionType.badResponse,
      response: statusCode == null
          ? null
          : Response<dynamic>(
              statusCode: statusCode,
              requestOptions: RequestOptions(path: ''),
            ),
    ));
  }

  group('client id', () {
    test('reports a missing client id', () {
      expect(SimklApi(clientId: '', dio: mockDio).hasClientId, isFalse);
      expect(api.hasClientId, isTrue);
      expect(api.clientId, 'cid');
    });

    test('setClientId replaces the key used for requests', () async {
      api.setClientId('other');
      stubGet(makeResponse(<String, dynamic>{'user_code': 'ABCDE'}));

      await api.requestPin();

      final Map<String, dynamic> query = verify(() => mockDio.get<dynamic>(
            any(),
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),
          )).captured.single as Map<String, dynamic>;
      expect(query['client_id'], 'other');
      expect(api.clientId, 'other');
    });
  });

  group('requestPin', () {
    test('parses the PIN payload', () async {
      stubGet(makeResponse(<String, dynamic>{
        'user_code': 'ABCDE',
        'verification_url': 'https://simkl.com/pin/',
        'expires_in': 600,
        'interval': 3,
      }));

      final SimklPin pin = await api.requestPin();

      expect(pin.userCode, 'ABCDE');
      expect(pin.verificationUrl, 'https://simkl.com/pin/');
      expect(pin.expiresIn, 600);
      expect(pin.interval, 3);
    });

    test('applies defaults for the optional fields', () async {
      stubGet(makeResponse(<String, dynamic>{'user_code': 'ABCDE'}));

      final SimklPin pin = await api.requestPin();

      expect(pin.verificationUrl, 'https://simkl.com/pin');
      expect(pin.expiresIn, 900);
      expect(pin.interval, 5);
    });

    test('throws when the response carries no code', () async {
      stubGet(makeResponse(<String, dynamic>{}));

      expect(api.requestPin, throwsA(isA<SimklApiException>()));
    });
  });

  group('pollPin', () {
    test('returns the token once the user has confirmed', () async {
      stubGet(makeResponse(<String, dynamic>{'access_token': 'tok'}));

      expect(await api.pollPin('ABCDE'), 'tok');
    });

    test('returns null while authorization is pending', () async {
      stubGet(makeResponse(<String, dynamic>{'result': 'KO'}));

      expect(await api.pollPin('ABCDE'), isNull);
    });

    test('treats 400 / 404 as "still pending"', () async {
      for (final int status in <int>[400, 404]) {
        stubError(status);

        expect(await api.pollPin('ABCDE'), isNull, reason: 'status $status');
      }
    });

    test('rethrows other failures', () async {
      stubError(500);

      expect(() => api.pollPin('ABCDE'), throwsA(isA<SimklApiException>()));
    });
  });

  group('authorized requests', () {
    test('refuse to run without a token', () async {
      expect(api.hasAccessToken, isFalse);
      expect(api.getAllItems, throwsA(isA<SimklApiException>()));
      verifyNever(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ));
    });

    test('send the bearer token once one is set', () async {
      api.setAccessToken('tok');
      stubGet(makeResponse(<String, dynamic>{
        'user': <String, dynamic>{'name': 'ann'},
        'account': <String, dynamic>{'id': 7},
      }));

      final SimklUser user = await api.getUserSettings();

      expect(user.name, 'ann');
      expect(user.accountId, 7);
      final Options options = verify(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: captureAny(named: 'options'),
          )).captured.single as Options;
      expect(options.headers?['Authorization'], 'Bearer tok');
      expect(options.headers?['simkl-api-key'], 'cid');
    });

    test('tokenOverride wins over the stored token', () async {
      api.setAccessToken('stored');
      stubGet(makeResponse(<String, dynamic>{}));

      await api.getUserSettings(tokenOverride: 'fresh');

      final Options options = verify(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: captureAny(named: 'options'),
          )).captured.single as Options;
      expect(options.headers?['Authorization'], 'Bearer fresh');
    });

    test('clearAccessToken disconnects the account', () {
      api.setAccessToken('tok');
      api.clearAccessToken();

      expect(api.hasAccessToken, isFalse);
    });

    test('getAllItems asks for episode dates and memos', () async {
      api.setAccessToken('tok');
      stubGet(makeResponse(<String, dynamic>{
        'movies': <Map<String, dynamic>>[
          <String, dynamic>{
            'status': 'completed',
            'movie': <String, dynamic>{'title': 'Fight Club'},
          },
        ],
      }));

      final SimklAllItems items = await api.getAllItems();

      expect(items.movies, hasLength(1));
      expect(items.totalCount, 1);
      final Map<String, dynamic> query = verify(() => mockDio.get<dynamic>(
            any(),
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),
          )).captured.single as Map<String, dynamic>;
      expect(query['extended'], 'full');
      expect(query['episode_watched_at'], 'yes');
      expect(query['memos'], 'yes');
    });
  });

  group('error mapping', () {
    test('flags 412 as a client-id failure', () async {
      api.setAccessToken('tok');
      stubError(412);

      await expectLater(
        api.getAllItems,
        throwsA(isA<SimklApiException>()
            .having((SimklApiException e) => e.isClientIdFailure,
                'isClientIdFailure', isTrue)
            .having((SimklApiException e) => e.statusCode, 'statusCode', 412)),
      );
    });

    test('keeps the status code for auth and rate-limit failures', () async {
      api.setAccessToken('tok');
      for (final int status in <int>[401, 403, 429]) {
        stubError(status);

        await expectLater(
          api.getAllItems,
          throwsA(isA<SimklApiException>()
              .having((SimklApiException e) => e.statusCode, 'statusCode',
                  status)
              .having((SimklApiException e) => e.isClientIdFailure,
                  'isClientIdFailure', isFalse)),
          reason: 'status $status',
        );
      }
    });

    test('maps transport failures without a status code', () async {
      api.setAccessToken('tok');
      stubError(null, type: DioExceptionType.connectionError);

      await expectLater(
        api.getAllItems,
        throwsA(isA<SimklApiException>().having(
            (SimklApiException e) => e.statusCode, 'statusCode', isNull)),
      );
    });
  });
}
