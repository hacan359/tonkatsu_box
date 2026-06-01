import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/anilist_api.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(registerAllFallbacks);

  late MockDio mockDio;
  late AniListApi api;

  setUp(() {
    mockDio = MockDio();
    api = AniListApi(dio: mockDio);
  });

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

  Map<String, dynamic> animeMedia({
    int id = 100922,
    bool isAdult = false,
  }) {
    return <String, dynamic>{
      'id': id,
      'isAdult': isAdult,
      'title': <String, dynamic>{
        'romaji': 'Grand Blue',
        'english': 'Grand Blue Dreaming',
        'native': 'ぐらんぶる',
      },
      'episodes': 12,
    };
  }

  Map<String, dynamic> entryJson({
    String status = 'COMPLETED',
    int score = 85,
    int progress = 12,
    int progressVolumes = 0,
    int repeat = 0,
    Map<String, dynamic>? media,
  }) {
    return <String, dynamic>{
      'status': status,
      'score': score,
      'progress': progress,
      'progressVolumes': progressVolumes,
      'repeat': repeat,
      'notes': null,
      'startedAt': <String, dynamic>{'year': 2020, 'month': 1, 'day': 5},
      'completedAt': <String, dynamic>{'year': 2020, 'month': 3, 'day': 1},
      'updatedAt': 1609459200,
      'media': media ?? animeMedia(),
    };
  }

  Map<String, dynamic> collectionResponse({
    required List<Map<String, dynamic>> lists,
  }) {
    return <String, dynamic>{
      'data': <String, dynamic>{
        'MediaListCollection': <String, dynamic>{
          'lists': lists,
        },
      },
    };
  }

  group('AniListApi.fetchUserMediaList', () {
    test('should reject empty username', () async {
      expect(
        () => api.fetchUserMediaList(userName: '   ', type: MediaType.anime),
        throwsArgumentError,
      );
    });

    test('should reject unsupported media types', () async {
      expect(
        () => api.fetchUserMediaList(userName: 'u', type: MediaType.game),
        throwsArgumentError,
      );
    });

    test('should parse entries and populate Anime model', () async {
      when(() => mockDio.post<dynamic>(any(),
              data: any(named: 'data')))
          .thenAnswer((_) async => makeResponse(collectionResponse(
                lists: <Map<String, dynamic>>[
                  <String, dynamic>{
                    'isCustomList': false,
                    'entries': <Map<String, dynamic>>[entryJson()],
                  },
                ],
              )));

      final List<AniListListEntry> entries = await api.fetchUserMediaList(
        userName: 'tester',
        type: MediaType.anime,
      );

      expect(entries, hasLength(1));
      final AniListListEntry e = entries.first;
      expect(e.mediaId, 100922);
      expect(e.mediaType, MediaType.anime);
      expect(e.rawStatus, 'COMPLETED');
      expect(e.scoreRaw100, 85);
      expect(e.progress, 12);
      expect(e.repeat, 0);
      expect(e.anime, isNotNull);
      expect(e.anime!.title, 'Grand Blue');
    });

    test('should treat score 0 as null', () async {
      when(() => mockDio.post<dynamic>(any(),
              data: any(named: 'data')))
          .thenAnswer((_) async => makeResponse(collectionResponse(
                lists: <Map<String, dynamic>>[
                  <String, dynamic>{
                    'isCustomList': false,
                    'entries': <Map<String, dynamic>>[entryJson(score: 0)],
                  },
                ],
              )));

      final List<AniListListEntry> entries = await api.fetchUserMediaList(
        userName: 'u',
        type: MediaType.anime,
      );

      expect(entries.single.scoreRaw100, isNull);
    });

    test('should skip custom lists', () async {
      when(() => mockDio.post<dynamic>(any(),
              data: any(named: 'data')))
          .thenAnswer((_) async => makeResponse(collectionResponse(
                lists: <Map<String, dynamic>>[
                  <String, dynamic>{
                    'isCustomList': true,
                    'entries': <Map<String, dynamic>>[
                      entryJson(media: animeMedia(id: 1)),
                    ],
                  },
                  <String, dynamic>{
                    'isCustomList': false,
                    'entries': <Map<String, dynamic>>[
                      entryJson(media: animeMedia(id: 2)),
                    ],
                  },
                ],
              )));

      final List<AniListListEntry> entries = await api.fetchUserMediaList(
        userName: 'u',
        type: MediaType.anime,
      );

      expect(entries.map((AniListListEntry e) => e.mediaId).toList(), <int>[2]);
    });

    test('should filter isAdult media', () async {
      when(() => mockDio.post<dynamic>(any(),
              data: any(named: 'data')))
          .thenAnswer((_) async => makeResponse(collectionResponse(
                lists: <Map<String, dynamic>>[
                  <String, dynamic>{
                    'isCustomList': false,
                    'entries': <Map<String, dynamic>>[
                      entryJson(media: animeMedia(id: 1, isAdult: true)),
                      entryJson(media: animeMedia(id: 2)),
                    ],
                  },
                ],
              )));

      final List<AniListListEntry> entries = await api.fetchUserMediaList(
        userName: 'u',
        type: MediaType.anime,
      );

      expect(entries.map((AniListListEntry e) => e.mediaId).toList(), <int>[2]);
    });

    test('should deduplicate entries by mediaId across lists', () async {
      when(() => mockDio.post<dynamic>(any(),
              data: any(named: 'data')))
          .thenAnswer((_) async => makeResponse(collectionResponse(
                lists: <Map<String, dynamic>>[
                  <String, dynamic>{
                    'isCustomList': false,
                    'entries': <Map<String, dynamic>>[
                      entryJson(media: animeMedia(id: 7)),
                    ],
                  },
                  <String, dynamic>{
                    'isCustomList': false,
                    'entries': <Map<String, dynamic>>[
                      entryJson(media: animeMedia(id: 7)),
                    ],
                  },
                ],
              )));

      final List<AniListListEntry> entries = await api.fetchUserMediaList(
        userName: 'u',
        type: MediaType.anime,
      );

      expect(entries, hasLength(1));
    });

    test('should throw AniListUserNotFoundException on HTTP 404', () async {
      when(() => mockDio.post<dynamic>(any(),
              data: any(named: 'data')))
          .thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: ''),
          statusCode: 404,
        ),
        type: DioExceptionType.badResponse,
      ));

      expect(
        () => api.fetchUserMediaList(userName: 'ghost', type: MediaType.anime),
        throwsA(isA<AniListUserNotFoundException>()),
      );
    });

    test(
        'should throw AniListUserNotFoundException when GraphQL says not found',
        () async {
      when(() => mockDio.post<dynamic>(any(),
              data: any(named: 'data')))
          .thenAnswer((_) async => makeResponse(<String, dynamic>{
                'errors': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'message': 'User does not exist',
                  },
                ],
              }));

      expect(
        () => api.fetchUserMediaList(userName: 'ghost', type: MediaType.anime),
        throwsA(isA<AniListUserNotFoundException>()),
      );
    });

    test(
        'should throw AniListPrivateProfileException when GraphQL says private',
        () async {
      when(() => mockDio.post<dynamic>(any(),
              data: any(named: 'data')))
          .thenAnswer((_) async => makeResponse(<String, dynamic>{
                'errors': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'message': 'This user is private',
                  },
                ],
              }));

      expect(
        () => api.fetchUserMediaList(userName: 'tester', type: MediaType.anime),
        throwsA(isA<AniListPrivateProfileException>()),
      );
    });

    test('should return empty list when MediaListCollection is null',
        () async {
      when(() => mockDio.post<dynamic>(any(),
              data: any(named: 'data')))
          .thenAnswer((_) async => makeResponse(<String, dynamic>{
                'data': <String, dynamic>{'MediaListCollection': null},
              }));

      final List<AniListListEntry> entries = await api.fetchUserMediaList(
        userName: 'u',
        type: MediaType.anime,
      );

      expect(entries, isEmpty);
    });

    test('should parse partial fuzzy dates (year only)', () async {
      final Map<String, dynamic> json = entryJson();
      json['startedAt'] = <String, dynamic>{
        'year': 2018,
        'month': null,
        'day': null,
      };
      json['completedAt'] = null;
      when(() => mockDio.post<dynamic>(any(),
              data: any(named: 'data')))
          .thenAnswer((_) async => makeResponse(collectionResponse(
                lists: <Map<String, dynamic>>[
                  <String, dynamic>{
                    'isCustomList': false,
                    'entries': <Map<String, dynamic>>[json],
                  },
                ],
              )));

      final List<AniListListEntry> entries = await api.fetchUserMediaList(
        userName: 'u',
        type: MediaType.anime,
      );

      expect(entries.single.startedAt, DateTime.utc(2018, 1, 1));
      expect(entries.single.completedAt, isNull);
    });
  });
}
