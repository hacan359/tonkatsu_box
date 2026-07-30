import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

/// Section title with an optional dimmed hint on the same baseline.
class StatsSectionHeader extends StatelessWidget {
  /// Creates a section header.
  const StatsSectionHeader({required this.title, this.hint, super.key});

  /// Section title.
  final String title;

  /// Dimmed explanation shown after the title.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: AppSpacing.sm,
        children: <Widget>[
          Text(title, style: AppTypography.h2),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                hint!,
                style: AppTypography.caption
                    .copyWith(color: AppColors.textTertiary),
              ),
            ),
        ],
      ),
    );
  }
}
