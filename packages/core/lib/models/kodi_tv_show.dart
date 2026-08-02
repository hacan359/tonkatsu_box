import 'kodi_date_parser.dart';
import 'kodi_unique_ids.dart';

/// A TV show from Kodi `VideoLibrary.GetTVShows`.
///
/// Show-level `playcount`/`lastplayed` is usually 0 in Kodi (tracked per
/// episode); used for matching and to decide whether to fetch episodes.
class KodiTvShow {
  const KodiTvShow({
    required this.tvShowId,
    required this.title,
    required this.uniqueIds,
    this.year,
    this.playcount = 0,
    this.lastPlayed,
    this.userRating,
  });

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

  final int tvShowId;
  final String title;
  final int? year;

  /// Aggregate playcount, often 0 — see per-episode data.
  final int playcount;

  final DateTime? lastPlayed;

  /// User rating, 0–10.
  final double? userRating;

  /// External ids (TMDB / IMDB / TVDB) for matching.
  final KodiUniqueIds uniqueIds;

  static int? _parseYear(Object? raw) {
    if (raw is int && raw > 0) return raw;
    if (raw is String) {
      final int? parsed = int.tryParse(raw);
      return (parsed != null && parsed > 0) ? parsed : null;
    }
    return null;
  }

  static double? _parseRating(Object? raw) {
    if (raw is int && raw > 0) return raw.toDouble();
    if (raw is double && raw > 0) return raw;
    return null;
  }
}
