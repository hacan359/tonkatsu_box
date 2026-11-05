import 'package:core/models/collection_item.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/constants/platform_features.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/screen_app_bar.dart';
import '../../../../shared/widgets/glass_popup_menu.dart';

enum ItemDetailMenuAction {
  toggleCanvas,
  refresh,
  rename,
  changeCover,
  resetCover,
  move,
  clone,
  duplicateAsCustom,
  copyLink,
  remove,
}

/// The card's top-zone actions, lent to the frame; the back button is the
/// frame's own. A null [onToggleFavorite] hides the heart.
List<Widget> buildItemDetailActions({
  required BuildContext context,
  required CollectionItem item,
  required bool isEditable,
  required bool hasCanvas,
  required bool showCanvas,
  required bool isViewModeLocked,
  required VoidCallback onToggleLock,
  required VoidCallback onEditCustom,
  required ValueChanged<ItemDetailMenuAction> onMenuSelected,
  VoidCallback? onToggleFavorite,
  bool canTrackReleases = false,
  bool isTracked = false,
  VoidCallback? onToggleTracked,
  String? trackTooltip,
  String? untrackTooltip,
}) {
    final S l = S.of(context);
    final ThemeData theme = Theme.of(context);
    String withShortcut(String label, String shortcut) =>
        kIsMobile ? label : '$label ($shortcut)';
    return <Widget>[
        if (isEditable && onToggleFavorite != null)
          _action(
            iconData: item.isFavorite ? Icons.favorite : Icons.heart_broken,
            color: item.isFavorite
                ? AppColors.favorite
                : AppColors.textSecondary,
            tooltip: item.isFavorite
                ? l.removeFromFavorites
                : l.addToFavorites,
            onPressed: onToggleFavorite,
          ),
        if (canTrackReleases)
          _action(
            iconData: isTracked
                ? Icons.notifications_active
                : Icons.notifications_none,
            color: isTracked ? AppColors.brand : AppColors.textSecondary,
            tooltip: isTracked
                ? (untrackTooltip ?? l.releasesUntrackShow)
                : (trackTooltip ?? l.releasesTrackShow),
            onPressed: onToggleTracked,
          ),
        if (isEditable && hasCanvas && showCanvas)
          _action(
            iconData: isViewModeLocked ? Icons.lock : Icons.lock_open,
            color: isViewModeLocked
                ? AppColors.warning
                : AppColors.textSecondary,
            tooltip: withShortcut(
              isViewModeLocked
                  ? l.collectionUnlockBoard
                  : l.collectionLockBoard,
              'Ctrl+L',
            ),
            onPressed: onToggleLock,
          ),
        if (isEditable && item.mediaType == MediaType.custom)
          _action(
            iconData: Icons.edit_outlined,
            color: AppColors.textSecondary,
            tooltip: l.customItemEdit,
            onPressed: onEditCustom,
          ),
        // The board toggle lives in the menu, so a read-only card with a
        // board still gets one; the editing entries stay gated below.
        if (isEditable || hasCanvas)
          GlassPopupMenuButton<ItemDetailMenuAction>(
            iconSize: kScreenAppBarIconSize - 2,
            icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
            onSelected: onMenuSelected,
            rows: (BuildContext _) => <Widget>[
              if (hasCanvas)
                _menuItem(
                  ItemDetailMenuAction.toggleCanvas,
                  showCanvas ? Icons.dashboard : Icons.dashboard_outlined,
                  withShortcut(l.boardTab, 'Ctrl+B'),
                  color: showCanvas ? AppColors.brand : null,
                ),
              if (hasCanvas && isEditable) const GlassMenuDivider(),
              if (isEditable && item.mediaType != MediaType.custom)
                _menuItem(
                  ItemDetailMenuAction.refresh,
                  Icons.refresh,
                  l.refreshItemFromApi,
                ),
              if (isEditable && item.mediaType != MediaType.custom)
                _menuItem(
                  ItemDetailMenuAction.rename,
                  Icons.drive_file_rename_outline,
                  l.rename,
                ),
              if (isEditable && item.mediaType != MediaType.custom)
                _menuItem(
                  ItemDetailMenuAction.changeCover,
                  Icons.image_outlined,
                  l.coverOverrideChange,
                ),
              if (isEditable &&
                  item.mediaType != MediaType.custom &&
                  item.overrideCoverUrl != null)
                _menuItem(
                  ItemDetailMenuAction.resetCover,
                  Icons.settings_backup_restore,
                  l.coverOverrideReset,
                ),
              if (isEditable) ...<Widget>[
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
                if (item.mediaType != MediaType.custom)
                  _menuItem(
                    ItemDetailMenuAction.duplicateAsCustom,
                    Icons.control_point_duplicate,
                    l.duplicateAsCustom,
                  ),
                _menuItem(
                  ItemDetailMenuAction.copyLink,
                  Icons.link,
                  l.cardLinkCopy,
                ),
                const GlassMenuDivider(),
                _menuItem(
                  ItemDetailMenuAction.remove,
                  Icons.delete_outline,
                  l.remove,
                  color: theme.colorScheme.error,
                ),
              ],
            ],
          ),
    ];
  }

  /// Smaller and tighter than Material defaults: with up to six actions the
  /// default 48px tap boxes read sparse next to the 20px back button.
  Widget _action({
    required IconData iconData,
    required Color color,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      icon: Icon(iconData),
      color: color,
      tooltip: tooltip,
      iconSize: kScreenAppBarIconSize - 2,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(AppSpacing.xs),
      onPressed: onPressed,
    );
  }

GlassMenuRow<ItemDetailMenuAction> _menuItem(
  ItemDetailMenuAction value,
  IconData icon,
  String label, {
  Color? color,
}) {
  return GlassMenuRow<ItemDetailMenuAction>(
    value: value,
    icon: icon,
    iconColor: color,
    labelColor: color,
    label: label,
  );
}
