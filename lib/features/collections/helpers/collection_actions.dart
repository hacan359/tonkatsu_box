// Helper action methods for CollectionScreen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/anilist_api.dart';
import '../../../core/api/comicvine_api.dart';
import '../../../core/api/google_books_api.dart';
import '../../../core/api/fantlab_api.dart';
import '../../../core/api/igdb_api.dart';
import '../../../core/api/mangabaka_api.dart';
import '../../../core/api/openlibrary_api.dart';
import '../../../core/api/tmdb_api.dart';
import '../../../core/api/vndb_api.dart';
import '../../../core/database/database_service.dart';
import '../../../core/services/export_service.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../core/services/xcoll_file.dart';
import '../../../data/repositories/canvas_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/models/anime.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/data_source.dart';
import '../../../shared/models/book.dart';
import '../../../shared/models/game.dart';
import '../../../shared/models/manga.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/movie.dart';
import '../../../shared/models/steamgriddb_image.dart';
import '../../../shared/models/tv_show.dart';
import '../../../shared/models/visual_novel.dart';
import '../../../shared/widgets/collection_picker_dialog.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../providers/canvas_provider.dart';
import '../providers/collections_provider.dart';
import '../widgets/copy_as_text_dialog.dart';
import '../widgets/edit_collection_dialog.dart';
import '../../../shared/navigation/search_providers.dart';
import '../../settings/providers/settings_provider.dart';

/// Static action methods for the collection screen.
///
/// Extracted from [CollectionScreen] to keep that file smaller.
/// Each method takes its dependencies explicitly.
class CollectionActions {
  CollectionActions._();

  /// Opens the Search tab to add items into [collectionId].
  ///
  /// Switches to the shared Search tab (handled by [AppShell]) with this
  /// collection set as the add target, rather than pushing a separate search
  /// screen — so the shell and its single search field stay consistent. Adds go
  /// straight into the collection, which refreshes itself via its items notifier.
  static void addItems({
    required WidgetRef ref,
    required int? collectionId,
  }) {
    ref.read(searchTabRequestProvider.notifier).state =
        SearchTabRequest(collectionId: collectionId);
  }

  /// Moves an item to another collection.
  ///
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
          sourceTagId: item.tagId,
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
          sourceTagId: item.tagId,
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

  /// Offers to delete a collection that became empty.
  ///
  /// Returns `true` if the collection was deleted.
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
        .removeItem(item.id);

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

  /// Edits a collection (name, description, cover).
  ///
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

  /// Deletes a collection.
  ///
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

  /// Export format picker dialog.
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

  /// Adds a SteamGridDB image to the canvas.
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

  /// Adds a VGMaps image to the canvas.
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

  /// Re-fetches the item from its source API and upserts the fresh row
  /// into the matching cache table. The cached cover image is deleted
  /// first so it gets re-downloaded with the new URL (or the same URL
  /// re-fetches the bytes if the local file was corrupted). `Custom`
  /// items have no API origin and are rejected by the caller.
  static Future<bool> refreshItemFromApi({
    required BuildContext context,
    required WidgetRef ref,
    required CollectionItem item,
  }) async {
    final S l = S.of(context);

    final _RefreshOutcome outcome = await _refreshItemWork(ref, item);
    if (!context.mounted) return outcome.success;

    switch (outcome.message) {
      case _RefreshMessage.success:
        ref.invalidate(collectionsProvider);
        context.showSnack(l.refreshItemSuccess, type: SnackType.success);
      case _RefreshMessage.notFound:
        context.showSnack(l.refreshItemNotFound, type: SnackType.error);
      case _RefreshMessage.unsupported:
        context.showSnack(l.refreshItemUnsupported, type: SnackType.error);
      case _RefreshMessage.failed:
        context.showSnack(
          l.refreshItemFailed(outcome.error ?? ''),
          type: SnackType.error,
        );
    }
    return outcome.success;
  }

