// Модель эпизода сериала из Kodi VideoLibrary.

import 'kodi_date_parser.dart';
import 'kodi_unique_ids.dart';

/// Эпизод из Kodi VideoLibrary.GetEpisodes.
class KodiEpisode {
  /// Создаёт [KodiEpisode].
  const KodiEpisode({
    required this.episodeId,
    required this.showTitle,
    required this.season,
    required this.episode,
    required this.uniqueIds,
    this.playcount = 0,
    this.lastPlayed,
  });

  /// Парсит элемент массива `episodes` из ответа `VideoLibrary.GetEpisodes`.
  factory KodiEpisode.fromJson(Map<String, dynamic> json) {
    return KodiEpisode(
      episodeId: json['episodeid'] as int,
      showTitle: (json['showtitle'] as String?) ?? '',
      season: (json['season'] as int?) ?? 0,
      episode: (json['episode'] as int?) ?? 0,
      playcount: (json['playcount'] as int?) ?? 0,
      lastPlayed: parseKodiDateTime(json['lastplayed'] as String?),
      uniqueIds: KodiUniqueIds.fromJson(
        json['uniqueid'] as Map<String, dynamic>?,
      ),
    );
  }

  /// Внутренний ID эпизода в Kodi.
  final int episodeId;

  /// Название родительского шоу.
  final String showTitle;

  /// Номер сезона (1-based; 0 обычно означает "спешлы").
  final int season;

  /// Номер эпизода в рамках сезона.
  final int episode;

  /// Сколько раз эпизод был воспроизведён.
  final int playcount;

  /// Время последнего воспроизведения.
  final DateTime? lastPlayed;

  /// Внешние идентификаторы эпизода (обычно TVDB episode id).
  final KodiUniqueIds uniqueIds;

  /// Эпизод просмотрен.
  bool get isWatched => playcount > 0;
}
