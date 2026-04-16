// Модель фильма из Kodi VideoLibrary.

import 'kodi_date_parser.dart';
import 'kodi_unique_ids.dart';

/// Фильм из Kodi VideoLibrary.GetMovies.
///
/// DTO, не сохраняется в SQLite — используется только в `KodiSyncService`
/// для матчинга с локальной коллекцией и wishlist-ом.
class KodiMovie {
  /// Создаёт [KodiMovie].
  const KodiMovie({
    required this.movieId,
    required this.title,
    required this.uniqueIds,
    this.year,
    this.playcount = 0,
    this.lastPlayed,
    this.userRating,
    this.set,
    this.dateAdded,
    this.communityRating,
  });

  /// Парсит элемент массива `movies` из ответа `VideoLibrary.GetMovies`.
  ///
  /// Обязательные поля: `movieid`, `title`. Остальное — опциональные.
  /// `lastplayed` приходит в формате `"YYYY-MM-DD HH:MM:SS"` (local time);
  /// пустая строка трактуется как "никогда не воспроизводился".
  factory KodiMovie.fromJson(Map<String, dynamic> json) {
    final String? setRaw = json['set'] as String?;
    return KodiMovie(
      movieId: json['movieid'] as int,
      title: (json['title'] as String?) ?? '',
      year: _parseYear(json['year']),
      playcount: (json['playcount'] as int?) ?? 0,
      lastPlayed: parseKodiDateTime(json['lastplayed'] as String?),
      userRating: _parseRating(json['userrating']),
      uniqueIds: KodiUniqueIds.fromJson(
        json['uniqueid'] as Map<String, dynamic>?,
      ),
      set: (setRaw != null && setRaw.isNotEmpty) ? setRaw : null,
      dateAdded: parseKodiDateTime(json['dateadded'] as String?),
      communityRating: _parseCommunityRating(json['rating']),
    );
  }

  /// Внутренний ID фильма в Kodi.
  final int movieId;

  /// Название фильма.
  final String title;

  /// Год выпуска (может отсутствовать — Kodi возвращает 0 или поле не
  /// приходит).
  final int? year;

  /// Сколько раз воспроизводился (0 = не смотрели).
  final int playcount;

  /// Когда последний раз воспроизводился (null если playcount == 0
  /// или поле пустое).
  final DateTime? lastPlayed;

  /// Оценка пользователя в Kodi по шкале 0–10 (null если не выставлена).
  final int? userRating;

  /// Внешние идентификаторы — для матчинга с TMDB.
  final KodiUniqueIds uniqueIds;

  /// Movie set / collection (e.g. "Harry Potter Collection").
  /// null если фильм не входит в набор.
  final String? set;

  /// Когда фильм был добавлен в библиотеку Kodi.
  final DateTime? dateAdded;

  /// Community рейтинг от scraper'а (TMDB/IMDB), 0.0–10.0.
  final double? communityRating;

  /// Пользователь смотрел фильм.
  bool get isWatched => playcount > 0;

  static int? _parseYear(Object? raw) {
    if (raw is int && raw > 0) return raw;
    if (raw is String) {
      final int? parsed = int.tryParse(raw);
      return (parsed != null && parsed > 0) ? parsed : null;
    }
    return null;
  }

  static int? _parseRating(Object? raw) {
    if (raw is int && raw > 0) return raw;
    if (raw is double && raw > 0) return raw.round();
    return null;
  }

  static double? _parseCommunityRating(Object? raw) {
    if (raw is double && raw > 0) return raw;
    if (raw is int && raw > 0) return raw.toDouble();
    return null;
  }
}
