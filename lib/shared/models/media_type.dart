// Тип медиа-контента в коллекции.

import '../../l10n/app_localizations.dart';

/// Тип медиа-контента.
enum MediaType {
  /// Игра (IGDB).
  game('game'),

  /// Фильм (TMDB).
  movie('movie'),

  /// Сериал (TMDB).
  tvShow('tv_show'),

  /// Анимация (TMDB) — анимационные фильмы и сериалы.
  animation('animation'),

  /// Визуальная новелла (VNDB).
  visualNovel('visual_novel');

  const MediaType(this.value);

  /// Строковое значение для хранения в БД.
  final String value;

  /// Создаёт [MediaType] из строки.
  ///
  /// Возвращает [game] если значение не распознано.
  static MediaType fromString(String value) {
    for (final MediaType type in MediaType.values) {
      if (type.value == value) {
        return type;
      }
    }
    return MediaType.game;
  }

  /// Отображаемое название на английском.
  String get displayLabel {
    switch (this) {
      case MediaType.game:
        return 'Game';
      case MediaType.movie:
        return 'Movie';
      case MediaType.tvShow:
        return 'TV Show';
      case MediaType.animation:
        return 'Animation';
      case MediaType.visualNovel:
        return 'Visual Novel';
    }
  }

  /// Локализованное отображаемое название.
  String localizedLabel(S l) {
    switch (this) {
      case MediaType.game:
        return l.mediaTypeGame;
      case MediaType.movie:
        return l.mediaTypeMovie;
      case MediaType.tvShow:
        return l.mediaTypeTvShow;
      case MediaType.animation:
        return l.mediaTypeAnimation;
      case MediaType.visualNovel:
        return l.mediaTypeVisualNovel;
    }
  }
}

/// Тип источника анимации (фильм или сериал).
///
/// Хранится в `collection_items.platform_id`:
/// - [movie] = 0 → анимационный фильм
/// - [tvShow] = 1 → анимационный сериал
abstract final class AnimationSource {
  /// Анимационный фильм.
  static const int movie = 0;

  /// Анимационный сериал.
  static const int tvShow = 1;
}
