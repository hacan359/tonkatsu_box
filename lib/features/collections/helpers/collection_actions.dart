import 'package:core/models/book.dart';
import 'package:core/models/card_link.dart';
import 'package:core/models/collection.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/steamgriddb_image.dart';
import 'package:core/models/xcoll_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/hardcover_api.dart';
import '../../../core/api/fantlab_api.dart';
import '../../../core/services/export_service.dart';
import '../../../data/repositories/canvas_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/widgets/collection_picker_dialog.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../home/providers/all_items_provider.dart';
import '../providers/canvas_provider.dart';
import '../providers/collections_provider.dart';
import '../widgets/copy_as_text_dialog.dart';
import '../widgets/edit_collection_dialog.dart';
import '../widgets/fantlab_edition_picker.dart';
import '../widgets/hardcover_edition_picker.dart';
import 'item_refresh.dart';
import '../../../shared/navigation/search_providers.dart';
import '../../settings/providers/settings_provider.dart';

/// Actions extracted from [CollectionScreen] to keep that file smaller;
/// each method takes its dependencies explicitly.
class CollectionActions {
  CollectionActions._();

  // Long enough to read the saved path; snacks no longer wait for a tap.
  static const Duration _exportedSnackDuration = Duration(seconds: 6);

  /// Switches to the shared Search tab with this collection as add target —
  /// no separate search screen, so the shell's single field stays consistent.
  static void addItems({
    required WidgetRef ref,
    required int? collectionId,
  }) {
    ref.read(searchTabRequestProvider.notifier).state =
        SearchTabRequest(collectionId: collectionId);
  }

  /// Copies a `[[card:…]]` cross-link for [item] to the clipboard.
  static void copyItemLink(BuildContext context, CollectionItem item) {
    Clipboard.setData(ClipboardData(text: buildCardLinkToken(item)));
    context.showSnack(S.of(context).cardLinkCopied, type: SnackType.success);
  }

  /// Returns `true` if the source collection became empty after the move.
  static Future<bool> moveItem({
    required BuildContext context,
    required WidgetRef ref,
    required int? collectionId,
    required CollectionItem item,
  }) async {
    final S l = S.of(context);

    final CollectionChoice? choice = await showCollectionPickerDialog(
      context: context,
      ref: ref,
      excludeCollectionId: collectionId,
      showUncategorized: false,
      title: l.collectionMoveToCollection,
    );
    if (choice == null || !context.mounted) return false;

    final int? targetCollectionId;
    final String targetName;
    switch (choice) {
      case ChosenCollection(:final Collection collection):
        targetCollectionId = collection.id;
        targetName = collection.name;
      case WithoutCollection():
        targetCollectionId = null;
        targetName = S.of(context).collectionsUncategorized;
    }

    final ({bool success, bool sourceEmpty}) result = await ref
        .read(
          collectionItemsNotifierProvider(collectionId).notifier,
        )
        .moveItem(
          item.id,
          targetCollectionId: targetCollectionId,
          mediaType: item.mediaType,
        );

    if (!context.mounted) return false;

    final String displayName = item.displayName(
      ref.read(sharedPreferencesProvider).animeMangaTitleLanguage,
    );
    if (result.success) {
      context.showSnack(
        S.of(context).collectionItemMovedTo(displayName, targetName),
        type: SnackType.success,
      );
      return result.sourceEmpty;
    } else {
      context.showSnack(
        S.of(context).collectionItemAlreadyExists(displayName, targetName),
      );
      return false;
    }
  }

