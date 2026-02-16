// Подфильтр для TV-таба поиска.

/// Подфильтр для TV-таба: фильмы, сериалы, анимация или всё.
enum TvSubFilter {
  /// Все типы медиа.
  all('all', 'All'),

  /// Только фильмы (без анимации).
  movies('movies', 'Movies'),

  /// Только сериалы (без анимации).
  tvShows('tvShows', 'TV Shows'),

  /// Только анимация (фильмы + сериалы).
  animation('animation', 'Animation');

  const TvSubFilter(this.value, this.label);

  /// Строковое значение для идентификации.
  final String value;

  /// Отображаемое название.
  final String label;

  /// Создаёт [TvSubFilter] из строки.
  ///
  /// Возвращает [all] для неизвестных значений.
  static TvSubFilter fromString(String value) {
    for (final TvSubFilter filter in TvSubFilter.values) {
      if (filter.value == value) {
        return filter;
      }
    }
    return TvSubFilter.all;
  }
}
