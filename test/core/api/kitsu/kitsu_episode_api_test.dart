import 'package:core/models/tv_episode.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/kitsu_api.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockDio mockDio;
  late KitsuApi api;

  setUpAll(registerAllFallbacks);

  setUp(() {
    mockDio = MockDio();
    api = KitsuApi(dio: mockDio);
  });

  Map<String, dynamic> episode(int number) => <String, dynamic>{
        'id': '$number',
        'type': 'episodes',
        'attributes': <String, dynamic>{
          'seasonNumber': 1,
          'number': number,
          'canonicalTitle': 'Episode $number',
        },
      };

  Response<dynamic> page(List<Map<String, dynamic>> rows, int count) =>
      Response<dynamic>(
        data: <String, dynamic>{
          'data': rows,
          'meta': <String, dynamic>{'count': count},
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      );

  /// Answers each request from [byOffset], keyed by the `page[offset]` sent.
  void stubPages(Map<int, Response<dynamic>> byOffset) {
    when(() => mockDio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        )).thenAnswer((Invocation inv) async {
      final Map<String, dynamic> qp =
          inv.namedArguments[const Symbol('queryParameters')]
              as Map<String, dynamic>;
      final int offset = (qp['page[offset]'] as int?) ?? 0;
      return byOffset[offset]!;
    });
  }

  group('getAnimeEpisodes', () {
    test('returns the single page when the total fits in one', () async {
      stubPages(<int, Response<dynamic>>{
        0: page(<Map<String, dynamic>>[episode(1), episode(2)], 2),
      });

      final List<TvEpisode> episodes = await api.getAnimeEpisodes(7442);

      expect(episodes, hasLength(2));
      expect(episodes.map((TvEpisode e) => e.episodeNumber), <int>[1, 2]);
      verify(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).called(1);
    });

    test('pages through the rest and orders by season then number', () async {
      stubPages(<int, Response<dynamic>>{
        0: page(<Map<String, dynamic>>[
          for (int i = 1; i <= 20; i++) episode(i),
        ], 45),
        20: page(<Map<String, dynamic>>[
          for (int i = 21; i <= 40; i++) episode(i),
        ], 45),
        40: page(<Map<String, dynamic>>[
          for (int i = 41; i <= 45; i++) episode(i),
        ], 45),
      });

      final List<TvEpisode> episodes = await api.getAnimeEpisodes(7442);

      expect(episodes, hasLength(45));
      expect(
        episodes.map((TvEpisode e) => e.episodeNumber),
        List<int>.generate(45, (int i) => i + 1),
      );
    });

    test('requests 20 per page — Kitsu rejects more', () async {
      stubPages(<int, Response<dynamic>>{
        0: page(<Map<String, dynamic>>[episode(1)], 1),
      });

      await api.getAnimeEpisodes(1);

      final Map<String, dynamic> qp = verify(() => mockDio.get<dynamic>(
            any(),
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),
          )).captured.single as Map<String, dynamic>;
      expect(qp['page[limit]'], 20);
    });

    test('skips episodes without a number instead of failing', () async {
      stubPages(<int, Response<dynamic>>{
        0: page(<Map<String, dynamic>>[
          episode(1),
          <String, dynamic>{
            'id': 'x',
            'type': 'episodes',
            'attributes': <String, dynamic>{'canonicalTitle': 'No number'},
          },
        ], 2),
      });

      expect(await api.getAnimeEpisodes(1), hasLength(1));
    });

    test('falls back to the row count when meta.count is absent', () async {
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response<dynamic>(
            data: <String, dynamic>{
              'data': <Map<String, dynamic>>[episode(1)],
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ));

      expect(await api.getAnimeEpisodes(1), hasLength(1));
    });

    test('crawls by links.next when meta.count is absent', () async {
      Response<dynamic> linkedPage(
        List<Map<String, dynamic>> rows, {
        required bool hasNext,
      }) =>
          Response<dynamic>(
            data: <String, dynamic>{
              'data': rows,
              'links': <String, dynamic>{
                if (hasNext) 'next': 'https://kitsu.io/api/edge/next',
              },
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          );

      stubPages(<int, Response<dynamic>>{
        0: linkedPage(<Map<String, dynamic>>[
          for (int i = 1; i <= 20; i++) episode(i),
        ], hasNext: true),
        20: linkedPage(<Map<String, dynamic>>[
          for (int i = 21; i <= 25; i++) episode(i),
        ], hasNext: false),
      });

      final List<TvEpisode> episodes = await api.getAnimeEpisodes(1);

      expect(episodes, hasLength(25));
      expect(
        episodes.map((TvEpisode e) => e.episodeNumber),
        List<int>.generate(25, (int i) => i + 1),
      );
    });

    test('wraps transport failures in KitsuApiException', () async {
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionError,
      ));

      expect(
        () => api.getAnimeEpisodes(1),
        throwsA(isA<KitsuApiException>()),
      );
    });
  });

  group('getAnimeEpisodeCount', () {
    test('reads meta.count from a one-item request', () async {
      stubPages(<int, Response<dynamic>>{
        0: page(<Map<String, dynamic>>[episode(1)], 1390),
      });

      expect(await api.getAnimeEpisodeCount(7442), 1390);

      final Map<String, dynamic> qp = verify(() => mockDio.get<dynamic>(
            any(),
            queryParameters: captureAny(named: 'queryParameters'),
            options: any(named: 'options'),
          )).captured.single as Map<String, dynamic>;
      expect(qp['page[limit]'], 1);
    });

    test('returns null for an unknown anime', () async {
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response<dynamic>(
          statusCode: 404,
          requestOptions: RequestOptions(path: ''),
        ),
      ));

      expect(await api.getAnimeEpisodeCount(1), isNull);
    });
  });
}
