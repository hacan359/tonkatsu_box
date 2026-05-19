import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/collection_item.dart';
import '../../providers/collection_selection_provider.dart';
import '../../providers/collections_provider.dart';
import '../bulk_action_bar.dart';

class CollectionBulkActionBar extends ConsumerWidget {
  const CollectionBulkActionBar({required this.collectionId, super.key});

  final int? collectionId;

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

    return BulkActionBar(
      items: selectedItems,
      collectionId: collectionId,
      onClearSelection: () => ref
          .read(collectionSelectionProvider(collectionId).notifier)
          .clear(),
    );
  }
}