  /// Copies an item to another collection (full copy).
  static Future<void> cloneItem({
    required BuildContext context,
    required WidgetRef ref,
    required int? collectionId,
    required CollectionItem item,
  }) async {
    final S l = S.of(context);

    final CollectionChoice? choice = await showCollectionPickerDialog(
      context: context,
      ref: ref,
      excludeCollectionId: collectionId,
      showUncategorized: false,
      title: l.collectionCopyToCollection,
    );
    if (choice == null || !context.mounted) return;

    final int targetCollectionId;
    final String targetName;
    switch (choice) {
      case ChosenCollection(:final Collection collection):
        targetCollectionId = collection.id;
        targetName = collection.name;
      case WithoutCollection():
        return;
    }

    final bool success = await ref
        .read(
          collectionItemsNotifierProvider(collectionId).notifier,
        )
        .cloneItem(
          item.id,
          targetCollectionId: targetCollectionId,
          mediaType: item.mediaType,
        );

    if (!context.mounted) return;

    final String displayName = item.displayName(
      ref.read(sharedPreferencesProvider).animeMangaTitleLanguage,
    );
    if (success) {
      context.showSnack(
        S.of(context).collectionItemCopiedTo(displayName, targetName),
        type: SnackType.success,
      );
    } else {
      context.showSnack(
        S.of(context).collectionItemAlreadyInTarget(
              displayName,
              targetName,
            ),
      );
    }
  }

  /// Offers to delete a collection that became empty; `true` when deleted.
  static Future<bool> promptDeleteEmptyCollection({
    required BuildContext context,
    required WidgetRef ref,
    required int collectionId,
  }) async {
    final NavigatorState navigator = Navigator.of(context);
    final S dl = S.of(context);
    final bool confirmed = await ConfirmDialog.show(
      context,
      title: dl.collectionEmpty,
      message: dl.collectionDeleteEmptyPrompt,
      confirmLabel: dl.delete,
      cancelLabel: dl.keep,
    );
    if (confirmed && context.mounted) {
      await ref
          .read(collectionsProvider.notifier)
          .delete(collectionId);
      if (context.mounted) {
        navigator.pop();
      }
      return true;
    }
    return false;
  }

  /// Removes an item from a collection (with confirmation).
  static Future<void> removeItem({
    required BuildContext context,
    required WidgetRef ref,
    required int? collectionId,
    required CollectionItem item,
  }) async {
    final String displayName = item.displayName(
      ref.read(sharedPreferencesProvider).animeMangaTitleLanguage,
    );
    final S dl = S.of(context);
    final bool confirmed = await ConfirmDialog.show(
      context,
      title: dl.collectionRemoveItemTitle,
      message: dl.collectionRemoveItemMessage(displayName),
      confirmLabel: dl.remove,
    );

    if (!confirmed || !context.mounted) return;

    await ref
        .read(collectionItemsNotifierProvider(collectionId).notifier)
        .removeItem(item.id, mediaType: item.mediaType);

    // Keep the canvas in sync: drop the removed item
    ref
        .read(canvasNotifierProvider(collectionId).notifier)
        .removeByCollectionItemId(item.id);

    if (context.mounted) {
      context.showSnack(
        S.of(context).collectionItemRemoved(displayName),
        type: SnackType.success,
      );
    }
  }

  /// Returns `true` if the user saved the changes.
  static Future<bool> renameCollection({
    required BuildContext context,
    required WidgetRef ref,
    required Collection collection,
  }) async {
    final bool changed = await EditCollectionDialog.show(context, collection);
    if (!changed || !context.mounted) return false;
    context.showSnack(
      S.of(context).collectionsRenamed,
      type: SnackType.success,
    );
    return true;
  }

  /// Returns `true` if the collection was deleted.
  static Future<bool> deleteCollection({
    required BuildContext context,
    required WidgetRef ref,
    required Collection collection,
  }) async {
    final S dl = S.of(context);
    final bool confirmed = await ConfirmDialog.show(
      context,
      title: dl.deleteCollectionTitle,
      message: dl.deleteCollectionMessage(collection.name),
      confirmLabel: dl.delete,
    );

    if (!confirmed || !context.mounted) return false;

    try {
      await ref.read(collectionsProvider.notifier).delete(collection.id);

      if (context.mounted) {
        context.showSnack(
          S.of(context).collectionsDeleted,
          type: SnackType.success,
        );
      }
      return true;
    } on Exception catch (e) {
      if (context.mounted) {
        context.showSnack(
          S.of(context).collectionsFailedToDelete('$e'),
          type: SnackType.error,
        );
      }
      return false;
    }
  }

