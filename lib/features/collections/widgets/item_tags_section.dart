import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/tag.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../providers/global_tags_provider.dart';
import '../providers/item_tags_provider.dart';
import 'tag_picker_dialog.dart';

/// The item's tag chips; tapping any of them (or the empty placeholder)
/// opens the multi-select picker over the global tag set.
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
          for (final Tag tag in itemTags)
            _buildChip(
              label: tag.name,
              accent: tag.color != null ? Color(tag.color!) : AppColors.brand,
              textColor:
                  tag.textColor != null ? Color(tag.textColor!) : null,
            ),
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

  Widget _buildChip({
    required String label,
    IconData? icon,
    Color? accent,
    Color? textColor,
  }) {
    final Color labelColor =
        textColor ?? accent ?? AppColors.textTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: accent != null ? accent.withAlpha(30) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        border: Border.all(
          color: accent != null
              ? accent.withAlpha(80)
              : AppColors.surfaceBorder,
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
    final Set<int> current =
        ref.read(itemTagsProvider).valueOrNull?[itemId] ?? <int>{};
    final Set<int>? selected =
        await TagPickerDialog.show(context, initialSelection: current);
    if (selected == null) return;
    await ref.read(itemTagsProvider.notifier).setItemTags(itemId, selected);
  }
}
