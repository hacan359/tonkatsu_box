// Уникальные идентификаторы медиа-элемента из Kodi (TMDB / IMDB / TVDB).

/// Набор внешних ID, которые Kodi проставляет через скрэперы
/// (TMDB, IMDB, TheTVDB, AniDB и т.п.).
///
/// Используется для матчинга Kodi item → TMDB item при sync.
/// Порядок приоритета: [tmdbId] → [imdbId] → [tvdbId].
class KodiUniqueIds {
  /// Создаёт [KodiUniqueIds].
  const KodiUniqueIds({this.tmdbId, this.imdbId, this.tvdbId});

  /// Парсит блок `uniqueid` из ответа Kodi JSON-RPC.
  ///
  /// Формат:
  /// ```json
  /// "uniqueid": { "tmdb": "27205", "imdb": "tt1375666", "tvdb": "12345" }
  /// ```
  ///
  /// Возвращает пустой [KodiUniqueIds] если `json` равен null или `{}`.
  /// Значения в Kodi — строки; TMDB/TVDB парсятся через [int.tryParse],
  /// некорректные числа игнорируются.
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

  /// ID в TMDB (для фильмов и сериалов).
  final int? tmdbId;

  /// ID в IMDB (формат `tt1234567`, префикс `tt` сохраняется).
  final String? imdbId;

  /// ID в TheTVDB (для сериалов).
  final int? tvdbId;

  /// Есть ли хотя бы один валидный ID.
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
