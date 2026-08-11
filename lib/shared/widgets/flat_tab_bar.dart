import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// One block of a [FlatTabBar].
@immutable
class FlatTabOption<T> {
  /// Creates an option.
  const FlatTabOption({required this.value, required this.label});

  /// Identifies the option; compared with the bar's `selected`.
  final T value;

  /// Block label.
  final String label;
}

/// Full-width switcher of flat blocks sharing one baseline. Unlike
/// `SegmentedPill`, it has no container, so it never reads as a stray widget.
class FlatTabBar<T> extends StatelessWidget {
  /// Creates the bar.
  const FlatTabBar({
    required this.options,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  /// Blocks to render, in order.
  final List<FlatTabOption<T>> options;

  /// The active option's value.
  final T selected;

  /// Called with the tapped value.
  final ValueChanged<T> onChanged;

  /// Bar height; also the touch-target height of one block.
  static const double _kHeight = 46;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kHeight,
      child: DecoratedBox(
        // Runs edge to edge, so the bar reads as a band of the page rather
        // than as a control sitting on it.
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.surfaceBorder, width: 0.5),
          ),
        ),
        child: Row(
          children: <Widget>[
            for (final FlatTabOption<T> option in options)
              Expanded(
                child: _TabBlock<T>(
                  option: option,
                  selected: option.value == selected,
                  onTap: () => onChanged(option.value),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabBlock<T> extends StatelessWidget {
  const _TabBlock({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final FlatTabOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        // Tight: equal parts already give the block its width, and generous
        // padding only brings the ellipsis closer.
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.brand.withAlpha(20) : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.brand : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          option.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.brand : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
