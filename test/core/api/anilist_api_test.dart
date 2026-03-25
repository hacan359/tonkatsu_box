// Тесты для клиента AniList API

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xerabora/core/api/anilist_api.dart';
import 'package:xerabora/shared/models/anime.dart';
import 'package:xerabora/shared/models/manga.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late MockDio mockDio;
  late AniListApi api;

  setUp(() {
    mockDio = MockDio();
    api = AniListApi(dio: mockDio);
  });

  group('AniListApiException', () {
    test('должен содержать message и statusCode', () {
      const AniListApiException exception =
          AniListApiException('test', statusCode: 429);
      expect(exception.message, 'test');
      expect(exception.statusCode, 429);
    });

    test('toString должен форматировать сообщение', () {
      const AniListApiException exception =
          AniListApiException('error', statusCode: 500);
      expect(exception.toString(),
          'AniListApiException: error (status: 500)');
    });
  });

  group('AniListApi', () {
    Response<dynamic> makeResponse(
      Map<String, dynamic> data, {
      int statusCode = 200,
    }) {
      return Response<dynamic>(
        data: data,
        statusCode: statusCode,
        requestOptions: RequestOptions(path: ''),
      );
    }

    Map<String, dynamic> mangaJson({
      int id = 30013,
      String title = 'One Punch-Man',
    }) {
      return <String, dynamic>{
        'id': id,
        'title': <String, dynamic>{
          'romaji': title,
          'english': 'One-Punch Man',
          'native': 'ワンパンマン',
        },
        'averageScore': 84,
        'popularity': 120000,
        'status': 'RELEASING',
        'format': 'MANGA',
      };
    }

    Map<String, dynamic> pageResponse({
      List<Map<String, dynamic>>? media,
      bool hasNextPage = false,
      int lastPage = 1,
      int total = 1,
    }) {
      return <String, dynamic>{
        'data': <String, dynamic>{
          'Page': <String, dynamic>{
            'pageInfo': <String, dynamic>{
              'total': total,
              'currentPage': 1,
              'lastPage': lastPage,
              'hasNextPage': hasNextPage,
            },
            'media': media ?? <Map<String, dynamic>>[mangaJson()],
          },
        },
      };
    }

    group('searchManga', () {
      test('должен вернуть пустой список для пустого запроса', () async {
        final (List<Manga> results, bool hasMore, int totalPages) =
            await api.searchManga(query: '');
        expect(results, isEmpty);
        expect(hasMore, isFalse);
        expect(totalPages, 0);
      });

      test('должен вернуть пустой список для запроса из пробелов', () async {
        final (List<Manga> results, bool hasMore, int totalPages) =
            await api.searchManga(query: '   ');
        expect(results, isEmpty);
        expect(hasMore, isFalse);
        expect(totalPages, 0);
      });

      test('должен отправить POST и вернуть результаты', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => makeResponse(pageResponse(hasNextPage: true)),
        );

        final (List<Manga> results, bool hasMore, int _) =
            await api.searchManga(query: 'one punch');

        expect(results, hasLength(1));
        expect(results.first.id, 30013);
        expect(hasMore, isTrue);

        verify(() => mockDio.post<dynamic>(
              'https://graphql.anilist.co',
              data: any(named: 'data'),
            )).called(1);
      });

      test('должен выбросить AniListApiException при DioException', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: ''),
        ));

        expect(
          () => api.searchManga(query: 'test'),
          throwsA(isA<AniListApiException>()),
        );
      });

      test('должен обработать rate limit (429)', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            statusCode: 429,
            requestOptions: RequestOptions(path: ''),
          ),
          requestOptions: RequestOptions(path: ''),
        ));

        try {
          await api.searchManga(query: 'test');
          fail('Should throw');
        } on AniListApiException catch (e) {
          expect(e.message, contains('Rate limit'));
          expect(e.statusCode, 429);
        }
      });
    });

    group('browseManga', () {
      test('должен вернуть результаты с totalPages', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => makeResponse(
            pageResponse(lastPage: 3, total: 60),
          ),
        );

        final (
          List<Manga> results,
          bool hasMore,
          int totalPages,
        ) = await api.browseManga();

        expect(results, hasLength(1));
        expect(hasMore, isFalse);
        expect(totalPages, 3);
      });

      test('должен передать genre в переменные', () async {
        Map<String, dynamic>? capturedData;
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((Invocation inv) async {
          capturedData = inv.namedArguments[const Symbol('data')]
              as Map<String, dynamic>?;
          return makeResponse(
            pageResponse(media: <Map<String, dynamic>>[]),
          );
        });

        await api.browseManga(genre: 'Action');

        expect(capturedData, isNotNull);
        final Map<String, dynamic> variables =
            capturedData!['variables'] as Map<String, dynamic>;
        expect(variables['genre'], 'Action');
      });

      test('должен передать format в переменные', () async {
        Map<String, dynamic>? capturedData;
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((Invocation inv) async {
          capturedData = inv.namedArguments[const Symbol('data')]
              as Map<String, dynamic>?;
          return makeResponse(
            pageResponse(media: <Map<String, dynamic>>[]),
          );
        });

        await api.browseManga(format: 'MANHWA');

        expect(capturedData, isNotNull);
        final Map<String, dynamic> variables =
            capturedData!['variables'] as Map<String, dynamic>;
        expect(variables['format'], 'MANHWA');
      });

      test('должен обработать ошибку ответа', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => makeResponse(
            <String, dynamic>{},
            statusCode: 500,
          ),
        );

        expect(
          () => api.browseManga(),
          throwsA(isA<AniListApiException>()),
        );
      });

      test('должен обработать GraphQL errors в ответе', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => makeResponse(<String, dynamic>{
            'errors': <dynamic>[
              <String, dynamic>{'message': 'Validation error'},
            ],
          }),
        );

        final (List<Manga> results, bool hasMore, int totalPages) =
            await api.browseManga();

        expect(results, isEmpty);
        expect(hasMore, isFalse);
        expect(totalPages, 0);
      });

      test('должен обработать null Page в ответе', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => makeResponse(<String, dynamic>{
            'data': <String, dynamic>{},
          }),
        );

        final (List<Manga> results, bool hasMore, int totalPages) =
            await api.browseManga();

        expect(results, isEmpty);
        expect(hasMore, isFalse);
        expect(totalPages, 0);
      });
    });

    group('getMangaById', () {
      test('должен вернуть мангу по ID', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => makeResponse(<String, dynamic>{
            'data': <String, dynamic>{
              'Media': mangaJson(id: 30013),
            },
          }),
        );

        final Manga? manga = await api.getMangaById(30013);

        expect(manga, isNotNull);
        expect(manga!.id, 30013);
      });

      test('должен вернуть null для null Media', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => makeResponse(<String, dynamic>{
            'data': <String, dynamic>{
              'Media': null,
            },
          }),
        );

        final Manga? manga = await api.getMangaById(999999);

        expect(manga, isNull);
      });

      test('должен обработать ошибку ответа', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => makeResponse(
            <String, dynamic>{},
            statusCode: 404,
          ),
        );

        expect(
          () => api.getMangaById(1),
          throwsA(isA<AniListApiException>()),
        );
      });

      test('должен обработать GraphQL errors', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => makeResponse(<String, dynamic>{
            'errors': <dynamic>[
              <String, dynamic>{'message': 'Not found'},
            ],
          }),
        );

        final Manga? manga = await api.getMangaById(999999);

        expect(manga, isNull);
      });

      test('должен обработать DioException connection error', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(path: ''),
        ));

        try {
          await api.getMangaById(1);
          fail('Should throw');
        } on AniListApiException catch (e) {
          expect(e.message, contains('internet'));
        }
      });
    });

    group('getMangaByIds', () {
      test('должен вернуть пустой список для пустого массива', () async {
        final List<Manga> results = await api.getMangaByIds(<int>[]);
        expect(results, isEmpty);
      });

      test('должен загрузить несколько манг', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => makeResponse(<String, dynamic>{
            'data': <String, dynamic>{
              'Page': <String, dynamic>{
                'media': <dynamic>[
                  mangaJson(id: 1, title: 'Naruto'),
                  mangaJson(id: 2, title: 'Bleach'),
                ],
              },
            },
          }),
        );

        final List<Manga> results =
            await api.getMangaByIds(<int>[1, 2]);

        expect(results, hasLength(2));
      });

      test('должен обработать DioException', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(path: ''),
        ));

        try {
          await api.getMangaByIds(<int>[1]);
          fail('Should throw');
        } on AniListApiException catch (e) {
          expect(e.message, contains('internet'));
        }
      });

      test('должен обработать ошибку ответа', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => makeResponse(
            <String, dynamic>{},
            statusCode: 500,
          ),
        );

        expect(
          () => api.getMangaByIds(<int>[1]),
          throwsA(isA<AniListApiException>()),
        );
      });

      test('должен обработать null Page в ответе', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => makeResponse(<String, dynamic>{
            'data': <String, dynamic>{},
          }),
        );

        final List<Manga> results =
            await api.getMangaByIds(<int>[1]);

        expect(results, isEmpty);
      });

      test('должен обработать GraphQL errors', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => makeResponse(<String, dynamic>{
            'errors': <dynamic>[
              <String, dynamic>{'message': 'Error'},
            ],
          }),
        );

        final List<Manga> results =
            await api.getMangaByIds(<int>[1]);

        expect(results, isEmpty);
      });
    });

    // === Anime methods ===

    Map<String, dynamic> animeJson({
      int id = 1,
      String title = 'Cowboy Bebop',
    }) {
      return <String, dynamic>{
        'id': id,
        'title': <String, dynamic>{
          'romaji': title,
          'english': title,
        },
        'averageScore': 86,
        'status': 'FINISHED',
        'episodes': 26,
        'format': 'TV',
        'season': 'SPRING',
        'seasonYear': 1998,
      };
    }

    Map<String, dynamic> animePageResponse({
      List<Map<String, dynamic>>? media,
      bool hasNextPage = false,
      int lastPage = 1,
    }) {
      return <String, dynamic>{
        'data': <String, dynamic>{
          'Page': <String, dynamic>{
            'pageInfo': <String, dynamic>{
              'total': 1,
              'currentPage': 1,
              'lastPage': lastPage,
              'hasNextPage': hasNextPage,
            },
            'media': media ?? <Map<String, dynamic>>[animeJson()],
          },
        },
      };
    }

    group('browseAnime', () {
      test('должен вернуть результаты', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => makeResponse(
            animePageResponse(hasNextPage: true, lastPage: 5),
          ),
        );

        final (List<Anime> results, bool hasMore, int totalPages) =
            await api.browseAnime();

        expect(results, hasLength(1));
        expect(results.first.id, 1);
        expect(results.first.title, 'Cowboy Bebop');
        expect(hasMore, isTrue);
        expect(totalPages, 5);
      });

      test('должен передать query в переменные', () async {
        Map<String, dynamic>? capturedData;
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((Invocation inv) async {
          capturedData = inv.namedArguments[const Symbol('data')]
              as Map<String, dynamic>?;
          return makeResponse(
            animePageResponse(media: <Map<String, dynamic>>[]),
          );
        });

        await api.browseAnime(query: 'bebop');

        final Map<String, dynamic> variables =
            capturedData!['variables'] as Map<String, dynamic>;
        expect(variables['search'], 'bebop');
      });

      test('должен передать genre и status в переменные', () async {
        Map<String, dynamic>? capturedData;
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer((Invocation inv) async {
          capturedData = inv.namedArguments[const Symbol('data')]
              as Map<String, dynamic>?;
          return makeResponse(
            animePageResponse(media: <Map<String, dynamic>>[]),
          );
        });

        await api.browseAnime(genre: 'Action', status: 'RELEASING');

        final Map<String, dynamic> variables =
            capturedData!['variables'] as Map<String, dynamic>;
        expect(variables['genre'], 'Action');
        expect(variables['status'], 'RELEASING');
      });

      test('должен выбросить AniListApiException при DioException', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: ''),
        ));

        expect(
          () => api.browseAnime(),
          throwsA(isA<AniListApiException>()),
        );
      });

      test('должен обработать null data в ответе', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => makeResponse(<String, dynamic>{
            'data': <String, dynamic>{},
          }),
        );

        final (List<Anime> results, bool hasMore, int totalPages) =
            await api.browseAnime();

        expect(results, isEmpty);
        expect(hasMore, isFalse);
        expect(totalPages, 0);
      });
    });

    group('getAnimeById', () {
      test('должен вернуть аниме по ID', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => makeResponse(<String, dynamic>{
            'data': <String, dynamic>{
              'Media': animeJson(id: 1),
            },
          }),
        );

        final Anime? anime = await api.getAnimeById(1);

        expect(anime, isNotNull);
        expect(anime!.id, 1);
      });

      test('должен вернуть null для null Media', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => makeResponse(<String, dynamic>{
            'data': <String, dynamic>{
              'Media': null,
            },
          }),
        );

        final Anime? anime = await api.getAnimeById(999999);
        expect(anime, isNull);
      });

      test('должен обработать ошибку ответа', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => makeResponse(
            <String, dynamic>{},
            statusCode: 404,
          ),
        );

        expect(
          () => api.getAnimeById(1),
          throwsA(isA<AniListApiException>()),
        );
      });
    });

    group('getAnimeByIds', () {
      test('должен вернуть пустой список для пустого массива', () async {
        final List<Anime> results = await api.getAnimeByIds(<int>[]);
        expect(results, isEmpty);
      });

      test('должен загрузить несколько аниме', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => makeResponse(<String, dynamic>{
            'data': <String, dynamic>{
              'Page': <String, dynamic>{
                'media': <dynamic>[
                  animeJson(id: 1, title: 'Bebop'),
                  animeJson(id: 2, title: 'Eva'),
                ],
              },
            },
          }),
        );

        final List<Anime> results =
            await api.getAnimeByIds(<int>[1, 2]);
        expect(results, hasLength(2));
      });

      test('должен обработать DioException', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenThrow(DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(path: ''),
        ));

        try {
          await api.getAnimeByIds(<int>[1]);
          fail('Should throw');
        } on AniListApiException catch (e) {
          expect(e.message, contains('internet'));
        }
      });

      test('должен обработать null Page в ответе', () async {
        when(() => mockDio.post<dynamic>(
              any(),
              data: any(named: 'data'),
            )).thenAnswer(
          (_) async => makeResponse(<String, dynamic>{
            'data': <String, dynamic>{},
          }),
        );

        final List<Anime> results =
            await api.getAnimeByIds(<int>[1]);
        expect(results, isEmpty);
      });
    });

    group('dispose', () {
      test('должен закрыть Dio клиент', () {
        when(() => mockDio.close()).thenReturn(null);
        api.dispose();
        verify(() => mockDio.close()).called(1);
      });
    });
  });
}
