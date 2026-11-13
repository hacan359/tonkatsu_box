import 'package:core/models/collection_sort_mode.dart';
import 'package:core/models/tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../settings/widgets/settings_tile.dart';
import '../helpers/tag_name_filter.dart';
import '../providers/collections_provider.dart';
import '../../../shared/constants/collection_sort_mode_ui.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../../../shared/widgets/glass_dialog.dart';

Future<void> showCollectionFilterSheet(
  BuildContext context, {
  required int? collectionId,
  required List<Tag> tags,
  required Set<int> selectedTagIds,
  required bool groupByTags,
  required ValueChanged<int?> onTagToggled,
  required VoidCallback onGroupToggled,
}) {
  return showGlassSheet<void>(
    context: context,
    isScrollControlled: true,
    selfBacked: true,
    builder: (BuildContext ctx) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext _, ScrollController scrollController) =>
          CollectionFilterSheet(
            scrollController: scrollController,
            collectionId: collectionId,
            tags: tags,
            selectedTagIds: selectedTagIds,
            groupByTags: groupByTags,
            onTagToggled: onTagToggled,
            onGroupToggled: onGroupToggled,
          ),
    ),
  );
}

/// Keeps a local snapshot of `selectedTagIds`/`groupByTags`: Navigator routes
/// are not rebuilt by the parent's setState. Parent callbacks fire on change.
class CollectionFilterSheet extends ConsumerStatefulWidget {
  const CollectionFilterSheet({
    required this.scrollController,
    required this.collectionId,
    required this.tags,
    required this.selectedTagIds,
    required this.groupByTags,
    required this.onTagToggled,
    required this.onGroupToggled,
    super.key,
  });

  final ScrollController scrollController;

  /// `null` means the uncategorized collection.
  final int? collectionId;

  final List<Tag> tags;

  /// Initial snapshot; the sheet keeps its own local copy afterwards.
  final Set<int> selectedTagIds;

  /// Initial snapshot; the sheet keeps its own local copy afterwards.
  final bool groupByTags;

  /// Called with the tag id, or `null` to clear all tags.
  final ValueChanged<int?> onTagToggled;

  final VoidCallback onGroupToggled;

  @override
  ConsumerState<CollectionFilterSheet> createState() =>
      _CollectionFilterSheetState();
}

class _CollectionFilterSheetState extends ConsumerState<CollectionFilterSheet> {
  late final Set<int> _selectedTagIds = <int>{...widget.selectedTagIds};
  late bool _groupByTags = widget.groupByTags;
  final TextEditingController _tagQuery = TextEditingController();
  final FocusNode _tagQueryFocus = FocusNode();

  @override
  void dispose() {
    _tagQuery.dispose();
    _tagQueryFocus.dispose();
    super.dispose();
  }

  void _handleTagToggle(int? id) {
    setState(() {
      if (id == null) {
        _selectedTagIds.clear();
      } else if (_selectedTagIds.contains(id)) {
        _selectedTagIds.remove(id);
      } else {
        _selectedTagIds.add(id);
      }
    });
    widget.onTagToggled(id);
  }

  void _handleGroupToggle() {
    setState(() {
      _groupByTags = !_groupByTags;
      // Mirrors the parent: toggling grouping clears the selected tags.
      _selectedTagIds.clear();
    });
    widget.onGroupToggled();
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final CollectionSortMode currentSort = ref.watch(
      collectionSortProvider(widget.collectionId),
    );
    final bool isDescending = ref.watch(
      collectionSortDescProvider(widget.collectionId),
    );
    final bool hasTagFilter = _selectedTagIds.isNotEmpty;
    final bool searchableTags = widget.tags.length >= kTagSearchMinTags;
    final List<Tag> visibleTags = filterTagsByName(
      widget.tags,
      _tagQuery.text,
      keepIds: _selectedTagIds,
    );

    return GlassPanel(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusLg),
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.7),
                    radius: 1.1,
                    colors: <Color>[
                      AppColors.brand.withAlpha(60),
                      AppColors.brand.withAlpha(16),
                      Colors.transparent,
                    ],
                    stops: const <double>[0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
          ),

