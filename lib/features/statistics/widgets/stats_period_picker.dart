import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../models/library_stats.dart';

/// What the picker offers and does. Assembled by the screen, which owns the
/// provider, so the pages can place it without reaching for `ref`.
@immutable
class StatsPeriodPickerData {
  /// Creates the payload.
  const StatsPeriodPickerData({
    required this.periods,
    required this.selected,
    required this.onChanged,
    this.trailing,
  });

  /// Selectable periods, "all time" first.
  final List<StatsPeriod> periods;

  /// The active period.
  final StatsPeriod selected;

  /// Called with the chosen period.
  final ValueChanged<StatsPeriod> onChanged;

  /// Optional action shown beside the picker (the share button).
  final Widget? trailing;
}

/// Period selector: a dropdown in the hero across from the headline. A tab
/// row cost a whole band of the page and grew with every year in the library.
class StatsPeriodPicker extends StatelessWidget {
  /// Creates the picker.
  const StatsPeriodPicker({required this.data, super.key});

  /// What to render.
  final StatsPeriodPickerData data;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final Widget? trailing = data.trailing;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        PopupMenuButton<StatsPeriod>(
          onSelected: data.onChanged,
          initialValue: data.selected,
          offset: const Offset(0, 40),
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<StatsPeriod>>[
            for (final StatsPeriod period in data.periods)
              PopupMenuItem<StatsPeriod>(
                value: period,
                height: 36,
                child: Text(
                  _labelFor(l, period),
                  style: AppTypography.body.copyWith(
                    color: period == data.selected
                        ? AppColors.brand
                        : AppColors.textPrimary,
                    fontWeight: period == data.selected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + AppSpacing.xs,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  _labelFor(l, data.selected),
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (trailing != null) ...<Widget>[
          const SizedBox(width: AppSpacing.xs),
          trailing,
        ],
      ],
    );
  }
}

String _labelFor(S l, StatsPeriod period) {
  final int? year = period.year;
  return year != null ? '$year' : l.statsPeriodAllTime;
}
