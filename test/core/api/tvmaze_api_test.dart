import 'package:core/models/data_source.dart';
import 'package:core/models/tv_episode.dart';
import 'package:core/models/tv_season.dart';
import 'package:core/models/tv_show.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/tvmaze_api.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late MockDio mockDio;
  late TvMazeApi api;

  setUpAll(registerAllFallbacks);

  setUp(() {
    mockDio = MockDio();
    api = TvMazeApi(dio: mockDio);
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
        )).thenAnswer((_) async => response);
  }

  void stubError() {
    when(() => mockDio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        )).thenThrow(DioException(requestOptions: RequestOptions(path: '')));
  }

  group('searchShows', () {
    test('parses the {score, show} envelope', () async {
      stubGet(makeResponse(<Map<String, dynamic>>[
        <String, dynamic>{
          'score': 1.1,
          'show': <String, dynamic>{'id': 169, 'name': 'Breaking Bad'},
        },
      ]));

      final List<TvShow> shows = await api.searchShows('breaking');
      expect(shows, hasLength(1));
      expect(shows.first.tmdbId, 169);
      expect(shows.first.source, DataSource.tvmaze);
    });

    test('skips rows without a show object', () async {
      stubGet(makeResponse(<Map<String, dynamic>>[
        <String, dynamic>{'score': 1.1},
        <String, dynamic>{
          'show': <String, dynamic>{'id': 1, 'name': 'Ok'},
        },
      ]));

      expect(await api.searchShows('x'), hasLength(1));
    });

    test('throws TvMazeApiException on a Dio error', () async {
      stubError();
      expect(api.searchShows('x'), throwsA(isA<TvMazeApiException>()));
    });
  });

  group('getShow', () {
    test('parses a single show', () async {
      stubGet(makeResponse(<String, dynamic>{'id': 169, 'name': 'BB'}));
      final TvShow? show = await api.getShow(169);
      expect(show?.tmdbId, 169);
    });

    test('returns null when payload is not a map', () async {
      stubGet(makeResponse(<dynamic>[]));
      expect(await api.getShow(169), isNull);
    });

    test('returns null for a 404 instead of throwing', () async {
      when(() => mockDio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response<dynamic>(
          statusCode: 404,
          requestOptions: RequestOptions(path: ''),
        ),
      ));
      expect(await api.getShow(169), isNull);
    });

    test('throws TvMazeApiException on a non-404 Dio error', () async {
      stubError();
      expect(api.getShow(169), throwsA(isA<TvMazeApiException>()));
    });
  });

  group('getSeasons', () {
    test('parses the season list', () async {
      stubGet(makeResponse(<Map<String, dynamic>>[
        <String, dynamic>{'number': 1, 'episodeOrder': 7},
        <String, dynamic>{'number': 2, 'episodeOrder': 13},
      ]));

      final List<TvSeason> seasons = await api.getSeasons(169);
      expect(seasons, hasLength(2));
      expect(seasons.first.tmdbShowId, 169);
      expect(seasons[1].episodeCount, 13);
    });
  });

  group('getAllEpisodes', () {
    test('parses episodes and drops specials without a number', () async {
      stubGet(makeResponse(<Map<String, dynamic>>[
        <String, dynamic>{'season': 1, 'number': 1, 'name': 'Pilot'},
        <String, dynamic>{'season': 1, 'number': null, 'name': 'Special'},
      ]));

      final List<TvEpisode> episodes = await api.getAllEpisodes(169);
      expect(episodes, hasLength(1));
      expect(episodes.first.episodeNumber, 1);
    });
  });
}
