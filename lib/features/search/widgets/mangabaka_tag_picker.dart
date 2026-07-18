import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/mangabaka_tags_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/mangabaka_tag.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';

/// Opens the MangaBaka tag picker as a modal bottom sheet. Mirrors the AniList
/// tag picker: searchable, grouped by top-level category, with a manual
/// Refresh that re-fetches the catalog from the API.
///
/// [currentValue] / the return value are tag names (`List<String>`), matching
/// the multi-select filter contract.
Future<Object?> showMangaBakaTagPicker(
  BuildContext context,
  WidgetRef _,
  S l,
  Object? currentValue,
) {
  final List<String> initial = switch (currentValue) {
    final List<Object?> list => list.whereType<String>().toList(),
    final String single => <String>[single],
    _ => const <String>[],
  };
  return showModalBottomSheet<Object?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext ctx) => _MangaBakaTagPicker(
      initialSelection: initial,
      l: l,
    ),
  );
}

class _MangaBakaTagPicker extends ConsumerStatefulWidget {
  const _MangaBakaTagPicker({
    required this.initialSelection,
    required this.l,
  });

  final List<String> initialSelection;
  final S l;

  @override
  ConsumerState<_MangaBakaTagPicker> createState() =>
      _MangaBakaTagPickerState();
}

class _MangaBakaTagPickerState extends ConsumerState<_MangaBakaTagPicker> {
  late final Set<String> _selected = <String>{...widget.initialSelection};
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _showSpoilers = false;
  bool _showAdult = false;
  final Set<String> _collapsedCategories = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      await ref
          .read(mangaBakaTagsRepositoryProvider)
          .getTags(forceRefresh: true);
    } on Object {
      // Refresh failures fall back to the cached set.
    }
    ref.invalidate(mangaBakaTagsProvider);
  }

  static String _categoryOf(MangaBakaTag t) {
    final String? path = t.namePath;
    if (path == null || path.isEmpty) return t.name;
    final List<String> parts = path.split(RegExp(r'\s*[>/»]\s*'));
    return parts.first.trim().isEmpty ? t.name : parts.first.trim();
  }

  Map<String, List<MangaBakaTag>> _groupAndFilter(List<MangaBakaTag> all) {
    final String q = _query.trim().toLowerCase();
    final Map<String, List<MangaBakaTag>> grouped =
        <String, List<MangaBakaTag>>{};
    for (final MangaBakaTag t in all) {
      if (!_showAdult && t.isAdult) continue;
      if (!_showSpoilers && t.isSpoiler) continue;
      if (q.isNotEmpty && !t.name.toLowerCase().contains(q)) continue;
      grouped.putIfAbsent(_categoryOf(t), () => <MangaBakaTag>[]).add(t);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final S l = widget.l;
    final AsyncValue<List<MangaBakaTag>> tagsAsync =
        ref.watch(mangaBakaTagsProvider);
    final Size screen = MediaQuery.sizeOf(context);
    final double height = screen.height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: height, maxWidth: screen.width),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(l.tagPickerTitle, style: AppTypography.h3),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: l.tagPickerRefresh,
                  onPressed: _refresh,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l.tagPickerSearchHint,
              ),
              onChanged: (String v) => setState(() => _query = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(l.tagPickerShowSpoilers,
                        style: AppTypography.bodySmall),
                    value: _showSpoilers,
                    onChanged: (bool v) => setState(() => _showSpoilers = v),
                  ),
                ),
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(l.tagPickerShowAdult,
                        style: AppTypography.bodySmall),
                    value: _showAdult,
                    onChanged: (bool v) => setState(() => _showAdult = v),
                  ),
                ),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: tagsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (Object e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      e.toString(),
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.error),
                    ),
                  ),
                ),
                data: (List<MangaBakaTag> all) => _buildList(all, l),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  Text(
                    l.selectedCount(_selected.length),
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  if (_selected.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(_selected.clear),
                      child: Text(l.clearAll),
                    ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l.cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(
                      _selected.isEmpty
                          ? const <String>[]
                          : _selected.toList(),
                    ),
                    child: Text(l.apply),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<MangaBakaTag> all, S l) {
    final Map<String, List<MangaBakaTag>> grouped = _groupAndFilter(all);
    if (grouped.isEmpty) {
      return Center(
        child: Text(
          l.tagPickerEmpty,
          style: AppTypography.bodySmall
              .copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    final List<String> categories = grouped.keys.toList()..sort();
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (BuildContext ctx, int idx) {
        final String cat = categories[idx];
        final List<MangaBakaTag> tags = grouped[cat]!;
        final bool collapsed = _collapsedCategories.contains(cat);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            InkWell(
              onTap: () => setState(() {
                if (collapsed) {
                  _collapsedCategories.remove(cat);
                } else {
                  _collapsedCategories.add(cat);
                }
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs,
                  horizontal: AppSpacing.sm,
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      collapsed ? Icons.chevron_right : Icons.expand_more,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        cat,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      tags.length.toString(),
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ),
            if (!collapsed)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: <Widget>[
                    for (final MangaBakaTag t in tags)
                      FilterChip(
                        label: Text(t.name),
                        selected: _selected.contains(t.name),
                        onSelected: (bool sel) => setState(() {
                          if (sel) {
                            _selected.add(t.name);
                          } else {
                            _selected.remove(t.name);
                          }
                        }),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
