import 'package:core/models/audio_item.dart';
import 'package:core/models/data_source.dart';
import 'package:core/utils/stable_id.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'api_dio.dart';

/// One entry of the ListenBrainz fresh-releases explore feed. Carries enough
/// to render a Discover row without any MusicBrainz request.
class FreshRelease {
  const FreshRelease({
    required this.releaseGroupMbid,
    required this.name,
    this.artistName,
    this.releaseDate,
    this.primaryType,
    this.listenCount,
  });

  final String releaseGroupMbid;
  final String name;
  final String? artistName;

  /// "YYYY-MM-DD".
  final String? releaseDate;

  final String? primaryType;
  final int? listenCount;

  /// Minimal [AudioItem] for the card grid; a tap enriches via MusicBrainz.
  AudioItem toAlbum() => AudioItem(
        id: fnv1a64(releaseGroupMbid),
        source: DataSource.musicBrainz,
        nativeId: releaseGroupMbid,
        title: name,
        artists: artistName != null ? <String>[artistName!] : const <String>[],
        primaryType: primaryType,
        releaseYear: AudioItem.yearFromDate(releaseDate),
        firstReleaseDate: releaseDate,
        listenCount: listenCount,
        coverUrl: AudioItem.coverUrlForReleaseGroup(releaseGroupMbid),
        externalUrl: AudioItem.releaseGroupUrl(releaseGroupMbid),
      );
}

/// ListenBrainz popularity and fresh releases (keyless). Best-effort: the
/// API sheds load with 500s, so every failure degrades to "no data".
class ListenBrainzApi {
  ListenBrainzApi({Dio? dio})
      : _dio = dio ??
            createApiDio(
              baseUrl: 'https://api.listenbrainz.org/1/',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            );

  final Dio _dio;

  static final Logger _log = Logger('ListenBrainzApi');

  /// Listen counts for up to 100 release-group MBIDs in one POST. Missing
  /// entries and any transport/server error come back as an empty map.
  Future<Map<String, int>> getReleaseGroupPopularity(
    List<String> mbids,
  ) async {
    if (mbids.isEmpty) return const <String, int>{};
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        'popularity/release-group',
        data: <String, dynamic>{
          'release_group_mbids':
              mbids.length > 100 ? mbids.sublist(0, 100) : mbids,
        },
      );
      final List<dynamic> rows =
          response.data as List<dynamic>? ?? <dynamic>[];
      final Map<String, int> counts = <String, int>{};
      for (final Object? row in rows) {
        if (row is! Map<String, dynamic>) continue;
        final String? mbid = row['release_group_mbid'] as String?;
        final int? count = (row['total_listen_count'] as num?)?.toInt();
        if (mbid != null && count != null) counts[mbid] = count;
      }
      return counts;
    } on Object catch (e) {
      _log.warning('ListenBrainz popularity unavailable: $e');
      return const <String, int>{};
    }
  }

  /// Fresh releases across the whole network. The trailing slash in the path
  /// is mandatory — without it the API answers 404.
  Future<List<FreshRelease>> getFreshReleases({
    int days = 30,
    bool past = true,
    bool future = false,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        'explore/fresh-releases/',
        queryParameters: <String, dynamic>{
          'days': days,
          'sort': 'release_date',
          'past': past,
          'future': future,
        },
      );
      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>? ?? <String, dynamic>{};
      final Map<String, dynamic> payload =
          data['payload'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final List<dynamic> releases =
          payload['releases'] as List<dynamic>? ?? <dynamic>[];

      final List<FreshRelease> parsed = <FreshRelease>[];
      for (final Object? row in releases) {
        if (row is! Map<String, dynamic>) continue;
        final String? mbid = row['release_group_mbid'] as String?;
        final String? name = row['release_name'] as String?;
        if (mbid == null || mbid.isEmpty || name == null) continue;
        parsed.add(FreshRelease(
          releaseGroupMbid: mbid,
          name: name,
          artistName: row['artist_credit_name'] as String?,
          releaseDate: row['release_date'] as String?,
          primaryType: row['release_group_primary_type'] as String?,
          listenCount: (row['listen_count'] as num?)?.toInt(),
        ));
      }
      return parsed;
    } on Object catch (e) {
      _log.warning('ListenBrainz fresh releases unavailable: $e');
      return const <FreshRelease>[];
    }
  }

  void dispose() => _dio.close();
}

final Provider<ListenBrainzApi> listenBrainzApiProvider =
    Provider<ListenBrainzApi>((Ref ref) {
  final ListenBrainzApi api = ListenBrainzApi();
  ref.onDispose(api.dispose);
  return api;
});
