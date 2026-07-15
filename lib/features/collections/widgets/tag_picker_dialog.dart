import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/tag.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../providers/global_tags_provider.dart';

/// Multi-select picker over the global tag set.
///
/// One text field drives both search (filters the list as you type) and
/// quick-create: when the query matches no existing tag exactly, an explicit
/// "Create «query»" row appears at the top of the list.
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
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _query => _searchController.text.trim();

  Future<void> _createTag() async {
    final String name = _query;
    if (name.isEmpty) return;
    final int id = await ref
        .read(globalTagsProvider.notifier)
        .resolveOrCreate(name);
    if (!mounted) return;
    setState(() {
      _selected.add(id);
      _searchController.clear();
    });
  }

  /// Enter selects the exact match when there is one, otherwise creates.
  Future<void> _submitQuery(List<Tag> tags) async {
    if (_query.isEmpty) return;
    final Tag? exact = Tag.findByNameCaseInsensitive(tags, _query);
    if (exact != null) {
      setState(() {
        _selected.add(exact.id);
        _searchController.clear();
      });
      return;
    }
    await _createTag();
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final List<Tag> tags =
        ref.watch(globalTagsProvider).valueOrNull ?? <Tag>[];

    final String query = _query;
    final String lowerQuery = query.toLowerCase();
    final List<Tag> visibleTags = query.isEmpty
        ? tags
        : tags
            .where((Tag t) => t.name.toLowerCase().contains(lowerQuery))
            .toList();
    final bool offerCreate = query.isNotEmpty &&
        Tag.findByNameCaseInsensitive(tags, query) == null;

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
      title: Text(l.tagPickerTitle),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l.tagPickerSearchHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          visualDensity: VisualDensity.compact,
                          onPressed: () =>
                              setState(_searchController.clear),
                        ),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submitQuery(tags),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (offerCreate) _buildCreateTile(l, query),
              if (visibleTags.isEmpty && !offerCreate)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    l.tagNone,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textTertiary),
                  ),
                )
              else
                for (final Tag tag in visibleTags)
                  CheckboxListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
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

  Widget _buildCreateTile(S l, String query) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.zero,
      onTap: _createTag,
      leading: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.brand.withAlpha(30),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.brand.withAlpha(120)),
        ),
        child: const Icon(Icons.add, size: 16, color: AppColors.brand),
      ),
      title: Text(
        l.tagCreateNamed(query),
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.brand,
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
