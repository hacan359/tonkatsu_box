// Бейдж с числовым рейтингом.

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Компактный бейдж с числовым рейтингом.
///
/// Цвет фона зависит от значения:
/// - >= 0.75 — зелёный ([AppColors.success])
/// - >= 0.50 — жёлтый ([AppColors.warning])
/// - < 0.50 — красный ([AppColors.error])
///
/// [normalizedRating] — рейтинг от 0.0 до 1.0 (например, 85/100 = 0.85).
/// Отображает значение как целое число от 0 до 100.
class RatingBadge extends StatelessWidget {
  /// Создаёт [RatingBadge].
  const RatingBadge({
    required this.normalizedRating,
    super.key,
  });

  /// Рейтинг от 0.0 до 1.0.
  final double normalizedRating;

  /// Порог для «хорошего» рейтинга (зелёный).
  static const double _goodThreshold = 0.75;

  /// Порог для «среднего» рейтинга (жёлтый).
  static const double _averageThreshold = 0.50;

  @override
  Widget build(BuildContext context) {
    final Color color = _colorForRating(normalizedRating);
    final int displayValue = (normalizedRating * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        '$displayValue',
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Возвращает цвет в зависимости от рейтинга.
  static Color _colorForRating(double rating) {
    if (rating >= _goodThreshold) return AppColors.success;
    if (rating >= _averageThreshold) return AppColors.warning;
    return AppColors.error;
  }
}
