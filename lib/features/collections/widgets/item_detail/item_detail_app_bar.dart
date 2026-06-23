import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/constants/platform_features.dart';
import '../../../../shared/models/collection_item.dart';
import '../../../../shared/models/media_type.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/screen_app_bar.dart';

enum ItemDetailMenuAction { refresh, rename, move, clone, remove }

class ItemDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ItemDetailAppBar({
    required this.item,
    required this.displayName,
    required this.isEditable,
    required this.hasCanvas,
    required this.showCanvas,
    required this.isViewModeLocked,
    required this.onToggleLock,
    required this.onToggleCanvas,
    required this.onEditCustom,
    required this.onMenuSelected,
    this.onToggleFavorite,
    this.canTrackReleases = false,
    this.isTracked = false,
    this.onToggleTracked,
    this.trackTooltip,
    this.untrackTooltip,
    super.key,
  });

  final CollectionItem item;
  final String displayName;
  final bool isEditable;
  final bool hasCanvas;
  final bool showCanvas;
  final bool isViewModeLocked;
  final VoidCallback onToggleLock;
  final VoidCallback onToggleCanvas;
  final VoidCallback onEditCustom;
  final ValueChanged<ItemDetailMenuAction> onMenuSelected;

  /// Toggles the favorite flag; when null the heart is hidden.
  final VoidCallback? onToggleFavorite;

  /// Whether the calendar bell applies to this item.
  final bool canTrackReleases;

  /// Whether the item is currently on the calendar (tracked / added).
  final bool isTracked;

  /// Toggles calendar membership; required when [canTrackReleases] is true.
  final VoidCallback? onToggleTracked;

  /// Bell tooltips; default to the release-tracking wording.
  final String? trackTooltip;
  final String? untrackTooltip;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  String _withShortcut(String label, String shortcut) =>
      kIsMobile ? label : '$label ($shortcut)';

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final ThemeData theme = Theme.of(context);
    return ScreenAppBar(
      title: displayName,
      actions: <Widget>[
        if (isEditable && onToggleFavorite != null)
          IconButton(
            icon: Icon(
              item.isFavorite ? Icons.favorite : Icons.heart_broken,
            ),
            color: item.isFavorite
                ? AppColors.favorite
                : AppColors.textSecondary,
            tooltip: item.isFavorite
                ? l.removeFromFavorites
                : l.addToFavorites,
            onPressed: onToggleFavorite,
          ),
        if (canTrackReleases)
          IconButton(
            icon: Icon(
              isTracked ? Icons.notifications_active : Icons.notifications_none,
            ),
            color: isTracked ? AppColors.brand : AppColors.textSecondary,
            tooltip: isTracked
                ? (untrackTooltip ?? l.releasesUntrackShow)
                : (trackTooltip ?? l.releasesTrackShow),
            onPressed: onToggleTracked,
          ),
        if (isEditable && hasCanvas && showCanvas)
          IconButton(
            icon: Icon(isViewModeLocked ? Icons.lock : Icons.lock_open),
            color: isViewModeLocked
                ? AppColors.warning
                : AppColors.textSecondary,
            tooltip: _withShortcut(
              isViewModeLocked
                  ? l.collectionUnlockBoard
                  : l.collectionLockBoard,
              'Ctrl+L',
            ),
            onPressed: onToggleLock,
          ),
        if (hasCanvas)
          IconButton(
            icon: Icon(
              showCanvas ? Icons.dashboard : Icons.dashboard_outlined,
            ),
            color: showCanvas ? AppColors.brand : AppColors.textSecondary,
            tooltip: _withShortcut(l.boardTab, 'Ctrl+B'),
            onPressed: onToggleCanvas,
          ),
        if (isEditable && item.mediaType == MediaType.custom)
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            color: AppColors.textSecondary,
            tooltip: l.customItemEdit,
            onPressed: onEditCustom,
          ),
        if (isEditable)
          PopupMenuButton<ItemDetailMenuAction>(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            onSelected: onMenuSelected,
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<ItemDetailMenuAction>>[
              if (item.mediaType != MediaType.custom)
                _menuItem(
                  ItemDetailMenuAction.refresh,
                  Icons.refresh,
                  l.refreshItemFromApi,
                ),
              if (item.mediaType != MediaType.custom)
                _menuItem(
                  ItemDetailMenuAction.rename,
                  Icons.drive_file_rename_outline,
                  l.renameItem,
                ),
              _menuItem(
                ItemDetailMenuAction.move,
                Icons.drive_file_move_outlined,
                l.collectionMoveToCollection,
              ),
              _menuItem(
                ItemDetailMenuAction.clone,
                Icons.copy_outlined,
                l.collectionCopyToCollection,
              ),
              const PopupMenuDivider(),
              _menuItem(
                ItemDetailMenuAction.remove,
                Icons.delete_outline,
                l.remove,
                color: theme.colorScheme.error,
              ),
            ],
          ),
      ],
    );
  }

  PopupMenuItem<ItemDetailMenuAction> _menuItem(
    ItemDetailMenuAction value,
    IconData icon,
    String label, {
    Color? color,
  }) {
    return PopupMenuItem<ItemDetailMenuAction>(
      value: value,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: color != null ? TextStyle(color: color) : null,
        ),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
