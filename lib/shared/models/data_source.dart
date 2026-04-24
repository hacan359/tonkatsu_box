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

  /// Локальный источник (кастомные элементы).
  local('Custom', Color(0xFF26A69A), null);

  const DataSource(this.label, this.color, this.iconAsset);

  /// Короткая метка для отображения.
  final String label;

  /// Фирменный цвет источника.
  final Color color;

  /// Путь к цветному PNG-логотипу (null если нет брендового ассета).
  final String? iconAsset;
}
