// One parsed row from a Kinorium CSV export.

/// Kinorium media kind, taken verbatim from the `Type` column. The CSV writes
/// these in Russian; [fromRaw] maps the known values and falls back to
/// [unknown] for anything unexpected.
enum KinoriumType {
  film,
  animatedFilm,
  series,
  animatedSeries,
  episode,
  unknown;

  static KinoriumType fromRaw(String raw) {
    switch (raw.trim()) {
      case 'Фильм':
        return KinoriumType.film;
      case 'Мультфильм':
        return KinoriumType.animatedFilm;
      case 'Сериал':
        return KinoriumType.series;
      case 'Мультсериал':
        return KinoriumType.animatedSeries;
      case 'Эпизод':
        return KinoriumType.episode;
      default:
        return KinoriumType.unknown;
    }
  }

  /// Searched on TMDB's movie endpoint.
  bool get isMovieLike =>
      this == KinoriumType.film || this == KinoriumType.animatedFilm;

  /// Searched on TMDB's TV endpoint.
  bool get isTvLike =>
      this == KinoriumType.series || this == KinoriumType.animatedSeries;

  /// Kinorium already separates animated titles, so the kind is a reliable
  /// animation hint on its own (genre data refines it later).
  bool get isAnimationHint =>
      this == KinoriumType.animatedFilm || this == KinoriumType.animatedSeries;
}

/// A single Kinorium title with only the fields the importer needs.
class KinoriumEntry {
  const KinoriumEntry({
    required this.title,
    required this.type,
    this.originalTitle,
    this.year,
    this.myRating,
    this.date,
    this.genres = const <String>[],
    this.actors,
    this.directors,
    this.note,
  });

  /// Localized (usually Russian) title from the `Title` column.
  final String title;

  /// Original-language title from the `Original Title` column. Often the
  /// English name; empty for many Russian/Soviet titles.
  final String? originalTitle;

  final KinoriumType type;

  /// Release year; `null` when the CSV holds `0` or a blank.
  final int? year;

  /// `My rating` on Kinorium's 1–10 scale. `null` when not rated.
  final double? myRating;

  /// `Date` column. For watched lists this is the watch date; for the
  /// "буду смотреть" list it is the date the title was added.
  final DateTime? date;

  final List<String> genres;

  final String? actors;

  final String? directors;

  final String? note;

  /// Best query string for TMDB: prefer the original title, fall back to the
  /// localized one when the original is missing (Russian titles, gaps).
  String get searchQuery {
    final String? original = originalTitle?.trim();
    if (original != null && original.isNotEmpty) {
      return original;
    }
    return title.trim();
  }

  bool get hasValidQuery => searchQuery.isNotEmpty;
}
