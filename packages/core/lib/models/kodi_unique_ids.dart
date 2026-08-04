/// Ids Kodi's scrapers attach to an item, used to match a Kodi item to a TMDB
/// one. Priority runs [tmdbId] → [imdbId] → [tvdbId].
class KodiUniqueIds {
  const KodiUniqueIds({this.tmdbId, this.imdbId, this.tvdbId});

  /// Reads `"uniqueid": {"tmdb": "27205", "imdb": "tt1375666"}`. Kodi sends
  /// strings; unparseable numbers are dropped. Empty for null or `{}`.
  factory KodiUniqueIds.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return const KodiUniqueIds();
    }
    return KodiUniqueIds(
      tmdbId: _parseIntId(json['tmdb']),
      imdbId: _parseImdbId(json['imdb']),
      tvdbId: _parseIntId(json['tvdb']),
    );
  }

  final int? tmdbId;

  /// Keeps the `tt` prefix, e.g. `tt1234567`.
  final String? imdbId;

  final int? tvdbId;

  bool get hasAny => tmdbId != null || imdbId != null || tvdbId != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KodiUniqueIds &&
          other.tmdbId == tmdbId &&
          other.imdbId == imdbId &&
          other.tvdbId == tvdbId);

  @override
  int get hashCode => Object.hash(tmdbId, imdbId, tvdbId);

  @override
  String toString() =>
      'KodiUniqueIds(tmdb: $tmdbId, imdb: $imdbId, tvdb: $tvdbId)';

  static int? _parseIntId(Object? raw) {
    if (raw == null) return null;
    if (raw is int) return raw > 0 ? raw : null;
    if (raw is String) {
      final int? parsed = int.tryParse(raw);
      return (parsed != null && parsed > 0) ? parsed : null;
    }
    return null;
  }

  static String? _parseImdbId(Object? raw) {
    if (raw is! String) return null;
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }
}
