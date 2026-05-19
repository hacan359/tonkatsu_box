import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/models/collected_item_info.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/widgets/collection_picker_dialog.dart';
import '../../collections/providers/collections_provider.dart';

/// Result of the collection picker. `id == null` means Uncategorized.
class PickedCollection {
  const PickedCollection(this.id, this.name);

  final int? id;
  final String name;
}

/// Shared add-to-collection pipeline: upsert model, call `addItem`, cache
/// image, fire snackbar. Folded out of the per-source duplication that used
/// to live in `_SearchScreenState`.
class SearchCollectionAdder {
  const SearchCollectionAdder(this._ref);

  final WidgetRef _ref;

  /// Adds [externalId] to [collectionId]. When [collectionName] is provided
  /// the named snack variant is used; [afterAdd] runs only on success
  /// (e.g. TV season preload).
  Future<bool> addToCollection({
    required BuildContext context,
    required int? collectionId,
    required MediaType mediaType,
    required int externalId,
    int? platformId,
    required String title,
    required Future<void> Function() upsert,
    required ImageType imageType,
    required String imageId,
    String? imageUrl,
    Future<void> Function()? afterAdd,
    String? collectionName,
  }) async {
    await upsert();

    final bool success = await _ref
        .read(collectionItemsNotifierProvider(collectionId).notifier)
        .addItem(
          mediaType: mediaType,
          externalId: externalId,
          platformId: platformId,
        );

    if (!context.mounted) return success;
    final S l = S.of(context);

    if (success) {
      _cacheImage(imageType, imageId, imageUrl);
      if (afterAdd != null) {
        await afterAdd();
        if (!context.mounted) return success;
      }
      context.showSnack(
        collectionName != null
            ? l.searchAddedToNamed(title, collectionName)
            : l.searchAddedToCollection(title),
        type: SnackType.success,
      );
    } else {
      context.showSnack(
        collectionName != null
            ? l.searchAlreadyInNamed(title, collectionName)
            : l.searchAlreadyInCollection(title),
        type: SnackType.info,
      );
    }
    return success;
  }

  /// Returns `null` when the user cancels or the context unmounts.
  Future<PickedCollection?> pickCollection({
    required BuildContext context,
    required Set<int?> alreadyIn,
  }) async {
    final S l = S.of(context);
    final CollectionChoice? choice = await showCollectionPickerDialog(
      context: context,
      ref: _ref,
      title: l.searchAddToCollection,
      alreadyInCollectionIds: alreadyIn,
    );
    if (choice == null || !context.mounted) return null;
    return switch (choice) {
      ChosenCollection(:final Collection collection) =>
        PickedCollection(collection.id, collection.name),
      WithoutCollection() =>
        PickedCollection(null, l.collectionsUncategorized),
    };
  }

  /// Union of collection IDs that already contain [externalId] across two
  /// collected-items providers — used by Movie/TvShow handlers where the
  /// same TMDB id may live under regular or animation media type.
  Future<Set<int?>> collectedCollectionIdsAcross(
    int externalId,
    FutureProvider<Map<int, List<CollectedItemInfo>>> a,
    FutureProvider<Map<int, List<CollectedItemInfo>>> b,
  ) async {
    final List<Map<int, List<CollectedItemInfo>>> both = await Future.wait(
      <Future<Map<int, List<CollectedItemInfo>>>>[
        _ref.read(a.future),
        _ref.read(b.future),
      ],
    );
    return <CollectedItemInfo>[
      ...both[0][externalId] ?? <CollectedItemInfo>[],
      ...both[1][externalId] ?? <CollectedItemInfo>[],
    ].map((CollectedItemInfo i) => i.collectionId).toSet();
  }

  void _cacheImage(ImageType type, String imageId, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return;
    _ref.read(imageCacheServiceProvider).downloadImage(
          type: type,
          imageId: imageId,
          remoteUrl: imageUrl,
        );
  }
}
