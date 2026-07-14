import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../fractional_star_rating.dart';

/// "My rating" header with the current value and a fractional star slider.
class UserRatingSection extends StatelessWidget {
  const UserRatingSection({
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// 1.0..10.0 (step 0.1), `null` when not rated.
  final double? value;
  final ValueChanged<double?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(Icons.star, size: 18, color: AppColors.ratingStar),
            const SizedBox(width: 6),
            Text(
              S.of(context).detailMyRating,
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.w600),
            ),
            if (value != null) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              Text(
                S.of(context).detailRatingValue(value!.toStringAsFixed(1)),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        FractionalStarRating(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
