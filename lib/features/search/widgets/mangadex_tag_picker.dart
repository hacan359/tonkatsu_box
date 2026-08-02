import 'package:core/models/mangadex_tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/mangadex_tags_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../filters/mangadex_tag_filter.dart';

/// Opens the MangaDex tag picker as a modal bottom sheet, mirroring the
/// MangaBaka tag picker: searchable, with a manual Refresh that re-fetches the
/// catalog from the API.
///
/// [currentValue] / the return value are tag UUIDs (`List<String>`), matching
/// the multi-select filter contract (MangaDex `includedTags[]`).
Future<Object?> showMangaDexTagPicker(
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
    builder: (BuildContext ctx) => _MangaDexTagPicker(
      initialSelection: initial,
      l: l,
    ),
  );
}

class _MangaDexTagPicker extends ConsumerStatefulWidget {
  const _MangaDexTagPicker({required this.initialSelection, required this.l});

  final List<String> initialSelection;
  final S l;

  @override
  ConsumerState<_MangaDexTagPicker> createState() => _MangaDexTagPickerState();
}

class _MangaDexTagPickerState extends ConsumerState<_MangaDexTagPicker> {
  late final Set<String> _selected = <String>{...widget.initialSelection};
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      await ref.read(mangaDexTagsRepositoryProvider).getTags(forceRefresh: true);
    } on Object {
      // Refresh failures fall back to the cached set.
    }
    ref.invalidate(mangaDexTagsProvider);
  }

  List<MangaDexTag> _filter(List<MangaDexTag> all) {
    final String q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((MangaDexTag t) => t.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final S l = widget.l;
    final AsyncValue<List<MangaDexTag>> tagsAsync =
        ref.watch(mangaDexThemesProvider);
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
                data: (List<MangaDexTag> all) => _buildList(all, l),
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

  Widget _buildList(List<MangaDexTag> all, S l) {
    final List<MangaDexTag> tags = _filter(all);
    if (tags.isEmpty) {
      return Center(
        child: Text(
          l.tagPickerEmpty,
          style: AppTypography.bodySmall
              .copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: <Widget>[
          for (final MangaDexTag t in tags)
            FilterChip(
              label: Text(t.name),
              selected: _selected.contains(t.id),
              onSelected: (bool sel) => setState(() {
                if (sel) {
                  _selected.add(t.id);
                } else {
                  _selected.remove(t.id);
                }
              }),
            ),
        ],
      ),
    );
  }
}
