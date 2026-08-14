import 'package:core/models/tag.dart';
import 'package:core/models/tag_sort_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/constants/tag_sort_mode_ui.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../providers/global_tags_provider.dart';
import '../providers/tag_sort_provider.dart';

/// The shared body of both tag dialogs: one field driving search and
/// quick-create, the persisted sort mode, and the filtered tag list.
class TagSearchList extends ConsumerStatefulWidget {
  const TagSearchList({
    required this.rowBuilder,
    this.onCreate,
    this.onSubmitExisting,
    this.onReorder,
    this.leading,
    super.key,
  });

  /// [reorderable] is true only in the unfiltered manual view with
  /// [onReorder] set — the row then must mount its own drag listener.
  final Widget Function(Tag tag, int index, bool reorderable) rowBuilder;

  /// Called with the trimmed query; the field clears afterwards. Absent,
  /// the create row never appears and Enter cannot create.
  final Future<void> Function(String name)? onCreate;

  /// Enter on a query matching an existing tag; the field clears afterwards.
  /// Absent, such an Enter leaves the query in place as a filter.
  final void Function(Tag tag)? onSubmitExisting;

  /// Receives the full id list in its new order after a drag.
  final void Function(List<int> orderedIds)? onReorder;

  /// Rendered before the search field (the manage dialog's color dot).
  final Widget? leading;

  @override
  ConsumerState<TagSearchList> createState() => _TagSearchListState();
}

class _TagSearchListState extends ConsumerState<TagSearchList> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  String get _query => _searchController.text.trim();

  void _clearSearch() {
    setState(_searchController.clear);
    _searchFocus.requestFocus();
  }

  Future<void> _create() async {
    final Future<void> Function(String name)? onCreate = widget.onCreate;
    final String name = _query;
    if (onCreate == null || name.isEmpty) return;
    await onCreate(name);
    if (!mounted) return;
    _clearSearch();
  }

  void _submit(List<Tag> tags) {
    final String query = _query;
    if (query.isEmpty) return;
    final Tag? exact = Tag.findByNameCaseInsensitive(tags, query);
    if (exact != null) {
      final void Function(Tag tag)? onExisting = widget.onSubmitExisting;
      if (onExisting == null) return;
      onExisting(exact);
      _clearSearch();
      return;
    }
    _create();
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final AsyncValue<List<Tag>> tagsAsync = ref.watch(globalTagsProvider);
    final TagSortMode sortMode = ref.watch(tagSortModeProvider);
    final List<Tag> allTags = tagsAsync.valueOrNull ?? <Tag>[];
    final String query = _query;
    final bool offerCreate = widget.onCreate != null &&
        query.isNotEmpty &&
        Tag.findByNameCaseInsensitive(allTags, query) == null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            if (widget.leading != null) ...<Widget>[
              widget.leading!,
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                // Mobile: no autofocus so the keyboard waits for a tap.
                autofocus: !kIsMobile,
                decoration: InputDecoration(
                  hintText: l.tagPickerSearchHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          visualDensity: VisualDensity.compact,
                          onPressed: _clearSearch,
                        ),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(allTags),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            PopupMenuButton<TagSortMode>(
              tooltip: l.tagSortTooltip,
              icon: const Icon(Icons.sort_by_alpha, size: 20),
              onSelected: (TagSortMode mode) =>
                  ref.read(tagSortModeProvider.notifier).setMode(mode),
              itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<TagSortMode>>[
                for (final TagSortMode mode in TagSortMode.values)
                  CheckedPopupMenuItem<TagSortMode>(
                    value: mode,
                    checked: sortMode == mode,
                    child: Text(mode.localizedLabel(l)),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (offerCreate) _buildCreateTile(l, query),
        Flexible(
          child: tagsAsync.when(
            data: (List<Tag> tags) => _buildList(l, tags, sortMode),
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator(),
            ),
            error: (Object e, StackTrace? stack) => SelectableText(
              'Error: $e\n\n$stack',
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildList(S l, List<Tag> tags, TagSortMode sortMode) {
    final String query = _query;
    final String lowerQuery = query.toLowerCase();
    final List<Tag> filtered = query.isEmpty
        ? tags
        : tags
            .where((Tag t) => t.name.toLowerCase().contains(lowerQuery))
            .toList();
    final List<Tag> visible = sortMode.apply(filtered);

    if (visible.isEmpty) {
      // The create tile above already covers the "no match" case.
      if (query.isNotEmpty && widget.onCreate != null) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Text(
          l.tagNone,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      );
    }

    // Drag indexes only map back to sort_order in the unfiltered manual view.
    final void Function(List<int> orderedIds)? onReorder = widget.onReorder;
    final bool canReorder = onReorder != null &&
        sortMode == TagSortMode.manual &&
        query.isEmpty;
    if (!canReorder) {
      return ListView.builder(
        shrinkWrap: true,
        itemCount: visible.length,
        itemBuilder: (BuildContext context, int index) =>
            widget.rowBuilder(visible[index], index, false),
      );
    }
    return ReorderableListView.builder(
      shrinkWrap: true,
      buildDefaultDragHandles: false,
      itemCount: visible.length,
      onReorderItem: (int oldIndex, int newIndex) {
        final List<int> ids = visible.map((Tag t) => t.id).toList();
        final int moved = ids.removeAt(oldIndex);
        ids.insert(newIndex, moved);
        onReorder(ids);
      },
      itemBuilder: (BuildContext context, int index) =>
          widget.rowBuilder(visible[index], index, true),
    );
  }

  Widget _buildCreateTile(S l, String query) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.zero,
      onTap: _create,
      leading: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.brand.withAlpha(30),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.brand.withAlpha(120)),
        ),
        child: Icon(Icons.add, size: 16, color: AppColors.brand),
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
