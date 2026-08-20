import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class MediaProgressRow extends StatelessWidget {
  const MediaProgressRow({
    required this.label,
    required this.current,
    required this.total,
    required this.accentColor,
    required this.onIncrement,
    required this.onEdit,
    super.key,
  });

  final String label;

  final int current;

  /// null when the total is unknown.
  final int? total;

  final Color accentColor;

  final VoidCallback onIncrement;

  /// Tapping the value opens the manual editor.
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final String progressText =
        total != null ? '$current / $total' : '$current';
    final double? progressValue =
        total != null && total! > 0 ? current / total! : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                child: Text(
                  progressText,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            SizedBox(
              width: 28,
              height: 28,
              child: IconButton(
                onPressed: onIncrement,
                icon: const Icon(Icons.add, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                style: IconButton.styleFrom(
                  foregroundColor: accentColor,
                ),
              ),
            ),
          ],
        ),
        if (progressValue != null) ...<Widget>[
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            child: LinearProgressIndicator(
              value: progressValue.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
        ],
      ],
    );
  }
}
