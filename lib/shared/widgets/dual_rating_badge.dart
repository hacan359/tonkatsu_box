import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Renders nothing when neither rating is set — the caller does not hide it.
/// [compact] shrinks for landscape; [inline] drops the background for lists.
/// [scale] grows the badge with the card it sits on.
class DualRatingBadge extends StatelessWidget {
  const DualRatingBadge({
    this.userRating,
    this.apiRating,
    this.compact = false,
    this.inline = false,
    this.scale = 1.0,
    super.key,
  });

  /// Personal rating, 1.0–10.0 (step 0.1).
  final double? userRating;

  /// Normalized API rating, 0.0–10.0.
  final double? apiRating;

  final bool compact;
  final bool inline;
  final double scale;

  bool get hasRating => userRating != null || _hasApiRating;

  bool get _hasApiRating => apiRating != null && apiRating! > 0;

  String get formattedRating {
    final bool hasUser = userRating != null;
    final bool hasApi = _hasApiRating;

    if (hasUser && hasApi) {
      return '${userRating!.toStringAsFixed(1)} / ${apiRating!.toStringAsFixed(1)}';
    }
    if (hasUser) {
      return userRating!.toStringAsFixed(1);
    }
    if (hasApi) {
      return apiRating!.toStringAsFixed(1);
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (!hasRating) return const SizedBox.shrink();

    if (inline) {
      return _buildInline();
    }
    return _buildBadge();
  }

  Widget _buildBadge() {
    final double fontSize = (compact ? 8.0 : 11.0) * scale;
    final double iconSize = (compact ? 8.0 : 11.0) * scale;
    final double hPad = (compact ? 3.0 : 5.0) * scale;
    final double vPad = (compact ? 1.0 : 2.0) * scale;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: AppColors.scrim.withAlpha(0xCC),
        borderRadius: BorderRadius.circular((compact ? 4 : 6) * scale),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.star,
            size: iconSize,
            color: AppColors.ratingStar,
          ),
          SizedBox(width: (compact ? 1 : 2) * scale),
          Text(
            formattedRating,
            style: TextStyle(
              color: AppColors.onOverlay,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInline() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          Icons.star,
          size: 14,
          color: AppColors.ratingStar,
        ),
        const SizedBox(width: 2),
        Text(
          formattedRating,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
