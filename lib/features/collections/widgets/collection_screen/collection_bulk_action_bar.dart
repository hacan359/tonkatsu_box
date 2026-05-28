import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/collection_item.dart';
import '../../../../shared/models/collection_tag.dart';
import '../../helpers/collection_filters.dart';
import '../../providers/collection_selection_provider.dart';
import '../../providers/collections_provider.dart';
import '../../../settings/providers/settings_provider.dart';
import '../bulk_action_bar.dart';

class CollectionBulkActionBar extends ConsumerWidget {
  const CollectionBulkActionBar({
    required this.collectionId,
    this.collectionName,
    this.filters,
    this.tags = const <CollectionTag>[],
    super.key,
  });

  final int? collectionId;
  final String? collectionName;

  /// Active screen filters. When provided, the "select all visible" action
  /// targets `filters.apply(allItems, tags)` instead of the full list.
  final CollectionFilters? filters;
  final List<CollectionTag> tags;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Set<int> selection = ref.watch(
      collectionSelectionProvider(collectionId),
    );
    if (selection.isEmpty) return const SizedBox.shrink();

    final List<CollectionItem> all = ref
            .watch(collectionItemsNotifierProvider(collectionId))
            .valueOrNull ??
        const <CollectionItem>[];
    final List<CollectionItem> selectedItems = <CollectionItem>[
      for (final CollectionItem i in all)
        if (selection.contains(i.id)) i,
    ];
    if (selectedItems.isEmpty) return const SizedBox.shrink();

    final String anilistLang =
        ref.read(sharedPreferencesProvider).animeMangaTitleLanguage;
    final List<CollectionItem> visible = filters?.apply(
          all,
          tags,
          animeMangaTitleLanguage: anilistLang,
        ) ??
        all;

    return BulkActionBar(
      items: selectedItems,
      collectionId: collectionId,
      collectionName: collectionName,
      visibleCount: visible.length,
      onSelectAllVisible: () => ref
          .read(collectionSelectionProvider(collectionId).notifier)
          .selectAll(visible.map((CollectionItem i) => i.id)),
      onClearSelection: () => ref
          .read(collectionSelectionProvider(collectionId).notifier)
          .clear(),
    );
  }
}
