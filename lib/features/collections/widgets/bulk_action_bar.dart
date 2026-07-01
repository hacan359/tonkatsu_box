// Works both inside a collection and on All Items: operates on a
// `List<CollectionItem>` via [BulkOperations], so collectionId is optional.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/collection_sort_mode.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/collection_picker_dialog.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../helpers/bulk_operations.dart';
import '../providers/collections_provider.dart';
import 'bulk_export/bulk_poster_export_dialog.dart';

/// Selection toolbar that works both inside a single collection and on All
/// Items. When [collectionId] is set the bar excludes that collection from
/// move/copy targets and exposes move-to-top / move-to-bottom under manual
/// sort; when null it acts globally over All Items.
class BulkActionBar extends ConsumerWidget {
  const BulkActionBar({
    required this.items,
    required this.onClearSelection,
    this.collectionId,
    this.collectionName,
    this.visibleCount,
    this.onSelectAllVisible,
    super.key,
  });

  final List<CollectionItem> items;

  final VoidCallback onClearSelection;

  /// Null when the bar is on All Items rather than inside a collection.
  final int? collectionId;

  /// Used as the file name when exporting to PNG.
  final String? collectionName;

  /// Total items visible after filters/search; used to hide "select all
  /// visible" once everything is already selected.
  final int? visibleCount;

  /// Null hides the "select all visible" button.
  final VoidCallback? onSelectAllVisible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final CollectionSortMode sortMode = collectionId == null
        ? CollectionSortMode.lastActivity
        : ref.watch(collectionSortProvider(collectionId));
    final bool isManualSort = collectionId != null &&
        sortMode == CollectionSortMode.manual;
    final int count = items.length;

