import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/collection_tag.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_durations.dart';
import '../../../shared/theme/app_typography.dart';

/// Supports multi-select: a click toggles a tag, "All" clears everything.
class TagSidebar extends StatelessWidget {
  const TagSidebar({
    required this.tags,
    required this.onTagToggled,
    required this.onGroupToggled,
    this.selectedTagIds = const <int>{},
    this.groupByTags = false,
    super.key,
  });

  final List<CollectionTag> tags;

  /// Empty set means "show everything".
  final Set<int> selectedTagIds;

  final bool groupByTags;

  /// Called with `null` to reset all filters.
  final ValueChanged<int?> onTagToggled;

  final VoidCallback onGroupToggled;

  static const double width = 32.0;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return Container(
      width: width,
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: AppColors.surfaceBorder, width: 0.5),
        ),
      ),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 8),
          _TagTab(
            label: S.of(context).tagSidebarGroup,
            color: AppColors.brand,
            isSelected: groupByTags,
            onTap: onGroupToggled,
          ),
          const SizedBox(height: 4),
          Container(
            width: 20,
            height: 1,
            color: AppColors.surfaceBorder,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: tags.length,
              separatorBuilder: (_, _) => const SizedBox(height: 2),
              itemBuilder: (BuildContext context, int index) {
                final CollectionTag tag = tags[index];
                final Color tagColor = tag.color != null
                    ? Color(tag.color!)
                    : AppColors.textSecondary;
                return _TagTab(
                  label: tag.name,
                  color: tagColor,
                  isSelected: selectedTagIds.contains(tag.id),
                  onTap: () => onTagToggled(tag.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TagTab extends StatefulWidget {
  const _TagTab({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_TagTab> createState() => _TagTabState();
}

class _TagTabState extends State<_TagTab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.isSelected;
    final Color color = widget.color;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: widget.label,
          waitDuration: const Duration(milliseconds: 400),
          child: AnimatedContainer(
            duration: AppDurations.fast,
            width: TagSidebar.width,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: active
                  ? color.withAlpha(30)
                  : _hovered
                      ? color.withAlpha(15)
                      : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: active ? color : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Center(
              child: RotatedBox(
                quarterTurns: 1,
                child: Text(
                  widget.label,
                  style: AppTypography.caption.copyWith(
                    color: active || _hovered
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                    fontSize: 9,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
