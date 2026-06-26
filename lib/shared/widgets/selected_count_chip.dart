import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Pinned, non-scrolling pill showing how many chips in a row are selected,
/// clearing the whole selection when tapped.
///
/// Meant to sit at the leading edge of a scrollable chip row so an active
/// selection stays visible even when the selected chips have scrolled out of
/// view — the case that is easy to miss on a phone, where there are no hover
/// arrows. Show it only when [count] is greater than zero.
class SelectedCountChip extends StatelessWidget {
  /// Creates a [SelectedCountChip].
  const SelectedCountChip({
    required this.count,
    required this.onClear,
    required this.clearTooltip,
    this.accent = AppColors.brand,
    super.key,
  });

  /// How many chips are selected.
  final int count;

  /// Clears the whole selection.
  final VoidCallback onClear;

  /// Localized label for the tooltip and screen readers (e.g. "Clear selection").
  final String clearTooltip;

  /// Pill background; defaults to the app brand accent.
  final Color accent;

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
                color: accent,
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.check,
                    size: 14,
                    color: AppColors.background,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '$count',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.background,
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