    return Material(
      color: AppColors.brand.withAlpha(28),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.brand.withAlpha(60)),
            bottom: BorderSide(color: AppColors.brand.withAlpha(60)),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: <Widget>[
            _CloseButton(onPressed: onClearSelection),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l.bulkSelected(count),
              style: AppTypography.body.copyWith(
                color: AppColors.brand,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onSelectAllVisible != null &&
                (visibleCount ?? 0) > count) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              TextButton(
                onPressed: onSelectAllVisible,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brand,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(l.bulkSelectAllVisible),
              ),
            ],
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    _BarAction(
                      icon: Icons.drive_file_move_outlined,
                      tooltip: l.collectionMoveToCollection,
                      onTap: () => _handleMove(context, ref),
                    ),
                    _BarAction(
                      icon: Icons.copy_outlined,
                      tooltip: l.collectionCopyToCollection,
                      onTap: () => _handleClone(context, ref),
                    ),
                    _StatusMenuAction(
                      onSelected: (ItemStatus s) =>
                          _handleStatus(context, ref, s),
                    ),
                    _BarAction(
                      icon: Icons.image_outlined,
                      tooltip: l.bulkExportPngTitle,
                      onTap: () => _handleExportPng(context),
                    ),
                    if (isManualSort) ...<Widget>[
                      const _BarDivider(),
                      _BarAction(
                        icon: Icons.vertical_align_top,
                        tooltip: l.moveToTop,
                        onTap: () => _handleMoveToTop(ref),
                      ),
                      _BarAction(
                        icon: Icons.vertical_align_bottom,
                        tooltip: l.moveToBottom,
                        onTap: () => _handleMoveToBottom(ref),
                      ),
                    ],
                    const _BarDivider(),
                    _BarAction(
                      icon: Icons.delete_outline,
                      tooltip: l.remove,
                      danger: true,
                      onTap: () => _handleRemove(context, ref),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMove(BuildContext context, WidgetRef ref) async {
    final S l = S.of(context);
    final CollectionChoice? choice = await showCollectionPickerDialog(
      context: context,
      ref: ref,
      excludeCollectionId: collectionId,
      showUncategorized: false,
      title: l.bulkMove,
    );
    if (choice == null || !context.mounted) return;

    final int? targetId = switch (choice) {
      ChosenCollection(:final Collection collection) => collection.id,
      WithoutCollection() => null,
    };

    final List<CollectionItem> snapshot = List<CollectionItem>.of(items);
    final ({int moved, int skipped}) result =
        await BulkOperations.moveItemsToCollection(ref, snapshot, targetId);
    onClearSelection();
    if (!context.mounted) return;
    context.showSnack(
      l.bulkResult(result.moved, result.skipped),
      type: SnackType.success,
    );
  }

  Future<void> _handleClone(BuildContext context, WidgetRef ref) async {
    final S l = S.of(context);
    final CollectionChoice? choice = await showCollectionPickerDialog(
      context: context,
      ref: ref,
      excludeCollectionId: collectionId,
      showUncategorized: false,
      title: l.bulkCopy,
    );
    if (choice == null || !context.mounted) return;

    final int? targetId = switch (choice) {
      ChosenCollection(:final Collection collection) => collection.id,
      WithoutCollection() => null,
    };
    if (targetId == null) return;

    final List<CollectionItem> snapshot = List<CollectionItem>.of(items);
    final ({int cloned, int skipped}) result =
        await BulkOperations.cloneItemsToCollection(ref, snapshot, targetId);
    onClearSelection();
    if (!context.mounted) return;
    context.showSnack(
      l.bulkResult(result.cloned, result.skipped),
      type: SnackType.success,
    );
  }

  Future<void> _handleStatus(
    BuildContext context,
    WidgetRef ref,
    ItemStatus status,
  ) async {
    final S l = S.of(context);
    final List<CollectionItem> snapshot = List<CollectionItem>.of(items);
    final int changed =
        await BulkOperations.updateItemsStatus(ref, snapshot, status);
    onClearSelection();
    if (!context.mounted) return;
    context.showSnack(
      l.bulkStatusUpdated(changed),
      type: SnackType.success,
    );
  }

  Future<void> _handleRemove(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final S l = S.of(context);
    final int count = items.length;
    final bool confirmed = await ConfirmDialog.show(
      context,
      title: l.collectionRemoveItemTitle,
      message: l.bulkRemoveConfirm(count),
      confirmLabel: l.remove,
    );
    if (!confirmed || !context.mounted) return;

    final List<CollectionItem> snapshot = List<CollectionItem>.of(items);
    final int removed = await BulkOperations.removeItems(ref, snapshot);
    onClearSelection();
    if (!context.mounted) return;
    context.showSnack(
      l.bulkRemoved(removed),
      type: SnackType.success,
    );
  }

  Future<void> _handleExportPng(BuildContext context) {
    return showBulkPosterExportDialog(
      context: context,
      items: items,
      collectionName: collectionName,
    );
  }

  Future<void> _handleMoveToTop(WidgetRef ref) async {
    final Set<int> ids = items.map((CollectionItem i) => i.id).toSet();
    await ref
        .read(collectionItemsNotifierProvider(collectionId).notifier)
        .moveItemsToTop(ids);
    onClearSelection();
  }

  Future<void> _handleMoveToBottom(WidgetRef ref) async {
    final Set<int> ids = items.map((CollectionItem i) => i.id).toSet();
    await ref
        .read(collectionItemsNotifierProvider(collectionId).notifier)
        .moveItemsToBottom(ids);
    onClearSelection();
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.close_rounded),
      iconSize: 20,
      visualDensity: VisualDensity.compact,
      color: AppColors.brand,
      tooltip: S.of(context).bulkClearSelection,
      onPressed: onPressed,
    );
  }
}

class _BarAction extends StatelessWidget {
  const _BarAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      iconSize: 20,
      visualDensity: VisualDensity.compact,
      color: danger ? AppColors.error : AppColors.textPrimary,
      tooltip: tooltip,
      onPressed: onTap,
    );
  }
}

class _StatusMenuAction extends StatelessWidget {
  const _StatusMenuAction({required this.onSelected});

  final ValueChanged<ItemStatus> onSelected;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    return PopupMenuButton<ItemStatus>(
      icon: const Icon(Icons.flag_outlined),
      iconSize: 20,
      tooltip: l.bulkChangeStatus,
      onSelected: onSelected,
      itemBuilder: (BuildContext context) {
        return ItemStatus.values.map((ItemStatus s) {
          return PopupMenuItem<ItemStatus>(
            value: s,
            height: 36,
            child: Row(
              children: <Widget>[
                Icon(s.materialIcon, size: 16, color: s.color),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  s.genericLabel(l),
                  style: AppTypography.body.copyWith(fontSize: 13),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}

class _BarDivider extends StatelessWidget {
  const _BarDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Container(
        width: 1,
        height: 20,
        color: AppColors.brand.withAlpha(60),
      ),
    );
  }
}
