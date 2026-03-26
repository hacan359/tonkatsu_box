// Вспомогательные методы действий для CollectionScreen.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/export_service.dart';
import '../../../core/services/text_export_service.dart';
import '../../../core/services/xcoll_file.dart';
import '../../../data/repositories/canvas_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/steamgriddb_image.dart';
import '../../../shared/widgets/collection_picker_dialog.dart';
import '../providers/canvas_provider.dart';
import '../providers/collections_provider.dart';
import '../widgets/copy_as_text_dialog.dart';
import '../widgets/create_collection_dialog.dart';
import '../../search/screens/search_screen.dart';

/// Статические методы для действий на экране коллекции.
///
/// Извлечены из [CollectionScreen] для уменьшения размера файла.
/// Каждый метод принимает необходимые зависимости явно.
class CollectionActions {
  CollectionActions._();

  /// Навигация к поиску для добавления элементов.
  static Future<void> addItems({
    required BuildContext context,
    required WidgetRef ref,
    required int? collectionId,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => SearchScreen(
          collectionId: collectionId,
        ),
      ),
    );
    if (context.mounted) {
      ref
          .read(collectionItemsNotifierProvider(collectionId).notifier)
          .refresh();
    }
  }

  /// Перемещение элемента в другую коллекцию.
  ///
  /// Возвращает `true`, если исходная коллекция опустела после перемещения.
  static Future<bool> moveItem({
    required BuildContext context,
    required WidgetRef ref,
    required int? collectionId,
    required CollectionItem item,
  }) async {
    final bool isUncategorized = collectionId == null;
    final S l = S.of(context);

    final CollectionChoice? choice = await showCollectionPickerDialog(
      context: context,
      ref: ref,
      excludeCollectionId: collectionId,
      showUncategorized: !isUncategorized,
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

    if (result.success) {
      context.showSnack(
        S.of(context).collectionItemMovedTo(item.itemName, targetName),
        type: SnackType.success,
      );
      return result.sourceEmpty;
    } else {
      context.showSnack(
        S.of(context).collectionItemAlreadyExists(item.itemName, targetName),
      );
      return false;
    }
  }

  /// Копирование элемента в другую коллекцию (полная копия).
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

    if (success) {
      context.showSnack(
        S.of(context).collectionItemCopiedTo(item.itemName, targetName),
        type: SnackType.success,
      );
    } else {
      context.showSnack(
        S.of(context).collectionItemAlreadyInTarget(
              item.itemName,
              targetName,
            ),
      );
    }
  }

  /// Предложение удалить опустевшую коллекцию.
  ///
  /// Возвращает `true`, если коллекция была удалена.
  static Future<bool> promptDeleteEmptyCollection({
    required BuildContext context,
    required WidgetRef ref,
    required int collectionId,
  }) async {
    final NavigatorState navigator = Navigator.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final S dl = S.of(context);
        return AlertDialog(
          title: Text(dl.collectionEmpty),
          content: Text(dl.collectionDeleteEmptyPrompt),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(dl.keep),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(dl.delete),
            ),
          ],
        );
      },
    );
    if (confirmed == true && context.mounted) {
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

  /// Удаление элемента из коллекции (с подтверждением).
  static Future<void> removeItem({
    required BuildContext context,
    required WidgetRef ref,
    required int? collectionId,
    required CollectionItem item,
  }) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final S dl = S.of(context);
        return AlertDialog(
          scrollable: true,
          title: Text(dl.collectionRemoveItemTitle),
          content: Text(dl.collectionRemoveItemMessage(item.itemName)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(dl.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(dl.remove),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    await ref
        .read(collectionItemsNotifierProvider(collectionId).notifier)
        .removeItem(item.id);

    // Синхронизация канваса — удалить элемент
    ref
        .read(canvasNotifierProvider(collectionId).notifier)
        .removeByCollectionItemId(item.id);

    if (context.mounted) {
      context.showSnack(
        S.of(context).collectionItemRemoved(item.itemName),
        type: SnackType.success,
      );
    }
  }

  /// Переименование коллекции.
  ///
  /// Возвращает новое имя или `null`, если отменено.
  static Future<String?> renameCollection({
    required BuildContext context,
    required WidgetRef ref,
    required Collection collection,
  }) async {
    final String? newName =
        await RenameCollectionDialog.show(context, collection.name);

    if (newName == null || newName == collection.name || !context.mounted) {
      return null;
    }

    try {
      await ref
          .read(collectionsProvider.notifier)
          .rename(collection.id, newName);

      if (context.mounted) {
        context.showSnack(
          S.of(context).collectionsRenamed,
          type: SnackType.success,
        );
      }
      return newName;
    } on Exception catch (e) {
      if (context.mounted) {
        context.showSnack(
          S.of(context).collectionsFailedToRename('$e'),
          type: SnackType.error,
        );
      }
      return null;
    }
  }

  /// Удаление коллекции.
  ///
  /// Возвращает `true`, если коллекция была удалена.
  static Future<bool> deleteCollection({
    required BuildContext context,
    required WidgetRef ref,
    required Collection collection,
  }) async {
    final bool confirmed =
        await DeleteCollectionDialog.show(context, collection.name);

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

  /// Быстрое копирование списка в буфер обмена (дефолтный шаблон).
  static Future<void> copyAsList({
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

    final TextExportService service = TextExportService();
    final String text = service.applyTemplate(
      TextExportService.defaultTemplate,
      items,
    );

    await Clipboard.setData(ClipboardData(text: text));

    if (context.mounted) {
      context.showSnack(
        S.of(context).copiedToClipboard(items.length),
        type: SnackType.success,
      );
    }
  }

  /// Открывает диалог копирования коллекции как текста с шаблоном.
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
    // Получаем список элементов
    final AsyncValue<List<CollectionItem>> itemsAsync =
        ref.read(collectionItemsNotifierProvider(collectionId));

    final List<CollectionItem>? items = itemsAsync.valueOrNull;
    if (items == null) {
      if (context.mounted) {
        context.showSnack('Items not loaded yet', type: SnackType.error);
      }
      return;
    }

    // Выбор формата экспорта
    if (!context.mounted) return;
    final ({ExportFormat format, bool includeUserData})? chosen =
        await _showExportFormatDialog(context);
    if (chosen == null) return;
    final ExportFormat format = chosen.format;
    final bool includeUserData = chosen.includeUserData;

    // Показываем индикатор
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

  /// Диалог выбора формата экспорта.
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

  /// Добавление изображения SteamGridDB на канвас.
  static void addSteamGridDbImage({
    required BuildContext context,
    required WidgetRef ref,
    required int? collectionId,
    required SteamGridDbImage image,
  }) {
    // Масштабируем до max 300px по ширине, сохраняя пропорции
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

    // Добавляем в центр канваса
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

  /// Добавление изображения VGMaps на канвас.
  static void addVgMapsImage({
    required BuildContext context,
    required WidgetRef ref,
    required int? collectionId,
    required String url,
    required int? width,
    required int? height,
  }) {
    // Масштабируем до max 400px по ширине (карты больше обычных изображений)
    const double maxWidth = 400;
    double targetWidth = maxWidth;
    double targetHeight = maxWidth;

    if (width != null && height != null && width > 0 && height > 0) {
      final double aspectRatio = width / height;
      targetWidth =
          width.toDouble() > maxWidth ? maxWidth : width.toDouble();
      targetHeight = targetWidth / aspectRatio;
    }

    // Добавляем в центр канваса
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
}
