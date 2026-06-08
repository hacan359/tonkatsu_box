import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_cache_service.dart';
import '../../../shared/models/collected_item_info.dart';
import '../../../shared/models/data_source.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../services/search_collection_adder.dart';
import 'media_action_handler.dart';

/// Single-source media handler — no platform picker, no animation branch,
/// no post-add side effects. Anime, Manga, and VisualNovel all fit this
/// shape and previously lived as three near-identical copies.
///
/// The handler dispatches on item type at the registry level; the [T]
/// generic carries the concrete model so accessors don't have to repeat
/// `as` casts.
class SimpleMediaHandler<T extends Object> implements MediaActionHandler {
  SimpleMediaHandler({
    required WidgetRef ref,
    required SearchCollectionAdder adder,
    required int? targetCollectionId,
    required this.mediaType,
    required this.imageType,
    required this.collectedProvider,
    required this.externalIdOf,
    required this.imageIdOf,
    required this.titleOf,
    required this.imageUrlOf,
    required this.upsert,
    required this.sheetBuilder,
    this.sourceOf,
    this.enrich,
  })  : _ref = ref,
        _adder = adder,
        _targetCollectionId = targetCollectionId;

  final WidgetRef _ref;
  final SearchCollectionAdder _adder;
  final int? _targetCollectionId;

  final MediaType mediaType;
  final ImageType imageType;
  final FutureProvider<Map<int, List<CollectedItemInfo>>> collectedProvider;

  final int Function(T item) externalIdOf;
  final String Function(T item) imageIdOf;
  final String Function(T item) titleOf;
  final String? Function(T item) imageUrlOf;
  final Future<void> Function(T item) upsert;
  final Widget Function(T item, VoidCallback onAddToCollection) sheetBuilder;

  /// Optional provider discriminator stamped onto the collection row. Only
  /// manga needs it (AniList vs MangaBaka share a numeric id space).
  final DataSource? Function(T item)? sourceOf;

  /// Optional one-shot fetch that fills in detail a search result lacks (e.g.
  /// an OpenLibrary book description). Applied only when writing to the cache
  /// (add-to-collection), NOT on tap — opening the details sheet stays
  /// instant. The sheet shows the missing detail via its own lazy loader.
  /// Failures fall back to the original item.
  final Future<T> Function(T item)? enrich;

  /// Enriches [item] behind a blocking spinner. No-op (and no spinner) for
  /// sources without an [enrich] step.
  Future<T> _enriched(BuildContext context, T item) async {
    if (enrich == null) return item;
    return withBlockingSpinner(context, () => enrich!(item));
  }

  @override
  Future<void> onTap(
    BuildContext context,
    Object item,
    MediaType mediaType,
  ) async {
    final T typed = item as T;
    if (_targetCollectionId != null) {
      await _addToCollection(context, _targetCollectionId, typed);
      return;
    }
    showDetails(context, typed, mediaType);
  }

  @override
  Future<void> addToAnyCollection(
    BuildContext context,
    Object item,
    MediaType mediaType,
  ) async {
    final T item0 = item as T;
    final Set<int?> alreadyIn =
        await _collectedCollectionIds(externalIdOf(item0));
    if (!context.mounted) return;

    final PickedCollection? picked = await _adder.pickCollection(
      context: context,
      alreadyIn: alreadyIn,
    );
    if (picked == null || !context.mounted) return;

    // Enrich only after the picker is dismissed, so opening it stays instant.
    final T typed = await _enriched(context, item0);
    if (!context.mounted) return;

    await _adder.addToCollection(
      context: context,
      collectionId: picked.id,
      collectionName: picked.name,
      mediaType: this.mediaType,
      externalId: externalIdOf(typed),
      source: sourceOf?.call(typed),
      title: titleOf(typed),
      upsert: () => upsert(typed),
      imageType: imageType,
      imageId: imageIdOf(typed),
      imageUrl: imageUrlOf(typed),
    );
  }

  @override
  void showDetails(BuildContext context, Object item, MediaType mediaType) {
    final T typed = item as T;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext _) => sheetBuilder(
        typed,
        () => addToAnyCollection(context, typed, mediaType),
      ),
    );
  }

  Future<void> _addToCollection(
    BuildContext context,
    int collectionId,
    T item,
  ) async {
    final T typed = await _enriched(context, item);
    if (!context.mounted) return;
    await _adder.addToCollection(
      context: context,
      collectionId: collectionId,
      mediaType: mediaType,
      externalId: externalIdOf(typed),
      source: sourceOf?.call(typed),
      title: titleOf(typed),
      upsert: () => upsert(typed),
      imageType: imageType,
      imageId: imageIdOf(typed),
      imageUrl: imageUrlOf(typed),
    );
  }

  Future<Set<int?>> _collectedCollectionIds(int id) async {
    final Map<int, List<CollectedItemInfo>> collected =
        await _ref.read(collectedProvider.future);
    return (collected[id] ?? <CollectedItemInfo>[])
        .map((CollectedItemInfo i) => i.collectionId)
        .toSet();
  }
}
