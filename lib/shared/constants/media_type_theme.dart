// Цветовые темы и иконки для типов медиа.

import 'package:flutter/material.dart';

import '../models/media_type.dart';
import '../theme/app_colors.dart';

/// Цвета и иконки для визуального разделения типов медиа.
///
/// 🎮 Игры — индиго, 🎬 Фильмы — оранжевый, 📺 Сериалы — лаймовый,
/// 🎞️ Анимация — пурпурный.
abstract final class MediaTypeTheme {
  /// Цвет для игр.
  static const Color gameColor = AppColors.gameAccent;

  /// Цвет для фильмов.
  static const Color movieColor = AppColors.movieAccent;

  /// Цвет для сериалов.
  static const Color tvShowColor = AppColors.tvShowAccent;

  /// Цвет для анимации.
  static const Color animationColor = AppColors.animationAccent;

  /// Цвет для визуальных новелл.
  static const Color visualNovelColor = AppColors.visualNovelAccent;

  /// Возвращает иконку для типа медиа.
  static IconData iconFor(MediaType type) => switch (type) {
        MediaType.game => Icons.videogame_asset,
        MediaType.movie => Icons.movie,
        MediaType.tvShow => Icons.tv,
        MediaType.animation => Icons.animation,
        MediaType.visualNovel => Icons.menu_book,
      };

  /// Возвращает цвет для типа медиа.
  static Color colorFor(MediaType type) => switch (type) {
        MediaType.game => gameColor,
        MediaType.movie => movieColor,
        MediaType.tvShow => tvShowColor,
        MediaType.animation => animationColor,
        MediaType.visualNovel => visualNovelColor,
      };
}
