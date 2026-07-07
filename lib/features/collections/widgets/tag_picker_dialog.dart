import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/tag.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../providers/global_tags_provider.dart';

/// Multi-select picker over the global tag set with inline quick-create.
///
/// Returns the chosen tag id set, or `null` when dismissed.
class TagPickerDialog extends ConsumerStatefulWidget {
  const TagPickerDialog({required this.initialSelection, super.key});

  final Set<int> initialSelection;

  static Future<Set<int>?> show(
    BuildContext context, {
    required Set<int> initialSelection,
  }) {
    return showDialog<Set<int>>(
      context: context,
      builder: (BuildContext context) =>
          TagPickerDialog(initialSelection: initialSelection),
    );
  }

  @override
  ConsumerState<TagPickerDialog> createState() => _TagPickerDialogState();
}

class _TagPickerDialogState extends ConsumerState<TagPickerDialog> {
  late final Set<int> _selected = Set<int>.of(widget.initialSelection);
  final TextEditingController _createController = TextEditingController();

  @override
  void dispose() {
    _createController.dispose();
    super.dispose();
  }

  Future<void> _createTag() async {
    final String name = _createController.text.trim();
    if (name.isEmpty) return;
    final int id = await ref
        .read(globalTagsProvider.notifier)
        .resolveOrCreate(name);
    if (!mounted) return;
    setState(() {
      _selected.add(id);
      _createController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final List<Tag> tags =
        ref.watch(globalTagsProvider).valueOrNull ?? <Tag>[];

    return AlertDialog(
      title: Text(l.tagPickerTitle),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _createController,
                      decoration: InputDecoration(hintText: l.tagCreateHint),
                      onSubmitted: (_) => _createTag(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: l.tagCreate,
                    onPressed: _createTag,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (tags.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    l.tagNone,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textTertiary),
                  ),
                )
              else
                for (final Tag tag in tags)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _selected.contains(tag.id),
                    onChanged: (bool? checked) {
                      setState(() {
                        if (checked ?? false) {
                          _selected.add(tag.id);
                        } else {
                          _selected.remove(tag.id);
                        }
                      });
                    },
                    title: Row(
                      children: <Widget>[
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: tag.color != null
                                ? Color(tag.color!)
                                : AppColors.brand,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            tag.name,
                            style: AppTypography.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: Text(l.apply),
        ),
      ],
    );
  }
}
