// Панель фильтров, поиска и сортировки для CollectionScreen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/collection_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/collection_sort_mode.dart';
import '../../../shared/models/collection_tag.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/platform.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../providers/collections_provider.dart';

/// Панель фильтров, поиска и сортировки для CollectionScreen.
///
/// Desktop: верхняя строка (поиск, сорт, view, кнопка фильтров) +
/// раскрывающаяся панель (type, platforms, tags).
/// Mobile: верхняя строка + горизонтальные чипсы активных фильтров.
class CollectionFilterBar extends ConsumerStatefulWidget {
  /// Создаёт [CollectionFilterBar].
  const CollectionFilterBar({
    required this.collectionId,
    required this.statsAsync,
    required this.itemsAsync,
    required this.filterTypes,
    required this.filterPlatformIds,
    required this.filterTagIds,
    required this.filterStatus,
    required this.tags,
    required this.searchController,
    required this.searchQuery,
    required this.onTypeToggled,
    required this.onPlatformToggled,
    required this.onTagToggled,
    required this.onStatusChanged,
    required this.onGroupToggled,
    this.groupByTags = false,
    super.key,
  });

  final int? collectionId;
  final AsyncValue<CollectionStats> statsAsync;
  final AsyncValue<List<CollectionItem>> itemsAsync;
  final Set<MediaType> filterTypes;
  final Set<int> filterPlatformIds;
  final Set<int> filterTagIds;
  final ItemStatus? filterStatus;
  final List<CollectionTag> tags;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<MediaType?> onTypeToggled;
  final ValueChanged<int?> onPlatformToggled;
  final ValueChanged<int?> onTagToggled;
  final ValueChanged<ItemStatus?> onStatusChanged;
  final VoidCallback onGroupToggled;
  final bool groupByTags;

  @override
  ConsumerState<CollectionFilterBar> createState() =>
      _CollectionFilterBarState();
}

class _CollectionFilterBarState extends ConsumerState<CollectionFilterBar> {
  bool _filtersExpanded = false;

