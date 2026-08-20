import 'package:core/models/tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_spacing.dart';
import '../providers/global_tags_provider.dart';
import '../providers/item_tags_provider.dart';
import 'tag_row.dart';
import 'tag_search_list.dart';

/// Multi-select picker over the global tag set; pops the chosen id set, or
/// null when dismissed. Row edits ([TagRow]) are global and instant.
class TagPickerDialog extends ConsumerStatefulWidget {
  const TagPickerDialog({
    required this.initialSelection,
    this.title,
    this.confirmLabel,
    super.key,
  });

  /// Bulk callers pass an empty set — their items carry different tags, so
  /// an unchecked box there means "leave alone", not "remove this tag".
  final Set<int> initialSelection;

  /// Defaults to the neutral "select tags" wording.
  final String? title;

  /// Defaults to "Apply". Bulk callers pass their own label — there an
  /// unchecked box means "leave alone", not "remove this tag".
  final String? confirmLabel;

  static Future<Set<int>?> show(
    BuildContext context, {
    required Set<int> initialSelection,
    String? title,
    String? confirmLabel,
  }) {
    return showDialog<Set<int>>(
      context: context,
      builder: (BuildContext context) => TagPickerDialog(
        initialSelection: initialSelection,
        title: title,
        confirmLabel: confirmLabel,
      ),
    );
  }

  @override
  ConsumerState<TagPickerDialog> createState() => _TagPickerDialogState();
}

class _TagPickerDialogState extends ConsumerState<TagPickerDialog> {
  late final Set<int> _selected = Set<int>.of(widget.initialSelection);

  Future<void> _createTag(String name) async {
    final int id = await ref
        .read(globalTagsProvider.notifier)
        .resolveOrCreate(name);
    if (!mounted) return;
    setState(() => _selected.add(id));
  }

  void _toggle(int tagId) {
    setState(() {
      if (!_selected.remove(tagId)) {
        _selected.add(tagId);
      }
    });
  }

  Future<void> _deleteTag(Tag tag) async {
    final bool deleted = await TagEditActions.delete(context, ref, tag);
    if (!deleted || !mounted) return;
    setState(() => _selected.remove(tag.id));
  }

  void _apply() {
    // A row's delete is global and instant — never hand a dead id back.
    final List<Tag>? tags = ref.read(globalTagsProvider).valueOrNull;
    final Set<int> result = tags == null
        ? _selected
        : _selected.intersection(<int>{for (final Tag t in tags) t.id});
    Navigator.of(context).pop(result);
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
      title: Text(widget.title ?? l.tagPickerTitle),
      content: SizedBox(
        width: 400,
        child: TagSearchList(
          onCreate: _createTag,
          onSubmitExisting: (Tag tag) =>
              setState(() => _selected.add(tag.id)),
          rowBuilder: (Tag tag, int index, bool reorderable) => TagRow(
            key: ValueKey<int>(tag.id),
            tag: tag,
            usageCount: usage[tag.id] ?? 0,
            leading: SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _selected.contains(tag.id),
                visualDensity: VisualDensity.compact,
                onChanged: (_) => _toggle(tag.id),
              ),
            ),
            onTap: () => _toggle(tag.id),
            onColorTap: () => TagEditActions.changeColor(context, ref, tag),
            onTextColorTap: () =>
                TagEditActions.changeTextColor(context, ref, tag),
            onRename: () => TagEditActions.rename(context, ref, tag),
            onDelete: () => _deleteTag(tag),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: _apply,
          child: Text(widget.confirmLabel ?? l.apply),
        ),
      ],
    );
  }
}
