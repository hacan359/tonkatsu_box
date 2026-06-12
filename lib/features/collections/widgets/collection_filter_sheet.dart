// Used on narrow screens where the TagSidebar does not fit. All changes
// apply immediately; the sheet stays open.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/collection_sort_mode.dart';
import '../../../shared/models/collection_tag.dart';
import '../../../shared/theme/app_assets.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../settings/widgets/settings_tile.dart';
import '../providers/collections_provider.dart';

Future<void> showCollectionFilterSheet(
  BuildContext context, {
  required int? collectionId,
  required List<CollectionTag> tags,
  required Set<int> selectedTagIds,
  required bool groupByTags,
  required ValueChanged<int?> onTagToggled,
  required VoidCallback onGroupToggled,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
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

/// The sheet keeps its own local snapshot of `selectedTagIds`/`groupByTags`:
/// otherwise it would not react to its own actions (Navigator routes are not
/// rebuilt by the parent's setState). After each change the parent callback
/// is invoked so the parent updates too.
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

  final List<CollectionTag> tags;

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

class _CollectionFilterSheetState
    extends ConsumerState<CollectionFilterSheet> {
  late final Set<int> _selectedTagIds = <int>{...widget.selectedTagIds};
  late bool _groupByTags = widget.groupByTags;

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
    final CollectionSortMode currentSort =
        ref.watch(collectionSortProvider(widget.collectionId));
    final bool isDescending =
        ref.watch(collectionSortDescProvider(widget.collectionId));
    final bool hasTagFilter = _selectedTagIds.isNotEmpty;

    return Material(
      color: AppColors.background,
      elevation: 16,
      shadowColor: Colors.black,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusLg),
      ),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.backgroundTile),
            repeat: ImageRepeat.repeat,
            opacity: 0.03,
            scale: 0.667,
          ),
        ),
        child: Stack(
          children: <Widget>[
            // Brand-colored glow at the top.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.7),
                      radius: 1.1,
                      colors: <Color>[
                        AppColors.brand.withAlpha(80),
                        AppColors.brand.withAlpha(20),
                        Colors.transparent,
                      ],
                      stops: const <double>[0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            // Darkening towards the bottom.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        AppColors.background.withAlpha(80),
                        AppColors.background.withAlpha(160),
                        AppColors.background.withAlpha(220),
                      ],
                      stops: const <double>[0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            SingleChildScrollView(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface.withAlpha(80),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: AppColors.surfaceBorder.withAlpha(40),
                  ),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                    // Header: drag handle + clear-tags button (when any selected).
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.sm,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.md,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              Container(
                                width: 32,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(80),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusXxs),
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
                                      minimumSize: const Size(0, AppSpacing.buttonHeightDense),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () => _handleTagToggle(null),
                                    child: Text(
                                      l.filtersClear,
                                      style:
                                          AppTypography.bodySmall.copyWith(
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          0,
                          AppSpacing.md,
                          AppSpacing.sm,
                        ),
                        child: Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: <Widget>[
                            for (final CollectionTag tag in widget.tags)
                              _TagChip(
                                tag: tag,
                                selected: _selectedTagIds.contains(tag.id),
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
                              l.collectionFilterSort.toUpperCase(),
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
                              minimumSize: const Size(0, AppSpacing.buttonHeightDense),
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () => ref
                                .read(collectionSortDescProvider(widget.collectionId)
                                    .notifier)
                                .toggle(),
                            icon: Icon(
                              isDescending
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            label: Text(
                              isDescending
                                  ? l.collectionFilterDescending
                                  : l.collectionFilterAscending,
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
                            .read(collectionSortProvider(widget.collectionId)
                                .notifier)
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
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.tag,
    required this.selected,
    required this.onTap,
  });

  final CollectionTag tag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = tag.color != null
        ? Color(tag.color!)
        : AppColors.textSecondary;
    final Color bg = selected ? color : Colors.transparent;
    final Color fg = selected ? AppColors.background : color;
    return Material(
      color: bg,
      shape: StadiumBorder(
        side: BorderSide(
          color: color,
          width: selected ? 1.5 : 1,
        ),
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
      ),
      onTap: onTap,
    );
  }
}
