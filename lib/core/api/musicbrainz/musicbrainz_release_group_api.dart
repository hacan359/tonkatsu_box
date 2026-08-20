import 'package:core/models/audio_item.dart';
import 'package:core/models/audio_track.dart';
import 'package:dio/dio.dart';

import 'musicbrainz_http_client.dart';
import 'musicbrainz_types.dart';

/// Search, lookup and release/track reads for release-groups.
class MusicBrainzReleaseGroupApi {
  const MusicBrainzReleaseGroupApi(this._client);

  final MusicBrainzHttpClient _client;

  /// Lucene search over release-groups; an empty [query] is valid (Browse).
  /// [queryField] restricts the text to one field (`artist`, `releasegroup`).
  Future<(List<AudioItem>, bool hasMore, int total)> search({
    String query = '',
    String? queryField,
    String? primaryType,
    bool excludeSecondaryTypes = false,
    String? tag,
    int? yearFrom,
    int? yearTo,
    int page = 1,
    int perPage = 20,
  }) async {
    final String lucene = buildQuery(
      query: query,
      queryField: queryField,
      primaryType: primaryType,
      excludeSecondaryTypes: excludeSecondaryTypes,
      tag: tag,
      yearFrom: yearFrom,
      yearTo: yearTo,
    );
    if (lucene.isEmpty) return (const <AudioItem>[], false, 0);

    try {
      final Response<dynamic> response = await _client.get(
        'release-group',
        queryParameters: <String, dynamic>{
          'query': lucene,
          'limit': perPage,
          'offset': (page - 1) * perPage,
        },
      );
      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>? ?? <String, dynamic>{};
      final List<dynamic> groups =
          data['release-groups'] as List<dynamic>? ?? <dynamic>[];
      final int total = (data['count'] as num?)?.toInt() ?? 0;

      final List<AudioItem> albums = groups
          .whereType<Map<String, dynamic>>()
          .map(AudioItem.fromMusicBrainzReleaseGroup)
          .where((AudioItem a) => a.nativeId.isNotEmpty)
          .toList();
      return (albums, page * perPage < total, total);
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to search albums');
    }
  }

