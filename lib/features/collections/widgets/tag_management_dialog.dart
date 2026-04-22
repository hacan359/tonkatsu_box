// Диалог управления тегами коллекции.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/collection_tag.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/color_picker_dialog.dart';
import '../providers/collection_tags_provider.dart';

/// Диалог для управления тегами коллекции (создание, переименование, удаление).
class TagManagementDialog extends ConsumerStatefulWidget {
  /// Создаёт [TagManagementDialog].
  const TagManagementDialog({required this.collectionId, super.key});

  /// ID коллекции.
  final int collectionId;

  /// Показывает диалог.
  static Future<void> show(BuildContext context, int collectionId) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) =>
          TagManagementDialog(collectionId: collectionId),
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
        .read(collectionTagsProvider(widget.collectionId).notifier)
        .create(name, color: _selectedColor?.toARGB32());
    _newTagController.clear();
    setState(() => _selectedColor = null);
    _newTagFocus.requestFocus();
  }

  Future<void> _renameTag(CollectionTag tag) async {
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
    await ref
        .read(collectionTagsProvider(widget.collectionId).notifier)
        .rename(tag.id, newName);
  }

  Future<void> _changeColor(CollectionTag tag) async {
    final Color? picked = await ColorPickerDialog.show(
      context: context,
      currentColor: tag.color != null ? Color(tag.color!) : null,
      allowNoColor: true,
    );
    if (picked == null) return;
    final int? colorValue = picked == ColorPickerDialog.noColorSentinel
        ? null
        : picked.toARGB32();
    await ref
        .read(collectionTagsProvider(widget.collectionId).notifier)
        .updateColor(tag.id, colorValue);
  }

  Future<void> _deleteTag(CollectionTag tag) async {
    final S l = S.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.tagDelete),
        content: Text(l.tagDeleteConfirm(tag.name)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(collectionTagsProvider(widget.collectionId).notifier)
        .delete(tag.id);
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final AsyncValue<List<CollectionTag>> tagsAsync =
        ref.watch(collectionTagsProvider(widget.collectionId));

    return AlertDialog(
      title: Text(l.tagManage),
      scrollable: true,
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Поле создания нового тега
            Row(
              children: <Widget>[
                // Цвет
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
                      _selectedColor = picked == ColorPickerDialog.noColorSentinel
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

            // Список тегов
            tagsAsync.when(
              data: (List<CollectionTag> tags) {
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
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (final CollectionTag tag in tags)
                      ListTile(
                        dense: true,
                        leading: _ColorDot(
                          color: tag.color != null
                              ? Color(tag.color!)
                              : null,
                          size: 20,
                          onTap: () => _changeColor(tag),
                        ),
                        title: Text(tag.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _renameTag(tag),
                              tooltip: l.tagRename,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              onPressed: () => _deleteTag(tag),
                              tooltip: l.tagDelete,
                            ),
                          ],
                        ),
                      ),
                  ],
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

// ---------------------------------------------------------------------------
// Точка-кружок цвета тега
// ---------------------------------------------------------------------------

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.size,
    this.onTap,
  });

  final Color? color;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
                  Icons.palette_outlined,
                  size: size * 0.6,
                  color: AppColors.textTertiary,
                )
              : null,
        ),
      ),
    );
  }
}
