// Легковесная модель обложки для карточек коллекций.

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
      thumbnailUrl: _toThumbUrl(rawUrl, mediaType),
    );
  }

  /// ID элемента во внешнем источнике (IGDB/TMDB/VNDB).
  final int externalId;

  /// Тип медиа-контента.
  final MediaType mediaType;

  /// ID платформы (для игр) или источник анимации (0=movie, 1=tvShow).
  final int? platformId;

  /// URL thumbnail-обложки.
  final String? thumbnailUrl;

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
          thumbnailUrl == other.thumbnailUrl;

  @override
  int get hashCode => Object.hash(externalId, mediaType, platformId, thumbnailUrl);

  @override
  String toString() =>
      'CoverInfo(externalId: $externalId, mediaType: $mediaType, '
      'platformId: $platformId, thumbnailUrl: $thumbnailUrl)';
}
