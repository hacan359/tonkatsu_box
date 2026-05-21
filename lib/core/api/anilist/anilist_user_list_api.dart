import 'package:logging/logging.dart';

import '../../../shared/models/anime.dart';
import '../../../shared/models/manga.dart';
import '../../../shared/models/media_type.dart';
import 'anilist_graphql_client.dart';
import 'anilist_media_parser.dart';
import 'anilist_queries.dart';
import 'anilist_types.dart';

class AniListUserListApi {
  AniListUserListApi(this._client);

  final AniListGraphQLClient _client;
  static final Logger _log = Logger('AniListApi');

  /// Throws [AniListUserNotFoundException] / [AniListPrivateProfileException]
  /// for the common error cases. Only [MediaType.anime] and [MediaType.manga]
  /// are accepted.
  Future<List<AniListListEntry>> fetchUserMediaList({
    required String userName,
    required MediaType type,
  }) async {
    if (type != MediaType.anime && type != MediaType.manga) {
      throw ArgumentError.value(type, 'type', 'Only anime/manga supported');
    }
    final String trimmed = userName.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(userName, 'userName', 'must not be empty');
    }

    final String query = type == MediaType.anime
        ? AniListQueries.userAnimeList
        : AniListQueries.userMangaList;

    final Map<String, dynamic> body;
    try {
      body = await _client.post(
        query: query,
        variables: <String, dynamic>{'userName': trimmed},
        errorContext: 'Failed to fetch user media list',
      );
    } on AniListApiException catch (e) {
      if (e.statusCode == 404) throw AniListUserNotFoundException(trimmed);
      rethrow;
    }

    _translateUserErrors(body, trimmed);

    final Map<String, dynamic>? data =
        body['data'] as Map<String, dynamic>?;
    final Map<String, dynamic>? collection =
        data?['MediaListCollection'] as Map<String, dynamic>?;
    if (collection == null) {
      return <AniListListEntry>[];
    }

    final List<dynamic> lists =
        collection['lists'] as List<dynamic>? ?? <dynamic>[];

    final Map<int, AniListListEntry> dedup = <int, AniListListEntry>{};
    for (final dynamic listRaw in lists) {
      final Map<String, dynamic> list = listRaw as Map<String, dynamic>;
      // Custom lists duplicate entries from the canonical ones — skip.
      if (list['isCustomList'] as bool? ?? false) continue;

      final List<dynamic> entries =
          list['entries'] as List<dynamic>? ?? <dynamic>[];
      for (final dynamic entryRaw in entries) {
        final AniListListEntry? entry = _parseListEntry(
          entryRaw as Map<String, dynamic>,
          type,
        );
        if (entry != null) {
          dedup[entry.mediaId] = entry;
        }
      }
    }
    return dedup.values.toList();
  }

  // GraphQL errors arrive with HTTP 200 — translate the common ones into
  // typed exceptions before they reach the caller.
  void _translateUserErrors(Map<String, dynamic> body, String userName) {
    final List<dynamic>? errors = body['errors'] as List<dynamic>?;
    if (errors == null || errors.isEmpty) return;

    final Map<String, dynamic> first = errors.first as Map<String, dynamic>;
    final String raw = first['message'] as String? ?? '';
    final String lower = raw.toLowerCase();

    if (lower.contains('not found') || lower.contains('does not exist')) {
      throw AniListUserNotFoundException(userName);
    }
    if (lower.contains('private')) {
      throw AniListPrivateProfileException(userName);
    }
    _log.warning('AniList GraphQL error: $raw');
    throw AniListApiException(raw.isEmpty ? 'GraphQL error' : raw);
  }

  AniListListEntry? _parseListEntry(
    Map<String, dynamic> json,
    MediaType type,
  ) {
    final Map<String, dynamic>? media =
        json['media'] as Map<String, dynamic>?;
    if (media == null) return null;

    // Hentai / adult content is excluded from imports.
    if (media['isAdult'] as bool? ?? false) return null;

    final int? mediaId = media['id'] as int?;
    if (mediaId == null) return null;

    final String status = (json['status'] as String? ?? '').trim();

    final int scoreRaw = (json['score'] as num?)?.toInt() ?? 0;
    final int? scoreRaw100 = scoreRaw > 0 ? scoreRaw : null;

    final int progress = (json['progress'] as num?)?.toInt() ?? 0;
    final int progressVolumes =
        (json['progressVolumes'] as num?)?.toInt() ?? 0;
    final int repeat = (json['repeat'] as num?)?.toInt() ?? 0;

    final String? notesRaw = (json['notes'] as String?)?.trim();
    final String? notes =
        (notesRaw == null || notesRaw.isEmpty) ? null : notesRaw;

    final DateTime? startedAt = AniListMediaParser.fuzzyDate(
      json['startedAt'] as Map<String, dynamic>?,
    );
    final DateTime? completedAt = AniListMediaParser.fuzzyDate(
      json['completedAt'] as Map<String, dynamic>?,
    );

    final int? updatedAtUnix = (json['updatedAt'] as num?)?.toInt();
    final DateTime? updatedAt = (updatedAtUnix != null && updatedAtUnix > 0)
        ? DateTime.fromMillisecondsSinceEpoch(
            updatedAtUnix * 1000,
            isUtc: true,
          )
        : null;

    final Anime? anime =
        type == MediaType.anime ? Anime.fromJson(media) : null;
    final Manga? manga =
        type == MediaType.manga ? Manga.fromJson(media) : null;

    return AniListListEntry(
      mediaId: mediaId,
      mediaType: type,
      rawStatus: status,
      progress: progress,
      progressVolumes: progressVolumes,
      repeat: repeat,
      scoreRaw100: scoreRaw100,
      notes: notes,
      startedAt: startedAt,
      completedAt: completedAt,
      updatedAt: updatedAt,
      anime: anime,
      manga: manga,
    );
  }
}
