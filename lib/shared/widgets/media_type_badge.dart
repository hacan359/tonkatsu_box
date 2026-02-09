// Бейдж типа медиа для карточек.

import 'package:flutter/material.dart';

import '../constants/media_type_theme.dart';
import '../models/media_type.dart';

/// Компактный бейдж с иконкой и цветом типа медиа.
///
/// Отображается в углу карточки для визуальной идентификации типа.
class MediaTypeBadge extends StatelessWidget {
  /// Создаёт [MediaTypeBadge].
  const MediaTypeBadge({
    required this.mediaType,
    this.size = 20,
    this.iconSize = 12,
    super.key,
  });

  /// Тип медиа для отображения.
  final MediaType mediaType;

  /// Размер контейнера бейджа.
  final double size;

  /// Размер иконки внутри бейджа.
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final Color color = MediaTypeTheme.colorFor(mediaType);
    final IconData icon = MediaTypeTheme.iconFor(mediaType);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: Colors.white,
      ),
    );
  }
}
