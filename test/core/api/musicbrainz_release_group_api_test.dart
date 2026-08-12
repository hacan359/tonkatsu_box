import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/musicbrainz/musicbrainz_http_client.dart';
import 'package:tonkatsu_box/core/api/musicbrainz/musicbrainz_release_group_api.dart';
import 'package:tonkatsu_box/core/api/musicbrainz/musicbrainz_types.dart';

class _MockClient extends Mock implements MusicBrainzHttpClient {}

Response<dynamic> _releasesResponse(List<Map<String, dynamic>> releases) =>
    Response<dynamic>(
      requestOptions: RequestOptions(path: 'release'),
      statusCode: 200,
      data: <String, dynamic>{'releases': releases},
    );

Map<String, dynamic> _release(String mbid, {String? status, String? date}) =>
    <String, dynamic>{
      'id': mbid,
      'title': 'T $mbid',
      'status': ?status,
      'date': ?date,
    };

void main() {
  group('MusicBrainzReleaseGroupApi.getReleasesOrAny', () {
    late _MockClient client;
    late MusicBrainzReleaseGroupApi api;

    setUp(() {
      client = _MockClient();
      api = MusicBrainzReleaseGroupApi(client);
    });

    bool isOfficialQuery(Invocation inv) {
      final Map<String, dynamic>? params =
          inv.namedArguments[#queryParameters] as Map<String, dynamic>?;
      return params?['status'] == 'official';
    }

    test('should not fetch the fallback when official releases exist',
        () async {
      when(() => client.get(any(),
          queryParameters: any(named: 'queryParameters'))).thenAnswer(
        (Invocation inv) async => _releasesResponse(<Map<String, dynamic>>[
          if (isOfficialQuery(inv)) _release('off-1', date: '1973-03-01'),
        ]),
      );

      final List<MusicBrainzRelease> releases =
          await api.getReleasesOrAny('group-1');

      expect(releases.map((MusicBrainzRelease r) => r.mbid), <String>['off-1']);
      verify(() => client.get(any(),
          queryParameters: any(named: 'queryParameters'))).called(1);
    });

    test('should fall back to any release when no official ones exist',
        () async {
      when(() => client.get(any(),
          queryParameters: any(named: 'queryParameters'))).thenAnswer(
        (Invocation inv) async => _releasesResponse(<Map<String, dynamic>>[
          if (!isOfficialQuery(inv)) _release('boot-1', status: 'bootleg'),
        ]),
      );

      final List<MusicBrainzRelease> releases =
          await api.getReleasesOrAny('group-1');

      expect(
          releases.map((MusicBrainzRelease r) => r.mbid), <String>['boot-1']);
      verify(() => client.get(any(),
          queryParameters: any(named: 'queryParameters'))).called(2);
    });

    test('should pick the earliest release as the default', () async {
      when(() => client.get(any(),
          queryParameters: any(named: 'queryParameters'))).thenAnswer(
        (_) async => _releasesResponse(<Map<String, dynamic>>[
          _release('later', date: '1994-05-10'),
          _release('earlier', date: '1973-03-01'),
          _release('undated'),
        ]),
      );

      final MusicBrainzRelease? release =
          await api.getDefaultRelease('group-1');

      expect(release?.mbid, 'earlier');
    });
  });
}
