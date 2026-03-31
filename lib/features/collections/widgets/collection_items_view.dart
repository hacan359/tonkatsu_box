// Grid/List/Reorder view для элементов коллекции.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/collection_sort_mode.dart';
import '../../../shared/models/collection_tag.dart';
import '../../../core/database/dao/tag_dao.dart';
import '../../../core/database/database_service.dart';
import '../../../shared/navigation/navigation_shell.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/media_poster_card.dart';
import '../providers/collections_provider.dart';
import 'collection_item_tile.dart';
import 'collection_table_view.dart';

/// View для отображения элементов коллекции в grid/list/reorder режиме.
///
/// Автоматически выбирает режим отображения на основе [isGridMode]
/// и текущей сортировки (manual sort → reorderable list).
class CollectionItemsView extends ConsumerWidget {
  /// Создаёт [CollectionItemsView].
  const CollectionItemsView({
    required this.collectionId,
    required this.items,
    required this.isGridMode,
    this.isTableMode = false,
    required this.canEdit,
    required this.onItemTap,
    this.onItemMove,
    this.onItemClone,
    this.onItemRemove,
    this.onItemFocusChanged,
    this.tags = const <CollectionTag>[],
    super.key,
  });

  /// ID коллекции.
  final int? collectionId;

  /// Отфильтрованные элементы для отображения.
  final List<CollectionItem> items;

  /// Режим отображения — grid или list.
  final bool isGridMode;

  /// Режим таблицы (Excel-like).
  final bool isTableMode;

  /// Можно ли редактировать (move/remove/reorder).
  final bool canEdit;

  /// Callback нажатия на элемент.
  final ValueChanged<CollectionItem> onItemTap;

  /// Callback перемещения элемента.
  final ValueChanged<CollectionItem>? onItemMove;

  /// Callback копирования элемента.
  final ValueChanged<CollectionItem>? onItemClone;

  /// Callback удаления элемента.
  final ValueChanged<CollectionItem>? onItemRemove;

  /// Callback при изменении фокуса на элементе (для клавиатурных действий).
  final void Function(CollectionItem item, bool hasFocus)? onItemFocusChanged;

  /// Теги коллекции для группировки.
  final List<CollectionTag> tags;

