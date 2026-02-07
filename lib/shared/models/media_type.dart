// Тип медиа-контента в коллекции.

/// Тип медиа-контента.
enum MediaType {
  /// Игра (IGDB).
  game('game'),

  /// Фильм (TMDB).
  movie('movie'),

  /// Сериал (TMDB).
  tvShow('tv_show');

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
    }
  }
}
