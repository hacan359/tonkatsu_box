// Виджет кликабельных звёзд для пользовательского рейтинга (1-10).

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Кликабельная панель звёзд для установки рейтинга (1-10).
///
/// Отображает 10 звёзд в ряд. Заполненные — до выбранного значения,
/// пустые — после. Повторный клик на текущий рейтинг сбрасывает его.
class StarRatingBar extends StatelessWidget {
  /// Создаёт [StarRatingBar].
  const StarRatingBar({
    required this.onChanged,
    this.rating,
    this.starSize = 28.0,
    super.key,
  });

  /// Текущий рейтинг (1-10, null если не установлен).
  final int? rating;

  /// Размер одной звезды.
  final double starSize;

  /// Колбэк при изменении рейтинга. Передаёт null при сбросе.
  final ValueChanged<int?> onChanged;

  /// Максимальное количество звёзд.
  static const int maxStars = 10;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 1; i <= maxStars; i++)
          _StarButton(
            index: i,
            filled: rating != null && i <= rating!,
            size: starSize,
            onTap: () => onChanged(i == rating ? null : i),
          ),
      ],
    );
  }
}

class _StarButton extends StatelessWidget {
  const _StarButton({
    required this.index,
    required this.filled,
    required this.size,
    required this.onTap,
  });

  final int index;
  final bool filled;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Icon(
          filled ? Icons.star : Icons.star_border,
          size: size,
          color: filled ? AppColors.ratingStar : AppColors.textTertiary,
        ),
      ),
    );
  }
}
