import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/focusable_surface.dart';
import '../models/library_stats.dart';
import '../../../shared/widgets/glass_popup_menu.dart';

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
        // The fill lives under the button's ink; an opaque child used to
        // paint over the hover and focus highlight.
        FocusableSurface(
          child: GlassPopupMenuButton<StatsPeriod>(
            onSelected: data.onChanged,
            offset: const Offset(0, 40),
            rows: (BuildContext _) => <Widget>[
              for (final StatsPeriod period in data.periods)
                GlassMenuRow<StatsPeriod>(
                  value: period,
                  label: _labelFor(l, period),
                  checked: period == data.selected,
                ),
            ],
            // Padding inside the button, so the whole pill opens the menu.
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + AppSpacing.xs,
                vertical: AppSpacing.sm,
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
