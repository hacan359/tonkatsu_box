import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';

/// Centered placeholder for the Releases screen — used both for "no tracked
/// shows" and "all caught up".
class ReleasesEmptyState extends StatelessWidget {
  const ReleasesEmptyState({
    required this.title,
    this.hint,
    this.icon = Icons.notifications_none,
    super.key,
  });

  final String title;
  final String? hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 64, color: AppColors.textTertiary.withAlpha(120)),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (hint != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textTertiary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
