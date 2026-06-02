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
    this.canTrackReleases = false,
    this.isTracked = false,
    this.onToggleTracked,
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

  /// Whether the release-tracking bell applies to this item (TMDB TV / anime).
  final bool canTrackReleases;

  /// Whether the item is currently tracked for releases.
  final bool isTracked;

  /// Toggles release tracking; required when [canTrackReleases] is true.
  final VoidCallback? onToggleTracked;

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
        if (canTrackReleases)
          IconButton(
            icon: Icon(
              isTracked ? Icons.notifications_active : Icons.notifications_none,
            ),
            color: isTracked ? AppColors.brand : AppColors.textSecondary,
            tooltip: isTracked ? l.releasesUntrackShow : l.releasesTrackShow,
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
