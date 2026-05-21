import '../../../shared/models/anime.dart';
import '../../../shared/models/manga.dart';
import '../../../shared/models/media_type.dart';

class AniListApiException implements Exception {
  const AniListApiException(this.message, {this.statusCode, this.detail});

  final String message;
  final int? statusCode;
  final String? detail;

  @override
  String toString() =>
      'AniListApiException: $message (status: $statusCode)';
}

class AniListRateLimitException extends AniListApiException {
  const AniListRateLimitException(this.retryAfter, {String? detail})
      : super(
          'Rate limit exceeded. Please try again later',
          statusCode: 429,
          detail: detail,
        );

  final Duration retryAfter;
}

class AniListUserNotFoundException extends AniListApiException {
  const AniListUserNotFoundException(String username)
      : super('AniList user "$username" not found', statusCode: 404);
}

class AniListPrivateProfileException extends AniListApiException {
  const AniListPrivateProfileException(String username)
      : super(
          'AniList user "$username" has a private profile',
          statusCode: 403,
        );
}

class AniListMalLookupResult<T> {
  const AniListMalLookupResult({
    required this.resolved,
    required this.failedIds,
  });

  final Map<int, T> resolved;

  /// MAL ids that could not be resolved due to AniList API errors (after
  /// retries). Distinct from ids absent from [resolved] because AniList simply
  /// has no record.
  final List<int> failedIds;
}

class AniListListEntry {
  const AniListListEntry({
    required this.mediaId,
    required this.mediaType,
    required this.rawStatus,
    required this.progress,
    required this.progressVolumes,
    required this.repeat,
    this.scoreRaw100,
    this.notes,
    this.startedAt,
    this.completedAt,
    this.updatedAt,
    this.anime,
    this.manga,
  });

  final int mediaId;
  final MediaType mediaType;

  /// CURRENT / PLANNING / COMPLETED / DROPPED / PAUSED / REPEATING.
  final String rawStatus;

  final int progress;
  final int progressVolumes;
  final int repeat;

  /// Score on the 0..100 scale, or null if unset.
  final int? scoreRaw100;

  final String? notes;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? updatedAt;

  final Anime? anime;
  final Manga? manga;
}
