import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// One option of a [SegmentedPill].
class SegmentedPillOption<T> {
  const SegmentedPillOption({
    required this.value,
    required this.label,
    this.icon,
    this.color,
  });

  final T value;
  final String label;
  final IconData? icon;

  /// Per-option accent (e.g. a media-type color); overrides the pill's
  /// `selectedColor` and tints the label even when not selected.
  final Color? color;
}

/// Rounded "pill" segmented switcher matching the item-detail status row:
/// a soft tint of [selectedColor] on the active segment, the rest muted.
/// Segments size to their content (unlike the equal-width status row), so it
/// fits inside toolbars next to other widgets.
class SegmentedPill<T> extends StatelessWidget {
  const SegmentedPill({
    required this.options,
    required this.selected,
    required this.onChanged,
    this.selectedColor,
    this.expand = false,
    super.key,
  });

  final List<SegmentedPillOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Active-segment tint; null falls back to [AppColors.brand].
  final Color? selectedColor;

  /// When true, segments share the available width equally (for narrow,
  /// full-width containers like side panels). Otherwise they size to content.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: <Widget>[
          for (final SegmentedPillOption<T> o in options)
            if (expand)
              Expanded(
                child: _Segment<T>(
                  option: o,
                  isSelected: o.value == selected,
                  selectedColor: selectedColor ?? AppColors.brand,
                  expand: true,
                  onTap: () => onChanged(o.value),
                ),
              )
            else
              _Segment<T>(
                option: o,
                isSelected: o.value == selected,
                selectedColor: selectedColor ?? AppColors.brand,
                onTap: () => onChanged(o.value),
              ),
        ],
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.option,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
    this.expand = false,
  });

  final SegmentedPillOption<T> option;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final Color accent = option.color ?? selectedColor;
    final Color fg = isSelected
        ? accent
        : option.color?.withAlpha(150) ?? AppColors.textTertiary;
    final Widget label = Text(
      option.label,
      maxLines: 1,
      overflow: expand ? TextOverflow.ellipsis : TextOverflow.clip,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: fg,
      ),
    );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: 34,
        padding: EdgeInsets.symmetric(
          horizontal: expand ? AppSpacing.sm : AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected ? accent.withAlpha(48) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (option.icon != null) ...<Widget>[
              Icon(option.icon, size: 16, color: fg),
              const SizedBox(width: AppSpacing.xs),
            ],
            expand ? Flexible(child: label) : label,
          ],
        ),
      ),
    );
  }
}
