// Grid/List/Reorder view для элементов коллекции.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/collection_sort_mode.dart';
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

  Widget _buildListView(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref
          .read(collectionItemsNotifierProvider(collectionId).notifier)
          .refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) {
          final CollectionItem item = items[index];
          return CollectionItemTile(
            key: ValueKey<int>(item.id),
            item: item,
            isEditable: canEdit,
            onMove: canEdit ? () => onItemMove?.call(item) : null,
            onClone: canEdit ? () => onItemClone?.call(item) : null,
            onRemove: canEdit ? () => onItemRemove?.call(item) : null,
            onTap: () => onItemTap(item),
          );
        },
      ),
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
      // На десктопе ограничиваем максимальный размер карточки
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

    return RefreshIndicator(
      onRefresh: () => ref
          .read(collectionItemsNotifierProvider(collectionId).notifier)
          .refresh(),
      child: GridView.builder(
        padding: EdgeInsets.all(gridPadding),
        gridDelegate: gridDelegate,
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) {
          final CollectionItem item = items[index];
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
            subtitle: item.genresString,
            mediaType: item.mediaType,
            status: item.status,
            onTap: () => onItemTap(item),
            onFocusChanged: onItemFocusChanged != null
                ? (bool hasFocus) => onItemFocusChanged!(item, hasFocus)
                : null,
          );
        },
      ),
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
          onTap: () => onItemTap(item),
        );
      },
    );
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