  /// Async DB / network work for [refreshItemFromApi]. Kept context-free so
  /// the lint can see that UI feedback happens behind a single mounted check
  /// in the caller.
  static Future<_RefreshOutcome> _refreshItemWork(
    WidgetRef ref,
    CollectionItem item,
  ) async {
    final DatabaseService db = ref.read(databaseServiceProvider);
    final ImageCacheService cache = ref.read(imageCacheServiceProvider);

    try {
      await cache.deleteImage(item.imageType, item.coverImageId);

      switch (item.mediaType) {
        case MediaType.game:
          final Game? game =
              await ref.read(igdbApiProvider).getGameById(item.externalId);
          if (game == null) return _RefreshOutcome.notFound();
          await db.gameDao.upsertGame(game);
        case MediaType.movie:
          final Movie? movie =
              await ref.read(tmdbApiProvider).getMovie(item.externalId);
          if (movie == null) return _RefreshOutcome.notFound();
          await db.movieDao.upsertMovie(movie);
        case MediaType.tvShow:
        case MediaType.animation:
          final TvShow? show =
              await ref.read(tmdbApiProvider).getTvShow(item.externalId);
          if (show == null) return _RefreshOutcome.notFound();
          await db.tvShowDao.upsertTvShow(show);
        case MediaType.anime:
          final Anime? anime = await ref
              .read(aniListApiProvider)
              .getAnimeById(item.externalId);
          if (anime == null) return _RefreshOutcome.notFound();
          await db.animeDao.upsertAnime(anime);
        case MediaType.manga:
          final Manga? manga =
              item.source == DataSource.mangabaka
                  ? await ref
                      .read(mangaBakaApiProvider)
                      .getById(item.externalId)
                  : await ref
                      .read(aniListApiProvider)
                      .getMangaById(item.externalId);
          if (manga == null) return _RefreshOutcome.notFound();
          await db.mangaDao.upsertManga(manga);
        case MediaType.visualNovel:
          final VisualNovel? vn = await ref
              .read(vndbApiProvider)
              .getVnById(item.externalId.toString());
          if (vn == null) return _RefreshOutcome.notFound();
          await db.visualNovelDao.upsertVisualNovel(vn);
        case MediaType.book:
          final Book? cached = item.book;
          if (cached == null) return _RefreshOutcome.unsupported();
          if (item.source == DataSource.openLibrary) {
            final Book? full = await ref
                .read(openLibraryApiProvider)
                .getWork(cached.nativeId);
            if (full == null) return _RefreshOutcome.notFound();
            // OpenLibrary search rows carry year / pages the work lacks, so
            // overlay rather than replace.
            await db.bookDao.upsertBook(cached.withWorkDetails(full));
          } else if (item.source == DataSource.fantlab) {
            final Book? full =
                await ref.read(fantlabApiProvider).getWork(cached.nativeId);
            if (full == null) return _RefreshOutcome.notFound();
            await db.bookDao.upsertBook(full);
          } else if (item.source == DataSource.comicVine) {
            final Book? full = await ref
                .read(comicVineApiProvider)
                .getVolume(cached.nativeId);
            if (full == null) return _RefreshOutcome.notFound();
            await db.bookDao.upsertBook(full);
          } else if (item.source == DataSource.googleBooks) {
            final Book? full = await ref
                .read(googleBooksApiProvider)
                .getVolume(cached.nativeId);
            if (full == null) return _RefreshOutcome.notFound();
            await db.bookDao.upsertBook(full);
          } else {
            return _RefreshOutcome.unsupported();
          }
        case MediaType.custom:
          return _RefreshOutcome.unsupported();
      }

      return _RefreshOutcome.success();
    } catch (e) {
      return _RefreshOutcome.failed(e.toString());
    }
  }
}

enum _RefreshMessage { success, notFound, unsupported, failed }

class _RefreshOutcome {
  const _RefreshOutcome._(this.message, this.success, [this.error]);

  factory _RefreshOutcome.success() =>
      const _RefreshOutcome._(_RefreshMessage.success, true);
  factory _RefreshOutcome.notFound() =>
      const _RefreshOutcome._(_RefreshMessage.notFound, false);
  factory _RefreshOutcome.unsupported() =>
      const _RefreshOutcome._(_RefreshMessage.unsupported, false);
  factory _RefreshOutcome.failed(String error) =>
      _RefreshOutcome._(_RefreshMessage.failed, false, error);

  final _RefreshMessage message;
  final bool success;
  final String? error;
}