  /// Opens the "copy collection as text" dialog with a template.
  static Future<void> copyAsText({
    required BuildContext context,
    required WidgetRef ref,
    required int? collectionId,
  }) async {
    final List<CollectionItem>? items =
        ref.read(collectionItemsNotifierProvider(collectionId)).valueOrNull;

    if (items == null || items.isEmpty) {
      if (context.mounted) {
        context.showSnack('Items not loaded yet', type: SnackType.error);
      }
      return;
    }

    if (!context.mounted) return;

    final bool? copied = await showCopyAsTextDialog(
      context: context,
      items: items,
    );

    if (copied == true && context.mounted) {
      context.showSnack(
        S.of(context).copiedToClipboard(items.length),
        type: SnackType.success,
      );
    }
  }

  static Future<void> exportCollection({
    required BuildContext context,
    required WidgetRef ref,
    required int? collectionId,
    required Collection collection,
  }) async {
    final AsyncValue<List<CollectionItem>> itemsAsync =
        ref.read(collectionItemsNotifierProvider(collectionId));

    final List<CollectionItem>? items = itemsAsync.valueOrNull;
    if (items == null) {
      if (context.mounted) {
        context.showSnack('Items not loaded yet', type: SnackType.error);
      }
      return;
    }

    if (!context.mounted) return;
    final ({ExportFormat format, bool includeUserData})? chosen =
        await _showExportFormatDialog(context);
    if (chosen == null) return;
    final ExportFormat format = chosen.format;
    final bool includeUserData = chosen.includeUserData;

    if (context.mounted) {
      context.showSnack(
        format == ExportFormat.full
            ? 'Preparing full export...'
            : 'Preparing export...',
        loading: true,
        duration: const Duration(seconds: 30),
      );
    }

    final ExportService exportService = ref.read(exportServiceProvider);
    final ExportResult result = await exportService.exportToFile(
      collection,
      items,
      format: format,
      includeUserData: includeUserData,
    );

    if (!context.mounted) return;

    if (result.success) {
      context.showSnack(
        'Exported to ${result.filePath}',
        type: SnackType.success,
        duration: _exportedSnackDuration,
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      );
    } else if (!result.isCancelled) {
      context.showSnack(
        result.error ?? 'Export failed',
        type: SnackType.error,
      );
    } else {
      context.hideSnack();
    }
  }

