import '../utils/cover_image_id.dart' as cover_id;
import 'data_source.dart';
import 'image_type.dart';
import 'media_type.dart';

/// Cover of a collection item, for the cover mosaic on collection cards —
/// avoids loading full Game/Movie/TvShow/VisualNovel models.
class CoverInfo {
  const CoverInfo({
    required this.externalId,
    required this.mediaType,
    this.platformId,
    this.source,
    this.thumbnailUrl,
  });

  factory CoverInfo.fromDb(Map<String, dynamic> row) {
    final MediaType mediaType =
        MediaType.fromString(row['media_type'] as String);
    final String? rawUrl = row['thumbnail_url'] as String?;

    return CoverInfo(
      externalId: row['external_id'] as int,
      mediaType: mediaType,
      platformId: row['platform_id'] as int?,
      source: row['source'] != null
          ? DataSource.fromName(row['source'] as String?)
          : null,
      thumbnailUrl: _toThumbUrl(rawUrl, mediaType),
    );
  }

  /// Item id in the external source (IGDB/TMDB/VNDB).
  final int externalId;

  final MediaType mediaType;

  /// Platform id (games) or animation source (0=movie, 1=tvShow).
  final int? platformId;

  /// Provider, manga-only. Disambiguates a shared `externalId`.
  final DataSource? source;

  final String? thumbnailUrl;

  /// Source-aware cover cache id (manga is namespaced by provider). Matches
  /// `CollectionItem.coverImageId`.
  String get coverImageId => cover_id.coverImageId(
        mediaType: mediaType,
        externalId: externalId,
        source: source,
        coverUrl: thumbnailUrl,
      );

  /// Image type for the local cache; for `MediaType.animation` picks
  /// movie/tvShow by [platformId] == [AnimationSource.tvShow].
  ImageType get imageType {
    switch (mediaType) {
      case MediaType.game:
        return ImageType.gameCover;
      case MediaType.movie:
        return ImageType.moviePoster;
      case MediaType.tvShow:
        return ImageType.tvShowPoster;
      case MediaType.animation:
        if (platformId == AnimationSource.tvShow) {
          return ImageType.tvShowPoster;
        }
        return ImageType.moviePoster;
      case MediaType.visualNovel:
        return ImageType.vnCover;
      case MediaType.manga:
        return ImageType.mangaCover;
      case MediaType.anime:
        return ImageType.animeCover;
      case MediaType.book:
        return ImageType.bookCover;
      case MediaType.custom:
        return ImageType.customCover;
    }
  }

  /// Full-size URL → thumbnail: TMDB `/wXXX` becomes `/w154`; other
  /// providers are returned as is.
  static String? _toThumbUrl(String? url, MediaType mediaType) {
    if (url == null) return null;

    switch (mediaType) {
      case MediaType.movie:
      case MediaType.tvShow:
      case MediaType.animation:
        return url.replaceFirst(RegExp(r'/w\d+'), '/w154');
      case MediaType.game:
      case MediaType.visualNovel:
      case MediaType.manga:
      case MediaType.anime:
      case MediaType.book:
      case MediaType.custom:
        return url;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoverInfo &&
          runtimeType == other.runtimeType &&
          externalId == other.externalId &&
          mediaType == other.mediaType &&
          platformId == other.platformId &&
          source == other.source &&
          thumbnailUrl == other.thumbnailUrl;

  @override
  int get hashCode =>
      Object.hash(externalId, mediaType, platformId, source, thumbnailUrl);

  @override
  String toString() =>
      'CoverInfo(externalId: $externalId, mediaType: $mediaType, '
      'platformId: $platformId, thumbnailUrl: $thumbnailUrl)';
}
