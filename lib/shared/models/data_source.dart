// Внешний источник данных (IGDB, TMDB, SteamGridDB, VGMaps).

import 'package:flutter/material.dart';

/// Внешний источник данных.
enum DataSource {
  /// IGDB — база данных игр.
  igdb('IGDB', Color(0xFF9147FF)),

  /// TMDB — база данных фильмов и сериалов.
  tmdb('TMDB', Color(0xFF01D277)),

  /// SteamGridDB — изображения из Steam.
  steamGridDb('SGDB', Color(0xFF3A9BDC)),

  /// VGMaps — карты из видеоигр.
  vgMaps('VGMaps', Color(0xFFE57C23));

  const DataSource(this.label, this.color);

  /// Короткая метка для отображения.
  final String label;

  /// Фирменный цвет источника.
  final Color color;
}
