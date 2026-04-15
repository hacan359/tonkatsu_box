// Модель сериала из Kodi VideoLibrary.

import 'kodi_date_parser.dart';
import 'kodi_unique_ids.dart';

/// Сериал из Kodi VideoLibrary.GetTVShows.
///
/// `playcount`/`lastplayed` на уровне шоу в Kodi отражают суммарное
/// воспроизведение — как правило 0 на уровне TVShow (заполняется на
/// уровне эпизодов). Используется для матчинга и чтобы решить, идти
/// ли за эпизодами.
class KodiTvShow {
  /// Создаёт [KodiTvShow].
  const KodiTvShow({
    required this.tvShowId,
    required this.title,
    required this.uniqueIds,
    this.year,
    this.playcount = 0,
    this.lastPlayed,
    this.userRating,
  });

  /// Парсит элемент массива `tvshows` из ответа `VideoLibrary.GetTVShows`.
  factory KodiTvShow.fromJson(Map<String, dynamic> json) {
    return KodiTvShow(
      tvShowId: json['tvshowid'] as int,
      title: (json['title'] as String?) ?? '',
      year: _parseYear(json['year']),
      playcount: (json['playcount'] as int?) ?? 0,
      lastPlayed: parseKodiDateTime(json['lastplayed'] as String?),
      userRating: _parseRating(json['userrating']),
      uniqueIds: KodiUniqueIds.fromJson(
        json['uniqueid'] as Map<String, dynamic>?,
      ),
    );
  }

  /// Внутренний ID шоу в Kodi.
  final int tvShowId;

  /// Название шоу.
  final String title;

  /// Год первого эфира.
  final int? year;

  /// Суммарный playcount (часто 0 — смотри эпизоды).
  final int playcount;

  /// Когда последний раз воспроизводился какой-либо эпизод.
  final DateTime? lastPlayed;

  /// Оценка пользователя (0–10).
  final int? userRating;

  /// Внешние идентификаторы (TMDB / IMDB / TVDB).
  final KodiUniqueIds uniqueIds;

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
}
