import 'package:core/models/anime.dart';
import 'package:core/models/manga.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/kitsu_api.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late MockDio mockDio;
  late KitsuApi api;

  setUpAll(registerAllFallbacks);

  setUp(() {
    mockDio = MockDio();
    api = KitsuApi(dio: mockDio);
  });

  Response<dynamic> makeResponse(dynamic data) => Response<dynamic>(
        data: data,
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      );

  void stubGet(Response<dynamic> response) {
    when(() => mockDio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => response);
  }

  Map<String, dynamic> resource(String id, String type) => <String, dynamic>{
        'id': id,
        'type': type,
        'attributes': <String, dynamic>{
          'canonicalTitle': 'Title',
          'titles': <String, dynamic>{'en': 'Title'},
        },
      };

  group('browseManga', () {
    test('parses rows and derives pagination from meta / links', () async {
      stubGet(makeResponse(<String, dynamic>{
        'data': <Map<String, dynamic>>[
          resource('1', 'manga'),
          resource('2', 'manga'),
        ],
        'meta': <String, dynamic>{'count': 40},
        'links': <String, dynamic>{'next': 'https://kitsu.io/...?page=2'},
      }));

      final (List<Manga> mangas, bool hasMore, int totalPages) =
          await api.browseManga(query: 'vinland');

      expect(mangas, hasLength(2));
      expect(hasMore, isTrue);
      expect(totalPages, 2);
    });

    test('skips malformed rows', () async {
      stubGet(makeResponse(<String, dynamic>{
        'data': <dynamic>[
          resource('1', 'manga'),
          <String, dynamic>{'attributes': <String, dynamic>{}}, // no id
          'not a map',
        ],
      }));

      final (List<Manga> mangas, bool _, int _) = await api.browseManga();
      expect(mangas, hasLength(1));
    });

    test('maps a timeout to KitsuApiException', () async {
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.receiveTimeout,
      ));

      await expectLater(
        api.browseManga(query: 'x'),
        throwsA(isA<KitsuApiException>()),
      );
    });
  });

  group('browseAnime', () {
    test('parses anime rows (groundwork API)', () async {
      stubGet(makeResponse(<String, dynamic>{
        'data': <Map<String, dynamic>>[resource('7', 'anime')],
        'meta': <String, dynamic>{'count': 1},
      }));

      final (List<Anime> anime, bool hasMore, int _) =
          await api.browseAnime(query: 'frieren');

      expect(anime, hasLength(1));
      expect(anime.first.id, 7);
      expect(hasMore, isFalse);
    });
  });

  group('getMangaById', () {
    test('returns the parsed resource', () async {
      stubGet(makeResponse(<String, dynamic>{'data': resource('9', 'manga')}));
      final Manga? m = await api.getMangaById(9);
      expect(m?.id, 9);
    });

    test('returns null when data is not a map', () async {
      stubGet(makeResponse(<String, dynamic>{'data': null}));
      expect(await api.getMangaById(9), isNull);
    });
  });
}
