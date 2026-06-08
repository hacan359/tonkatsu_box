// Внешний источник данных (IGDB, TMDB, SteamGridDB, VGMaps).

import 'package:flutter/material.dart';

import '../theme/app_assets.dart';

/// Внешний источник данных.
enum DataSource {
  /// IGDB — база данных игр.
  igdb('IGDB', Color(0xFF9147FF), AppAssets.iconIgdbColor),

  /// TMDB — база данных фильмов и сериалов.
  tmdb('TMDB', Color(0xFF01D277), AppAssets.iconTmdbColor),

  /// SteamGridDB — изображения из Steam.
  steamGridDb('SGDB', Color(0xFF3A9BDC), AppAssets.iconSteamGridDbColor),

  /// VGMaps — карты из видеоигр.
  vgMaps('VGMaps', Color(0xFFE57C23), null),

  /// VNDB — база данных визуальных новелл.
  vndb('VNDB', Color(0xFF2A5FC1), AppAssets.iconVndbColor),

  /// AniList — база данных манги и аниме.
  anilist('AniList', Color(0xFF3DB4F2), AppAssets.iconAnilistColor),

  /// MangaBaka — open catalog of manga / manhwa / manhua / light novels.
  mangabaka('MangaBaka', Color(0xFFE5484D), AppAssets.iconMangaBakaColor),

  /// OpenLibrary — global open book catalog (~40M works, CC0/ODbL).
  openLibrary('OpenLibrary', Color(0xFF9B6A4F), AppAssets.iconOpenLibraryColor),

  /// Fantlab — Russian book catalog, strong on science fiction & fantasy.
  fantlab('Fantlab', Color(0xFFC5302E), null),

  /// Локальный источник (кастомные элементы).
  local('Custom', Color(0xFF26A69A), null);

  const DataSource(this.label, this.color, this.iconAsset);

  /// Короткая метка для отображения.
  final String label;

  /// Фирменный цвет источника.
  final Color color;

  /// Путь к цветному PNG-логотипу (null если нет брендового ассета).
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
