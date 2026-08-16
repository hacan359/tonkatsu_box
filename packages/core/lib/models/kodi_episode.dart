import 'kodi_date_parser.dart';
import 'kodi_unique_ids.dart';

class KodiEpisode {
  const KodiEpisode({
    required this.episodeId,
    required this.showTitle,
    required this.season,
    required this.episode,
    required this.uniqueIds,
    this.playcount = 0,
    this.lastPlayed,
  });

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

  final int episodeId;

  final String showTitle;

  /// 1-based; 0 usually means specials.
  final int season;

  final int episode;

  final int playcount;

  final DateTime? lastPlayed;

  /// Usually just the TVDB episode id.
  final KodiUniqueIds uniqueIds;

  bool get isWatched => playcount > 0;
}
