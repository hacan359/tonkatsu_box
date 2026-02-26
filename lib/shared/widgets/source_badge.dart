// Бейдж источника данных (IGDB, TMDB, SteamGridDB, VGMaps).

import 'package:flutter/material.dart';

import '../models/data_source.dart';

export '../models/data_source.dart';

/// Компактный бейдж с названием и цветом источника данных.
///
/// Используется в карточках, экранах деталей и настройках
/// для обозначения откуда получены данные.
class SourceBadge extends StatelessWidget {
  /// Создаёт [SourceBadge].
  const SourceBadge({
    required this.source,
    this.size = SourceBadgeSize.small,
    super.key,
  });

  /// Источник данных.
  final DataSource source;

  /// Размер бейджа.
  final SourceBadgeSize size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size.horizontalPadding,
        vertical: size.verticalPadding,
      ),
      decoration: BoxDecoration(
        color: source.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size.borderRadius),
        border: Border.all(
          color: source.color.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Text(
        source.label,
        style: TextStyle(
          color: source.color,
          fontSize: size.fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          height: 1,
        ),
      ),
    );
  }
}

/// Размеры бейджа источника.
enum SourceBadgeSize {
  /// Маленький — для карточек в списке.
  small(fontSize: 8, horizontalPadding: 4, verticalPadding: 2, borderRadius: 3),

  /// Средний — для экранов деталей.
  medium(fontSize: 10, horizontalPadding: 6, verticalPadding: 3, borderRadius: 4),

  /// Большой — для настроек.
  large(fontSize: 12, horizontalPadding: 8, verticalPadding: 4, borderRadius: 6);

  const SourceBadgeSize({
    required this.fontSize,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.borderRadius,
  });

  /// Размер шрифта.
  final double fontSize;

  /// Горизонтальный отступ.
  final double horizontalPadding;

  /// Вертикальный отступ.
  final double verticalPadding;

  /// Радиус скругления.
  final double borderRadius;
}
