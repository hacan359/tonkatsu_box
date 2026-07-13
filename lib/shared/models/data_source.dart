// External data provider (IGDB, TMDB, SteamGridDB, VGMaps, ...).

import 'package:flutter/material.dart';

import '../theme/app_assets.dart';

/// External data provider.
enum DataSource {
  /// IGDB — game database.
  igdb('IGDB', Color(0xFF9147FF), AppAssets.iconIgdbColor),

  /// TMDB — movie and TV database.
  tmdb('TMDB', Color(0xFF01D277), AppAssets.iconTmdbColor),

  /// SteamGridDB — Steam artwork.
  steamGridDb('SGDB', Color(0xFF3A9BDC), AppAssets.iconSteamGridDbColor),

  /// VGMaps — video game maps.
  vgMaps('VGMaps', Color(0xFFE57C23), null),

  /// VNDB — visual novel database.
  vndb('VNDB', Color(0xFF2A5FC1), AppAssets.iconVndbColor),

  /// AniList — anime and manga database.
  anilist('AniList', Color(0xFF3DB4F2), AppAssets.iconAnilistColor),

  /// MangaBaka — open catalog of manga / manhwa / manhua / light novels.
  mangabaka('MangaBaka', Color(0xFFE5484D), AppAssets.iconMangaBakaColor),

  /// OpenLibrary — global open book catalog (~40M works, CC0/ODbL).
  openLibrary('OpenLibrary', Color(0xFF9B6A4F), AppAssets.iconOpenLibraryColor),

  /// Fantlab — community book catalog with detailed metadata.
  fantlab('Fantlab', Color(0xFFC5302E), AppAssets.iconFantlabColor),

  /// ComicVine — comics / graphic novels catalog (volumes + issues). Feeds the
  /// `book` media type with `BookKind.comic` records.
  comicVine('ComicVine', Color(0xFFF26522), AppAssets.iconComicVineColor),

  /// Google Books — global book catalog (millions of editions, public search).
  /// Feeds the `book` media type with `BookKind.book` records.
  googleBooks(
    'Google Books',
    Color(0xFF4285F4),
    AppAssets.iconGoogleBooksColor,
  ),

  /// Hardcover — community book catalog (books, series, moods, ratings).
  /// Feeds the `book` media type; graphic novels map to `BookKind.comic`.
  hardcover('Hardcover', Color(0xFF6366F1), AppAssets.iconHardcoverColor),

  /// Local source (custom items).
  local('Custom', Color(0xFF26A69A), null);

  const DataSource(this.label, this.color, this.iconAsset);

  /// Short display label.
  final String label;

  /// Brand color of the source.
  final Color color;

  /// Path to the color PNG logo (null when there is no brand asset).
  final String? iconAsset;

  /// Parses a [DataSource] from its stored name (the `source` column in DB /
  /// export). Returns [DataSource.anilist] for null and unknown values — the
  /// safe manga default, since the manga cache was AniList-only before v44.
  static DataSource fromName(String? name) {
    if (name == null) return DataSource.anilist;
    for (final DataSource s in DataSource.values) {
      if (s.name == name) return s;
    }
    return DataSource.anilist;
  }
}
