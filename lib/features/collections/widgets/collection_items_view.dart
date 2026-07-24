import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/collection_sort_mode.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/tag.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/utils/item_card_progress.dart';
import '../../../shared/widgets/media_poster_card.dart';
import '../../settings/providers/settings_provider.dart';
import '../helpers/collection_actions.dart';
import '../helpers/tracker_card_progress.dart';
import '../providers/collection_selection_provider.dart';
import '../providers/collections_provider.dart';
import '../providers/item_tags_provider.dart';
import '../extensions/item_display_name.dart';
import 'collection_table/collection_table_view.dart';
import 'context_menu_item.dart';
import 'tag_picker_dialog.dart';
import 'selectable_poster_card.dart';
import 'status_chip_row.dart';
import '../../../shared/constants/platform_ui.dart';

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
    this.tags = const <Tag>[],
    this.itemTags = const <int, List<int>>{},
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
  final List<Tag> tags;

  /// Item id → global tag ids (from `itemTagsProvider`).
  final Map<int, List<int>> itemTags;
  final Set<int> filterTagIds;
  final bool groupByTags;

  /// Optional header that scrolls with the grid as a sliver. Table mode pins
  /// it above instead — that widget doesn't accept slivers.
  final Widget? header;

  /// Mirrors the table's status column filter outward so chevron counts in
  /// the outer filter bar can react to in-table cycling.
  final ValueChanged<ItemStatus?>? onTableFilterStatusChanged;

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
          collectionId: collectionId,
          heroHeader: header,
          items: items,
          tags: tags,
          itemTags: itemTags,
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
          onTagsEdit: canEdit
              ? (int itemId) => _editItemTags(context, ref, itemId)
              : null,
          onFavoriteToggled: canEdit
              ? (int itemId) => ref
                  .read(collectionItemsNotifierProvider(collectionId).notifier)
                  .toggleFavorite(itemId)
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

  /// Buckets items by their primary (first in display order) tag, so every
  /// item appears exactly once even when it carries several tags.
  List<_TagGroup> _groupByTag(String untaggedLabel) {
    if (tags.isEmpty) {
      return <_TagGroup>[
        _TagGroup(name: null, items: items),
      ];
    }

    final Map<int, List<CollectionItem>> grouped =
        <int, List<CollectionItem>>{
      for (final Tag tag in tags) tag.id: <CollectionItem>[],
    };
    final List<CollectionItem> untagged = <CollectionItem>[];

    final Map<int, Tag> tagById = tags.byId;
    for (final CollectionItem item in items) {
      final Tag? primary = tagById.primaryFor(itemTags[item.id]);
      if (primary != null) {
        grouped[primary.id]!.add(item);
      } else {
        untagged.add(item);
      }
    }

    final List<_TagGroup> result = <_TagGroup>[];
    for (final Tag tag in tags) {
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

    final SettingsState settings = ref.watch(settingsNotifierProvider);

    final SliverGridDelegate gridDelegate;
    if (isDesktop) {
      gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: AppSpacing.desktopMaxCardWidth * settings.cardScale,
        crossAxisSpacing: crossSpacing,
        mainAxisSpacing: mainSpacing,
        childAspectRatio: AppSpacing.posterAspectRatio,
      );
    } else {
      final int baseCount;
      if (isLandscape) {
        baseCount = AppSpacing.gridColumnsDesktop;
      } else if (screenWidth >= 500) {
        baseCount = AppSpacing.gridColumnsTablet;
      } else {
        baseCount = AppSpacing.gridColumnsMobile;
      }
      gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppSpacing.scaledColumns(baseCount, settings.cardScale),
        crossAxisSpacing: crossSpacing,
        mainAxisSpacing: mainSpacing,
        childAspectRatio: AppSpacing.posterAspectRatio,
      );
    }

    if (!_hasTagGroups) {
      return _buildFlatGridView(
          context, ref, gridDelegate, gridPadding, settings);
    }

    final S l = S.of(context);
    final List<_TagGroup> groups = _groupByTag(l.tagNone);

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
                    context, ref, items[index], isLandscape, settings);
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
                      return _buildGridCard(
                          context, ref, items[index], isLandscape, settings);
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
    SettingsState settings, {
    bool tagGlow = false,
  }) {
    final Tag? tag = tags.primaryFor(itemTags[item.id]);
    final int tagCount = itemTags[item.id]?.length ?? 0;
    final Set<int> selection = canEdit
        ? ref.watch(collectionSelectionProvider(collectionId))
        : const <int>{};
    final bool selectionActive = selection.isNotEmpty;
    final bool isSelected = selection.contains(item.id);
    final ItemCardProgress? progress =
        itemCardProgress(item) ?? trackerCardProgress(ref, item);

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
      typeLabelOverride: item.formatLabel,
      status: item.status,
      progress: progress,
      isFavorite: item.isFavorite,
      showFavorite: canEdit,
      enableHoverScale: !isSelected,
      onToggleFavorite: canEdit && !selectionActive
          ? () => ref
              .read(collectionItemsNotifierProvider(collectionId).notifier)
              .toggleFavorite(item.id)
          : null,
      tagName: tag?.name,
      tagColor: tag?.color,
      tagTextColor: tag?.textColor,
      tagMoreCount: tagCount > 1 ? tagCount - 1 : 0,
      tagGlow: tagGlow,
      onTagTap: canEdit
          ? (Offset pos) => _editItemTags(context, ref, item.id)
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

  /// Opens the multi-select tag picker for the item and persists the result.
  void _editItemTags(BuildContext context, WidgetRef ref, int itemId) {
    final Set<int> current = Set<int>.of(
        ref.read(itemTagsProvider).valueOrNull?[itemId] ?? const <int>[]);
    TagPickerDialog.show(context, initialSelection: current)
        .then((Set<int>? selected) {
      if (selected == null || !context.mounted) return;
      final ProviderContainer container = ProviderScope.containerOf(context);
      container
          .read(itemTagsProvider.notifier)
          .setItemTags(itemId, selected)
          .catchError((Object error, StackTrace stack) {
        _log.warning('Failed to set tags on item $itemId', error, stack);
        if (context.mounted) {
          context.showSnack(S.of(context).tagUpdateFailed,
              type: SnackType.error);
        }
      });
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
        if (canEdit) ...<PopupMenuEntry<String>>[
          contextMenuItem<String>(
            value: 'favorite',
            icon: item.isFavorite ? Icons.favorite : Icons.favorite_border,
            label:
                item.isFavorite ? l.removeFromFavorites : l.addToFavorites,
          ),
          contextMenuItem<String>(
            value: 'tags',
            icon: Icons.label_outline,
            label: l.tagPickerTitle,
          ),
          const PopupMenuDivider(),
        ],
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
        contextMenuItem<String>(
          value: 'copyLink',
          icon: Icons.link,
          label: l.cardLinkCopy,
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
        case 'favorite':
          ref
              .read(collectionItemsNotifierProvider(collectionId).notifier)
              .toggleFavorite(item.id);
        case 'tags':
          if (context.mounted) _editItemTags(context, ref, item.id);
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
        case 'copyLink':
          if (context.mounted) CollectionActions.copyItemLink(context, item);
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
