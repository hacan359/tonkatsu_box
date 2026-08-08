import 'package:dio/dio.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/movie.dart';
import 'package:core/models/tv_season.dart';
import 'package:core/models/tv_show.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/tvdb_api.dart';

import '../../helpers/test_helpers.dart';

/// TheTVDB answers `{status, data}` on success but `{message}` on 401, so both
/// shapes show up in these fixtures.
Response<dynamic> ok(Object? data) => Response<dynamic>(
      data: <String, dynamic>{'status': 'success', 'data': data},
      statusCode: 200,
      requestOptions: RequestOptions(path: '/'),
    );

DioException unauthorized() => DioException(
      requestOptions: RequestOptions(path: '/'),
      response: Response<dynamic>(
        data: <String, dynamic>{'message': 'Unauthorized'},
        statusCode: 401,
        requestOptions: RequestOptions(path: '/'),
      ),
    );

void main() {
  late TvdbApi sut;
  late MockDio mockDio;

  setUp(() {
    registerAllFallbacks();
    mockDio = MockDio();
    sut = TvdbApi(dio: mockDio);
  });

  tearDown(() => sut.dispose());

  void stubLogin({String token = 'jwt-1'}) {
    when(() => mockDio.post<dynamic>(any(), data: any(named: 'data')))
        .thenAnswer((_) async => ok(<String, dynamic>{'token': token}));
  }

  group('TvdbApi authentication', () {
    test('should refuse to call before a key is set', () async {
      expect(sut.hasApiKey, isFalse);
      await expectLater(sut.getMovie(113), throwsA(isA<TvdbApiException>()));
      verifyNever(() => mockDio.post<dynamic>(any(), data: any(named: 'data')));
    });

    test('should exchange the key for a token once and reuse it', () async {
      stubLogin();
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => ok(<String, dynamic>{
            'id': 113,
            'name': 'Inception',
          }));
      sut.setApiKey('key');

      await sut.getMovie(113);
      await sut.getMovie(114);

      verify(() => mockDio.post<dynamic>(any(), data: any(named: 'data')))
          .called(1);
    });

    test('should re-login once and retry when the token expired', () async {
      stubLogin();
      bool firstCall = true;
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async {
        if (firstCall) {
          firstCall = false;
          throw unauthorized();
        }
        return ok(<String, dynamic>{'id': 113, 'name': 'Inception'});
      });
      sut.setApiKey('key');

      final Movie? movie = await sut.getMovie(113);

      expect(movie?.title, 'Inception');
      verify(() => mockDio.post<dynamic>(any(), data: any(named: 'data')))
          .called(2);
    });

    test('should surface a second 401 instead of looping', () async {
      stubLogin();
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenThrow(unauthorized());
      sut.setApiKey('key');

      await expectLater(sut.getMovie(113), throwsA(isA<TvdbApiException>()));
      verify(() => mockDio.post<dynamic>(any(), data: any(named: 'data')))
          .called(2);
    });

    test('should drop the cached token when the key changes', () async {
      stubLogin();
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => ok(<String, dynamic>{'id': 1, 'name': 'x'}));

      sut.setApiKey('first');
      await sut.getMovie(1);
      sut.setApiKey('second');
      await sut.getMovie(1);

      verify(() => mockDio.post<dynamic>(any(), data: any(named: 'data')))
          .called(2);
    });

    test('validateApiKey should report a failed login as invalid', () async {
      when(() => mockDio.post<dynamic>(any(), data: any(named: 'data')))
          .thenThrow(unauthorized());

      expect(await sut.validateApiKey('bad'), isFalse);
    });

    test('validateApiKey should accept a login that returns a token', () async {
      stubLogin();

      expect(await sut.validateApiKey('good'), isTrue);
    });

    test('should reject a login response with no token', () async {
      when(() => mockDio.post<dynamic>(any(), data: any(named: 'data')))
          .thenAnswer((_) async => ok(<String, dynamic>{}));

      expect(await sut.validateApiKey('weird'), isFalse);
    });
  });

  group('TvdbApi requests', () {
    setUp(() {
      stubLogin();
      sut.setApiKey('key');
    });

    test('getMovie should return null for a missing record', () async {
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response<dynamic>(
          statusCode: 404,
          requestOptions: RequestOptions(path: '/'),
        ),
      ));

      expect(await sut.getMovie(999), isNull);
    });

    test('getMovie should ask for translations and the short payload',
        () async {
      final List<Map<String, dynamic>?> queries = <Map<String, dynamic>?>[];
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((Invocation i) async {
        queries.add(i.namedArguments[#queryParameters] as Map<String, dynamic>?);
        return ok(<String, dynamic>{'id': 113, 'name': 'Inception'});
      });

      await sut.getMovie(113);

      expect(queries.single!['meta'], 'translations');
      expect(queries.single!['short'], isTrue);
    });

    test('searchSeries should stamp the source on every hit', () async {
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => ok(<dynamic>[
            <String, dynamic>{'tvdb_id': '81189', 'name': 'Breaking Bad'},
          ]));

      final List<TvShow> shows = await sut.searchSeries('breaking');

      expect(shows.single.tmdbId, 81189);
      expect(shows.single.source, DataSource.tvdb);
    });

    test('search should pass limit and offset through', () async {
      final List<Map<String, dynamic>?> queries = <Map<String, dynamic>?>[];
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((Invocation i) async {
        queries.add(i.namedArguments[#queryParameters] as Map<String, dynamic>?);
        return ok(<dynamic>[]);
      });

      await sut.searchMovies('star', limit: 25, offset: 50);

      expect(queries.single!['limit'], 25);
      expect(queries.single!['offset'], 50);
    });

    test('searchMovies should not call the API for a blank query', () async {
      expect(await sut.searchMovies('   '), isEmpty);
      verifyNever(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ));
    });

    test('getSeries and getSeasons should share one extended request',
        () async {
      int calls = 0;
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async {
        calls++;
        return ok(<String, dynamic>{
          'id': 81189,
          'name': 'Breaking Bad',
          'defaultSeasonType': 1,
          'seasons': <dynamic>[
            <String, dynamic>{
              'number': 1,
              'type': <String, dynamic>{'id': 1},
            },
          ],
        });
      });

      await sut.getSeries(81189);
      final List<TvSeason> seasons = await sut.getSeasons(81189);

      expect(seasons, hasLength(1));
      expect(calls, 1);
    });

    test('getAllEpisodes should follow pagination until links.next is null',
        () async {
      int page = 0;
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async {
        final bool last = page == 1;
        final Response<dynamic> response = Response<dynamic>(
          data: <String, dynamic>{
            'status': 'success',
            'data': <String, dynamic>{
              'episodes': <dynamic>[
                <String, dynamic>{
                  'number': page + 1,
                  'seasonNumber': 1,
                  'name': 'E${page + 1}',
                },
              ],
            },
            'links': <String, dynamic>{'next': last ? null : 'more'},
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/'),
        );
        page++;
        return response;
      });

      expect(await sut.getAllEpisodes(81189), hasLength(2));
    });
  });
}
