import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/collection_sort_mode.dart';
import '../../../shared/models/collection_tag.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';
import '../../../core/database/dao/tag_dao.dart';
import '../../../core/database/database_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/media_poster_card.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/collection_selection_provider.dart';
import '../providers/collections_provider.dart';
import '../extensions/item_display_name.dart';
import 'collection_table/collection_table_view.dart';
import 'context_menu_item.dart';
import 'selectable_poster_card.dart';
import 'status_chip_row.dart';

/// Grid or table view for collection items, picked from [isTableMode];
/// otherwise the grid is shown. In table mode a manual sort enables
/// drag-to-reorder rows.
class CollectionItemsView extends ConsumerWidget {
  const CollectionItemsView({
    required this.collectionId,
    required this.items,
    this.isTableMode = false,
    required this.canEdit,
    required this.onItemTap,
    this.onItemMove,
    this.onItemClone,
    this.onItemRemove,
    this.onItemFocusChanged,
    this.tags = const <CollectionTag>[],
    this.filterTagIds = const <int>{},
    this.groupByTags = false,
    this.header,
    this.onTableFilterStatusChanged,
    super.key,
  });

  static final Logger _log = Logger('CollectionItemsView');

  final int? collectionId;
  final List<CollectionItem> items;
  final bool isTableMode;
  final bool canEdit;
  final ValueChanged<CollectionItem> onItemTap;
  final ValueChanged<CollectionItem>? onItemMove;
  final ValueChanged<CollectionItem>? onItemClone;
  final ValueChanged<CollectionItem>? onItemRemove;
  final void Function(CollectionItem item, bool hasFocus)? onItemFocusChanged;
  final List<CollectionTag> tags;
  final Set<int> filterTagIds;
  final bool groupByTags;

  /// Optional header that scrolls with the grid as a sliver. Table mode pins
  /// it above instead — that widget doesn't accept slivers.
  final Widget? header;

  /// Mirrors the table's status column filter outward so chevron counts in
  /// the outer filter bar can react to in-table cycling.
  final ValueChanged<ItemStatus?>? onTableFilterStatusChanged;

