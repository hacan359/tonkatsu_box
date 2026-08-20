import 'package:core/api/podcast_index_signature.dart';
import 'package:core/models/audio_item.dart';
import 'package:core/models/audio_kind.dart';
import 'package:core/models/audio_track.dart';
import 'package:core/models/data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/podcast_index/podcast_index_http_client.dart';
import 'package:tonkatsu_box/core/api/podcast_index_api.dart';

import '../../helpers/test_helpers.dart';

DioException _statusError(int status) {
  final RequestOptions options = RequestOptions(path: 'search/byterm');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: status,
    ),
  );
}

Response<dynamic> _okResponse(Map<String, dynamic> data) =>
    Response<dynamic>(
      requestOptions: RequestOptions(path: 'search/byterm'),
      statusCode: 200,
      data: data,
    );

Map<String, dynamic> _feedJson({int id = 197123}) => <String, dynamic>{
      'id': id,
      'podcastGuid': '17457c36-46b7-5d1a-825b-0860515bea7d',
      'title': 'Radiolab',
      'author': 'WNYC Studios',
      'description': '<p>Radiolab is on a curiosity bender.</p>',
      'language': 'en-us',
      'categories': <String, dynamic>{'67': 'Science', '28': 'History'},
      'episodeCount': 665,
      'artwork': 'https://example.com/art.jpg',
    };

Map<String, dynamic> _episodeJson({int id = 58680086814}) =>
    <String, dynamic>{
      'id': id,
      'guid': '51c2832f-b830-4368-868f-6a87a987f516',
      'title': 'Red Herring',
      'datePublished': 1786111200,
      'duration': 2164,
      'season': 0,
      'episode': 706,
    };

