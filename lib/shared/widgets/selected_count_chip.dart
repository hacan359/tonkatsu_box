import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Pinned at the leading edge of a scrollable chip row so an active selection
/// stays visible once the selected chips scroll away. Hide it at zero.
class SelectedCountChip extends StatelessWidget {
  const SelectedCountChip({
    required this.count,
    required this.onClear,
    required this.clearTooltip,
    this.accent,
    super.key,
  });

  /// How many chips are selected.
  final int count;

  /// Clears the whole selection.
  final VoidCallback onClear;

  /// Localized label for the tooltip and screen readers (e.g. "Clear selection").
  final String clearTooltip;

  /// Pill background; null falls back to the app brand accent.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: clearTooltip,
      child: Semantics(
        button: true,
        label: clearTooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: accent ?? AppColors.brand,
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.check,
                    size: 14,
                    color: AppColors.onBrand,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '$count',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.onBrand,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
