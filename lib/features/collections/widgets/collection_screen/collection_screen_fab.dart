import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/constants/platform_features.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/draggable_fab.dart';

enum CollectionMenuAction {
  customItem,
  rename,
  tierList,
  manageTags,
  copyAsText,
  export,
  import,
  delete,
}

class CollectionScreenFab extends StatelessWidget {
  const CollectionScreenFab({
    required this.canEdit,
    required this.isUncategorized,
    required this.isCollectionEditable,
    required this.isCanvasMode,
    required this.isTableMode,
    required this.isViewModeLocked,
    required this.onAddItems,
    required this.onCycleViewMode,
    required this.onToggleLock,
    required this.onToggleCanvas,
    required this.onMenuAction,
    super.key,
  });

  final bool canEdit;
  final bool isUncategorized;
  final bool isCollectionEditable;
  final bool isCanvasMode;
  final bool isTableMode;
  final bool isViewModeLocked;
  final VoidCallback onAddItems;
  final VoidCallback onCycleViewMode;
  final VoidCallback onToggleLock;
  final VoidCallback onToggleCanvas;
  final ValueChanged<CollectionMenuAction> onMenuAction;

  DraggableFabItem? _mainAction(S l) {
    // Uncategorized is a read-only legacy bucket: items can be moved out of it
    // but no longer added to it, so the "add items" action is hidden here.
    if (!canEdit || isCanvasMode || isUncategorized) return null;
    return DraggableFabItem(
      icon: Icons.add,
      label: l.collectionAddItems,
      onTap: onAddItems,
    );
  }

  List<DraggableFabItem> _primaryItems(S l) {
    return <DraggableFabItem>[
      if (!isCanvasMode)
        DraggableFabItem(
          icon: isTableMode ? Icons.grid_view : Icons.table_chart_outlined,
          label: isTableMode
              ? l.collectionListViewGrid
              : l.collectionListViewTable,
          onTap: onCycleViewMode,
        ),
      if (canEdit && isCanvasMode && kCanvasEnabled && !isUncategorized)
        DraggableFabItem(
          icon: isViewModeLocked ? Icons.lock : Icons.lock_open,
          label: isViewModeLocked
              ? l.collectionUnlockBoard
              : l.collectionLockBoard,
          iconColor: isViewModeLocked ? AppColors.warning : null,
          onTap: onToggleLock,
        ),
      if (kCanvasEnabled && !isUncategorized)
        DraggableFabItem(
          icon: isCanvasMode ? Icons.list : Icons.dashboard,
          label: isCanvasMode
              ? l.collectionSwitchToList
              : l.collectionSwitchToBoard,
          onTap: onToggleCanvas,
        ),
    ];
  }

  List<DraggableFabItem> _secondaryItems(S l) {
    if (isUncategorized) return const <DraggableFabItem>[];
    return <DraggableFabItem>[
      if (isCollectionEditable)
        DraggableFabItem(
          icon: Icons.add_box_outlined,
          label: l.customItemCreate,
          iconColor: AppColors.brand,
          onTap: () => onMenuAction(CollectionMenuAction.customItem),
        ),
      if (isCollectionEditable)
        DraggableFabItem(
          icon: Icons.tune,
          label: l.collectionEditMenu,
          onTap: () => onMenuAction(CollectionMenuAction.rename),
        ),
      DraggableFabItem(
        icon: Icons.leaderboard,
        label: l.tierListCreateFromCollection,
        onTap: () => onMenuAction(CollectionMenuAction.tierList),
      ),
      DraggableFabItem(
        icon: Icons.label_outlined,
        label: l.tagManage,
        onTap: () => onMenuAction(CollectionMenuAction.manageTags),
      ),
      DraggableFabItem(
        icon: Icons.text_snippet_outlined,
        label: l.copyAsText,
        onTap: () => onMenuAction(CollectionMenuAction.copyAsText),
      ),
      DraggableFabItem(
        icon: Icons.file_upload_outlined,
        label: l.collectionExport,
        onTap: () => onMenuAction(CollectionMenuAction.export),
      ),
      if (isCollectionEditable)
        DraggableFabItem(
          icon: Icons.file_download_outlined,
          label: l.collectionsImportCollection,
          onTap: () => onMenuAction(CollectionMenuAction.import),
        ),
      const DraggableFabDivider(),
      DraggableFabItem(
        icon: Icons.delete,
        label: l.delete,
        iconColor: AppColors.error,
        onTap: () => onMenuAction(CollectionMenuAction.delete),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return DraggableFab(
      key: ValueKey<bool>(isCanvasMode),
      mainAction: _mainAction(l),
      primaryItems: _primaryItems(l),
      items: _secondaryItems(l),
      initialRight: isCanvasMode ? 72 : null,
    );
  }
}
