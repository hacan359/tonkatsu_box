import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';

class UncategorizedBanner extends StatelessWidget {
  const UncategorizedBanner({required this.onMove, super.key});

  final VoidCallback onMove;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return Card(
      color: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        side: const BorderSide(color: AppColors.surfaceBorder),
      ),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.info_outline,
              color: AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l.uncategorizedBanner,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: onMove,
              child: Text(l.uncategorizedBannerAction),
            ),
          ],
        ),
      ),
    );
  }
}
