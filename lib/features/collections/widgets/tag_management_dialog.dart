import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/tag.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/color_picker_dialog.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../providers/global_tags_provider.dart';
import '../providers/item_tags_provider.dart';

/// Manager over the global tag set: create, rename, recolor (background and
/// label text), reorder by drag, delete. Shows per-tag usage counts.
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
  final TextEditingController _newTagController = TextEditingController();
  final FocusNode _newTagFocus = FocusNode();
  Color? _selectedColor;

  @override
  void dispose() {
    _newTagController.dispose();
    _newTagFocus.dispose();
    super.dispose();
  }

  Future<void> _createTag() async {
    final String name = _newTagController.text.trim();
    if (name.isEmpty) return;

    await ref
        .read(globalTagsProvider.notifier)
        .create(name, color: _selectedColor?.toARGB32());
    _newTagController.clear();
    setState(() => _selectedColor = null);
    _newTagFocus.requestFocus();
  }

  Future<void> _renameTag(Tag tag) async {
    final S l = S.of(context);
    final TextEditingController controller =
        TextEditingController(text: tag.name);
    final String? newName = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.tagRename),
        content: TextField(
          controller: controller,
          autofocus: true,
          onSubmitted: (String value) =>
              Navigator.of(ctx).pop(value.trim()),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(l.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName == null || newName.isEmpty || newName == tag.name) return;
    await ref.read(globalTagsProvider.notifier).rename(tag.id, newName);
  }

  Future<void> _changeColor(Tag tag) async {
    final Color? picked = await ColorPickerDialog.show(
      context: context,
      currentColor: tag.color != null ? Color(tag.color!) : null,
      allowNoColor: true,
    );
    if (picked == null) return;
    final int? colorValue = picked == ColorPickerDialog.noColorSentinel
        ? null
        : picked.toARGB32();
    await ref.read(globalTagsProvider.notifier).updateColor(tag.id, colorValue);
  }

  Future<void> _changeTextColor(Tag tag) async {
    final Color? picked = await ColorPickerDialog.show(
      context: context,
      currentColor: tag.textColor != null ? Color(tag.textColor!) : null,
      allowNoColor: true,
    );
    if (picked == null) return;
    final int? colorValue = picked == ColorPickerDialog.noColorSentinel
        ? null
        : picked.toARGB32();
    await ref
        .read(globalTagsProvider.notifier)
        .updateTextColor(tag.id, colorValue);
  }

  Future<void> _deleteTag(Tag tag) async {
    final S l = S.of(context);
    final bool confirmed = await ConfirmDialog.show(
      context,
      title: l.tagDelete,
      message: l.tagDeleteConfirm(tag.name),
      confirmLabel: l.delete,
    );
    if (!confirmed) return;
    await ref.read(globalTagsProvider.notifier).delete(tag.id);
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final AsyncValue<List<Tag>> tagsAsync = ref.watch(globalTagsProvider);
    final Map<int, int> usage = <int, int>{};
    final Map<int, Set<int>> itemTags =
        ref.watch(itemTagsProvider).valueOrNull ?? <int, Set<int>>{};
    for (final Set<int> ids in itemTags.values) {
      for (final int id in ids) {
        usage[id] = (usage[id] ?? 0) + 1;
      }
    }

    return AlertDialog(
      title: Text(l.tagManage),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                _ColorDot(
                  color: _selectedColor,
                  size: 24,
                  onTap: () async {
                    final Color? picked = await ColorPickerDialog.show(
                      context: context,
                      currentColor: _selectedColor,
                      allowNoColor: true,
                    );
                    if (picked == null) return;
                    setState(() {
                      _selectedColor =
                          picked == ColorPickerDialog.noColorSentinel
                              ? null
                              : picked;
                    });
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _newTagController,
                    focusNode: _newTagFocus,
                    decoration: InputDecoration(
                      hintText: l.tagCreateHint,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _createTag(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _createTag,
                  tooltip: l.tagCreate,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: tagsAsync.when(
                data: (List<Tag> tags) {
                  if (tags.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg,
                      ),
                      child: Text(
                        l.tagNone,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    );
                  }
                  return ReorderableListView.builder(
                    shrinkWrap: true,
                    buildDefaultDragHandles: false,
                    itemCount: tags.length,
                    onReorderItem: (int oldIndex, int newIndex) {
                      final List<int> ids =
                          tags.map((Tag t) => t.id).toList();
                      final int moved = ids.removeAt(oldIndex);
                      ids.insert(newIndex, moved);
                      ref.read(globalTagsProvider.notifier).reorder(ids);
                    },
                    itemBuilder: (BuildContext context, int index) {
                      final Tag tag = tags[index];
                      return _TagRow(
                        key: ValueKey<int>(tag.id),
                        index: index,
                        tag: tag,
                        usageCount: usage[tag.id] ?? 0,
                        onColorTap: () => _changeColor(tag),
                        onTextColorTap: () => _changeTextColor(tag),
                        onRename: () => _renameTag(tag),
                        onDelete: () => _deleteTag(tag),
                      );
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: CircularProgressIndicator(),
                ),
                error: (Object e, StackTrace? stack) => SelectableText(
                  'Error: $e\n\n$stack',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          ],
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

class _TagRow extends StatelessWidget {
  const _TagRow({
    required this.index,
    required this.tag,
    required this.usageCount,
    required this.onColorTap,
    required this.onTextColorTap,
    required this.onRename,
    required this.onDelete,
    super.key,
  });

  final int index;
  final Tag tag;
  final int usageCount;
  final VoidCallback onColorTap;
  final VoidCallback onTextColorTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ReorderableDragStartListener(
            index: index,
            child: const Icon(
              Icons.drag_indicator,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          _ColorDot(
            color: tag.color != null ? Color(tag.color!) : null,
            size: 20,
            onTap: onColorTap,
          ),
          const SizedBox(width: AppSpacing.xs),
          _ColorDot(
            color: tag.textColor != null ? Color(tag.textColor!) : null,
            size: 20,
            icon: Icons.text_fields,
            onTap: onTextColorTap,
            tooltip: l.tagTextColor,
          ),
        ],
      ),
      title: Text(
        tag.name,
        style: tag.textColor != null
            ? TextStyle(color: Color(tag.textColor!))
            : null,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: usageCount > 0
          ? Text(
              '$usageCount',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: onRename,
            tooltip: l.tagRename,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: onDelete,
            tooltip: l.tagDelete,
          ),
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.size,
    this.icon,
    this.onTap,
    this.tooltip,
  });

  final Color? color;
  final double size;
  final IconData? icon;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final Widget dot = GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color ?? AppColors.surfaceLight,
            shape: BoxShape.circle,
            border: Border.all(
              color: color != null
                  ? color!.withAlpha(180)
                  : AppColors.surfaceBorder,
            ),
          ),
          child: color == null
              ? Icon(
                  icon ?? Icons.palette_outlined,
                  size: size * 0.6,
                  color: AppColors.textTertiary,
                )
              : (icon != null
                  ? Icon(icon, size: size * 0.6, color: Colors.white)
                  : null),
        ),
      ),
    );
    final String? message = tooltip;
    if (message == null) return dot;
    return Tooltip(message: message, child: dot);
  }
}
