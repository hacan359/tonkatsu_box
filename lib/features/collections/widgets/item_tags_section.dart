import 'package:core/models/tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../providers/global_tags_provider.dart';
import '../providers/item_tags_provider.dart';
import 'tag_picker_dialog.dart';

/// The item's tag chips; tapping any of them (or the empty placeholder)
/// opens the multi-select picker over the global tag set.
///
/// When editable, chips can be dragged into a manual per-item order
/// (immediate drag on desktop, long-press drag on mobile). Dropping on a
/// chip moves the dragged one past it in the direction of travel.
class ItemTagsSection extends ConsumerWidget {
  const ItemTagsSection({
    required this.itemId,
    required this.isEditable,
    super.key,
  });

  final int itemId;

  final bool isEditable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final List<Tag> allTags =
        ref.watch(globalTagsProvider).valueOrNull ?? <Tag>[];
    final List<Tag> itemTags = allTags
        .orderedFor(ref.watch(itemTagsProvider).valueOrNull?[itemId]);

    if (itemTags.isEmpty && !isEditable) return const SizedBox.shrink();

    final bool canReorder = isEditable && itemTags.length > 1;
    final Widget content = Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        if (itemTags.isEmpty)
          _buildChip(
            label: l.tagNone,
            icon: Icons.label_outlined,
          )
        else
          for (int i = 0; i < itemTags.length; i++)
            if (canReorder)
              _buildDraggableChip(ref, itemTags, i)
            else
              _buildTagChip(itemTags[i]),
      ],
    );

    if (!isEditable) return content;

    return GestureDetector(
      onTap: () => _editTags(context, ref),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: content,
      ),
    );
  }

  Widget _buildDraggableChip(WidgetRef ref, List<Tag> itemTags, int index) {
    final Tag tag = itemTags[index];
    final Widget chip = _buildTagChip(tag);
    final Widget feedback = Material(
      color: Colors.transparent,
      child: _buildTagChip(tag),
    );
    final Widget childWhenDragging = Opacity(opacity: 0.35, child: chip);

    final Widget target = DragTarget<_TagDragData>(
      onWillAcceptWithDetails: (DragTargetDetails<_TagDragData> d) =>
          d.data.itemId == itemId && d.data.tagId != tag.id,
      onAcceptWithDetails: (DragTargetDetails<_TagDragData> d) =>
          _reorder(ref, itemTags, d.data.tagId, index),
      builder: (
        BuildContext context,
        List<_TagDragData?> candidates,
        List<dynamic> rejected,
      ) =>
          candidates.isEmpty ? chip : _buildTagChip(tag, highlighted: true),
    );

    final _TagDragData data = _TagDragData(itemId: itemId, tagId: tag.id);
    // Tap-drag conflicts with scrolling on mobile — require long-press there.
    if (kIsMobile) {
      return LongPressDraggable<_TagDragData>(
        data: data,
        feedback: feedback,
        childWhenDragging: childWhenDragging,
        child: target,
      );
    }
    return Draggable<_TagDragData>(
      data: data,
      feedback: feedback,
      childWhenDragging: childWhenDragging,
      child: target,
    );
  }

  Future<void> _reorder(
    WidgetRef ref,
    List<Tag> itemTags,
    int draggedId,
    int targetIndex,
  ) async {
    final List<int> ids = itemTags.map((Tag t) => t.id).toList();
    final int oldIndex = ids.indexOf(draggedId);
    if (oldIndex < 0 || oldIndex == targetIndex) return;
    ids.removeAt(oldIndex);
    ids.insert(targetIndex, draggedId);
    await ref.read(itemTagsProvider.notifier).reorderItemTags(itemId, ids);
  }

  Widget _buildTagChip(Tag tag, {bool highlighted = false}) {
    return _buildChip(
      label: tag.name,
      accent: tag.color != null ? Color(tag.color!) : AppColors.brand,
      textColor: tag.textColor != null ? Color(tag.textColor!) : null,
      highlighted: highlighted,
    );
  }

  Widget _buildChip({
    required String label,
    IconData? icon,
    Color? accent,
    Color? textColor,
    bool highlighted = false,
  }) {
    final Color labelColor =
        textColor ?? accent ?? AppColors.textTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: accent != null ? accent.withAlpha(30) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        border: Border.all(
          color: highlighted
              ? AppColors.brand
              : accent != null
                  ? accent.withAlpha(80)
                  : AppColors.surfaceBorder,
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12, color: labelColor),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editTags(BuildContext context, WidgetRef ref) async {
    final Set<int> current = Set<int>.of(
        ref.read(itemTagsProvider).valueOrNull?[itemId] ?? const <int>[]);
    final Set<int>? selected =
        await TagPickerDialog.show(context, initialSelection: current);
    if (selected == null) return;
    await ref.read(itemTagsProvider.notifier).setItemTags(itemId, selected);
  }
}

/// Drag payload scoped to one item's tag chips, so a chip can't be dropped
/// onto another item's section (or any other int-typed drag target).
class _TagDragData {
  const _TagDragData({required this.itemId, required this.tagId});

  final int itemId;
  final int tagId;
}
