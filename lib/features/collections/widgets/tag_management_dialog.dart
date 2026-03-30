// Диалог управления тегами коллекции.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/collection_tag.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
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
        .create(name);
    _newTagController.clear();
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
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Поле создания нового тега
            Row(
              children: <Widget>[
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
                        leading: Icon(
                          Icons.label_outlined,
                          color: tag.color != null
                              ? Color(tag.color!)
                              : AppColors.textSecondary,
                          size: 20,
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
