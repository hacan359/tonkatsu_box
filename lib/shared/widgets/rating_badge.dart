import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class RatingBadge extends StatelessWidget {
  const RatingBadge({
    required this.rating,
    this.compact = false,
    super.key,
  });

  /// Expected on a 0..10 scale.
  final double rating;

  final bool compact;

  static Color colorForRating(double rating) {
    if (rating >= 8.0) return AppColors.ratingHigh;
    if (rating >= 6.0) return AppColors.ratingMedium;
    return AppColors.ratingLow;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 3 : 6,
        vertical: compact ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: colorForRating(rating),
        borderRadius: BorderRadius.circular(compact ? 4 : 6),
      ),
      child: Text(
        rating.toStringAsFixed(1),
        style: TextStyle(
          color: AppColors.onOverlay,
          fontSize: compact ? 8 : 12,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
      ),
    );
  }
}