  int get _activeFilterCount {
    return widget.filterTypes.length +
        widget.filterPlatformIds.length +
        (kIsMobile ? widget.filterTagIds.length : 0);
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final CollectionStats? stats = widget.statsAsync.valueOrNull;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Строка 1 — type chips (как на Main)
        _buildTypeChipsRow(l, stats),
        // Строка 2 — поиск, сорт
        _buildMainRow(context),
        // Разделитель-стрелка для раскрытия фильтров
        if (!kIsMobile) _buildExpandArrow(),
        // Строка 3 — доп. фильтры
        if (kIsMobile)
          _buildMobileChips(context)
        else
          _buildDesktopFilterPanel(context),
      ],
    );
  }

  Widget _buildTypeChipsRow(S l, CollectionStats? stats) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm, AppSpacing.xs, AppSpacing.sm, AppSpacing.sm,
      ),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildTypeChip(null, l.collectionFilterAll, stats?.total),
              for (final _TypeEntry e in _typeEntries(l, stats)) ...<Widget>[
                const SizedBox(width: AppSpacing.xs),
                _buildTypeChip(e.type, e.label, e.count),
              ],
              const SizedBox(width: AppSpacing.md),
              _buildStatusDropdownChip(l),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Строка 1 — всегда видна
  // ===========================================================================

  Widget _buildMainRow(BuildContext context) {
    final CollectionSortMode currentSort =
        ref.watch(collectionSortProvider(widget.collectionId));
    final bool isDescending =
        ref.watch(collectionSortDescProvider(widget.collectionId));

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: <Widget>[
          // Поиск
          Expanded(child: _buildSearch(context)),
          const SizedBox(width: AppSpacing.xs),

          // Сортировка
          _buildSortButton(context, currentSort, isDescending),
          // Mobile: кнопка фильтров
          if (kIsMobile) ...<Widget>[
            const SizedBox(width: AppSpacing.xs),
            _buildFilterToggle(context),
          ],
        ],
      ),
    );
  }

  Widget _buildSearch(BuildContext context) {
    return SizedBox(
      height: 32,
      child: TextField(
        controller: widget.searchController,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: S.of(context).collectionFilterSearchHint,
          hintStyle:
              AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
          prefixIcon: const Icon(Icons.search, size: 16,
              color: AppColors.textTertiary),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 32, minHeight: 32),
          suffixIcon: widget.searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 14,
                      color: AppColors.textTertiary),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: () => widget.searchController.clear(),
                )
              : null,
          filled: true,
          fillColor: AppColors.surfaceLight,
          contentPadding:
              const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSortButton(
    BuildContext context,
    CollectionSortMode currentSort,
    bool isDescending,
  ) {
    return PopupMenuButton<String>(
      tooltip: S.of(context).collectionFilterSort,
      onSelected: (String value) {
        if (value == 'toggle_direction') {
          ref
              .read(collectionSortDescProvider(widget.collectionId).notifier)
              .toggle();
        } else {
          ref
              .read(collectionSortProvider(widget.collectionId).notifier)
              .setSortMode(CollectionSortMode.fromString(value));
        }
      },
      constraints: const BoxConstraints(),
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      child: _buildBarChip(
        label: currentSort.localizedShortLabel(S.of(context)),
        trailing: Icon(
          isDescending ? Icons.arrow_downward : Icons.arrow_upward,
          size: 14,
          color: AppColors.textSecondary,
        ),
      ),
      itemBuilder: (BuildContext context) {
        final S sl = S.of(context);
        return <PopupMenuEntry<String>>[
          ...CollectionSortMode.values.map(
            (CollectionSortMode mode) => PopupMenuItem<String>(
              value: mode.value,
              child: Row(
                children: <Widget>[
                  if (mode == currentSort)
                    const Icon(Icons.check, size: 18, color: AppColors.brand)
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(mode.localizedDisplayLabel(sl)),
                      Text(mode.localizedDescription(sl),
                          style: AppTypography.caption),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'toggle_direction',
            child: Row(
              children: <Widget>[
                Icon(
                  isDescending ? Icons.arrow_downward : Icons.arrow_upward,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(isDescending
                    ? S.of(context).collectionFilterDescending
                    : S.of(context).collectionFilterAscending),
              ],
            ),
          ),
        ];
      },
    );
  }

  Widget _buildFilterToggle(BuildContext context) {
    final int count = _activeFilterCount;

    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        children: <Widget>[
          IconButton(
            icon: Icon(
              _filtersExpanded
                  ? Icons.filter_list_off
                  : Icons.tune_rounded,
              size: 18,
              color: count > 0 ? AppColors.brand : AppColors.textSecondary,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
            onPressed: () {
              if (kIsMobile) {
                _showMobileFilterSheet(context);
              } else {
                setState(() => _filtersExpanded = !_filtersExpanded);
              }
            },
          ),
          if (count > 0)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: AppColors.brand,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  Widget _buildExpandArrow() {
    final bool hasFilters =
        _extractPlatforms().isNotEmpty || widget.tags.isNotEmpty;
    if (!hasFilters) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => setState(() => _filtersExpanded = !_filtersExpanded),
      behavior: HitTestBehavior.opaque,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: SizedBox(
          width: double.infinity,
          height: 16,
          child: Center(
            child: AnimatedRotation(
              turns: _filtersExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: _activeFilterCount > 0
                    ? AppColors.brand
                    : AppColors.textTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Desktop — раскрывающаяся панель фильтров
  // ===========================================================================

  Widget _buildDesktopFilterPanel(BuildContext context) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 200),
      crossFadeState: _filtersExpanded
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      firstChild: const SizedBox(width: double.infinity, height: 0),
      secondChild: _buildFilterPanelContent(context),
    );
  }

  Widget _buildFilterPanelContent(BuildContext context) {
    final S l = S.of(context);
    final List<Platform> platforms = _extractPlatforms();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm,
      ),
      child: Column(
        children: <Widget>[
          // Platform chips
          if (platforms.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _buildPlatformChip(null, l.collectionFilterAll),
                    for (final Platform p in platforms) ...<Widget>[
                      const SizedBox(width: AppSpacing.xs),
                      _buildPlatformChip(p.id, p.displayName, color: p.familyColor),
                    ],
                  ],
                ),
              ),
            ),
          ],

          // Clear all (теги на desktop показываются в TagSidebar)
          if (_activeFilterCount > 0) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            _buildClearButton(),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // Mobile — чипсы активных фильтров
  // ===========================================================================

  Widget _buildMobileChips(BuildContext context) {
    final List<Widget> chips = <Widget>[];
    final S l = S.of(context);

    // Active type filters
    for (final MediaType type in widget.filterTypes) {
      chips.add(_buildActiveChip(
        label: type.localizedLabel(l),
        color: MediaTypeTheme.colorFor(type),
        onRemove: () => widget.onTypeToggled(type),
      ));
    }

    // Active platform filters
    for (final int platformId in widget.filterPlatformIds) {
      final String platformName = _findPlatformName(platformId);
      chips.add(_buildActiveChip(
        label: platformName,
        color: AppColors.brand,
        onRemove: () => widget.onPlatformToggled(platformId),
      ));
    }

    // Active tag filters
    for (final int tagId in widget.filterTagIds) {
      final CollectionTag? tag =
          widget.tags.where((CollectionTag t) => t.id == tagId).firstOrNull;
      if (tag != null) {
        final Color tagColor =
            tag.color != null ? Color(tag.color!) : AppColors.textSecondary;
        chips.add(_buildActiveChip(
          label: tag.name,
          color: tagColor,
          onRemove: () => widget.onTagToggled(tagId),
        ));
      }
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.xs,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            for (int i = 0; i < chips.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: AppSpacing.xs),
              chips[i],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveChip({
    required String label,
    required Color color,
    required VoidCallback onRemove,
  }) {
    return Container(
      height: 28,
      padding: const EdgeInsets.only(left: 10, right: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 14, color: color),
          ),
        ],
      ),
    );
  }

  void _showMobileFilterSheet(BuildContext context) {
    final S l = S.of(context);
    final List<Platform> platforms = _extractPlatforms();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext ctx) {
        // Локальные копии для live-обновления внутри sheet
        Set<int> sheetPlatforms = Set<int>.from(widget.filterPlatformIds);
        Set<int> sheetTags = Set<int>.from(widget.filterTagIds);

        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setSheetState) {
            void togglePlatform(int? id) {
              setSheetState(() {
                if (id == null) {
                  sheetPlatforms = <int>{};
                } else if (sheetPlatforms.contains(id)) {
                  sheetPlatforms = Set<int>.from(sheetPlatforms)..remove(id);
                } else {
                  sheetPlatforms = Set<int>.from(sheetPlatforms)..add(id);
                }
              });
              widget.onPlatformToggled(id);
            }

            void toggleTag(int? tagId) {
              setSheetState(() {
                if (tagId == null) {
                  sheetTags = <int>{};
                } else if (sheetTags.contains(tagId)) {
                  sheetTags = Set<int>.from(sheetTags)..remove(tagId);
                } else {
                  sheetTags = Set<int>.from(sheetTags)..add(tagId);
                }
              });
              widget.onTagToggled(tagId);
            }

            Widget sheetPlatformChip(int? id, String label, {Color? color}) {
              final bool selected = id == null
                  ? sheetPlatforms.isEmpty
                  : sheetPlatforms.contains(id);
              final Color accentColor = color ?? AppColors.textPrimary;
              return ChoiceChip(
                label: Text(label, style: AppTypography.caption.copyWith(
                  color: selected ? AppColors.background : accentColor,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                )),
                selected: selected,
                selectedColor: accentColor,
                backgroundColor: AppColors.surface,
                side: BorderSide(color: selected ? Colors.transparent : accentColor.withAlpha(50)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                onSelected: (_) => togglePlatform(id),
              );
            }

            Widget sheetTagChip(CollectionTag tag) {
              final bool selected = sheetTags.contains(tag.id);
              final Color tagColor = tag.color != null ? Color(tag.color!) : AppColors.textSecondary;
              return ChoiceChip(
                label: Text(tag.name, style: AppTypography.caption.copyWith(
                  color: selected ? AppColors.background : tagColor,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                )),
                selected: selected,
                selectedColor: tagColor,
                backgroundColor: AppColors.surface,
                side: BorderSide(color: selected ? Colors.transparent : tagColor.withAlpha(60)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                onSelected: (_) => toggleTag(tag.id),
              );
            }

            Widget sheetTagAll() {
              final bool selected = sheetTags.isEmpty;
              return ChoiceChip(
                label: Text(l.tagSidebarAll, style: AppTypography.caption.copyWith(
                  color: selected ? AppColors.background : AppColors.textTertiary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                )),
                selected: selected,
                selectedColor: AppColors.textPrimary,
                backgroundColor: AppColors.surface,
                side: BorderSide(color: selected ? Colors.transparent : AppColors.surfaceBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                onSelected: (_) => toggleTag(null),
              );
            }

            final int activeCount = sheetPlatforms.length + sheetTags.length;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(l.collectionFilterFilters, style: AppTypography.h3
                          .copyWith(color: AppColors.textPrimary)),
                      if (activeCount > 0)
                        TextButton(
                          onPressed: () {
                            widget.onTypeToggled(null);
                            togglePlatform(null);
                            toggleTag(null);
                          },
                          child: Text(l.collectionFilterClearAll),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  if (platforms.isNotEmpty) ...<Widget>[
                    const SizedBox(height: AppSpacing.md),
                    Text(l.collectionFilterPlatform, style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textTertiary)),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: <Widget>[
                        sheetPlatformChip(null, l.collectionFilterAll),
                        for (final Platform p in platforms)
                          sheetPlatformChip(p.id, p.displayName, color: p.familyColor),
                      ],
                    ),
                  ],

                  if (widget.tags.isNotEmpty) ...<Widget>[
                    const SizedBox(height: AppSpacing.md),
                    Text(l.tagsLabel, style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textTertiary)),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: <Widget>[
                        _buildGroupChip(l, setSheetState),
                        sheetTagAll(),
                        for (final CollectionTag tag in widget.tags)
                          sheetTagChip(tag),
                      ],
                    ),
                  ],

                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGroupChip(S l, StateSetter setSheetState) {
    final bool selected = widget.groupByTags;
    return ChoiceChip(
      label: Text(l.tagSidebarGroup, style: AppTypography.caption.copyWith(
        color: selected ? AppColors.background : AppColors.brand,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      )),
      selected: selected,
      selectedColor: AppColors.brand,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: selected ? Colors.transparent : AppColors.brand.withAlpha(60),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      avatar: Icon(
        Icons.workspaces_outlined,
        size: 14,
        color: selected ? AppColors.background : AppColors.brand,
      ),
      onSelected: (_) {
        setSheetState(() {});
        widget.onGroupToggled();
      },
    );
  }

  // ===========================================================================
  // Shared chips
  // ===========================================================================

  Widget _buildTypeChip(MediaType? type, String label, int? count) {
    // null = "All" chip, selected when no filters active
    final bool selected = type == null
        ? widget.filterTypes.isEmpty
        : widget.filterTypes.contains(type);
    final Color accentColor = type != null
        ? MediaTypeTheme.colorFor(type)
        : AppColors.textPrimary;

    final String displayLabel =
        count != null && count > 0 ? '$label ($count)' : label;

    return ChoiceChip(
      label: Text(
        displayLabel,
        style: AppTypography.bodySmall.copyWith(
          color: selected ? AppColors.background : accentColor,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: selected,
      selectedColor: accentColor,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: selected ? Colors.transparent : accentColor.withAlpha(80),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onSelected: (bool value) {
        widget.onTypeToggled(type); // null = clear all types
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Status dropdown
  // ---------------------------------------------------------------------------

  static const List<ItemStatus> _statusOrder = <ItemStatus>[
    ItemStatus.inProgress,
    ItemStatus.planned,
    ItemStatus.notStarted,
    ItemStatus.completed,
    ItemStatus.dropped,
  ];

  Widget _buildStatusDropdownChip(S l) {
    final ItemStatus? current = widget.filterStatus;
    final bool isActive = current != null;
    final Color chipColor =
        isActive ? current.color : AppColors.textSecondary;
    final String label = isActive
        ? current.genericLabel(l)
        : l.homeFilterAll;

    return PopupMenuButton<String>(
      onSelected: (String value) {
        final ItemStatus? status =
            value == 'all' ? null : ItemStatus.fromString(value);
        widget.onStatusChanged(status);
      },
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      color: AppColors.surface,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'all',
          height: 36,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.filter_list_off,
                size: 16,
                color: current == null
                    ? AppColors.brand
                    : AppColors.textTertiary,
              ),
              const SizedBox(width: 8),
              Text(
                l.homeFilterAll,
                style: AppTypography.body.copyWith(
                  color: current == null
                      ? AppColors.brand
                      : AppColors.textPrimary,
                  fontWeight: current == null
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 8),
        for (final ItemStatus status in _statusOrder)
          PopupMenuItem<String>(
            value: status.value,
            height: 36,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  status.materialIcon,
                  size: 16,
                  color: current == status
                      ? status.color
                      : AppColors.textTertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  status.genericLabel(l),
                  style: AppTypography.body.copyWith(
                    color: current == status
                        ? status.color
                        : AppColors.textPrimary,
                    fontWeight: current == status
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? chipColor.withAlpha(25) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? chipColor.withAlpha(80)
                : AppColors.surfaceBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              isActive ? current.materialIcon : Icons.filter_list,
              size: 14,
              color: isActive ? chipColor : AppColors.textTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isActive ? chipColor : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: isActive ? chipColor : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformChip(int? platformId, String label, {Color? color}) {
    final bool selected = platformId == null
        ? widget.filterPlatformIds.isEmpty
        : widget.filterPlatformIds.contains(platformId);
    final Color accentColor = color ?? AppColors.textPrimary;

    return ChoiceChip(
      label: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: selected ? AppColors.background : accentColor,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: selected,
      selectedColor: accentColor,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: selected ? Colors.transparent : accentColor.withAlpha(50),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      onSelected: (bool value) {
        widget.onPlatformToggled(platformId); // null = clear all
      },
    );
  }

  Widget _buildClearButton() {
    return GestureDetector(
      onTap: () {
        widget.onTypeToggled(null);
        widget.onPlatformToggled(null);
        widget.onTagToggled(null);
      },
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.close_rounded, size: 14,
                color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Text(
              S.of(context).clear,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  Widget _buildBarChip({required String label, Widget? trailing}) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label, style: AppTypography.bodySmall),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 2),
            trailing,
          ],
        ],
      ),
    );
  }

  List<Platform> _extractPlatforms() {
    final List<CollectionItem>? items = widget.itemsAsync.valueOrNull;
    if (items == null) return <Platform>[];

    final Map<int, Platform> map = <int, Platform>{};
    for (final CollectionItem item in items) {
      if (item.mediaType == MediaType.game &&
          item.platformId != null &&
          item.platformId != -1 &&
          item.platform != null) {
        map[item.platformId!] = item.platform!;
      }
    }
    return map.values.toList()
      ..sort((Platform a, Platform b) => a.name.compareTo(b.name));
  }

  String _findPlatformName(int platformId) {
    final List<CollectionItem>? items = widget.itemsAsync.valueOrNull;
    if (items == null) return '';
    for (final CollectionItem item in items) {
      if (item.platformId == platformId && item.platform != null) {
        return item.platform!.displayName;
      }
    }
    return '';
  }

  List<_TypeEntry> _typeEntries(S l, CollectionStats? stats) {
    return <_TypeEntry>[
      _TypeEntry(MediaType.game, l.collectionFilterGames, stats?.gameCount),
      _TypeEntry(MediaType.movie, l.collectionFilterMovies, stats?.movieCount),
      _TypeEntry(MediaType.tvShow, l.collectionFilterTvShows, stats?.tvShowCount),
      _TypeEntry(MediaType.animation, l.collectionFilterAnimation, stats?.animationCount),
      _TypeEntry(MediaType.visualNovel, l.collectionFilterVisualNovels, stats?.visualNovelCount),
      _TypeEntry(MediaType.manga, l.collectionFilterManga, stats?.mangaCount),
      _TypeEntry(MediaType.anime, l.mediaTypeAnime, stats?.animeCount),
      _TypeEntry(MediaType.custom, l.collectionFilterCustom, stats?.customCount),
    ];
  }

}

class _TypeEntry {
  const _TypeEntry(this.type, this.label, this.count);
  final MediaType type;
  final String label;
  final int? count;
}
