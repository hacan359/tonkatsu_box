import 'package:core/models/album.dart';
import 'package:core/models/album_track.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'musicbrainz/musicbrainz_http_client.dart';
import 'musicbrainz/musicbrainz_release_group_api.dart';
import 'musicbrainz/musicbrainz_types.dart';
export 'musicbrainz/musicbrainz_types.dart';

/// MusicBrainz REST facade (`https://musicbrainz.org/ws/2`, keyless). Albums
/// are release-groups; track lists live on a picked release.
class MusicBrainzApi {
  MusicBrainzApi({Dio? dio}) : _client = MusicBrainzHttpClient(dio: dio) {
    _releaseGroups = MusicBrainzReleaseGroupApi(_client);
  }

  final MusicBrainzHttpClient _client;
  late final MusicBrainzReleaseGroupApi _releaseGroups;

  Future<(List<Album>, bool hasMore, int total)> search({
    String query = '',
    String? queryField,
    String? primaryType,
    bool excludeSecondaryTypes = false,
    String? tag,
    int? yearFrom,
    int? yearTo,
    int page = 1,
    int perPage = 20,
  }) =>
      _releaseGroups.search(
        query: query,
        queryField: queryField,
        primaryType: primaryType,
        excludeSecondaryTypes: excludeSecondaryTypes,
        tag: tag,
        yearFrom: yearFrom,
        yearTo: yearTo,
        page: page,
        perPage: perPage,
      );

  Future<Album?> getReleaseGroup(String mbid) =>
      _releaseGroups.getReleaseGroup(mbid);

  Future<List<MusicBrainzRelease>> getReleases(
    String releaseGroupMbid, {
    bool officialOnly = true,
  }) =>
      _releaseGroups.getReleases(releaseGroupMbid, officialOnly: officialOnly);

  Future<List<MusicBrainzRelease>> getReleasesOrAny(String releaseGroupMbid) =>
      _releaseGroups.getReleasesOrAny(releaseGroupMbid);

  Future<MusicBrainzRelease?> getDefaultRelease(String releaseGroupMbid) =>
      _releaseGroups.getDefaultRelease(releaseGroupMbid);

  Future<List<AlbumTrack>> getReleaseTracks(
    String releaseMbid, {
    required int albumId,
  }) =>
      _releaseGroups.getReleaseTracks(releaseMbid, albumId: albumId);

  void dispose() => _client.dispose();
}

final Provider<MusicBrainzApi> musicBrainzApiProvider =
    Provider<MusicBrainzApi>((Ref ref) {
  final MusicBrainzApi api = MusicBrainzApi();
  ref.onDispose(api.dispose);
  return api;
});
