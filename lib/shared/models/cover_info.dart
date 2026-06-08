// Легковесная модель обложки для карточек коллекций.

import '../../core/services/image_cache_service.dart';
import '../utils/cover_image_id.dart' as cover_id;
import 'data_source.dart';
import 'media_type.dart';

/// Информация об обложке элемента коллекции.
///
/// Используется для отображения мозаики обложек на карточках коллекций
/// без загрузки полных моделей Game/Movie/TvShow/VisualNovel.
class CoverInfo {
  /// Создаёт экземпляр [CoverInfo].
  const CoverInfo({
    required this.externalId,
    required this.mediaType,
    this.platformId,
    this.source,
    this.thumbnailUrl,
  });

  /// Создаёт [CoverInfo] из строки БД.
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

  /// ID элемента во внешнем источнике (IGDB/TMDB/VNDB).
  final int externalId;

  /// Тип медиа-контента.
  final MediaType mediaType;

  /// ID платформы (для игр) или источник анимации (0=movie, 1=tvShow).
  final int? platformId;

  /// Provider, manga-only. Disambiguates a shared `externalId`.
  final DataSource? source;

  /// URL thumbnail-обложки.
  final String? thumbnailUrl;

  /// Source-aware cover cache id (manga is namespaced by provider). Matches
  /// `CollectionItem.coverImageId`.
  String get coverImageId => cover_id.coverImageId(
        mediaType: mediaType,
        externalId: externalId,
        source: source,
      );

  /// Тип изображения для локального кэша (`ImageCacheService`).
  ///
  /// Для `MediaType.animation` различает movie/tvShow по
  /// [platformId] == [AnimationSource.tvShow].
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

  /// Конвертирует полноразмерный URL в thumbnail.
  ///
  /// Для TMDB (movie/tvShow/animation) заменяет `/wXXX` на `/w154`.
  /// Для IGDB (game) и VNDB (visualNovel) возвращает как есть.
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
