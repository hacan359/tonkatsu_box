import 'package:core/models/tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/widgets/color_picker_dialog.dart';
import '../providers/global_tags_provider.dart';
import '../providers/item_tags_provider.dart';
import 'tag_row.dart';
import 'tag_search_list.dart';

/// Manager over the global tag set: drag reorder plus everything a [TagRow]
/// carries; search, quick-create and sorting come from [TagSearchList].
class TagManagementDialog extends ConsumerStatefulWidget {
  const TagManagementDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) => const TagManagementDialog(),
    );
  }

  @override
  ConsumerState<TagManagementDialog> createState() =>
      _TagManagementDialogState();
}

class _TagManagementDialogState extends ConsumerState<TagManagementDialog> {
  Color? _selectedColor;

  Future<void> _createTag(String name) async {
    await ref
        .read(globalTagsProvider.notifier)
        .resolveOrCreate(name, color: _selectedColor?.toARGB32());
    if (!mounted) return;
    setState(() => _selectedColor = null);
  }

  Future<void> _pickNewTagColor() async {
    final Color? picked = await ColorPickerDialog.show(
      context: context,
      currentColor: _selectedColor,
      allowNoColor: true,
    );
    if (picked == null) return;
    setState(() {
      _selectedColor =
          picked == ColorPickerDialog.noColorSentinel ? null : picked;
    });
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final Map<int, int> usage = ref.watch(tagUsageCountsProvider);

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        0,
      ),
      title: Text(l.tagManage),
      content: SizedBox(
        width: 400,
        child: TagSearchList(
          leading: TagColorDot(
            color: _selectedColor,
            size: 24,
            onTap: _pickNewTagColor,
          ),
          onCreate: _createTag,
          onReorder: (List<int> orderedIds) =>
              ref.read(globalTagsProvider.notifier).reorder(orderedIds),
          rowBuilder: (Tag tag, int index, bool reorderable) => TagRow(
            key: ValueKey<int>(tag.id),
            tag: tag,
            usageCount: usage[tag.id] ?? 0,
            leading: reorderable
                ? ReorderableDragStartListener(
                    index: index,
                    child: Icon(
                      Icons.drag_indicator,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                  )
                : null,
            onColorTap: () => TagEditActions.changeColor(context, ref, tag),
            onTextColorTap: () =>
                TagEditActions.changeTextColor(context, ref, tag),
            onRename: () => TagEditActions.rename(context, ref, tag),
            onDelete: () => TagEditActions.delete(context, ref, tag),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.close),
        ),
      ],
    );
  }
}
