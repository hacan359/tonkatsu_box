import 'kodi_date_parser.dart';
import 'kodi_unique_ids.dart';

/// A movie from Kodi `VideoLibrary.GetMovies`.
///
/// DTO, never persisted to SQLite — used only by `KodiSyncService` to match
/// against the local collection and wishlist.
class KodiMovie {
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

  /// `lastplayed` is `"YYYY-MM-DD HH:MM:SS"` (local time); an empty string
  /// means "never played".
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

  final int movieId;
  final String title;
  final int? year;

  /// Play count, 0 = unwatched.
  final int playcount;

  /// Null when playcount == 0 or the field was empty.
  final DateTime? lastPlayed;

  /// Kodi user rating, 0–10, null when unset.
  final double? userRating;

  /// External ids for TMDB matching.
  final KodiUniqueIds uniqueIds;

  /// Movie set / collection (e.g. "Harry Potter Collection"), null if none.
  final String? set;

  final DateTime? dateAdded;

  /// Scraper (TMDB/IMDB) community rating, 0.0–10.0.
  final double? communityRating;

  bool get isWatched => playcount > 0;

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

  static double? _parseCommunityRating(Object? raw) {
    if (raw is double && raw > 0) return raw;
    if (raw is int && raw > 0) return raw.toDouble();
    return null;
  }
}
