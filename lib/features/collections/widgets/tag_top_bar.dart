import 'package:core/models/tag.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/scrollable_row_with_arrows.dart';

/// Wide-screen tag filter: one horizontal chip row above the items view.
/// Supports multi-select: a click toggles a tag, the reset chip clears all.
class TagTopBar extends StatefulWidget {
  const TagTopBar({
    required this.tags,
    required this.counts,
    required this.onTagToggled,
    required this.onGroupToggled,
    this.selectedTagIds = const <int>{},
    this.groupByTags = false,
    super.key,
  });

  final List<Tag> tags;

  /// Per-tag item counts within the current collection.
  final Map<int, int> counts;

  /// Empty set means "show everything".
  final Set<int> selectedTagIds;

  final bool groupByTags;

  /// Called with `null` to reset all filters.
  final ValueChanged<int?> onTagToggled;

  final VoidCallback onGroupToggled;

  static const double height = 38.0;

  @override
  State<TagTopBar> createState() => _TagTopBarState();
}

class _TagTopBarState extends State<TagTopBar> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: TagTopBar.height,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder, width: 0.5),
        ),
      ),
      // Same affordance as the genre-cloud legend row: edge-fade arrows on
      // desktop, wheel remap and touch/mouse drag come with the widget.
      child: ScrollableRowWithArrows(
        controller: _controller,
        height: TagTopBar.height,
        child: ListView(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 6,
          ),
          children: <Widget>[
            _TagBarChip(
              key: const ValueKey<String>('tagTopBarGroup'),
              label: S.of(context).tagSidebarGroup,
              icon: Icons.workspaces_outlined,
              color: AppColors.brand,
              selected: widget.groupByTags,
              onTap: widget.onGroupToggled,
            ),
            if (widget.selectedTagIds.isNotEmpty)
              _TagBarChip(
                key: const ValueKey<String>('tagTopBarReset'),
                label: '${widget.selectedTagIds.length}',
                icon: Icons.filter_alt_off_outlined,
                color: AppColors.textSecondary,
                selected: true,
                onTap: () => widget.onTagToggled(null),
              ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              width: 1,
              color: AppColors.surfaceBorder,
            ),
            for (final Tag tag in widget.tags)
              _TagBarChip(
                key: ValueKey<int>(tag.id),
                label: tag.name,
                count: widget.counts[tag.id] ?? 0,
                color: tag.color != null
                    ? Color(tag.color!)
                    : AppColors.textSecondary,
                labelColor: tag.textColor != null
                    ? Color(tag.textColor!)
                    : null,
                selected: widget.selectedTagIds.contains(tag.id),
                onTap: () => widget.onTagToggled(tag.id),
              ),
          ],
        ),
      ),
    );
  }
}

class _TagBarChip extends StatelessWidget {
  const _TagBarChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.labelColor,
    this.count,
    this.icon,
    super.key,
  });

  final String label;
  final Color color;
  final Color? labelColor;
  final int? count;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color textColor = selected
        ? AppColors.textPrimary
        : (labelColor ?? color);
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withAlpha(selected ? 70 : 20),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: color.withAlpha(selected ? 255 : 80),
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 12, color: textColor),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (count != null) ...<Widget>[
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 9,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
