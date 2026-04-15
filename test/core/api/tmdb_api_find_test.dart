// Тесты для TmdbApi.findByImdbId / findByTvdbId.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/api/tmdb_api.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late TmdbApi sut;
  late MockDio mockDio;

  const String testApiKey = 'test_api_key_123';

  setUp(() {
    mockDio = MockDio();
    sut = TmdbApi(dio: mockDio);
    sut.setApiKey(testApiKey);
    sut.setGenreCacheForTesting(
      movieGenres: <int, String>{},
      tvGenres: <int, String>{},
    );
  });

  tearDown(() {
    sut.dispose();
  });

  Map<String, dynamic> makeFindResponse({
    List<Map<String, dynamic>> movieResults = const <Map<String, dynamic>>[],
    List<Map<String, dynamic>> tvResults = const <Map<String, dynamic>>[],
  }) {
    return <String, dynamic>{
      'movie_results': movieResults,
      'person_results': <dynamic>[],
      'tv_results': tvResults,
      'tv_episode_results': <dynamic>[],
      'tv_season_results': <dynamic>[],
    };
  }

  Map<String, dynamic> movieItem({int id = 27205, String title = 'Inception'}) {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'original_title': title,
      'release_date': '2010-07-16',
      'vote_average': 8.3,
      'genre_ids': <int>[],
    };
  }

  Map<String, dynamic> tvItem({int id = 1396, String name = 'Breaking Bad'}) {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'original_name': name,
      'first_air_date': '2008-01-20',
      'vote_average': 8.9,
      'genre_ids': <int>[],
    };
  }

  group('findByImdbId', () {
    test('возвращает фильм при успешном ответе', () async {
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response<dynamic>(
            data: makeFindResponse(
              movieResults: <Map<String, dynamic>>[movieItem()],
            ),
            statusCode: 200,
            requestOptions: RequestOptions(),
          ));

      final TmdbFindResult result = await sut.findByImdbId('tt1375666');

      expect(result.movies, hasLength(1));
      expect(result.tvShows, isEmpty);
      expect(result.firstMovie!.tmdbId, 27205);
      expect(result.firstMovie!.title, 'Inception');
      expect(result.isEmpty, isFalse);
    });

    test('возвращает сериал при успешном ответе', () async {
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response<dynamic>(
            data: makeFindResponse(
              tvResults: <Map<String, dynamic>>[tvItem()],
            ),
            statusCode: 200,
            requestOptions: RequestOptions(),
          ));

      final TmdbFindResult result = await sut.findByImdbId('tt0903747');

      expect(result.movies, isEmpty);
      expect(result.tvShows, hasLength(1));
      expect(result.firstTvShow!.tmdbId, 1396);
    });

    test('пустой результат → isEmpty', () async {
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response<dynamic>(
            data: makeFindResponse(),
            statusCode: 200,
            requestOptions: RequestOptions(),
          ));

      final TmdbFindResult result = await sut.findByImdbId('tt0000000');

      expect(result.isEmpty, isTrue);
      expect(result.firstMovie, isNull);
      expect(result.firstTvShow, isNull);
    });

    test('передаёт external_source = imdb_id в query', () async {
      final List<Map<String, dynamic>?> capturedQueries =
          <Map<String, dynamic>?>[];

      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((Invocation inv) async {
        capturedQueries.add(
          inv.namedArguments[#queryParameters] as Map<String, dynamic>?,
        );
        return Response<dynamic>(
          data: makeFindResponse(),
          statusCode: 200,
          requestOptions: RequestOptions(),
        );
      });

      await sut.findByImdbId('tt1375666');

      expect(capturedQueries, hasLength(1));
      expect(capturedQueries.first!['external_source'], 'imdb_id');
      expect(capturedQueries.first!['api_key'], testApiKey);
    });

    test('передаёт IMDB ID в URL как есть', () async {
      final List<String?> capturedUrls = <String?>[];

      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((Invocation inv) async {
        capturedUrls.add(inv.positionalArguments.first as String?);
        return Response<dynamic>(
          data: makeFindResponse(),
          statusCode: 200,
          requestOptions: RequestOptions(),
        );
      });

      await sut.findByImdbId('tt1375666');

      expect(capturedUrls.first!.endsWith('/find/tt1375666'), isTrue);
    });

    test('404 → пустой результат, не выбрасывает', () async {
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(DioException(
        response: Response<dynamic>(
          statusCode: 404,
          requestOptions: RequestOptions(),
        ),
        requestOptions: RequestOptions(),
      ));

      final TmdbFindResult result = await sut.findByImdbId('tt0000000');
      expect(result.isEmpty, isTrue);
    });

    test('500 → TmdbApiException', () async {
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(DioException(
        response: Response<dynamic>(
          statusCode: 500,
          requestOptions: RequestOptions(),
        ),
        requestOptions: RequestOptions(),
      ));

      expect(
        () => sut.findByImdbId('tt1'),
        throwsA(isA<TmdbApiException>()),
      );
    });
  });

  group('findByTvdbId', () {
    test('передаёт external_source = tvdb_id и ID как строку', () async {
      final List<Map<String, dynamic>?> capturedQueries =
          <Map<String, dynamic>?>[];
      final List<String?> capturedUrls = <String?>[];

      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((Invocation inv) async {
        capturedUrls.add(inv.positionalArguments.first as String?);
        capturedQueries.add(
          inv.namedArguments[#queryParameters] as Map<String, dynamic>?,
        );
        return Response<dynamic>(
          data: makeFindResponse(),
          statusCode: 200,
          requestOptions: RequestOptions(),
        );
      });

      await sut.findByTvdbId(81189);

      expect(capturedUrls.first!.endsWith('/find/81189'), isTrue);
      expect(capturedQueries.first!['external_source'], 'tvdb_id');
    });

    test('возвращает сериал', () async {
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response<dynamic>(
            data: makeFindResponse(
              tvResults: <Map<String, dynamic>>[tvItem()],
            ),
            statusCode: 200,
            requestOptions: RequestOptions(),
          ));

      final TmdbFindResult result = await sut.findByTvdbId(81189);
      expect(result.firstTvShow!.tmdbId, 1396);
    });
  });

  group('TmdbFindResult', () {
    test('пустой по умолчанию', () {
      const TmdbFindResult result = TmdbFindResult();
      expect(result.movies, isEmpty);
      expect(result.tvShows, isEmpty);
      expect(result.isEmpty, isTrue);
      expect(result.firstMovie, isNull);
      expect(result.firstTvShow, isNull);
    });
  });

  group('без API key', () {
    test('findByImdbId выбрасывает TmdbApiException', () async {
      final TmdbApi noKeyApi = TmdbApi(dio: mockDio);
      expect(
        () => noKeyApi.findByImdbId('tt1'),
        throwsA(isA<TmdbApiException>()),
      );
      noKeyApi.dispose();
    });
  });
}