void main() {
  group('PodcastIndexAuthInterceptor', () {
    test('signature is sha1(key + secret + ts) in lowercase hex', () {
      // printf 'ab99' | sha1sum
      expect(
        podcastIndexSignature('a', 'b', 99),
        'a5f73381e970929586a0f142775a16617c57b985',
      );
    });

    test('signs requests with the three auth headers', () async {
      final PodcastIndexAuthInterceptor interceptor =
          PodcastIndexAuthInterceptor(
        now: () => DateTime.fromMillisecondsSinceEpoch(99 * 1000),
      )..setCredentials('a', 'b');
      final RequestOptions options = RequestOptions(path: 'search/byterm');

      interceptor.onRequest(options, RequestInterceptorHandler());

      expect(options.headers['X-Auth-Date'], '99');
      expect(options.headers['X-Auth-Key'], 'a');
      expect(
        options.headers['Authorization'],
        'a5f73381e970929586a0f142775a16617c57b985',
      );
    });

    test('leaves requests unsigned without credentials', () {
      final PodcastIndexAuthInterceptor interceptor =
          PodcastIndexAuthInterceptor();
      final RequestOptions options = RequestOptions(path: 'search/byterm');

      interceptor.onRequest(options, RequestInterceptorHandler());

      expect(options.headers.containsKey('Authorization'), isFalse);
      expect(options.headers.containsKey('X-Auth-Key'), isFalse);
    });

    test('clearCredentials drops the pair', () {
      final PodcastIndexAuthInterceptor interceptor =
          PodcastIndexAuthInterceptor()..setCredentials('a', 'b');
      expect(interceptor.hasCredentials, isTrue);
      interceptor.clearCredentials();
      expect(interceptor.hasCredentials, isFalse);
    });
  });

  group('PodcastIndexHttpClient', () {
    test('401 maps to a keys/clock message', () {
      final MockDio dio = MockDio();
      when(() => dio.interceptors).thenReturn(Interceptors());
      final PodcastIndexHttpClient client = PodcastIndexHttpClient(dio: dio);

      final PodcastIndexApiException e =
          client.handleDioException(_statusError(401), 'fallback');

      expect(e.statusCode, 401);
      expect(e.message, contains('signature'));
      expect(e.message, contains('clock'));
    });

    test('timeouts and connection errors keep their own messages', () {
      final MockDio dio = MockDio();
      when(() => dio.interceptors).thenReturn(Interceptors());
      final PodcastIndexHttpClient client = PodcastIndexHttpClient(dio: dio);

      final PodcastIndexApiException timeout = client.handleDioException(
        DioException(
          requestOptions: RequestOptions(path: 'x'),
          type: DioExceptionType.connectionTimeout,
        ),
        'fallback',
      );
      expect(timeout.message, 'Connection timeout');

      final PodcastIndexApiException offline = client.handleDioException(
        DioException(
          requestOptions: RequestOptions(path: 'x'),
          type: DioExceptionType.connectionError,
        ),
        'fallback',
      );
      expect(offline.message, 'No internet connection');
    });
  });

  group('PodcastIndexApi', () {
    late MockDio dio;
    late PodcastIndexApi api;

    setUp(() {
      dio = MockDio();
      when(() => dio.interceptors).thenReturn(Interceptors());
      api = PodcastIndexApi(dio: dio);
    });

    group('search', () {
      test('parses feeds into podcast-kind audio items', () async {
        when(() => dio.get<dynamic>(any(),
                queryParameters: any(named: 'queryParameters')))
            .thenAnswer((_) async => _okResponse(<String, dynamic>{
                  'feeds': <dynamic>[_feedJson()],
                  'count': 1,
                }));

        final List<AudioItem> feeds = await api.search('radiolab');

        expect(feeds, hasLength(1));
        final AudioItem podcast = feeds.first;
        expect(podcast.id, 197123);
        expect(podcast.kind, AudioKind.podcast);
        expect(podcast.source, DataSource.podcastIndex);
        expect(podcast.nativeId, '17457c36-46b7-5d1a-825b-0860515bea7d');
        expect(podcast.artists, <String>['WNYC Studios']);
        expect(podcast.description, 'Radiolab is on a curiosity bender.');
        expect(podcast.genres, containsAll(<String>['Science', 'History']));
        expect(podcast.trackCount, 665);
        expect(podcast.coverUrl, 'https://example.com/art.jpg');
      });

      test('wraps transport failures in PodcastIndexApiException', () async {
        when(() => dio.get<dynamic>(any(),
                queryParameters: any(named: 'queryParameters')))
            .thenThrow(_statusError(401));

        expect(
          () => api.search('radiolab'),
          throwsA(isA<PodcastIndexApiException>()),
        );
      });
    });

    group('getEpisodes', () {
      test('maps the episode id onto position and orders survive', () async {
        when(() => dio.get<dynamic>(any(),
                queryParameters: any(named: 'queryParameters')))
            .thenAnswer((_) async => _okResponse(<String, dynamic>{
                  'items': <dynamic>[
                    _episodeJson(),
                    _episodeJson(id: 0), // no id — dropped
                  ],
                }));

        final List<AudioTrack> episodes = await api.getEpisodes(197123);

        expect(episodes, hasLength(1));
        final AudioTrack episode = episodes.first;
        expect(episode.audioId, 197123);
        expect(episode.discNumber, 0);
        expect(episode.position, 58680086814);
        expect(episode.nativeId, '51c2832f-b830-4368-868f-6a87a987f516');
        expect(episode.lengthMs, 2164 * 1000);
        expect(episode.datePublished, 1786111200);
        expect(episode.source, DataSource.podcastIndex);
      });

      test('passes since through to the query', () async {
        Map<String, dynamic>? captured;
        when(() => dio.get<dynamic>(any(),
                queryParameters: any(named: 'queryParameters')))
            .thenAnswer((Invocation invocation) async {
          captured = invocation.namedArguments[#queryParameters]
              as Map<String, dynamic>?;
          return _okResponse(<String, dynamic>{'items': <dynamic>[]});
        });

        await api.getEpisodes(197123, since: 1785000000);

        expect(captured?['since'], 1785000000);
        expect(captured?['id'], 197123);
      });
    });

    group('getPodcast', () {
      test('returns null when the feed is missing', () async {
        // A missing feed answers with an empty list under "feed".
        when(() => dio.get<dynamic>(any(),
                queryParameters: any(named: 'queryParameters')))
            .thenAnswer((_) async => _okResponse(<String, dynamic>{
                  'feed': <dynamic>[],
                }));

        expect(await api.getPodcast(1), isNull);
      });

      test('parses a present feed', () async {
        when(() => dio.get<dynamic>(any(),
                queryParameters: any(named: 'queryParameters')))
            .thenAnswer((_) async => _okResponse(<String, dynamic>{
                  'feed': _feedJson(),
                }));

        final AudioItem? podcast = await api.getPodcast(197123);
        expect(podcast?.title, 'Radiolab');
        expect(podcast?.kind, AudioKind.podcast);
      });
    });

    group('getTrending', () {
      test('passes lang and category filters', () async {
        Map<String, dynamic>? captured;
        when(() => dio.get<dynamic>(any(),
                queryParameters: any(named: 'queryParameters')))
            .thenAnswer((Invocation invocation) async {
          captured = invocation.namedArguments[#queryParameters]
              as Map<String, dynamic>?;
          return _okResponse(<String, dynamic>{'feeds': <dynamic>[]});
        });

        await api.getTrending(lang: 'ru,en', category: 'True Crime');

        expect(captured?['lang'], 'ru,en');
        expect(captured?['cat'], 'True Crime');
      });
    });
  });
}
