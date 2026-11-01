import 'package:flutter/material.dart';

import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/app_typography.dart';
import '../../../../../shared/widgets/rating_popup.dart';

class RatingCell extends StatelessWidget {
  const RatingCell({
    required this.rating,
    this.onRatingChanged,
    super.key,
  });

  final double? rating;
  final ValueChanged<double?>? onRatingChanged;

  @override
  Widget build(BuildContext context) {
    final Widget content = rating == null
        ? Text(
            '—',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: AppColors.textTertiary,
              fontSize: 13,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.star_rounded,
                size: 14,
                color: AppColors.ratingStar,
              ),
              const SizedBox(width: 2),
              Text(
                rating!.toStringAsFixed(1),
                style: AppTypography.body.copyWith(
                  color: AppColors.ratingStar,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          );

    final ValueChanged<double?>? onChanged = onRatingChanged;
    if (onChanged == null) return content;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          showRatingPopup(context, initial: rating, onCommit: onChanged),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: content,
      ),
    );
  }
}