  /// Full release-group with the extras search rows lack (genres, rating).
  Future<AudioItem?> getReleaseGroup(String mbid) async {
    try {
      final Response<dynamic> response = await _client.get(
        'release-group/$mbid',
        queryParameters: <String, dynamic>{
          'inc': 'artists+tags+genres+ratings',
        },
      );
      final Map<String, dynamic>? data =
          response.data as Map<String, dynamic>?;
      if (data == null) return null;
      return AudioItem.fromMusicBrainzReleaseGroup(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _client.handleDioException(e, 'Failed to load album');
    }
  }

  /// Releases (editions) of a group, oldest first. Browse endpoint — search
  /// rows carry only a release counter.
  Future<List<MusicBrainzRelease>> getReleases(
    String releaseGroupMbid, {
    bool officialOnly = true,
  }) async {
    try {
      final Response<dynamic> response = await _client.get(
        'release',
        queryParameters: <String, dynamic>{
          'release-group': releaseGroupMbid,
          if (officialOnly) 'status': 'official',
          'inc': 'media+labels',
          'limit': 100,
        },
      );
      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>? ?? <String, dynamic>{};
      final List<dynamic> releases =
          data['releases'] as List<dynamic>? ?? <dynamic>[];

      final List<MusicBrainzRelease> parsed = releases
          .whereType<Map<String, dynamic>>()
          .map(MusicBrainzRelease.fromJson)
          .where((MusicBrainzRelease r) => r.mbid.isNotEmpty)
          .toList()
        ..sort(_byDateOldestFirst);
      return parsed;
    } on DioException catch (e) {
      throw _client.handleDioException(e, 'Failed to load album editions');
    }
  }

  /// Official releases; when the group has no Official ones, whatever it has.
  Future<List<MusicBrainzRelease>> getReleasesOrAny(
    String releaseGroupMbid,
  ) async {
    final List<MusicBrainzRelease> official =
        await getReleases(releaseGroupMbid);
    if (official.isNotEmpty) return official;
    return getReleases(releaseGroupMbid, officialOnly: false);
  }

  /// The canonical default edition: the earliest release of [getReleasesOrAny].
  Future<MusicBrainzRelease?> getDefaultRelease(String releaseGroupMbid) async {
    final List<MusicBrainzRelease> releases =
        await getReleasesOrAny(releaseGroupMbid);
    return releases.isEmpty ? null : releases.first;
  }

  /// Track list of one release. [audioId] keys the rows to the cached album.
  Future<List<AudioTrack>> getReleaseTracks(
    String releaseMbid, {
    required int audioId,
  }) async {
    try {
      final Response<dynamic> response = await _client.get(
        'release/$releaseMbid',
        queryParameters: <String, dynamic>{
          'inc': 'recordings+artist-credits',
        },
      );
      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>? ?? <String, dynamic>{};
      final List<dynamic> media =
          data['media'] as List<dynamic>? ?? <dynamic>[];

      final List<AudioTrack> tracks = <AudioTrack>[];
      for (final Object? medium in media) {
        if (medium is! Map<String, dynamic>) continue;
        final int disc = (medium['position'] as num?)?.toInt() ?? 1;
        final List<dynamic> rawTracks =
            medium['tracks'] as List<dynamic>? ?? <dynamic>[];
        for (final Object? track in rawTracks) {
          if (track is! Map<String, dynamic>) continue;
          tracks.add(AudioTrack.fromMusicBrainzTrack(
            track,
            audioId: audioId,
            discNumber: disc,
          ));
        }
      }
      return tracks;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const <AudioTrack>[];
      throw _client.handleDioException(e, 'Failed to load track list');
    }
  }

  /// Builds the Lucene query: escaped free text plus AND-ed filters. Public
  /// for tests — the escaping rules are the risky part.
  static String buildQuery({
    String query = '',
    String? queryField,
    String? primaryType,
    bool excludeSecondaryTypes = false,
    String? tag,
    int? yearFrom,
    int? yearTo,
  }) {
    final List<String> parts = <String>[];
    final String text = query.trim();
    if (text.isNotEmpty) {
      parts.add(
        queryField == null || queryField.isEmpty
            ? escapeLucene(text)
            : '$queryField:"${text.replaceAll('"', r'\"')}"',
      );
    }
    if (primaryType != null && primaryType.isNotEmpty) {
      parts.add('primarytype:$primaryType');
    }
    if (excludeSecondaryTypes) {
      parts.add('-secondarytype:*');
    }
    if (tag != null && tag.isNotEmpty) {
      parts.add('tag:"${tag.replaceAll('"', r'\"')}"');
    }
    if (yearFrom != null || yearTo != null) {
      parts.add('firstreleasedate:[${yearFrom ?? '*'} TO ${yearTo ?? '*'}]');
    }
    return parts.join(' AND ');
  }

  /// Escapes Lucene operators in free text so a user typing `AC/DC` or
  /// `what?` searches for the literal characters.
  static String escapeLucene(String text) {
    final StringBuffer out = StringBuffer();
    for (final int code in text.runes) {
      final String ch = String.fromCharCode(code);
      if (_luceneSpecials.contains(ch)) out.write(r'\');
      out.write(ch);
    }
    // AND / OR / NOT survive escaping as bare words; lowercase defuses them.
    return out
        .toString()
        .replaceAllMapped(_luceneOperators, (Match m) => m[0]!.toLowerCase());
  }

  static const Set<String> _luceneSpecials = <String>{
    '+', '-', '&', '|', '!', '(', ')', '{', '}', '[', ']',
    '^', '"', '~', '*', '?', ':', r'\', '/',
  };

  static final RegExp _luceneOperators = RegExp(r'\b(AND|OR|NOT)\b');

  static int _byDateOldestFirst(MusicBrainzRelease a, MusicBrainzRelease b) {
    // Missing dates sort last — an undated bootleg must not become "earliest".
    final String da = (a.date == null || a.date!.isEmpty) ? '9999' : a.date!;
    final String db = (b.date == null || b.date!.isEmpty) ? '9999' : b.date!;
    return da.compareTo(db);
  }
}