  static Future<({ExportFormat format, bool includeUserData})?> _showExportFormatDialog(
    BuildContext context,
  ) {
    return showDialog<({ExportFormat format, bool includeUserData})>(
      context: context,
      builder: (BuildContext dialogContext) {
        final S dl = S.of(dialogContext);
        bool includeUserData = false;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              scrollable: true,
              title: Text(dl.collectionExportFormat),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(dl.collectionChooseExportFormat),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(dl.collectionExportLight),
                    subtitle: Text(dl.collectionExportLightDesc),
                    onTap: () => Navigator.of(dialogContext).pop(
                      (format: ExportFormat.light, includeUserData: includeUserData),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.folder_zip_outlined),
                    title: Text(dl.collectionExportFull),
                    subtitle: Text(dl.collectionExportFullDesc),
                    onTap: () => Navigator.of(dialogContext).pop(
                      (format: ExportFormat.full, includeUserData: includeUserData),
                    ),
                  ),
                  const Divider(),
                  CheckboxListTile(
                    value: includeUserData,
                    onChanged: (bool? value) {
                      setState(() {
                        includeUserData = value ?? false;
                      });
                    },
                    title: Text(dl.collectionExportIncludeUserData),
                    subtitle: Text(dl.collectionExportIncludeUserDataDesc),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(dl.cancel),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static void addSteamGridDbImage({
    required BuildContext context,
    required WidgetRef ref,
    required int? collectionId,
    required SteamGridDbImage image,
  }) {
    // Scale to a max width of 300px, keeping the aspect ratio
    const double maxWidth = 300;
    const double defaultSize = 200;
    double targetWidth = defaultSize;
    double targetHeight = defaultSize;

    if (image.width > 0 && image.height > 0) {
      final double aspectRatio = image.width / image.height;
      targetWidth =
          image.width.toDouble() > maxWidth ? maxWidth : image.width.toDouble();
      targetHeight = targetWidth / aspectRatio;
    }

    final double centerX =
        CanvasRepository.initialCenterX - targetWidth / 2;
    final double centerY =
        CanvasRepository.initialCenterY - targetHeight / 2;

    ref
        .read(canvasNotifierProvider(collectionId).notifier)
        .addImageItem(
          centerX,
          centerY,
          <String, dynamic>{'url': image.url},
          width: targetWidth,
          height: targetHeight,
        );

    if (context.mounted) {
      context.showSnack(
        S.of(context).imageAddedToBoard,
        type: SnackType.success,
      );
    }
  }

  static void addVgMapsImage({
    required BuildContext context,
    required WidgetRef ref,
    required int? collectionId,
    required String url,
    required int? width,
    required int? height,
  }) {
    // Scale to a max width of 400px (maps are larger than regular images)
    const double maxWidth = 400;
    double targetWidth = maxWidth;
    double targetHeight = maxWidth;

    if (width != null && height != null && width > 0 && height > 0) {
      final double aspectRatio = width / height;
      targetWidth =
          width.toDouble() > maxWidth ? maxWidth : width.toDouble();
      targetHeight = targetWidth / aspectRatio;
    }

    final double centerX =
        CanvasRepository.initialCenterX - targetWidth / 2;
    final double centerY =
        CanvasRepository.initialCenterY - targetHeight / 2;

    ref
        .read(canvasNotifierProvider(collectionId).notifier)
        .addImageItem(
          centerX,
          centerY,
          <String, dynamic>{'url': url},
          width: targetWidth,
          height: targetHeight,
        );

    if (context.mounted) {
      context.showSnack(
        S.of(context).mapAddedToBoard,
        type: SnackType.success,
      );
    }
  }

  /// Re-fetches from the source API and upserts into the cache table; on
  /// success the cached cover is dropped so it re-downloads with the new URL.
  static Future<bool> refreshItemFromApi({
    required BuildContext context,
    required WidgetRef ref,
    required CollectionItem item,
  }) async {
    final S l = S.of(context);

    // Books with an edition catalog first offer to switch the edition;
    // picking refreshes with it, dismissing keeps the current one.
    FantlabEdition? pickedFantlab;
    HardcoverEdition? pickedHardcover;
    final Book? cachedBook =
        item.mediaType == MediaType.book ? item.book : null;
    if (cachedBook != null && item.source == DataSource.fantlab) {
      pickedFantlab = await showFantlabEditionPicker(
        context,
        workId: cachedBook.nativeId,
        currentEditionId: editionIdFromCoverUrl(cachedBook.coverUrl),
      );
      if (!context.mounted) return false;
    } else if (cachedBook != null && item.source == DataSource.hardcover) {
      pickedHardcover = await showHardcoverEditionPicker(
        context,
        bookId: cachedBook.nativeId,
        currentEditionId:
            hardcoverEditionIdFromExternalUrl(cachedBook.externalUrl) ??
                hardcoverEditionIdFromCoverUrl(cachedBook.coverUrl),
      );
      if (!context.mounted) return false;
    }

    final RefreshOutcome outcome = await refreshItemFromSource(
      ref,
      item,
      pickedFantlabEdition: pickedFantlab,
      pickedHardcoverEdition: pickedHardcover,
    );
    if (outcome.isSuccess) {
      ref.invalidate(collectionsProvider);
      // The refetched cache row backs this title in every collection and in
      // All Items; a stale list would miss it in a meta search by creator.
      ref.invalidate(collectionItemsNotifierProvider);
      ref.invalidate(allItemsNotifierProvider);
    }
    if (!context.mounted) return outcome.isSuccess;

    switch (outcome.kind) {
      case RefreshOutcomeKind.success:
        context.showSnack(l.refreshItemSuccess, type: SnackType.success);
      case RefreshOutcomeKind.notFound:
        context.showSnack(l.refreshItemNotFound, type: SnackType.error);
      case RefreshOutcomeKind.unsupported:
        context.showSnack(l.refreshItemUnsupported, type: SnackType.error);
      case RefreshOutcomeKind.failed:
        context.showSnack(
          l.refreshItemFailed(outcome.error ?? ''),
          type: SnackType.error,
        );
    }
    return outcome.isSuccess;
  }
}
