import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/anilist/anilist_types.dart';
import 'package:tonkatsu_box/core/api/anilist/anilist_user_list_api.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockAniListGraphQLClient client;
  late AniListUserListApi api;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    client = MockAniListGraphQLClient();
    api = AniListUserListApi(client);
  });

  void stubPost(Map<String, dynamic> body) {
    when(() => client.post(
          query: any(named: 'query'),
          variables: any(named: 'variables'),
          errorContext: any(named: 'errorContext'),
        )).thenAnswer((_) async => body);
  }

  Map<String, dynamic> entry(int id, {bool adult = false, bool noMedia = false}) =>
      <String, dynamic>{
        'status': 'CURRENT',
        'score': 80,
        'progress': 3,
        if (!noMedia)
          'media': <String, dynamic>{
            'id': id,
            'title': <String, dynamic>{'romaji': 'T$id'},
            'isAdult': adult,
          },
      };

  Map<String, dynamic> listsBody(List<Map<String, dynamic>> lists) =>
      <String, dynamic>{
        'data': <String, dynamic>{
          'MediaListCollection': <String, dynamic>{'lists': lists},
        },
      };

  Map<String, dynamic> oneList(
    List<Map<String, dynamic>> entries, {
    bool custom = false,
  }) =>
      <String, dynamic>{'isCustomList': custom, 'entries': entries};

  group('argument validation', () {
    test('rejects non anime/manga types', () {
      expect(
        () => api.fetchUserMediaList(userName: 'u', type: MediaType.movie),
        throwsArgumentError,
      );
    });

    test('rejects an empty user name', () {
      expect(
        () => api.fetchUserMediaList(userName: '   ', type: MediaType.anime),
        throwsArgumentError,
      );
    });
  });

  group('GraphQL error translation', () {
    test('"not found" maps to AniListUserNotFoundException', () async {
      stubPost(<String, dynamic>{
        'errors': <dynamic>[<String, dynamic>{'message': 'User not found'}],
      });
      await expectLater(
        api.fetchUserMediaList(userName: 'ghost', type: MediaType.anime),
        throwsA(isA<AniListUserNotFoundException>()),
      );
    });

    test('"private" maps to AniListPrivateProfileException', () async {
      stubPost(<String, dynamic>{
        'errors': <dynamic>[<String, dynamic>{'message': 'This profile is private'}],
      });
      await expectLater(
        api.fetchUserMediaList(userName: 'secret', type: MediaType.anime),
        throwsA(isA<AniListPrivateProfileException>()),
      );
    });

    test('other errors surface as AniListApiException', () async {
      stubPost(<String, dynamic>{
        'errors': <dynamic>[<String, dynamic>{'message': 'rate limited'}],
      });
      await expectLater(
        api.fetchUserMediaList(userName: 'u', type: MediaType.anime),
        throwsA(isA<AniListApiException>()),
      );
    });

    test('a 404 from the client maps to not-found', () async {
      when(() => client.post(
            query: any(named: 'query'),
            variables: any(named: 'variables'),
            errorContext: any(named: 'errorContext'),
          )).thenThrow(const AniListApiException('nope', statusCode: 404));
      await expectLater(
        api.fetchUserMediaList(userName: 'u', type: MediaType.anime),
        throwsA(isA<AniListUserNotFoundException>()),
      );
    });
  });

  group('parsing', () {
    test('null MediaListCollection yields an empty list', () async {
      stubPost(<String, dynamic>{'data': <String, dynamic>{}});
      final List<AniListListEntry> r =
          await api.fetchUserMediaList(userName: 'u', type: MediaType.anime);
      expect(r, isEmpty);
    });

    test('parses entries and reports their media ids', () async {
      stubPost(listsBody(<Map<String, dynamic>>[
        oneList(<Map<String, dynamic>>[entry(1), entry(2)]),
      ]));
      final List<AniListListEntry> r =
          await api.fetchUserMediaList(userName: 'u', type: MediaType.anime);
      expect(r.map((AniListListEntry e) => e.mediaId).toSet(), <int>{1, 2});
    });

    test('deduplicates the same media across lists', () async {
      stubPost(listsBody(<Map<String, dynamic>>[
        oneList(<Map<String, dynamic>>[entry(1)]),
        oneList(<Map<String, dynamic>>[entry(1)]),
      ]));
      final List<AniListListEntry> r =
          await api.fetchUserMediaList(userName: 'u', type: MediaType.anime);
      expect(r.length, 1);
    });

    test('skips custom lists, adult entries and entries without media',
        () async {
      stubPost(listsBody(<Map<String, dynamic>>[
        oneList(<Map<String, dynamic>>[entry(10)], custom: true),
        oneList(<Map<String, dynamic>>[
          entry(1),
          entry(2, adult: true),
          entry(3, noMedia: true),
        ]),
      ]));
      final List<AniListListEntry> r =
          await api.fetchUserMediaList(userName: 'u', type: MediaType.anime);
      expect(r.map((AniListListEntry e) => e.mediaId).toSet(), <int>{1});
    });
  });
}
