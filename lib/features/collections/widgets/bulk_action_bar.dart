// Bulk action bar — рендерится поверх контента когда выделен хотя бы
// один элемент. Работает и в коллекции, и на All Items: оперирует
// `List<CollectionItem>` через [BulkOperations].

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
import '../helpers/bulk_operations.dart';
import '../providers/collections_provider.dart';

/// Bulk action bar над списком элементов.
///
/// - [items] — выделенные элементы (с `id`, `collectionId`, `mediaType`,
///   `status` — этого хватает для всех операций).
/// - [onClearSelection] — внешний callback, обнуляющий селекшн на
///   стороне родителя (бар сам не знает про конкретный селекшн-провайдер).
/// - [collectionId] — если задан, бар «знает», что мы внутри одной
///   коллекции: исключает её из целей move/copy и показывает
///   move-to-top / move-to-bottom при ручной сортировке.
class BulkActionBar extends ConsumerWidget {
  /// Создаёт [BulkActionBar].
  const BulkActionBar({
    required this.items,
    required this.onClearSelection,
    this.collectionId,
    super.key,
  });

  /// Выделенные элементы.
  final List<CollectionItem> items;

  /// Колбэк сброса селекшна.
  final VoidCallback onClearSelection;

  /// ID контекстной коллекции. `null` если бар стоит на All Items.
  final int? collectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final ThemeData theme = Theme.of(context);
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
            const Spacer(),
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
              onSelected: (ItemStatus s) => _handleStatus(context, ref, s),
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
              onTap: () => _handleRemove(context, ref, theme),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Handlers

  Future<void> _handleMove(BuildContext context, WidgetRef ref) async {
    final S l = S.of(context);
    final CollectionChoice? choice = await showCollectionPickerDialog(
      context: context,
      ref: ref,
      excludeCollectionId: collectionId,
      showUncategorized: collectionId != null,
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
    ThemeData theme,
  ) async {
    final S l = S.of(context);
    final int count = items.length;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final S dl = S.of(dialogContext);
        return AlertDialog(
          title: Text(dl.collectionRemoveItemTitle),
          content: Text(dl.bulkRemoveConfirm(count)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(dl.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              child: Text(dl.remove),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;

    final List<CollectionItem> snapshot = List<CollectionItem>.of(items);
    final int removed = await BulkOperations.removeItems(ref, snapshot);
    onClearSelection();
    if (!context.mounted) return;
    context.showSnack(
      l.bulkRemoved(removed),
      type: SnackType.success,
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

// ---------------------------------------------------------------------------
// Internal widgets

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
