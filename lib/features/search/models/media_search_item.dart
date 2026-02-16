// Обёртка для смешанных результатов поиска медиа (фильм или сериал).

import '../../../shared/models/movie.dart';
import '../../../shared/models/tv_show.dart';

/// Тип элемента медиа-поиска.
enum MediaSearchItemType {
  /// Фильм.
  movie,

  /// Сериал.
  tvShow,
}

/// Обёртка для элемента поиска медиа (фильм или сериал).
///
/// Используется в TV-табе для отображения смешанных результатов
/// из разных API (Movies + TV Shows + Animation).
class MediaSearchItem {
  /// Создаёт [MediaSearchItem] из фильма.
  const MediaSearchItem.fromMovie(Movie this.movie) : tvShow = null;

  /// Создаёт [MediaSearchItem] из сериала.
  const MediaSearchItem.fromTvShow(TvShow this.tvShow) : movie = null;

  /// Фильм (если элемент — фильм).
  final Movie? movie;

  /// Сериал (если элемент — сериал).
  final TvShow? tvShow;

  /// Тип элемента.
  MediaSearchItemType get type =>
      movie != null ? MediaSearchItemType.movie : MediaSearchItemType.tvShow;

  /// Название.
  String get title => movie?.title ?? tvShow!.title;

  /// Год выпуска.
  int? get year => movie?.releaseYear ?? tvShow?.firstAirYear;

  /// Рейтинг.
  double? get rating => movie?.rating ?? tvShow?.rating;

  /// URL постера.
  String? get posterUrl => movie?.posterUrl ?? tvShow?.posterUrl;

  /// Жанры.
  List<String>? get genres => movie?.genres ?? tvShow?.genres;

  /// TMDB ID.
  int get tmdbId => movie?.tmdbId ?? tvShow!.tmdbId;

  /// Является ли анимацией (содержит жанр "Animation" или genre_id 16).
  bool get isAnimation {
    final List<String>? g = genres;
    if (g == null) return false;
    return g.any(
      (String genre) =>
          genre == 'Animation' || genre == '16',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaSearchItem &&
        other.type == type &&
        other.tmdbId == tmdbId;
  }

  @override
  int get hashCode => Object.hash(type, tmdbId);
}
