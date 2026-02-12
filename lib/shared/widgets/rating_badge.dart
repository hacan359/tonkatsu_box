// Бейдж рейтинга с цветовой индикацией.

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Цветной бейдж рейтинга.
///
/// Отображает числовой рейтинг с цветом фона:
/// - >= 8.0 — зелёный ([AppColors.ratingHigh])
/// - >= 6.0 — жёлтый ([AppColors.ratingMedium])
/// - < 6.0 — красный ([AppColors.ratingLow])
class RatingBadge extends StatelessWidget {
  /// Создаёт бейдж рейтинга.
  const RatingBadge({
    required this.rating,
    super.key,
  });

  /// Числовой рейтинг (0.0–10.0).
  final double rating;

  /// Возвращает цвет фона на основе рейтинга.
  static Color colorForRating(double rating) {
    if (rating >= 8.0) return AppColors.ratingHigh;
    if (rating >= 6.0) return AppColors.ratingMedium;
    return AppColors.ratingLow;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorForRating(rating),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        rating.toStringAsFixed(1),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
      ),
    );
  }
}
