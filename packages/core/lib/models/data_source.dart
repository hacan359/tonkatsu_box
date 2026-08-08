/// Brand assets live app-side: see the `DataSourceUi.iconAsset` extension.
enum DataSource {
  /// IGDB — game database.
  igdb('IGDB', 0xFF9147FF),

  /// TMDB — movie and TV database.
  tmdb('TMDB', 0xFF01D277),

  /// TVmaze — keyless TV series database with season / episode data.
  tvmaze('TVmaze', 0xFF3C5C8C),

  /// TheTVDB — movie and TV database with its own season / episode data.
  /// Carries no user rating, only a popularity score.
  tvdb('TheTVDB', 0xFF6CD591),

  /// SteamGridDB — Steam artwork.
  steamGridDb('SGDB', 0xFF3A9BDC, brandName: 'SteamGridDB'),

  /// VGMaps — video game maps.
  vgMaps('VGMaps', 0xFFE57C23),

  /// VNDB — visual novel database.
  vndb('VNDB', 0xFF2A5FC1),

  /// AniList — anime and manga database.
  anilist('AniList', 0xFF3DB4F2),

  /// MangaBaka — open catalog of manga / manhwa / manhua / light novels.
  mangabaka('MangaBaka', 0xFFE5484D),

  /// MangaDex — large manga catalog with localized titles and chapter counts.
  mangadex('MangaDex', 0xFFFF6740),

  /// Kitsu — independent anime and manga catalog.
  kitsu('Kitsu', 0xFFF75239),

  /// OpenLibrary — global open book catalog (~40M works, CC0/ODbL).
  openLibrary('OpenLibrary', 0xFF9B6A4F),

  /// Fantlab — community book catalog with detailed metadata.
  fantlab('Fantlab', 0xFFC5302E),

  /// ComicVine — comics / graphic novels catalog (volumes + issues). Feeds the
  /// `book` media type with `BookKind.comic` records.
  comicVine('ComicVine', 0xFFF26522),

  /// Google Books — global book catalog (millions of editions, public search).
  /// Feeds the `book` media type with `BookKind.book` records.
  googleBooks('Google Books', 0xFF4285F4),

  /// Hardcover — community book catalog (books, series, moods, ratings).
  /// Feeds the `book` media type; graphic novels map to `BookKind.comic`.
  hardcover('Hardcover', 0xFF6366F1),

  /// Local source (custom items).
  local('Custom', 0xFF26A69A);

  const DataSource(this.label, this.colorValue, {String? brandName})
      : _brandName = brandName;

  /// Short display label (badges, chips).
  final String label;

  final String? _brandName;

  /// Full brand name for attribution; equals [label] unless the badge uses an
  /// abbreviation (SGDB / SteamGridDB).
  String get brandName => _brandName ?? label;

  /// Brand color of the source as an ARGB int.
  final int colorValue;

  /// Canonical provider key, derived from [name] so nothing needs syncing
  /// (`comicVine` → `comicvine`).
  String get key => name.toLowerCase();

  /// Falls back to [DataSource.anilist] for null / unknown — the manga cache
  /// was AniList-only before v44.
  static DataSource fromName(String? name) =>
      fromNameOr(name, DataSource.anilist);

  /// Parses a stored name with an explicit [fallback] for null and unknown
  /// values.
  static DataSource fromNameOr(String? name, DataSource fallback) =>
      tryFromName(name) ?? fallback;

  /// Parses a stored name, or null when it is absent or not a known source.
  static DataSource? tryFromName(String? name) {
    if (name == null) return null;
    for (final DataSource s in DataSource.values) {
      if (s.name == name) return s;
    }
    return null;
  }
}
