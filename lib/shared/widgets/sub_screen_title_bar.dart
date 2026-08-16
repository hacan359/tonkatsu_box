import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Stands in for [AppBar] inside a tab Navigator, where a real app bar would
/// sit above the wrong route.
class SubScreenTitleBar extends StatelessWidget {
  const SubScreenTitleBar({
    required this.title,
    this.onBack,
    super.key,
  });

  final String title;

  /// Defaults to `Navigator.of(context).pop()`.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder, width: 0.5),
        ),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            color: AppColors.textTertiary,
            visualDensity: VisualDensity.compact,
            onPressed: onBack ?? () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