          SingleChildScrollView(
            controller: widget.scrollController,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: DecoratedBox(
              decoration: glassTileDecoration(radius: AppSpacing.radiusMd),
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.sm,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: SizedBox(
                          width: double.infinity,
                          child: Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              Container(
                                width: 32,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.textPrimary.withAlpha(80),
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusXxs,
                                  ),
                                ),
                              ),
                              if (hasTagFilter)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                      ),
                                      minimumSize: const Size(
                                        0,
                                        AppSpacing.buttonHeightDense,
                                      ),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () => _handleTagToggle(null),
                                    child: Text(
                                      l.filtersClear,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    if (widget.tags.isNotEmpty) ...<Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.xs,
                        ),
                        child: Text(
                          l.tagsLabel.toUpperCase(),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      if (searchableTags)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            AppSpacing.sm,
                          ),
                          child: _TagSearchField(
                            controller: _tagQuery,
                            focusNode: _tagQueryFocus,
                            onChanged: () => setState(() {}),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          0,
                          AppSpacing.md,
                          AppSpacing.sm,
                        ),
                        child: visibleTags.isEmpty
                            ? Text(
                                l.tagNone,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              )
                            : Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children: <Widget>[
                                  for (final Tag tag in visibleTags)
                                    _TagChip(
                                      tag: tag,
                                      selected: _selectedTagIds.contains(
                                        tag.id,
                                      ),
                                      onTap: () => _handleTagToggle(tag.id),
                                    ),
                                ],
                              ),
                      ),
                      SettingsTile(
                        title: l.tagSidebarGroup,
                        showChevron: false,
                        onTap: _handleGroupToggle,
                        trailing: Switch(
                          value: _groupByTags,
                          onChanged: (_) => _handleGroupToggle(),
                        ),
                      ),
                    ],

                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.xs,
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              l.sort.toUpperCase(),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textTertiary,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                              ),
                              minimumSize: const Size(
                                0,
                                AppSpacing.buttonHeightDense,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () => ref
                                .read(
                                  collectionSortDescProvider(
                                    widget.collectionId,
                                  ).notifier,
                                )
                                .toggle(),
                            icon: Icon(
                              isDescending
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            label: Text(
                              currentSort.localizedDirectionLabel(
                                l,
                                descending: isDescending,
                              ),
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final CollectionSortMode mode
                        in CollectionSortMode.values)
                      _SortTile(
                        label: mode.localizedDisplayLabel(l),
                        selected: mode == currentSort,
                        onTap: () => ref
                            .read(
                              collectionSortProvider(
                                widget.collectionId,
                              ).notifier,
                            )
                            .setSortMode(mode),
                      ),

                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagSearchField extends StatelessWidget {
  const _TagSearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final bool hasQuery = controller.text.isNotEmpty;
    return TextField(
      key: const ValueKey<String>('filterSheetTagSearch'),
      controller: controller,
      focusNode: focusNode,
      // Touch keeps focus on an outside tap, so the keyboard would stick to
      // the sheet while the user is picking chips.
      onTapOutside: kIsMobile ? (_) => focusNode.unfocus() : null,
      style: AppTypography.bodySmall,
      decoration: InputDecoration(
        hintText: S.of(context).tagPickerSearchHint,
        prefixIcon: const Icon(Icons.search, size: 18),
        suffixIcon: hasQuery
            ? IconButton(
                icon: const Icon(Icons.clear, size: 16),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  controller.clear();
                  onChanged();
                },
              )
            : null,
        isDense: true,
      ),
      onChanged: (_) => onChanged(),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.tag,
    required this.selected,
    required this.onTap,
  });

  final Tag tag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = tag.color != null
        ? Color(tag.color!)
        : AppColors.textSecondary;
    final Color bg = selected ? color : glassChipColor();
    final Color fg = selected ? AppColors.background : color;
    return Material(
      color: bg,
      shape: StadiumBorder(
        side: BorderSide(color: color, width: selected ? 1.5 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (selected) ...<Widget>[
                Icon(Icons.check, size: 14, color: fg),
                const SizedBox(width: 4),
              ],
              Text(
                tag.name,
                style: AppTypography.bodySmall.copyWith(
                  color: fg,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortTile extends StatelessWidget {
  const _SortTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        size: 18,
        color: selected ? AppColors.brand : AppColors.textTertiary,
      ),
      title: Text(
        label,
        style: AppTypography.body.copyWith(
          color: selected ? AppColors.brand : AppColors.textPrimary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      onTap: onTap,
    );
  }
}
