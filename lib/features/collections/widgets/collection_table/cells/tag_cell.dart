import 'package:flutter/material.dart';

import '../../../../../shared/models/tag.dart';
import '../../../../../shared/theme/app_colors.dart';
import '../../../../../shared/theme/app_spacing.dart';
import '../../../../../shared/theme/app_typography.dart';

/// Chips of the item's tags; tapping the cell opens the multi-select picker.
class TagCell extends StatelessWidget {
  const TagCell({
    this.tags = const <Tag>[],
    this.onEditTags,
    super.key,
  });

  /// The item's tags in display order.
  final List<Tag> tags;

  /// Opens the tag picker for this item.
  final VoidCallback? onEditTags;

  /// How many chips fit before collapsing into "+N".
  static const int _maxChips = 2;

  @override
  Widget build(BuildContext context) {
    final List<Widget> chips = <Widget>[
      for (final Tag tag in tags.take(_maxChips)) _buildTagChip(tag),
      if (tags.length > _maxChips) _buildMoreChip(tags.length - _maxChips),
    ];
    final Widget content = chips.isEmpty
        ? const SizedBox.shrink()
        : Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs / 2,
              children: chips,
            ),
          );

    if (onEditTags == null) return content;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onEditTags,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: content,
      ),
    );
  }

  Widget _buildTagChip(Tag t) {
    final Color chipColor =
        t.color != null ? Color(t.color!) : AppColors.textSecondary;
    final Color labelColor =
        t.textColor != null ? Color(t.textColor!) : chipColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withAlpha(40),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: chipColor.withAlpha(110)),
      ),
      child: Text(
        t.name,
        style: AppTypography.caption.copyWith(
          color: labelColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildMoreChip(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.textTertiary.withAlpha(110)),
      ),
      child: Text(
        '+$count',
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