  /// Максимальная ширина карточки на десктопе.
  static const double _desktopMaxCardWidth = 150;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return _buildEmptyState(context);
    }

    if (isTableMode) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: CollectionTableView(
          items: items,
          onItemTap: onItemTap,
          onItemSecondaryTap: canEdit
              ? (CollectionItem item, Offset pos) =>
                  _showItemContextMenu(context, pos, item)
              : null,
        ),
      );
    }

    if (isGridMode) {
      return _buildGridView(context, ref);
    }

    final CollectionSortMode sortMode =
        ref.watch(collectionSortProvider(collectionId));
    final bool isManualSort =
        sortMode == CollectionSortMode.manual && canEdit;

    if (isManualSort) {
      return _buildReorderableList(context, ref);
    }

    return _buildListView(context, ref);
  }

  /// Группирует элементы по тегам.
  ///
  /// Элементы с unknown tagId (orphaned) попадают в группу "без тега".
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
        result.add(_TagGroup(name: tag.name, items: tagItems));
      }
    }
    if (untagged.isNotEmpty) {
      final String? label = result.isEmpty ? null : untaggedLabel;
      result.add(_TagGroup(name: label, items: untagged));
    }
    return result;
  }

  bool get _hasTagGroups => tags.isNotEmpty;

  Widget _buildListView(BuildContext context, WidgetRef ref) {
    if (!_hasTagGroups) {
      return _buildFlatListView(context, ref, items);
    }

    final S l = S.of(context);
    final List<_TagGroup> groups = _groupByTag(l.tagNone);

    return RefreshIndicator(
      onRefresh: () => ref
          .read(collectionItemsNotifierProvider(collectionId).notifier)
          .refresh(),
      child: CustomScrollView(
        slivers: <Widget>[
          for (int i = 0; i < groups.length; i++) ...<Widget>[
            if (groups[i].name != null)
              SliverToBoxAdapter(
                child: _buildSectionDivider(
                  groups[i].name!,
                  groups[i].items.length,
                  isFirst: i == 0,
                ),
              ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  final CollectionItem item = groups[i].items[index];
                  return _buildListTile(context, item);
                },
                childCount: groups[i].items.length,
              ),
            ),
            if (i < groups.length - 1)
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.sm),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildFlatListView(
    BuildContext context,
    WidgetRef ref,
    List<CollectionItem> listItems,
  ) {
    return RefreshIndicator(
      onRefresh: () => ref
          .read(collectionItemsNotifierProvider(collectionId).notifier)
          .refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: listItems.length,
        itemBuilder: (BuildContext context, int index) {
          return _buildListTile(context, listItems[index]);
        },
      ),
    );
  }

  Widget _buildListTile(BuildContext context, CollectionItem item) {
    return CollectionItemTile(
      key: ValueKey<int>(item.id),
      item: item,
      isEditable: canEdit,
      onMove: canEdit ? () => onItemMove?.call(item) : null,
      onClone: canEdit ? () => onItemClone?.call(item) : null,
      onRemove: canEdit ? () => onItemRemove?.call(item) : null,
      onSecondaryTap: canEdit
          ? (Offset pos) => _showItemContextMenu(context, pos, item)
          : null,
      onLongPress: canEdit
          ? () => _showItemContextMenu(
                context,
                _centerOfContext(context),
                item,
              )
          : null,
      onTap: () => onItemTap(item),
    );
  }

  Widget _buildGridView(BuildContext context, WidgetRef ref) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isLandscape = isLandscapeMobile(context);
    final bool isDesktop = screenWidth >= navigationBreakpoint && !kIsMobile;

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

    if (!_hasTagGroups) {
      return _buildFlatGridView(context, ref, gridDelegate, gridPadding);
    }

    final S l = S.of(context);
    final List<_TagGroup> groups = _groupByTag(l.tagNone);
    final Map<int, CollectionTag> tagById = <int, CollectionTag>{
      for (final CollectionTag tag in tags) tag.id: tag,
    };

    return RefreshIndicator(
      onRefresh: () => ref
          .read(collectionItemsNotifierProvider(collectionId).notifier)
          .refresh(),
      child: CustomScrollView(
        slivers: <Widget>[
          for (int i = 0; i < groups.length; i++) ...<Widget>[
            if (groups[i].name != null)
              SliverToBoxAdapter(
                child: _buildSectionDivider(
                  groups[i].name!,
                  groups[i].items.length,
                  isFirst: i == 0,
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: gridPadding),
              sliver: SliverGrid(
                gridDelegate: gridDelegate,
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    return _buildGridCard(
                      context,
                      groups[i].items[index],
                      isLandscape,
                      tagById,
                    );
                  },
                  childCount: groups[i].items.length,
                ),
              ),
            ),
            if (i < groups.length - 1)
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.sm),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildFlatGridView(
    BuildContext context,
    WidgetRef ref,
    SliverGridDelegate gridDelegate,
    double gridPadding,
  ) {
    final bool isLandscape = isLandscapeMobile(context);
    final Map<int, CollectionTag> tagById = <int, CollectionTag>{
      for (final CollectionTag tag in tags) tag.id: tag,
    };
    return RefreshIndicator(
      onRefresh: () => ref
          .read(collectionItemsNotifierProvider(collectionId).notifier)
          .refresh(),
      child: GridView.builder(
        padding: EdgeInsets.all(gridPadding),
        gridDelegate: gridDelegate,
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) {
          return _buildGridCard(context, items[index], isLandscape, tagById);
        },
      ),
    );
  }

  Widget _buildGridCard(
    BuildContext context,
    CollectionItem item,
    bool isLandscape,
    Map<int, CollectionTag> tagById,
  ) {
    final CollectionTag? tag =
        item.tagId != null ? tagById[item.tagId] : null;

    return MediaPosterCard(
      key: ValueKey<int>(item.id),
      variant: isLandscape ? CardVariant.compact : CardVariant.grid,
      title: item.itemName,
      imageUrl: item.thumbnailUrl ?? '',
      cacheImageType: item.imageType,
      cacheImageId: item.externalId.toString(),
      userRating: item.userRating,
      apiRating: item.apiRating,
      year: item.releaseYear,
      platformLabel: item.platform?.displayName,
      platformColor: item.platform?.familyColor,
      platformOverlayAsset: item.platform?.overlayAsset,
      mediaType: item.displayMediaType,
      status: item.status,
      tagName: tag?.name,
      tagColor: tag?.color,
      onTagTap: canEdit && tags.isNotEmpty
          ? (Offset pos) => _showTagPopup(context, pos, item)
          : null,
      onTap: () => onItemTap(item),
      onSecondaryTap: canEdit
          ? (Offset pos) => _showItemContextMenu(context, pos, item)
          : null,
      onLongPress: canEdit
          ? () => _showItemContextMenu(
                context,
                _centerOfContext(context),
                item,
              )
          : null,
      onFocusChanged: onItemFocusChanged != null
          ? (bool hasFocus) => onItemFocusChanged!(item, hasFocus)
          : null,
    );
  }

  Widget _buildReorderableList(BuildContext context, WidgetRef ref) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      buildDefaultDragHandles: false,
      itemCount: items.length,
      proxyDecorator:
          (Widget child, int index, Animation<double> animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? child) {
            final double elevation = lerpDouble(0, 6, animation.value) ?? 0;
            return Material(
              elevation: elevation,
              color: Colors.transparent,
              shadowColor: Colors.black26,
              child: child,
            );
          },
          child: child,
        );
      },
      onReorder: (int oldIndex, int newIndex) {
        // ReorderableListView даёт newIndex ПОСЛЕ удаления элемента
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        ref
            .read(collectionItemsNotifierProvider(collectionId).notifier)
            .reorderItem(oldIndex, newIndex);
      },
      itemBuilder: (BuildContext context, int index) {
        final CollectionItem item = items[index];
        return CollectionItemTile(
          key: ValueKey<int>(item.id),
          item: item,
          isEditable: canEdit,
          showDragHandle: true,
          dragIndex: index,
          onMove: canEdit ? () => onItemMove?.call(item) : null,
          onRemove: canEdit ? () => onItemRemove?.call(item) : null,
          onSecondaryTap: canEdit
              ? (Offset pos) => _showItemContextMenu(
                    context,
                    pos,
                    item,
                  )
              : null,
          onLongPress: canEdit
              ? () => _showItemContextMenu(
                    context,
                    _centerOfContext(context),
                    item,
                  )
              : null,
          onTap: () => onItemTap(item),
        );
      },
    );
  }

  /// Разделитель секции с названием и количеством.
  Widget _buildSectionDivider(
    String name,
    int count, {
    required bool isFirst,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        top: isFirst ? AppSpacing.xs : AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.surfaceBorder,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              '$name ($count)',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.surfaceBorder,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
    );
  }

  /// Показывает контекстное меню ПКМ для элемента коллекции.
  /// Центр экрана — fallback позиция для контекстного меню без курсора.
  Offset _centerOfContext(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    return Offset(size.width / 2, size.height / 2);
  }

  /// Sentinel value для "без тега" в popup (чтобы отличить от dismiss).
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
          .refresh();
    }).catchError((Object error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
    });
  }

  void _showItemContextMenu(
    BuildContext context,
    Offset position,
    CollectionItem item,
  ) {
    final S l = S.of(context);
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<String>>[
        if (onItemMove != null)
          PopupMenuItem<String>(
            value: 'move',
            child: ListTile(
              leading: const Icon(Icons.drive_file_move_outlined),
              title: Text(l.collectionMoveToCollection),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (onItemClone != null)
          PopupMenuItem<String>(
            value: 'clone',
            child: ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: Text(l.collectionCopyToCollection),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if ((onItemMove != null || onItemClone != null) &&
            onItemRemove != null)
          const PopupMenuDivider(),
        if (onItemRemove != null)
          PopupMenuItem<String>(
            value: 'remove',
            child: ListTile(
              leading: const Icon(
                Icons.remove_circle_outline,
                color: AppColors.error,
              ),
              title: Text(
                l.remove,
                style: const TextStyle(color: AppColors.error),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    ).then((String? value) {
      if (value == null) return;
      switch (value) {
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
              canEdit
                  ? 'Add items to start building your collection.'
                  : 'This collection is empty.',
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

/// Группа элементов по тегу.
class _TagGroup {
  _TagGroup({required this.name, required this.items});

  /// Название тега (null = без разделителя).
  final String? name;

  /// Элементы в группе.
  final List<CollectionItem> items;
}
