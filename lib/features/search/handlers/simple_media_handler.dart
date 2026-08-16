import 'package:core/models/collected_item_info.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_cache_service.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../services/search_collection_adder.dart';
import 'media_action_handler.dart';

/// Handler shape shared by Anime/Manga/VisualNovel (no platform picker or
/// animation branch); [T] spares the accessors repeated `as` casts.
class SimpleMediaHandler<T extends Object> implements MediaActionHandler {
  SimpleMediaHandler({
    required WidgetRef ref,
    required SearchCollectionAdder adder,
    required Set<int> Function() targetCollections,
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
    this.enrichBeforeDetails,
  })  : _ref = ref,
        _adder = adder,
        _targetCollections = targetCollections;

  final WidgetRef _ref;
  final SearchCollectionAdder _adder;
  final Set<int> Function() _targetCollections;

  final MediaType mediaType;
  final ImageType imageType;
  final FutureProvider<Map<int, List<CollectedItemInfo>>> collectedProvider;

  final int Function(T item) externalIdOf;
  final String Function(T item) imageIdOf;
  final String Function(T item) titleOf;
  final String? Function(T item) imageUrlOf;
  final Future<void> Function(T item) upsert;
  final Widget Function(T item, VoidCallback onAddToCollection) sheetBuilder;

  /// Narrows "already collected" lookups for multi-source types, whose
  /// providers share a numeric id space; null for single-source ones.
  final DataSource? Function(T item)? sourceOf;

  /// Fills in detail a search row lacks; applied on add-to-collection and,
  /// when [enrichBeforeDetails] flags it, before the sheet. Failure = no-op.
  final Future<T> Function(T item)? enrich;

  /// True opens the sheet with the [enrich]ed item behind a spinner — for
  /// sources (Fantlab) whose search rows are too sparse for a useful sheet.
  final bool Function(T item)? enrichBeforeDetails;

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
    final Set<int> targets = _targetCollections();
    if (targets.isNotEmpty) {
      await _addToCollections(context, targets, typed);
      return;
    }
    // Sources with sparse search rows (Fantlab) fetch the full record before
    // the sheet so it shows the cover / genres / description, not a stub.
    final T forDetails = (enrichBeforeDetails?.call(typed) ?? false)
        ? await _enriched(context, typed)
        : typed;
    if (!context.mounted) return;
    showDetails(context, forDetails, mediaType);
  }

  @override
  Future<void> addToAnyCollection(
    BuildContext context,
    Object item,
    MediaType mediaType,
  ) async {
    final T item0 = item as T;
    final Set<int?> alreadyIn = await _collectedCollectionIds(
      externalIdOf(item0),
      sourceOf?.call(item0),
    );
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

  Future<void> _addToCollections(
    BuildContext context,
    Set<int> collectionIds,
    T item,
  ) async {
    final T typed = await _enriched(context, item);
    if (!context.mounted) return;
    await _adder.addToCollections(
      context: context,
      collectionIds: collectionIds,
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

  /// Placements of [id]; [source] narrows them for multi-source types, whose
  /// providers hand out colliding numeric ids.
  Future<Set<int?>> _collectedCollectionIds(int id, DataSource? source) async {
    final Map<int, List<CollectedItemInfo>> collected =
        await _ref.read(collectedProvider.future);
    return (collected[id] ?? <CollectedItemInfo>[])
        .forSource(mediaType, source)
        .map((CollectedItemInfo i) => i.collectionId)
        .toSet();
  }
}
