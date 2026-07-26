import '../theme/app_assets.dart';

/// External data provider.
enum DataSource {
  /// IGDB — game database.
  igdb('IGDB', 0xFF9147FF, AppAssets.iconIgdbColor),

  /// TMDB — movie and TV database.
  tmdb('TMDB', 0xFF01D277, AppAssets.iconTmdbColor),

  /// TVmaze — keyless TV series database with season / episode data.
  tvmaze('TVmaze', 0xFF3C5C8C, AppAssets.iconTvMazeColor),

  /// SteamGridDB — Steam artwork.
  steamGridDb('SGDB', 0xFF3A9BDC, AppAssets.iconSteamGridDbColor,
      brandName: 'SteamGridDB'),

  /// VGMaps — video game maps.
  vgMaps('VGMaps', 0xFFE57C23, null),

  /// VNDB — visual novel database.
  vndb('VNDB', 0xFF2A5FC1, AppAssets.iconVndbColor),

  /// AniList — anime and manga database.
  anilist('AniList', 0xFF3DB4F2, AppAssets.iconAnilistColor),

  /// MangaBaka — open catalog of manga / manhwa / manhua / light novels.
  mangabaka('MangaBaka', 0xFFE5484D, AppAssets.iconMangaBakaColor),

  /// MangaDex — large manga catalog with localized titles and chapter counts.
  mangadex('MangaDex', 0xFFFF6740, AppAssets.iconMangaDexColor),

  /// Kitsu — independent anime and manga catalog.
  kitsu('Kitsu', 0xFFF75239, AppAssets.iconKitsuColor),

  /// OpenLibrary — global open book catalog (~40M works, CC0/ODbL).
  openLibrary('OpenLibrary', 0xFF9B6A4F, AppAssets.iconOpenLibraryColor),

  /// Fantlab — community book catalog with detailed metadata.
  fantlab('Fantlab', 0xFFC5302E, AppAssets.iconFantlabColor),

  /// ComicVine — comics / graphic novels catalog (volumes + issues). Feeds the
  /// `book` media type with `BookKind.comic` records.
  comicVine('ComicVine', 0xFFF26522, AppAssets.iconComicVineColor),

  /// Google Books — global book catalog (millions of editions, public search).
  /// Feeds the `book` media type with `BookKind.book` records.
  googleBooks('Google Books', 0xFF4285F4, AppAssets.iconGoogleBooksColor),

  /// Hardcover — community book catalog (books, series, moods, ratings).
  /// Feeds the `book` media type; graphic novels map to `BookKind.comic`.
  hardcover('Hardcover', 0xFF6366F1, AppAssets.iconHardcoverColor),

  /// Local source (custom items).
  local('Custom', 0xFF26A69A, null);

  const DataSource(this.label, this.colorValue, this.iconAsset,
      {String? brandName})
      : _brandName = brandName;

  /// Short display label (badges, chips).
  final String label;

  final String? _brandName;

  /// Full brand name for attribution; equals [label] unless the badge uses an
  /// abbreviation (SGDB / SteamGridDB).
  String get brandName => _brandName ?? label;

  /// Brand color of the source as an ARGB int.
  final int colorValue;

  /// Path to the color PNG logo (null when there is no brand asset).
  final String? iconAsset;

  /// Canonical lowercase identifier — the single source for the provider
  /// "key" that used to be hardcoded as `groupId` literals and in the
  /// group→sources map. Derived from [name] so there is nothing to keep in
  /// sync (e.g. `comicVine` → `comicvine`, `googleBooks` → `googlebooks`).
  String get key => name.toLowerCase();

  /// Parses a [DataSource] from its stored name (the `source` column in DB /
  /// export). Returns [DataSource.anilist] for null and unknown values — the
  /// safe manga default, since the manga cache was AniList-only before v44.
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
