// Тесты для TMDB API клиента.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/api/tmdb_api.dart';
import 'package:xerabora/shared/models/movie.dart';
import 'package:xerabora/shared/models/tv_episode.dart';
import 'package:xerabora/shared/models/tv_season.dart';
import 'package:xerabora/shared/models/tv_show.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late TmdbApi sut;
  late MockDio mockDio;

  const String testApiKey = 'test_api_key_123';

  setUp(() {
    mockDio = MockDio();
    sut = TmdbApi(dio: mockDio);
  });

  tearDown(() {
    sut.dispose();
  });

  // ===== Вспомогательные данные =====

  Map<String, dynamic> createMovieJson({
    int id = 550,
    String title = 'Бойцовский клуб',
    String? originalTitle = 'Fight Club',
    String? posterPath = '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg',
    String? backdropPath = '/hZkgoQYus5dXo3H8T7Uef6DNknx.jpg',
    String? overview = 'Тест описание',
    String? releaseDate = '1999-10-15',
    double? voteAverage = 8.4,
    int? runtime = 139,
  }) {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'original_title': originalTitle,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'overview': overview,
      'release_date': releaseDate,
      'vote_average': voteAverage,
      'runtime': runtime,
      'genre_ids': <int>[18, 53],
    };
  }

  Map<String, dynamic> createTvShowJson({
    int id = 1396,
    String name = 'Во все тяжкие',
    String? originalName = 'Breaking Bad',
    String? posterPath = '/ggFHVNu6YYI5L9pCfOacjizRGt.jpg',
    String? backdropPath = '/tsRy63Mu5cu8etL1X7ZLyf7UP1M.jpg',
    String? overview = 'Сериал о химике',
    String? firstAirDate = '2008-01-20',
    int? numberOfSeasons = 5,
    int? numberOfEpisodes = 62,
    double? voteAverage = 8.9,
    String? status = 'Ended',
  }) {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'original_name': originalName,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'overview': overview,
      'first_air_date': firstAirDate,
      'number_of_seasons': numberOfSeasons,
      'number_of_episodes': numberOfEpisodes,
      'vote_average': voteAverage,
      'status': status,
      'genre_ids': <int>[18, 80],
    };
  }

  Map<String, dynamic> createSeasonJson({
    int seasonNumber = 1,
    String? name = 'Сезон 1',
    int? episodeCount = 7,
    String? posterPath = '/1BP4xYv9ZG4ZVHkL7ocOziBbSYH.jpg',
    String? airDate = '2008-01-20',
  }) {
    return <String, dynamic>{
      'season_number': seasonNumber,
      'name': name,
      'episode_count': episodeCount,
      'poster_path': posterPath,
      'air_date': airDate,
    };
  }

  Map<String, dynamic> createEpisodeJson({
    int episodeNumber = 1,
    String? name = 'Пилот',
    String? overview = 'Описание эпизода',
    String? airDate = '2008-01-20',
    String? stillPath = '/9074lJh4G2RBXhyR6F5mGDPXPCF.jpg',
    int? runtime = 45,
  }) {
    return <String, dynamic>{
      'episode_number': episodeNumber,
      'name': name,
      'overview': overview,
      'air_date': airDate,
      'still_path': stillPath,
      'runtime': runtime,
    };
  }

  // ===== TmdbApiException =====

  group('TmdbApiException', () {
    test('должен создать с сообщением', () {
      const TmdbApiException exception = TmdbApiException('Test error');

      expect(exception.message, equals('Test error'));
      expect(exception.statusCode, isNull);
    });

    test('должен создать с сообщением и кодом', () {
      const TmdbApiException exception = TmdbApiException(
        'Test error',
        statusCode: 401,
      );

      expect(exception.message, equals('Test error'));
      expect(exception.statusCode, equals(401));
    });

    test('toString должен вернуть строковое представление', () {
      const TmdbApiException exception = TmdbApiException(
        'Test error',
        statusCode: 401,
      );

      expect(
        exception.toString(),
        equals('TmdbApiException: Test error (status: 401)'),
      );
    });

    test('toString должен вернуть null для statusCode если не задан', () {
      const TmdbApiException exception = TmdbApiException('Test error');

      expect(
        exception.toString(),
        equals('TmdbApiException: Test error (status: null)'),
      );
    });
  });

  // ===== TmdbGenre =====

  group('TmdbGenre', () {
    test('fromJson должен создать жанр из JSON', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'id': 28,
        'name': 'Action',
      };

      final TmdbGenre genre = TmdbGenre.fromJson(json);

      expect(genre.id, equals(28));
      expect(genre.name, equals('Action'));
    });

    test('fromJson должен создать жанр с русским названием', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'id': 18,
        'name': 'Драма',
      };

      final TmdbGenre genre = TmdbGenre.fromJson(json);

      expect(genre.id, equals(18));
      expect(genre.name, equals('Драма'));
    });
  });

  // ===== TmdbApi =====

  group('TmdbApi', () {
    // ----- setApiKey / clearApiKey -----

    group('setApiKey', () {
      test('должен установить API ключ', () {
        sut.setApiKey(testApiKey);

        // Проверяем что после установки ключа можно вызвать метод
        // без исключения о недостающем ключе
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'results': <Map<String, dynamic>>[],
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        expect(
          () => sut.searchMovies('test'),
          returnsNormally,
        );
      });
    });

    group('clearApiKey', () {
      test('должен очистить API ключ', () {
        sut.setApiKey(testApiKey);
        sut.clearApiKey();

        expect(
          () => sut.searchMovies('test'),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'API key not set',
          )),
        );
      });
    });

    // ----- _ensureApiKey -----

    group('_ensureApiKey', () {
      test('должен выбросить исключение если ключ не установлен', () {
        expect(
          () => sut.searchMovies('test'),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'API key not set',
          )),
        );
      });

      test('должен выбросить исключение для getMovie без ключа', () {
        expect(
          () => sut.getMovie(550),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'API key not set',
          )),
        );
      });

      test('должен выбросить исключение для getPopularMovies без ключа', () {
        expect(
          () => sut.getPopularMovies(),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'API key not set',
          )),
        );
      });

      test('должен выбросить исключение для searchTvShows без ключа', () {
        expect(
          () => sut.searchTvShows('test'),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'API key not set',
          )),
        );
      });

      test('должен выбросить исключение для getTvShow без ключа', () {
        expect(
          () => sut.getTvShow(1396),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'API key not set',
          )),
        );
      });

      test('должен выбросить исключение для getTvSeasons без ключа', () {
        expect(
          () => sut.getTvSeasons(1396),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'API key not set',
          )),
        );
      });

      test('должен выбросить исключение для getPopularTvShows без ключа', () {
        expect(
          () => sut.getPopularTvShows(),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'API key not set',
          )),
        );
      });

      test('должен выбросить исключение для multiSearch без ключа', () {
        expect(
          () => sut.multiSearch('test'),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'API key not set',
          )),
        );
      });

      test('должен выбросить исключение для getMovieGenres без ключа', () {
        expect(
          () => sut.getMovieGenres(),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'API key not set',
          )),
        );
      });

      test('должен выбросить исключение для getTvGenres без ключа', () {
        expect(
          () => sut.getTvGenres(),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'API key not set',
          )),
        );
      });
    });

    // ----- validateApiKey -----

    group('validateApiKey', () {
      test('должен вернуть true при валидном ключе', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{'images': <String, dynamic>{}},
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final bool result = await sut.validateApiKey(testApiKey);

        expect(result, isTrue);
      });

      test('должен вернуть false при невалидном ключе (DioException)', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          response: Response<dynamic>(
            statusCode: 401,
            requestOptions: RequestOptions(),
          ),
          requestOptions: RequestOptions(),
        ));

        final bool result = await sut.validateApiKey('invalid_key');

        expect(result, isFalse);
      });

      test('должен вернуть false при ошибке соединения', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(),
        ));

        final bool result = await sut.validateApiKey(testApiKey);

        expect(result, isFalse);
      });
    });

    // ----- searchMovies -----

    group('searchMovies', () {
      setUp(() {
        sut.setApiKey(testApiKey);
      });

      test('должен вернуть пустой список при пустом запросе', () async {
        final List<Movie> result = await sut.searchMovies('');

        expect(result, isEmpty);
      });

      test('должен вернуть пустой список при запросе из пробелов', () async {
        final List<Movie> result = await sut.searchMovies('   ');

        expect(result, isEmpty);
      });

      test('должен вернуть список фильмов при успешном ответе', () async {
        final Map<String, dynamic> movie1 = createMovieJson();
        final Map<String, dynamic> movie2 = createMovieJson(
          id: 680,
          title: 'Криминальное чтиво',
          originalTitle: 'Pulp Fiction',
          releaseDate: '1994-09-10',
          voteAverage: 8.5,
        );

        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'results': <Map<String, dynamic>>[movie1, movie2],
                'total_results': 2,
                'total_pages': 1,
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<Movie> result = await sut.searchMovies('test');

        expect(result, hasLength(2));
        expect(result[0].tmdbId, equals(550));
        expect(result[0].title, equals('Бойцовский клуб'));
        expect(result[1].tmdbId, equals(680));
        expect(result[1].title, equals('Криминальное чтиво'));
      });

      test('должен выбросить TmdbApiException при DioException 401', () async {
        when(() => mockDio.get<dynamic>(
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
          () => sut.searchMovies('test'),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'Invalid API key',
          )),
        );
      });

      test('должен выбросить TmdbApiException при DioException 429', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          response: Response<dynamic>(
            statusCode: 429,
            requestOptions: RequestOptions(),
          ),
          requestOptions: RequestOptions(),
        ));

        expect(
          () => sut.searchMovies('test'),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'Rate limit exceeded. Please try again later',
          )),
        );
      });

      test('должен выбросить TmdbApiException при таймауте', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(),
        ));

        expect(
          () => sut.searchMovies('test'),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'Connection timeout',
          )),
        );
      });

      test('должен выбросить TmdbApiException при ошибке соединения', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(),
        ));

        expect(
          () => sut.searchMovies('test'),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'No internet connection',
          )),
        );
      });

      test('должен выбросить TmdbApiException при receiveTimeout', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          type: DioExceptionType.receiveTimeout,
          requestOptions: RequestOptions(),
        ));

        expect(
          () => sut.searchMovies('test'),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'Connection timeout',
          )),
        );
      });

      test('должен выбросить TmdbApiException при неуспешном статусе', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: null,
              statusCode: 500,
              requestOptions: RequestOptions(),
            ));

        expect(
          () => sut.searchMovies('test'),
          throwsA(isA<TmdbApiException>()),
        );
      });

      test('должен передать year в queryParameters когда указан', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'results': <Map<String, dynamic>>[],
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        await sut.searchMovies('test', year: 2024);

        final VerificationResult verification = verify(() => mockDio.get<dynamic>(
              any(),
              queryParameters: captureAny(named: 'queryParameters'),
            ));
        verification.called(1);

        final Map<String, dynamic> params =
            verification.captured.first as Map<String, dynamic>;
        expect(params['year'], equals(2024));
      });

      test('не должен передавать year когда не указан', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'results': <Map<String, dynamic>>[],
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        await sut.searchMovies('test');

        final VerificationResult verification = verify(() => mockDio.get<dynamic>(
              any(),
              queryParameters: captureAny(named: 'queryParameters'),
            ));
        verification.called(1);

        final Map<String, dynamic> params =
            verification.captured.first as Map<String, dynamic>;
        expect(params.containsKey('year'), isFalse);
      });
    });

    // ----- getMovie -----

    group('getMovie', () {
      setUp(() {
        sut.setApiKey(testApiKey);
      });

      test('должен вернуть фильм при успешном ответе', () async {
        final Map<String, dynamic> movieJson = createMovieJson();

        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: movieJson,
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final Movie? result = await sut.getMovie(550);

        expect(result, isNotNull);
        expect(result!.tmdbId, equals(550));
        expect(result.title, equals('Бойцовский клуб'));
        expect(result.originalTitle, equals('Fight Club'));
        expect(result.releaseYear, equals(1999));
        expect(result.rating, equals(8.4));
        expect(result.runtime, equals(139));
        expect(result.posterUrl, contains('/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg'));
        expect(result.backdropUrl, contains('/hZkgoQYus5dXo3H8T7Uef6DNknx.jpg'));
      });

      test('должен вернуть null при 404', () async {
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

        final Movie? result = await sut.getMovie(999999);

        expect(result, isNull);
      });

      test('должен выбросить TmdbApiException при DioException 500', () async {
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
          () => sut.getMovie(550),
          throwsA(isA<TmdbApiException>()),
        );
      });

      test('должен выбросить TmdbApiException при DioException 401', () async {
        when(() => mockDio.get<dynamic>(
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
          () => sut.getMovie(550),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'Invalid API key',
          )),
        );
      });

      test('должен выбросить TmdbApiException при неуспешном статусе', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: null,
              statusCode: 500,
              requestOptions: RequestOptions(),
            ));

        expect(
          () => sut.getMovie(550),
          throwsA(isA<TmdbApiException>()),
        );
      });
    });

    // ----- getPopularMovies -----

    group('getPopularMovies', () {
      setUp(() {
        sut.setApiKey(testApiKey);
      });

      test('должен вернуть список популярных фильмов', () async {
        final Map<String, dynamic> movie1 = createMovieJson();
        final Map<String, dynamic> movie2 = createMovieJson(
          id: 680,
          title: 'Криминальное чтиво',
        );

        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'results': <Map<String, dynamic>>[movie1, movie2],
                'total_results': 2,
                'total_pages': 1,
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<Movie> result = await sut.getPopularMovies();

        expect(result, hasLength(2));
        expect(result[0].tmdbId, equals(550));
        expect(result[1].tmdbId, equals(680));
      });

      test('должен вернуть пустой список при пустых результатах', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'results': <Map<String, dynamic>>[],
                'total_results': 0,
                'total_pages': 0,
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<Movie> result = await sut.getPopularMovies();

        expect(result, isEmpty);
      });

      test('должен выбросить TmdbApiException при DioException', () async {
        when(() => mockDio.get<dynamic>(
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
          () => sut.getPopularMovies(),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'Invalid API key',
          )),
        );
      });

      test('должен выбросить TmdbApiException при неуспешном статусе', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: null,
              statusCode: 503,
              requestOptions: RequestOptions(),
            ));

        expect(
          () => sut.getPopularMovies(),
          throwsA(isA<TmdbApiException>()),
        );
      });
    });

    // ----- searchTvShows -----

    group('searchTvShows', () {
      setUp(() {
        sut.setApiKey(testApiKey);
      });

      test('должен вернуть пустой список при пустом запросе', () async {
        final List<TvShow> result = await sut.searchTvShows('');

        expect(result, isEmpty);
      });

      test('должен вернуть пустой список при запросе из пробелов', () async {
        final List<TvShow> result = await sut.searchTvShows('   ');

        expect(result, isEmpty);
      });

      test('должен вернуть список сериалов при успешном ответе', () async {
        final Map<String, dynamic> tvShow1 = createTvShowJson();
        final Map<String, dynamic> tvShow2 = createTvShowJson(
          id: 1399,
          name: 'Игра престолов',
          originalName: 'Game of Thrones',
          firstAirDate: '2011-04-17',
          voteAverage: 8.4,
        );

        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'results': <Map<String, dynamic>>[tvShow1, tvShow2],
                'total_results': 2,
                'total_pages': 1,
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<TvShow> result = await sut.searchTvShows('test');

        expect(result, hasLength(2));
        expect(result[0].tmdbId, equals(1396));
        expect(result[0].title, equals('Во все тяжкие'));
        expect(result[1].tmdbId, equals(1399));
        expect(result[1].title, equals('Игра престолов'));
      });

      test('должен выбросить TmdbApiException при DioException', () async {
        when(() => mockDio.get<dynamic>(
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
          () => sut.searchTvShows('test'),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'Invalid API key',
          )),
        );
      });

      test('должен выбросить TmdbApiException при неуспешном статусе', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: null,
              statusCode: 500,
              requestOptions: RequestOptions(),
            ));

        expect(
          () => sut.searchTvShows('test'),
          throwsA(isA<TmdbApiException>()),
        );
      });

      test('должен передать first_air_date_year в queryParameters', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'results': <Map<String, dynamic>>[],
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        await sut.searchTvShows('test', firstAirDateYear: 2023);

        final VerificationResult verification = verify(() => mockDio.get<dynamic>(
              any(),
              queryParameters: captureAny(named: 'queryParameters'),
            ));
        verification.called(1);

        final Map<String, dynamic> params =
            verification.captured.first as Map<String, dynamic>;
        expect(params['first_air_date_year'], equals(2023));
      });

      test('не должен передавать first_air_date_year когда не указан', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'results': <Map<String, dynamic>>[],
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        await sut.searchTvShows('test');

        final VerificationResult verification = verify(() => mockDio.get<dynamic>(
              any(),
              queryParameters: captureAny(named: 'queryParameters'),
            ));
        verification.called(1);

        final Map<String, dynamic> params =
            verification.captured.first as Map<String, dynamic>;
        expect(params.containsKey('first_air_date_year'), isFalse);
      });
    });

    // ----- getTvShow -----

    group('getTvShow', () {
      setUp(() {
        sut.setApiKey(testApiKey);
      });

      test('должен вернуть сериал при успешном ответе', () async {
        final Map<String, dynamic> tvShowJson = createTvShowJson();

        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: tvShowJson,
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final TvShow? result = await sut.getTvShow(1396);

        expect(result, isNotNull);
        expect(result!.tmdbId, equals(1396));
        expect(result.title, equals('Во все тяжкие'));
        expect(result.originalTitle, equals('Breaking Bad'));
        expect(result.firstAirYear, equals(2008));
        expect(result.totalSeasons, equals(5));
        expect(result.totalEpisodes, equals(62));
        expect(result.rating, equals(8.9));
        expect(result.status, equals('Ended'));
      });

      test('должен вернуть null при 404', () async {
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

        final TvShow? result = await sut.getTvShow(999999);

        expect(result, isNull);
      });

      test('должен выбросить TmdbApiException при DioException 500', () async {
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
          () => sut.getTvShow(1396),
          throwsA(isA<TmdbApiException>()),
        );
      });

      test('должен выбросить TmdbApiException при неуспешном статусе', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: null,
              statusCode: 500,
              requestOptions: RequestOptions(),
            ));

        expect(
          () => sut.getTvShow(1396),
          throwsA(isA<TmdbApiException>()),
        );
      });
    });

    // ----- getTvSeasons -----

    group('getTvSeasons', () {
      setUp(() {
        sut.setApiKey(testApiKey);
      });

      test('должен вернуть список сезонов при успешном ответе', () async {
        final Map<String, dynamic> season1 = createSeasonJson();
        final Map<String, dynamic> season2 = createSeasonJson(
          seasonNumber: 2,
          name: 'Сезон 2',
          episodeCount: 13,
          airDate: '2009-03-08',
        );

        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'seasons': <Map<String, dynamic>>[season1, season2],
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<TvSeason> result = await sut.getTvSeasons(1396);

        expect(result, hasLength(2));
        expect(result[0].tmdbShowId, equals(1396));
        expect(result[0].seasonNumber, equals(1));
        expect(result[0].name, equals('Сезон 1'));
        expect(result[0].episodeCount, equals(7));
        expect(result[1].seasonNumber, equals(2));
        expect(result[1].name, equals('Сезон 2'));
        expect(result[1].episodeCount, equals(13));
      });

      test('должен вернуть пустой список если нет сезонов', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'id': 1396,
                'name': 'Test Show',
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<TvSeason> result = await sut.getTvSeasons(1396);

        expect(result, isEmpty);
      });

      test('должен вернуть пустой список при пустом массиве сезонов', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'seasons': <Map<String, dynamic>>[],
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<TvSeason> result = await sut.getTvSeasons(1396);

        expect(result, isEmpty);
      });

      test('должен выбросить TmdbApiException при DioException', () async {
        when(() => mockDio.get<dynamic>(
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
          () => sut.getTvSeasons(1396),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'Invalid API key',
          )),
        );
      });

      test('должен выбросить TmdbApiException при неуспешном статусе', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: null,
              statusCode: 500,
              requestOptions: RequestOptions(),
            ));

        expect(
          () => sut.getTvSeasons(1396),
          throwsA(isA<TmdbApiException>()),
        );
      });
    });

    // ----- getSeasonEpisodes -----

    group('getSeasonEpisodes', () {
      setUp(() {
        sut.setApiKey(testApiKey);
      });

      test('должен вернуть список эпизодов при успешном ответе', () async {
        final Map<String, dynamic> episode1 = createEpisodeJson();
        final Map<String, dynamic> episode2 = createEpisodeJson(
          episodeNumber: 2,
          name: 'Кот в мешке',
          overview: 'Описание второго эпизода',
          airDate: '2008-01-27',
          runtime: 48,
        );

        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'episodes': <Map<String, dynamic>>[episode1, episode2],
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<TvEpisode> result = await sut.getSeasonEpisodes(1396, 1);

        expect(result, hasLength(2));
        expect(result[0].tmdbShowId, equals(1396));
        expect(result[0].seasonNumber, equals(1));
        expect(result[0].episodeNumber, equals(1));
        expect(result[0].name, equals('Пилот'));
        expect(result[0].overview, equals('Описание эпизода'));
        expect(result[0].airDate, equals('2008-01-20'));
        expect(result[0].runtime, equals(45));
        expect(result[0].stillUrl, contains('/9074lJh4G2RBXhyR6F5mGDPXPCF.jpg'));
        expect(result[1].episodeNumber, equals(2));
        expect(result[1].name, equals('Кот в мешке'));
        expect(result[1].runtime, equals(48));
      });

      test('должен вернуть пустой список если нет эпизодов', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'id': 1234,
                'season_number': 1,
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<TvEpisode> result = await sut.getSeasonEpisodes(1396, 1);

        expect(result, isEmpty);
      });

      test('должен вернуть пустой список при пустом массиве', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'episodes': <Map<String, dynamic>>[],
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<TvEpisode> result = await sut.getSeasonEpisodes(1396, 1);

        expect(result, isEmpty);
      });

      test('должен выбросить TmdbApiException при DioException 401', () async {
        when(() => mockDio.get<dynamic>(
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
          () => sut.getSeasonEpisodes(1396, 1),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'Invalid API key',
          )),
        );
      });

      test('должен выбросить TmdbApiException при DioException таймаут', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(),
        ));

        expect(
          () => sut.getSeasonEpisodes(1396, 1),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'Connection timeout',
          )),
        );
      });

      test('должен выбросить TmdbApiException если нет API ключа', () {
        sut.clearApiKey();

        expect(
          () => sut.getSeasonEpisodes(1396, 1),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'API key not set',
          )),
        );
      });
    });

    // ----- getPopularTvShows -----

    group('getPopularTvShows', () {
      setUp(() {
        sut.setApiKey(testApiKey);
      });

      test('должен вернуть список популярных сериалов', () async {
        final Map<String, dynamic> tvShow1 = createTvShowJson();
        final Map<String, dynamic> tvShow2 = createTvShowJson(
          id: 1399,
          name: 'Игра престолов',
        );

        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'results': <Map<String, dynamic>>[tvShow1, tvShow2],
                'total_results': 2,
                'total_pages': 1,
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<TvShow> result = await sut.getPopularTvShows();

        expect(result, hasLength(2));
        expect(result[0].tmdbId, equals(1396));
        expect(result[1].tmdbId, equals(1399));
      });

      test('должен вернуть пустой список при пустых результатах', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'results': <Map<String, dynamic>>[],
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<TvShow> result = await sut.getPopularTvShows();

        expect(result, isEmpty);
      });

      test('должен выбросить TmdbApiException при DioException', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          response: Response<dynamic>(
            statusCode: 429,
            requestOptions: RequestOptions(),
          ),
          requestOptions: RequestOptions(),
        ));

        expect(
          () => sut.getPopularTvShows(),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'Rate limit exceeded. Please try again later',
          )),
        );
      });

      test('должен выбросить TmdbApiException при неуспешном статусе', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: null,
              statusCode: 503,
              requestOptions: RequestOptions(),
            ));

        expect(
          () => sut.getPopularTvShows(),
          throwsA(isA<TmdbApiException>()),
        );
      });
    });

    // ----- multiSearch -----

    group('multiSearch', () {
      setUp(() {
        sut.setApiKey(testApiKey);
      });

      test('должен вернуть пустой список при пустом запросе', () async {
        final List<MultiSearchResult> result = await sut.multiSearch('');

        expect(result, isEmpty);
      });

      test('должен вернуть пустой список при запросе из пробелов', () async {
        final List<MultiSearchResult> result = await sut.multiSearch('   ');

        expect(result, isEmpty);
      });

      test('должен вернуть фильмы и сериалы, отфильтровав person', () async {
        final Map<String, dynamic> movieResult = <String, dynamic>{
          ...createMovieJson(),
          'media_type': 'movie',
        };
        final Map<String, dynamic> tvResult = <String, dynamic>{
          ...createTvShowJson(),
          'media_type': 'tv',
        };
        final Map<String, dynamic> personResult = <String, dynamic>{
          'id': 17419,
          'name': 'Брэд Питт',
          'media_type': 'person',
        };

        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'results': <Map<String, dynamic>>[
                  movieResult,
                  tvResult,
                  personResult,
                ],
                'total_results': 3,
                'total_pages': 1,
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<MultiSearchResult> result = await sut.multiSearch('test');

        expect(result, hasLength(2));

        // Первый результат - фильм
        expect(result[0].mediaType, equals(TmdbMediaType.movie));
        expect(result[0].movie, isNotNull);
        expect(result[0].movie!.tmdbId, equals(550));
        expect(result[0].tvShow, isNull);

        // Второй результат - сериал
        expect(result[1].mediaType, equals(TmdbMediaType.tv));
        expect(result[1].tvShow, isNotNull);
        expect(result[1].tvShow!.tmdbId, equals(1396));
        expect(result[1].movie, isNull);
      });

      test('должен вернуть только фильмы если нет сериалов', () async {
        final Map<String, dynamic> movieResult = <String, dynamic>{
          ...createMovieJson(),
          'media_type': 'movie',
        };

        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'results': <Map<String, dynamic>>[movieResult],
                'total_results': 1,
                'total_pages': 1,
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<MultiSearchResult> result = await sut.multiSearch('fight');

        expect(result, hasLength(1));
        expect(result[0].mediaType, equals(TmdbMediaType.movie));
        expect(result[0].movie, isNotNull);
      });

      test('должен пропустить результаты с неизвестным media_type', () async {
        final Map<String, dynamic> unknownResult = <String, dynamic>{
          'id': 100,
          'name': 'Unknown',
          'media_type': 'collection',
        };

        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'results': <Map<String, dynamic>>[unknownResult],
                'total_results': 1,
                'total_pages': 1,
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<MultiSearchResult> result = await sut.multiSearch('test');

        expect(result, isEmpty);
      });

      test('должен выбросить TmdbApiException при DioException', () async {
        when(() => mockDio.get<dynamic>(
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
          () => sut.multiSearch('test'),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'Invalid API key',
          )),
        );
      });

      test('должен выбросить TmdbApiException при неуспешном статусе', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: null,
              statusCode: 500,
              requestOptions: RequestOptions(),
            ));

        expect(
          () => sut.multiSearch('test'),
          throwsA(isA<TmdbApiException>()),
        );
      });
    });

    // ----- getMovieGenres -----

    group('getMovieGenres', () {
      setUp(() {
        sut.setApiKey(testApiKey);
      });

      test('должен вернуть список жанров фильмов', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'genres': <Map<String, dynamic>>[
                  <String, dynamic>{'id': 28, 'name': 'Боевик'},
                  <String, dynamic>{'id': 12, 'name': 'Приключения'},
                  <String, dynamic>{'id': 18, 'name': 'Драма'},
                ],
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<TmdbGenre> result = await sut.getMovieGenres();

        expect(result, hasLength(3));
        expect(result[0].id, equals(28));
        expect(result[0].name, equals('Боевик'));
        expect(result[1].id, equals(12));
        expect(result[1].name, equals('Приключения'));
        expect(result[2].id, equals(18));
        expect(result[2].name, equals('Драма'));
      });

      test('должен вернуть пустой список при пустых жанрах', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'genres': <Map<String, dynamic>>[],
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<TmdbGenre> result = await sut.getMovieGenres();

        expect(result, isEmpty);
      });

      test('должен выбросить TmdbApiException при DioException', () async {
        when(() => mockDio.get<dynamic>(
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
          () => sut.getMovieGenres(),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'Invalid API key',
          )),
        );
      });

      test('должен выбросить TmdbApiException при неуспешном статусе', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: null,
              statusCode: 500,
              requestOptions: RequestOptions(),
            ));

        expect(
          () => sut.getMovieGenres(),
          throwsA(isA<TmdbApiException>()),
        );
      });
    });

    // ----- getTvGenres -----

    group('getTvGenres', () {
      setUp(() {
        sut.setApiKey(testApiKey);
      });

      test('должен вернуть список жанров сериалов', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'genres': <Map<String, dynamic>>[
                  <String, dynamic>{'id': 10759, 'name': 'Боевик и Приключения'},
                  <String, dynamic>{'id': 18, 'name': 'Драма'},
                  <String, dynamic>{'id': 35, 'name': 'Комедия'},
                ],
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<TmdbGenre> result = await sut.getTvGenres();

        expect(result, hasLength(3));
        expect(result[0].id, equals(10759));
        expect(result[0].name, equals('Боевик и Приключения'));
        expect(result[1].id, equals(18));
        expect(result[1].name, equals('Драма'));
        expect(result[2].id, equals(35));
        expect(result[2].name, equals('Комедия'));
      });

      test('должен вернуть пустой список при пустых жанрах', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: <String, dynamic>{
                'genres': <Map<String, dynamic>>[],
              },
              statusCode: 200,
              requestOptions: RequestOptions(),
            ));

        final List<TmdbGenre> result = await sut.getTvGenres();

        expect(result, isEmpty);
      });

      test('должен выбросить TmdbApiException при DioException', () async {
        when(() => mockDio.get<dynamic>(
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
          () => sut.getTvGenres(),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'Invalid API key',
          )),
        );
      });

      test('должен выбросить TmdbApiException при неуспешном статусе', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer((_) async => Response<dynamic>(
              data: null,
              statusCode: 500,
              requestOptions: RequestOptions(),
            ));

        expect(
          () => sut.getTvGenres(),
          throwsA(isA<TmdbApiException>()),
        );
      });
    });

    // ----- _handleDioException -----

    group('_handleDioException через публичные методы', () {
      setUp(() {
        sut.setApiKey(testApiKey);
      });

      test('должен обработать 404 как Resource not found', () async {
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

        // searchMovies не ловит 404 как getMovie, поэтому должен выбросить
        expect(
          () => sut.searchMovies('test'),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'Resource not found',
          )),
        );
      });

      test('должен включить statusCode в исключение', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          response: Response<dynamic>(
            statusCode: 429,
            requestOptions: RequestOptions(),
          ),
          requestOptions: RequestOptions(),
        ));

        expect(
          () => sut.searchMovies('test'),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.statusCode,
            'statusCode',
            429,
          )),
        );
      });

      test('должен обработать connectionTimeout', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(),
        ));

        expect(
          () => sut.getPopularMovies(),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'Connection timeout',
          )),
        );
      });

      test('должен обработать receiveTimeout', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          type: DioExceptionType.receiveTimeout,
          requestOptions: RequestOptions(),
        ));

        expect(
          () => sut.getPopularTvShows(),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'Connection timeout',
          )),
        );
      });

      test('должен обработать connectionError', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(),
        ));

        expect(
          () => sut.getMovieGenres(),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'No internet connection',
          )),
        );
      });

      test('должен использовать defaultMessage для неизвестных ошибок', () async {
        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenThrow(DioException(
          type: DioExceptionType.unknown,
          requestOptions: RequestOptions(),
        ));

        expect(
          () => sut.searchMovies('test'),
          throwsA(isA<TmdbApiException>().having(
            (TmdbApiException e) => e.message,
            'message',
            'Failed to search movies',
          )),
        );
      });
    });

    // ----- dispose -----

    group('dispose', () {
      test('должен закрыть Dio клиент', () {
        when(() => mockDio.close()).thenReturn(null);

        sut.dispose();

        verify(() => mockDio.close()).called(1);
      });
    });

    // ----- setLanguage -----

    group('setLanguage', () {
      test('должен изменить язык', () {
        expect(sut.language, equals('ru-RU'));

        sut.setLanguage('en-US');

        expect(sut.language, equals('en-US'));
      });

      test('должен использовать новый язык в запросах', () {
        sut.setApiKey(testApiKey);
        sut.setLanguage('en-US');

        when(() => mockDio.get<dynamic>(
              any(),
              queryParameters: any(named: 'queryParameters'),
            )).thenAnswer(
          (_) async => Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: <String, dynamic>{
              'results': <dynamic>[],
              'total_results': 0,
            },
          ),
        );

        sut.searchMovies('test');

        final Map<String, dynamic> captured = verify(
          () => mockDio.get<dynamic>(
            any(),
            queryParameters: captureAny(named: 'queryParameters'),
          ),
        ).captured.first as Map<String, dynamic>;

        expect(captured['language'], equals('en-US'));
      });
    });

    // ----- Конструктор -----

    group('конструктор', () {
      test('должен принимать кастомный language', () {
        final TmdbApi apiWithLang = TmdbApi(dio: mockDio, language: 'en-US');

        expect(apiWithLang.language, equals('en-US'));

        apiWithLang.dispose();
      });

      test('должен использовать ru-RU по умолчанию', () {
        expect(sut.language, equals('ru-RU'));
      });
    });
  });
}
