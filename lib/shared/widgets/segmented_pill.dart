import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// One option of a [SegmentedPill].
class SegmentedPillOption<T> {
  const SegmentedPillOption({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
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
    this.selectedColor = AppColors.brand,
    this.expand = false,
    super.key,
  });

  final List<SegmentedPillOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final Color selectedColor;

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
                  selectedColor: selectedColor,
                  expand: true,
                  onTap: () => onChanged(o.value),
                ),
              )
            else
              _Segment<T>(
                option: o,
                isSelected: o.value == selected,
                selectedColor: selectedColor,
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
    final Color fg = isSelected ? selectedColor : AppColors.textTertiary;
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
          color: isSelected ? selectedColor.withAlpha(48) : Colors.transparent,
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
