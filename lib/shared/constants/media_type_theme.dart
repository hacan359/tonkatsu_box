// Цветовые темы и иконки для типов медиа.

import 'package:flutter/material.dart';

import '../models/media_type.dart';

/// Цвета и иконки для визуального разделения типов медиа.
///
/// 🎮 Игры — синий, 🎬 Фильмы — красный, 📺 Сериалы — зелёный.
abstract final class MediaTypeTheme {
  /// Цвет для игр (синий).
  static const Color gameColor = Color(0xFF2196F3);

  /// Цвет для фильмов (красный).
  static const Color movieColor = Color(0xFFF44336);

  /// Цвет для сериалов (зелёный).
  static const Color tvShowColor = Color(0xFF4CAF50);

  /// Возвращает иконку для типа медиа.
  static IconData iconFor(MediaType type) => switch (type) {
        MediaType.game => Icons.videogame_asset,
        MediaType.movie => Icons.movie,
        MediaType.tvShow => Icons.tv,
      };

  /// Возвращает цвет для типа медиа.
  static Color colorFor(MediaType type) => switch (type) {
        MediaType.game => gameColor,
        MediaType.movie => movieColor,
        MediaType.tvShow => tvShowColor,
      };
}