  static const double _desktopMaxCardWidth = 170;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return _withHeader(_buildEmptyState(context));
    }

    final CollectionSortMode sortMode =
        ref.watch(collectionSortProvider(collectionId));
    final bool isManualSort =
        sortMode == CollectionSortMode.manual && canEdit;

    if (isTableMode) {
      final Set<int>? selectedIds = canEdit
          ? ref.watch(collectionSelectionProvider(collectionId))
          : null;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: CollectionTableView(
          heroHeader: header,
          items: items,
          tags: tags,
          onItemTap: onItemTap,
          onItemSecondaryTap: canEdit
              ? (CollectionItem item, Offset pos) =>
                  _showItemContextMenu(context, ref, pos, item)
              : null,
          selectedIds: selectedIds,
          onToggleSelect: canEdit
              ? (int itemId) => ref
                  .read(collectionSelectionProvider(collectionId).notifier)
                  .toggle(itemId)
              : null,
          onToggleSelectAll: canEdit
              ? (bool selectAll) {
                  final CollectionSelectionNotifier notifier = ref.read(
                    collectionSelectionProvider(collectionId).notifier,
                  );
                  if (selectAll) {
                    notifier.selectAll(
                        items.map((CollectionItem i) => i.id));
                  } else {
                    notifier.clear();
                  }
                }
              : null,
          onRatingChanged: canEdit
              ? (int itemId, double? rating) {
                  ref
                      .read(collectionItemsNotifierProvider(collectionId)
                          .notifier)
                      .updateUserRating(itemId, rating);
                }
              : null,
          onStatusChanged: canEdit
              ? (int itemId, ItemStatus status, MediaType mediaType) {
                  ref
                      .read(collectionItemsNotifierProvider(collectionId)
                          .notifier)
                      .updateStatus(itemId, status, mediaType);
                }
              : null,
          onTagChanged: canEdit
              ? (int itemId, int? tagId) async {
                  final TagDao dao = ref.read(tagDaoProvider);
                  await dao.setItemTag(itemId, tagId);
                  ref
                      .read(collectionItemsNotifierProvider(collectionId)
                          .notifier)
                      .updateItemTag(itemId, tagId);
                }
              : null,
          onReorder: isManualSort
              ? (int oldIndex, int newIndex) {
                  ref
                      .read(collectionItemsNotifierProvider(collectionId)
                          .notifier)
                      .reorderItem(oldIndex, newIndex);
                }
              : null,
          onFilterStatusChanged: onTableFilterStatusChanged,
        ),
      );
    }

    return _buildGridView(context, ref);
  }

  /// Buckets items by their `tagId`. Items pointing at an unknown tag (e.g.
  /// after the tag was deleted) land in the "untagged" bucket.
  List<_TagGroup> _groupByTag(String untaggedLabel) {
    if (tags.isEmpty) {
      return <_TagGroup>[
        _TagGroup(name: null, items: items),
      ];
    }

    final Set<int> knownTagIds = <int>{
      for (final CollectionTag tag in tags) tag.id,
    };
    final Map<int, List<CollectionItem>> grouped =
        <int, List<CollectionItem>>{
      for (final CollectionTag tag in tags) tag.id: <CollectionItem>[],
    };
    final List<CollectionItem> untagged = <CollectionItem>[];

    for (final CollectionItem item in items) {
      if (item.tagId != null && knownTagIds.contains(item.tagId)) {
        grouped[item.tagId]!.add(item);
      } else {
        untagged.add(item);
      }
    }

    final List<_TagGroup> result = <_TagGroup>[];
    for (final CollectionTag tag in tags) {
      final List<CollectionItem> tagItems = grouped[tag.id]!;
      if (tagItems.isNotEmpty) {
        result.add(_TagGroup(
          name: tag.name,
          color: tag.color != null ? Color(tag.color!) : null,
          items: tagItems,
        ));
      }
    }
    if (untagged.isNotEmpty) {
      final String? label = result.isEmpty ? null : untaggedLabel;
      result.add(_TagGroup(name: label, items: untagged));
    }
    return result;
  }

  bool get _hasTagGroups =>
      tags.isNotEmpty && (groupByTags || filterTagIds.isNotEmpty);

  /// Pins [header] above [body].
  Widget _withHeader(Widget body) {
    if (header == null) return body;
    return Column(
      children: <Widget>[
        header!,
        Expanded(child: body),
      ],
    );
  }

  Widget _buildGridView(BuildContext context, WidgetRef ref) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isLandscape = isLandscapeMobile(context);
    final bool isDesktop = screenWidth >= kDesktopContentBreakpoint && !kIsMobile;

    final double gridPadding = isLandscape ? AppSpacing.sm : AppSpacing.screenPadding;
    final double crossSpacing = isLandscape ? AppSpacing.sm : AppSpacing.gridGap;
    final double mainSpacing = isLandscape ? AppSpacing.sm : AppSpacing.lg;

    final SliverGridDelegate gridDelegate;
    if (isDesktop) {
      gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: _desktopMaxCardWidth,
        crossAxisSpacing: crossSpacing,
        mainAxisSpacing: mainSpacing,
        childAspectRatio: 0.55,
      );
    } else {
      final int crossAxisCount;
      if (isLandscape) {
        crossAxisCount = AppSpacing.gridColumnsDesktop;
      } else if (screenWidth >= 500) {
        crossAxisCount = AppSpacing.gridColumnsTablet;
      } else {
        crossAxisCount = AppSpacing.gridColumnsMobile;
      }
      gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossSpacing,
        mainAxisSpacing: mainSpacing,
        childAspectRatio: 0.55,
      );
    }

    final SettingsState settings = ref.watch(settingsNotifierProvider);

    if (!_hasTagGroups) {
      return _buildFlatGridView(
          context, ref, gridDelegate, gridPadding, settings);
    }

    final S l = S.of(context);
    final List<_TagGroup> groups = _groupByTag(l.tagNone);
    final Map<int, CollectionTag> tagById = <int, CollectionTag>{
      for (final CollectionTag tag in tags) tag.id: tag,
    };

    // Flatten the per-tag buckets — the grid renders the joined sequence as
    // a regular grid; the headers come from the buckets above.
    final List<CollectionItem> sorted = <CollectionItem>[
      for (final _TagGroup g in groups) ...g.items,
    ];

    return RefreshIndicator(
      onRefresh: () => ref
          .read(collectionItemsNotifierProvider(collectionId).notifier)
          .refresh(),
      child: header == null
          ? GridView.builder(
              padding: EdgeInsets.all(gridPadding),
              gridDelegate: gridDelegate,
              itemCount: sorted.length,
              itemBuilder: (BuildContext context, int index) {
                return _buildGridCard(
                  context,
                  ref,
                  sorted[index],
                  isLandscape,
                  tagById,
                  settings,
                  tagGlow: true,
                );
              },
            )
          : CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(child: header),
                SliverPadding(
                  padding: EdgeInsets.all(gridPadding),
                  sliver: SliverGrid.builder(
                    gridDelegate: gridDelegate,
                    itemCount: sorted.length,
                    itemBuilder: (BuildContext context, int index) {
                      return _buildGridCard(
                        context,
                        ref,
                        sorted[index],
                        isLandscape,
                        tagById,
                        settings,
                        tagGlow: true,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFlatGridView(
    BuildContext context,
    WidgetRef ref,
    SliverGridDelegate gridDelegate,
    double gridPadding,
    SettingsState settings,
  ) {
    final bool isLandscape = isLandscapeMobile(context);
    final Map<int, CollectionTag> tagById = <int, CollectionTag>{
      for (final CollectionTag tag in tags) tag.id: tag,
    };
    return RefreshIndicator(
      onRefresh: () => ref
          .read(collectionItemsNotifierProvider(collectionId).notifier)
          .refresh(),
      child: header == null
          ? GridView.builder(
              padding: EdgeInsets.all(gridPadding),
              gridDelegate: gridDelegate,
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                return _buildGridCard(
                    context, ref, items[index], isLandscape, tagById, settings);
              },
            )
          : CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(child: header),
                SliverPadding(
                  padding: EdgeInsets.all(gridPadding),
                  sliver: SliverGrid.builder(
                    gridDelegate: gridDelegate,
                    itemCount: items.length,
                    itemBuilder: (BuildContext context, int index) {
                      return _buildGridCard(context, ref, items[index],
                          isLandscape, tagById, settings);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildGridCard(
    BuildContext context,
    WidgetRef ref,
    CollectionItem item,
    bool isLandscape,
    Map<int, CollectionTag> tagById,
    SettingsState settings, {
    bool tagGlow = false,
  }) {
    final CollectionTag? tag =
        item.tagId != null ? tagById[item.tagId] : null;
    final Set<int> selection = canEdit
        ? ref.watch(collectionSelectionProvider(collectionId))
        : const <int>{};
    final bool selectionActive = selection.isNotEmpty;
    final bool isSelected = selection.contains(item.id);

    final Widget card = MediaPosterCard(
      key: ValueKey<int>(item.id),
      variant: isLandscape || isCompactScreen(context)
          ? CardVariant.compact
          : CardVariant.grid,
      title: ref.displayNameOf(item),
      imageUrl: item.thumbnailUrl ?? '',
      cacheImageType: item.imageType,
      cacheImageId: item.coverImageId,
      userRating: item.userRating,
      apiRating: item.apiRating,
      splitRatings: true,
      year: item.releaseYear,
      platformLabel: item.platform?.displayName,
      platformColor: item.platform?.familyColor,
      platformOverlayAsset: settings.resolveOverlayFor(item),
      mediaType: item.displayMediaType,
      status: item.status,
      tagName: tag?.name,
      tagColor: tag?.color,
      tagGlow: tagGlow,
      onTagTap: canEdit && tags.isNotEmpty
          ? (Offset pos) => _showTagPopup(context, pos, item)
          : null,
      onTap: selectionActive
          ? () => ref
              .read(collectionSelectionProvider(collectionId).notifier)
              .toggle(item.id)
          : () => onItemTap(item),
      onSecondaryTap: canEdit
          ? (Offset pos) => _showItemContextMenu(context, ref, pos, item)
          : null,
      onLongPress: canEdit
          ? () => ref
              .read(collectionSelectionProvider(collectionId).notifier)
              .toggle(item.id)
          : null,
      onFocusChanged: onItemFocusChanged != null
          ? (bool hasFocus) => onItemFocusChanged!(item, hasFocus)
          : null,
    );
    if (!canEdit) return card;
    return SelectablePosterCard(
      isSelected: isSelected,
      selectionActive: selectionActive,
      onToggleSelect: () => ref
          .read(collectionSelectionProvider(collectionId).notifier)
          .toggle(item.id),
      child: card,
    );
  }

  /// Distinct from `null` (popup dismissed) — picked when the user explicitly
  /// chose "no tag".
  static const int _noTagSentinel = -1;

  void _showTagPopup(
    BuildContext context,
    Offset position,
    CollectionItem item,
  ) {
    final S l = S.of(context);
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;

    showMenu<int>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<int>>[
        PopupMenuItem<int>(
          value: _noTagSentinel,
          child: Text(
            l.tagNone,
            style: AppTypography.bodySmall.copyWith(
              color: item.tagId == null
                  ? AppColors.brand
                  : AppColors.textTertiary,
            ),
          ),
        ),
        const PopupMenuDivider(),
        for (final CollectionTag tag in tags)
          PopupMenuItem<int>(
            value: tag.id,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: tag.color != null
                        ? Color(tag.color!)
                        : AppColors.brand,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  tag.name,
                  style: AppTypography.bodySmall.copyWith(
                    color: item.tagId == tag.id
                        ? AppColors.brand
                        : null,
                    fontWeight: item.tagId == tag.id
                        ? FontWeight.w600
                        : null,
                  ),
                ),
              ],
            ),
          ),
      ],
    ).then((int? selected) {
      if (selected == null || !context.mounted) return;
      final int? newTagId = selected == _noTagSentinel ? null : selected;
      if (newTagId == item.tagId) return;
      _setItemTag(context, item, newTagId);
    });
  }

  void _setItemTag(BuildContext context, CollectionItem item, int? tagId) {
    final ProviderContainer container = ProviderScope.containerOf(context);
    final TagDao dao = container.read(tagDaoProvider);
    dao.setItemTag(item.id, tagId).then((_) {
      container
          .read(collectionItemsNotifierProvider(collectionId).notifier)
          .updateItemTag(item.id, tagId);
    }).catchError((Object error, StackTrace stack) {
      _log.warning('Failed to set tag on item ${item.id}', error, stack);
      if (context.mounted) {
        final S l = S.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.tagUpdateFailed)),
        );
      }
    });
  }

  void _showItemContextMenu(
    BuildContext context,
    WidgetRef ref,
    Offset position,
    CollectionItem item,
  ) {
    final S l = S.of(context);
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final CollectionSortMode sortMode =
        ref.read(collectionSortProvider(collectionId));
    final bool isManualSort =
        sortMode == CollectionSortMode.manual && canEdit;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<String>>[
        if (isManualSort) ...<PopupMenuEntry<String>>[
          contextMenuItem<String>(
            value: 'moveToTop',
            icon: Icons.vertical_align_top,
            label: l.moveToTop,
          ),
          contextMenuItem<String>(
            value: 'moveToBottom',
            icon: Icons.vertical_align_bottom,
            label: l.moveToBottom,
          ),
          const PopupMenuDivider(),
        ],
        if (onItemMove != null)
          contextMenuItem<String>(
            value: 'move',
            icon: Icons.drive_file_move_outlined,
            label: l.collectionMoveToCollection,
          ),
        if (onItemClone != null)
          contextMenuItem<String>(
            value: 'clone',
            icon: Icons.copy_outlined,
            label: l.collectionCopyToCollection,
          ),
        if ((onItemMove != null || onItemClone != null) &&
            onItemRemove != null)
          const PopupMenuDivider(),
        if (onItemRemove != null)
          contextMenuItem<String>(
            value: 'remove',
            icon: Icons.remove_circle_outline,
            label: l.remove,
            color: AppColors.error,
          ),
        if (canEdit)
          ...statusChipPopupMenuEntries(context: context, item: item),
      ],
    ).then((String? value) {
      if (value == null) return;
      final ItemStatus? newStatus = tryDecodeStatusMenuValue(value);
      if (newStatus != null) {
        if (newStatus != item.status) {
          ref
              .read(collectionItemsNotifierProvider(collectionId).notifier)
              .updateStatus(item.id, newStatus, item.mediaType);
        }
        return;
      }
      switch (value) {
        case 'moveToTop':
          ref
              .read(collectionItemsNotifierProvider(collectionId).notifier)
              .moveItemToTop(item.id);
        case 'moveToBottom':
          ref
              .read(collectionItemsNotifierProvider(collectionId).notifier)
              .moveItemToBottom(item.id);
        case 'move':
          onItemMove?.call(item);
        case 'clone':
          onItemClone?.call(item);
        case 'remove':
          onItemRemove?.call(item);
      }
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    final S l = S.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.shelves,
              size: 64,
              color: AppColors.textTertiary.withAlpha(120),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l.collectionNoItemsYet, style: AppTypography.h2),
            const SizedBox(height: AppSpacing.sm),
            Text(
              canEdit ? l.collectionEmptyAddHint : l.collectionEmptyReadonly,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One bucket of items sharing a tag. `name == null` means the bucket is
/// rendered without a divider (used when grouping is off).
class _TagGroup {
  _TagGroup({required this.name, required this.items, this.color});

  final String? name;
  final Color? color;
  final List<CollectionItem> items;
}
